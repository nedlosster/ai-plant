# Ollama: docker для языковых моделей

Платформа: Radeon 8060S (gfx1151), Ubuntu 24.04. Эта статья -- профиль проекта Ollama: история, архитектура, внутреннее устройство хранилища моделей, Modelfile, REST API, отношения с llama.cpp, экосистема.

На платформе основной inference-стек -- [llama.cpp](llama-cpp.md) + [LM Studio](lm-studio.md). Ollama здесь не обязателен, но полезно понимать как он работает, потому что тысячи инструментов вокруг (Open WebUI, LangChain, Continue, OpenDevin) ожидают именно Ollama API.

## Содержание

- [Что это и откуда](#что-это-и-откуда)
- [Главная идея: docker-пайплайн для моделей](#главная-идея-docker-пайплайн-для-моделей)
- [Архитектура: Go-сервер поверх llama.cpp](#архитектура-go-сервер-поверх-llama-cpp)
- [Modelfile: Dockerfile для LLM](#modelfile-dockerfile-для-llm)
- [Content-addressed storage и OCI-registry](#content-addressed-storage-и-oci-registry)
- [Жизненный цикл модели](#жизненный-цикл-модели)
- [Concurrent models и continuous batching](#concurrent-models-и-continuous-batching)
- [REST API и OpenAI compatibility](#rest-api-и-openai-compatibility)
- [Function calling, multimodal, embeddings](#function-calling-multimodal-embeddings)
- [Отношения с llama.cpp](#отношения-с-llama-cpp)
- [Экосистема поверх Ollama](#экосистема-поверх-ollama)
- [Сравнение с LM Studio, llama.cpp raw, vLLM](#сравнение-с-lm-studio-llama-cpp-raw-vllm)
- [Критика и ограничения](#критика-и-ограничения)
- [Нужен ли Ollama на нашей платформе](#нужен-ли-ollama-на-нашей-платформе)
- [Связанные статьи](#связанные-статьи)

---

## Что это и откуда

**Ollama** -- инструмент для запуска LLM локально через единый CLI и HTTP-сервер. Автор -- **Jeffrey Morgan** и **Michael Chiang** (бывшие Docker engineers). Репозиторий: [github.com/ollama/ollama](https://github.com/ollama/ollama). Официальный сайт: [ollama.com](https://ollama.com).

Первый релиз -- июль 2023, через 4 месяца после запуска llama.cpp. К апрелю 2026 Ollama -- самый массовый локальный inference-инструмент среди нетехнических пользователей: инсталлятор в один клик, команды уровня `ollama run llama3.2`, без сборки, без настроек.

Количественно: **150000+ звёзд** на GitHub, мейнтейнится компанией Ollama Inc (small team, seed funding от GitHub ex-execs). На [ollama.com/library](https://ollama.com/library) публикуется **500+ моделей**, готовых к запуску одной командой.

## Главная идея: docker-пайплайн для моделей

Основатели Ollama -- ex-Docker. И это видно во всём проекте.

**Аналогия, которая объясняет всё:**

| Docker | Ollama |
|--------|--------|
| `docker pull ubuntu:22.04` | `ollama pull llama3.2` |
| `docker run ubuntu` | `ollama run llama3.2` |
| `docker ps` | `ollama ps` |
| `docker push myimage` | `ollama push myuser/mymodel` |
| `Dockerfile` | `Modelfile` |
| Docker Hub (docker.io) | Ollama Library (ollama.com/library) |
| OCI-registry протокол | OCI-registry протокол (тот же) |
| Content-addressed layers (SHA256) | Content-addressed blobs (SHA256) |
| `/var/lib/docker` | `~/.ollama/models` |
| `docker-compose.yml` | `Modelfile` с несколькими моделями |

Это не маркетинговый ход. Под капотом Ollama действительно **реализует OCI Distribution Specification** -- тот же протокол, что использует Docker Hub, GitHub Container Registry, Quay. Модель там -- это набор SHA256-адресуемых blob'ов, связанных через manifest.json. Любой OCI-совместимый реестр может хостить Ollama-модели, и наоборот.

Это принципиально отличает Ollama от llama.cpp (где модель -- один `.gguf` файл), LM Studio (где модели управляются через GUI), и vLLM (где модели грузятся из HuggingFace).

## Архитектура: Go-сервер поверх llama.cpp

Ollama -- **не inference-движок**. Это **Go-сервер, который обёртывает llama.cpp** в удобный интерфейс. Компоненты:

```
                     +-----------------------------+
                     |  CLI (ollama)  [Go]         |
                     |  Команды: run/pull/push/ps  |
                     +-------------+---------------+
                                   |
                                   v
+---------------------+  HTTP  +-----------------------+
|  Клиенты            |<------>|  Ollama Server [Go]   |
|  - Open WebUI       |  :11434|  - REST API           |
|  - LangChain        |        |  - Model manager      |
|  - Continue         |        |  - Registry client    |
|  - LobeChat         |        |  - Scheduler          |
|  - Custom apps      |        +-----------+-----------+
+---------------------+                    |
                                           | cgo
                                           v
                              +---------------------------+
                              |  llama.cpp (vendored)     |
                              |  [C++]                    |
                              |  - GGML engine            |
                              |  - GGUF loader            |
                              |  - Backends: CUDA, Metal, |
                              |    ROCm, Vulkan, CPU      |
                              +---------------------------+
                                           |
                                           v
                              +---------------------------+
                              |  GPU / CPU                |
                              +---------------------------+
```

### Почему Go

Morgan и Chiang выбрали Go, а не Rust или Python, по причинам DevOps-бэкграунда:
- **Статическая сборка в один бинарник** -- как Docker, как Kubernetes, как Hugo. Нет «установите Python 3.11 и 15 GB зависимостей».
- **Отличная concurrency** через goroutines: сервер обрабатывает десятки параллельных HTTP-запросов и model loading без race conditions
- **Родная HTTP-библиотека** -- `net/http` вместо 5 уровней фреймворков
- **Лёгкая интеграция с C/C++** через cgo -- ключ к работе с llama.cpp

### cgo bridge к llama.cpp

Сервер вызывает llama.cpp через [cgo](https://pkg.go.dev/cmd/cgo). В дереве репозитория находится **vendored snapshot llama.cpp** (подпапка `llama/`), с собственными патчами поверх upstream. Сборка происходит так:

1. `cmake` компилирует llama.cpp и backends в static libraries (`.a`)
2. Go linker через cgo подтягивает эти библиотеки в `ollama` бинарник
3. Итоговый файл -- **single static binary**, содержащий всё: сервер, CLI, GGML, backends

Это повторяет философию llama.cpp (zero dependencies, single binary) на следующем уровне. Один скачанный файл `ollama` содержит всё необходимое.

## Modelfile: Dockerfile для LLM

**Modelfile** -- текстовый формат, описывающий модель как сборку. Синтаксис явно скопирован с Dockerfile:

```dockerfile
FROM llama3.2

PARAMETER temperature 1
PARAMETER num_ctx 4096
PARAMETER top_p 0.9
PARAMETER stop "<|eot_id|>"

TEMPLATE """{{- if .System }}<|start_header_id|>system<|end_header_id|>

{{ .System }}<|eot_id|>
{{- end }}
{{- range .Messages }}<|start_header_id|>{{ .Role }}<|end_header_id|>

{{ .Content }}<|eot_id|>
{{- end }}<|start_header_id|>assistant<|end_header_id|>

"""

SYSTEM You are Mario from Super Mario Bros, acting as an assistant.
```

Директивы:

| Директива | Назначение |
|-----------|------------|
| `FROM` | Базовая модель (по имени из registry или путь к GGUF/safetensors) |
| `PARAMETER` | Runtime-параметр inference (температура, top-p, context window, stop tokens) |
| `TEMPLATE` | Go-шаблон (text/template) для формирования chat prompt |
| `SYSTEM` | Системный промпт по умолчанию |
| `ADAPTER` | LoRA-адаптер поверх базовой модели |
| `LICENSE` | Текст лицензии |
| `MESSAGE` | Few-shot примеры (user/assistant пары) |

### Сборка модели

```bash
# Modelfile в текущей директории
ollama create mario -f Modelfile

# Или с явным путём
ollama create mario -f /path/to/Modelfile

# Теперь можно запускать
ollama run mario
```

Команда `ollama create` -- это аналог `docker build`. Она:
1. Парсит Modelfile
2. Резолвит `FROM` -- либо скачивает базовую модель, либо использует локальную
3. Применяет `PARAMETER`, `TEMPLATE`, `SYSTEM` как новый layer поверх базовой
4. Сохраняет через content-addressed storage
5. Регистрирует в `~/.ollama/models/manifests/library/mario/latest`

### Template: Go text/template

`TEMPLATE` использует синтаксис пакета `text/template` из стандартной библиотеки Go. Переменные:

- `.System` -- системный промпт
- `.Messages` -- массив сообщений с `.Role` и `.Content`
- `.Prompt` -- raw prompt для completion
- `.Response` -- ответ модели
- `.Tools` -- массив tool definitions (для function calling)

Это **не Jinja2** (который использует llama.cpp через minja), а самостоятельный template engine Ollama. На практике оба выражают одно и то же: форматирование chat messages в flat prompt, но синтаксис разный.

## Content-addressed storage и OCI-registry

Самая элегантная часть Ollama. Модели хранятся **не как GGUF-файлы в папке**, а как набор контент-адресуемых blob'ов с manifest'ом.

### Структура `~/.ollama/models/`

```text
~/.ollama/models/
  blobs/
    sha256-25b36eed1a9b8c7d...   <- веса модели (GGUF file), большой
    sha256-abc123...              <- config layer (маленький JSON)
    sha256-def456...              <- template (маленький)
    sha256-789aaa...              <- system prompt
    sha256-11bb22...              <- tokenizer config
  manifests/
    registry.ollama.ai/
      library/
        llama3.2/
          latest    <- JSON манифест
          3b        <- тот же blob'ы, другой манифест
    my-custom/
      mario/
        latest      <- ссылается на те же blob'ы что и llama3.2
```

### Manifest

Манифест -- это JSON, совместимый с OCI Image Spec v1.1:

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
  "config": {
    "mediaType": "application/vnd.docker.container.image.v1+json",
    "digest": "sha256:abc123...",
    "size": 1234
  },
  "layers": [
    {
      "mediaType": "application/vnd.ollama.image.model",
      "digest": "sha256:25b36eed1a9b8c7d...",
      "size": 6872041856
    },
    {
      "mediaType": "application/vnd.ollama.image.template",
      "digest": "sha256:def456...",
      "size": 1052
    },
    {
      "mediaType": "application/vnd.ollama.image.system",
      "digest": "sha256:789aaa...",
      "size": 108
    },
    {
      "mediaType": "application/vnd.ollama.image.params",
      "digest": "sha256:11bb22...",
      "size": 98
    }
  ]
}
```

Каждый layer -- отдельный blob с SHA256-адресацией. Media types начинаются с `application/vnd.ollama.image.*`:
- `.model` -- собственно веса (GGUF)
- `.template` -- chat template
- `.system` -- system prompt
- `.params` -- параметры (temperature, top-p, ...)
- `.license` -- лицензия
- `.tensor` -- для моделей, хранящихся по тензорам (новый формат, для diffusion-моделей)

### Почему это важно: дедупликация

Content-addressed storage даёт **бесплатную дедупликацию**. Пример:

1. Скачали `llama3.2:latest` (3B, 2 GB)
2. Создали кастомную `mario` с `FROM llama3.2` + свой system prompt

Модель `mario` **не занимает 2 GB**. Она занимает **~100 байт** -- новый system prompt как отдельный blob + новый манифест, ссылающийся на тот же blob весов. Весы переиспользуются.

Другие примеры:
- Три варианта одной модели (`latest`, `3b`, `3b-instruct-q4_K_M`) используют общий tokenizer blob
- Две версии модели (`v1.0` и `v1.1`) различаются только одним слоем весов -- экономия при update'ах
- Форки модели разных пользователей используют общую базу

Это ровно та же дедупликация, что Docker использует для base images. Старая привычка DevOps-инженеров, применённая к LLM.

### OCI Distribution Spec: push/pull

`ollama pull llama3.2` под капотом делает это:

1. GET манифеста: `https://registry.ollama.ai/v2/library/llama3.2/manifests/latest`
2. Сервер возвращает JSON с layers
3. Для каждого layer: `GET /v2/library/llama3.2/blobs/sha256:25b36eed...`
4. Blob скачивается по chunked-transfer, проверка SHA256
5. Если blob уже есть в `~/.ollama/models/blobs/` -- пропускается
6. Манифест сохраняется в `~/.ollama/models/manifests/...`

Это **тот же протокол**, что использует `docker pull`. В теории можно пушить Ollama-модели в Docker Hub или GitHub Container Registry (с правильными media types). Некоторые пользователи действительно так делают -- хостят кастомные Ollama-модели в корпоративных OCI-реестрах с SSO, RBAC, audit logs.

## Жизненный цикл модели

### `ollama pull llama3.2`

Скачивание. Следует OCI Distribution Spec (см. выше). После завершения модель **не загружена в память** -- только на диске.

### `ollama run llama3.2`

Команда делает несколько вещей:
1. Проверяет наличие модели, если нет -- делает `pull`
2. POST на `/api/generate` с параметрами run (interactive)
3. Сервер загружает модель в VRAM (если не загружена)
4. Открывает interactive REPL -- читает stdin, стримит вывод

### `ollama ps`

Показывает **загруженные в память** модели:

```
NAME             ID              SIZE      PROCESSOR    UNTIL
llama3.2:latest  a80c4f17acd5    2.8 GB    100% GPU     4 minutes from now
```

Поле `UNTIL` -- ключ к пониманию: **модели выгружаются автоматически** через `keep_alive` (default 5 минут после последнего запроса). Это позволяет запустить несколько разных моделей за день, не перезагружая сервер и не думая о VRAM.

### `ollama stop llama3.2`

Принудительная выгрузка из памяти. Альтернатива -- `keep_alive: 0` в запросе.

### `ollama rm llama3.2`

Удаление с диска. Удаляется manifest, blob'ы не удаляются пока их кто-то ссылает. Периодический `ollama prune` чистит неиспользуемые blob'ы -- аналог `docker system prune`.

## Concurrent models и continuous batching

Ollama поддерживает одновременную работу нескольких моделей и параллельную обработку запросов на одну модель. Управляется через environment variables:

| Переменная | Назначение | Default |
|------------|------------|---------|
| `OLLAMA_MAX_LOADED_MODELS` | Сколько моделей может быть загружено одновременно | auto (считается по VRAM) |
| `OLLAMA_NUM_PARALLEL` | Сколько параллельных запросов на одну модель | auto (обычно 4) |
| `OLLAMA_MAX_QUEUE` | Очередь ожидающих запросов | 512 |
| `OLLAMA_KEEP_ALIVE` | Время жизни модели в памяти после последнего запроса | 5m |
| `OLLAMA_HOST` | Где слушать | `127.0.0.1:11434` |
| `OLLAMA_GPU_OVERHEAD` | Reserved VRAM для backend'а | 1 GB |
| `OLLAMA_FLASH_ATTENTION` | Включить flash attention для большего ctx | 0 |

### Автоматическое управление VRAM

Ollama **не требует** указывать `num_gpu_layers` как llama.cpp. При загрузке модели сервер делает это сам:

1. Спрашивает у backend сколько свободно VRAM (через `ggml_backend_free` API)
2. Считает `model_size + kv_cache_size + overhead`
3. Если помещается -- все слои на GPU
4. Если не помещается -- бинарный поиск: максимально возможное количество слоёв на GPU, остальное на CPU
5. Применяет offload

На Strix Halo с 120 GiB unified memory это работает хорошо: **все популярные модели до 122B MoE полностью помещаются на GPU**, и Ollama автоматически делает `num_gpu_layers = -1` (все слои).

### Continuous batching

Когда `OLLAMA_NUM_PARALLEL=4`, одна загруженная модель имеет 4 **слота** (аналог llama-server `--parallel`). Если 4 клиента одновременно присылают запросы, они все обрабатываются в одном batch на каждом шаге генерации. Это увеличивает **throughput** (суммарная скорость генерации всех слотов), но каждый индивидуальный слот идёт медленнее чем single-user.

Важная деталь: **параллельные слоты делят KV-cache пропорционально**. Если модель запущена с `num_ctx=8192` и `OLLAMA_NUM_PARALLEL=4`, каждый слот получает `8192 / 4 = 2048` токенов контекста. Это неочевидно и может быть причиной обрывов длинных запросов.

## REST API и OpenAI compatibility

Сервер Ollama слушает на `127.0.0.1:11434`. У него два набора endpoint'ов:

### Native Ollama API

| Endpoint | Назначение |
|----------|------------|
| `POST /api/generate` | Completion (нативный формат) |
| `POST /api/chat` | Chat completion (нативный формат) |
| `POST /api/embed` | Эмбеддинги |
| `GET /api/tags` | Список локальных моделей |
| `POST /api/pull` | Скачать модель |
| `POST /api/push` | Загрузить в registry |
| `POST /api/create` | Создать модель из Modelfile |
| `POST /api/delete` | Удалить модель |
| `POST /api/copy` | Копия модели с новым именем |
| `POST /api/show` | Информация о модели (Modelfile, template, params) |
| `GET /api/ps` | Список загруженных в память моделей |
| `POST /api/blobs/:digest` | Загрузить blob по SHA256 |
| `HEAD /api/blobs/:digest` | Проверить наличие blob |

Пример:

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {"role": "user", "content": "Привет"}
  ],
  "stream": true,
  "keep_alive": "10m"
}'
```

### OpenAI-compatible API

Для совместимости с существующими SDK:

| Endpoint | Mirror от OpenAI |
|----------|--------|
| `POST /v1/chat/completions` | ChatGPT API |
| `POST /v1/completions` | Legacy completion |
| `POST /v1/embeddings` | Embeddings |
| `GET /v1/models` | List models |

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama"  # игнорируется, нужен для валидации SDK
)

response = client.chat.completions.create(
    model="llama3.2",
    messages=[{"role": "user", "content": "Привет"}]
)
```

Это делает Ollama **drop-in replacement** для OpenAI API в существующих приложениях. Любой код, работающий с `openai` Python/Node SDK, переключается на локальные модели сменой base_url.

## Function calling, multimodal, embeddings

### Function calling

Поддерживается с 2024 года для моделей с нативным tool-use (Llama 3.x, Qwen3, Mistral Nemo). В запросе передаются `tools` в OpenAI формате:

```json
{
  "model": "llama3.2",
  "messages": [...],
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get weather for a city",
        "parameters": {
          "type": "object",
          "properties": {
            "city": {"type": "string"}
          }
        }
      }
    }
  ]
}
```

Сервер рендерит tool-описания в промпт через Go `text/template`, модель генерирует tool-call, сервер парсит его из вывода и возвращает в структурированном виде. В отличие от llama-server (который использует minja + Jinja2 из GGUF), Ollama использует свой template engine -- template хранится в манифесте отдельным слоем.

### Multimodal (vision)

Vision-модели в Ollama хранятся как **одна модель, содержащая и LLM, и projector**. При создании через Modelfile указывается две GGUF-директивы:

```dockerfile
FROM llava:7b
```

Под капотом `llava:7b` в registry содержит два blob'а (один для LLM, один для mmproj). Ollama автоматически передаёт их llama.cpp при загрузке.

Запросы идут через OpenAI vision format:

```json
{
  "model": "llava:7b",
  "messages": [{
    "role": "user",
    "content": "Что на картинке?",
    "images": ["base64data..."]
  }]
}
```

Поддерживаемые модели: LLaVA, LLaVA-Next, BakLLaVA, Moondream, Llama 3.2 Vision, Qwen2.5-VL, Gemma 3/4 Vision.

### Embeddings

`POST /api/embed` или `POST /v1/embeddings`:

```bash
curl http://localhost:11434/api/embed -d '{
  "model": "nomic-embed-text",
  "input": "The sky is blue"
}'
```

Поддерживаются стандартные модели: `nomic-embed-text`, `mxbai-embed-large`, `all-minilm`, `snowflake-arctic-embed`. Это критично для RAG-пайплайнов: в одной Ollama-инсталляции держится и chat-модель, и embedding-модель, используются через один API.

## Отношения с llama.cpp

Вопрос, который часто возникает: **Ollama -- это форк llama.cpp?** Нет. Но зависимость глубокая.

### Что общего

- **llama.cpp -- единственный inference backend в Ollama**. Все вычисления (GGML, GGUF loading, KV-cache, CUDA/Metal/Vulkan/ROCm, sampling) делаются кодом llama.cpp. Ollama -- это HTTP-сервер и менеджер моделей, а не inference engine
- Внутри репозитория Ollama лежит **vendored snapshot llama.cpp** (папка `llama/`). Ollama периодически обновляет этот snapshot из upstream ggml-org/llama.cpp
- Ollama использует все возможности llama.cpp: K-quants, IQ-quants, flash attention, MoE, MLA, mmproj для vision, grammar sampling, continuous batching

### Что своё

- Менеджмент моделей (pull/push/tag/registry) -- полностью написан с нуля на Go
- Model scheduling (загрузка/выгрузка из памяти по keep_alive) -- Go-layer
- HTTP API (native + OpenAI-compat) -- `net/http` в Go, не httplib llama.cpp
- Chat template engine (`text/template`) -- не Jinja2, не minja
- Modelfile parser и builder -- Go
- OCI registry client -- Go

### Custom patches поверх llama.cpp

Команда Ollama держит **набор патчей**, которые применяются к vendored llama.cpp. Обычно это:
- Fix'ы, которые ещё не приняты в upstream
- Изменения API для интеграции с Go cgo (лучшие сигнатуры функций, структур)
- Экспериментальные оптимизации для конкретного железа

Это создаёт **задержку в 2-4 недели** между появлением новой модели / фичи в llama.cpp upstream и её поддержкой в Ollama. На практике это обычно незаметно для массового пользователя, но для enthusiast'ов которые ждут новейшую модель -- llama-server upstream работает быстрее.

## Экосистема поверх Ollama

Ollama стал **неофициальным стандартом локальной LLM-интеграции** для приложений. Тулы, которые умеют работать с Ollama из коробки:

| Категория | Продукты |
|-----------|----------|
| **UI chat** | [Open WebUI](../apps/open-webui/README.md), [LobeChat](../apps/lobe-chat/README.md), Msty, BigAGI, Chatbot Ollama, Hollama, Ollamac |
| **IDE/coding** | [Continue.dev](../ai-agents/agents/continue-dev.md), [Aider](../ai-agents/agents/aider.md), [opencode](../ai-agents/agents/opencode.md) (через OpenAI-compat), twinny, Tabby |
| **Orchestration** | LangChain, LlamaIndex, CrewAI, AutoGen, Haystack, DSPy |
| **Agents** | [Cline](../ai-agents/agents/cline.md), [Roo Code](../ai-agents/agents/roo-code.md), OpenHands, Devika, AgentGPT |
| **Workflows** | Dify, n8n (AI-node), Flowise, LangFlow |
| **RAG** | AnythingLLM, PrivateGPT, LocalGPT, GPT4All, Quivr |
| **API gateway** | LiteLLM, OpenRouter (прокси) |

Это даёт **сетевой эффект**: если пишешь новое LLM-приложение, первое что нужно поддержать -- Ollama API, потому что у него самая большая аудитория пользователей. Даже если под капотом будет llama.cpp, vLLM или OpenAI -- API-интерфейс повторяет ollama/openai.

## Сравнение с LM Studio, llama.cpp raw, vLLM

| Параметр | Ollama | LM Studio | llama.cpp raw | vLLM |
|----------|--------|-----------|---------------|------|
| **Интерфейс** | CLI + HTTP API | GUI + HTTP API | CLI + HTTP API (llama-server) | Python + HTTP API |
| **Установка** | `curl \| sh` (1 шаг) | Installer (GUI) | `make` / `cmake` | `pip install vllm` |
| **Кривая обучения** | низкая | очень низкая | средняя | высокая |
| **Поиск моделей** | библиотека ollama.com | встроенный HF browser | HF вручную | HF/GitHub вручную |
| **Формат моделей** | OCI blob layers + GGUF | GGUF из HF | GGUF | safetensors (HF) |
| **Quantization формат** | GGUF (через llama.cpp) | GGUF | GGUF | AWQ, GPTQ, BitsAndBytes |
| **Multimodal** | да | да | да | частично |
| **Function calling** | да | да | да (--jinja) | да |
| **Continuous batching** | да | да (llama.cpp) | да | да (PagedAttention первоисточник) |
| **Speculative decoding** | да (с 2025) | да | да | да |
| **Concurrent models** | **да (авто)** | одна за раз | одна за раз (нужен отдельный процесс) | одна за раз |
| **Auto VRAM offload** | **да** | да | вручную (`-ngl`) | нет (требует все на GPU) |
| **Model hub** | ollama.com/library | HuggingFace | HuggingFace | HuggingFace |
| **Нужен GUI** | нет | да | нет | нет |
| **Production deploy** | возможно | нет | возможно | **основной use case** |
| **Multi-GPU tensor parallel** | ограничено | ограничено | ограничено | **полная поддержка** |
| **Throughput per GPU** | ~llama.cpp | ~llama.cpp | baseline | **2-5x быстрее** |
| **Memory efficiency** | ~llama.cpp | ~llama.cpp | baseline | лучше через PagedAttention |
| **Main audience** | developers, enthusiasts | non-technical users | hackers | datacenter |

### Когда выбирать что

- **Ollama**: хочется «просто запустить модель», чтобы потом её использовать из LangChain/Open WebUI/своего кода через API. Сценарий «разработчик в одну команду даёт доступ к локальной LLM всей команде».
- **LM Studio**: нетехнический пользователь, нужен GUI, нужен browser HuggingFace, chat-интерфейс из коробки.
- **llama.cpp raw (llama-server)**: максимальный контроль, все новые фичи сразу, кастомные параметры, production-deploy в docker с точным контролем VRAM.
- **vLLM**: datacenter NVIDIA, максимальный throughput, multi-user production, много параллельных запросов на одной модели.

## Критика и ограничения

### 1. Lag от upstream llama.cpp

Vendored snapshot + custom patches -> 2-4 недели задержки. Новые архитектуры (Mamba2, hybrid SSM) и оптимизации доступны в llama-server раньше.

### 2. Ограниченная квантизация

Ollama не предлагает пользователю выбор квантизации при импорте -- сервер сам выбирает (обычно Q4_K_M или Q4_0). Если нужен Q6_K, IQ2_XXS или custom mixed precision -- нужно делать GGUF отдельно через `llama-quantize` и импортировать через Modelfile.

### 3. KV-cache splitting неочевиден

Как упоминалось выше: при `OLLAMA_NUM_PARALLEL=4` и `num_ctx=8192` каждый слот получает 2048 токенов. Это не документировано явно и может быть причиной «непонятных обрывов длинных промптов» у новичков.

### 4. Automatic VRAM offload иногда ошибается

На гибридных APU (Strix Halo, Apple Silicon) с unified memory автоматический расчёт VRAM может дать неточную оценку, особенно при конкуренции с другими процессами (ComfyUI, PyTorch). Приходится выставлять `OLLAMA_GPU_OVERHEAD` вручную.

### 5. Нет native multi-GPU tensor parallel

Ollama наследует это ограничение от llama.cpp. Для большой модели на 2-4 GPU лучше использовать vLLM или llama.cpp с `--tensor-split` (последнее Ollama скрывает от пользователя).

### 6. Registry централизован

`registry.ollama.ai` -- единственная официальная точка распространения. Self-hosted OCI-реестры поддерживаются технически, но UX для кастомной модели «залить на свой реестр» хуже чем у Docker. Для enterprise часто используется LiteLLM / Hugging Face inference server как gateway.

## Нужен ли Ollama на нашей платформе

Короткий ответ: **в качестве основного inference-стека -- нет**. На Strix Halo уже есть [llama.cpp](llama-cpp.md) + [LM Studio](lm-studio.md) + [llama-server](vulkan-llama-cpp.md). Ollama добавил бы дублирование:

- Сборка llama.cpp мы делаем сами (через `/llama-cpp` скилл), получая latest upstream и гибкость патчей
- Vulkan backend работает лучше чем Ollama CUDA/ROCm path на gfx1151
- llama-server покрывает все Ollama endpoints плюс больше (через `--jinja` в чистом виде)
- Модели скачиваются через huggingface-cli с точным контролем квантизации

Ollama **имеет смысл** в двух сценариях:
1. **Интеграция с тулами, которые ждут Ollama API**. Например, [Continue.dev](../ai-agents/agents/continue-dev.md) имеет пресет для Ollama и пресет для OpenAI-compat. Первый работает «из коробки», второй требует указать модель и base_url вручную.
2. **Быстрый demo** для гостей / коллег. Команда `ollama run` проще чем «запусти llama-server с этими флагами, потом подключись через curl».

В качестве compromise можно установить Ollama как **thin wrapper** поверх уже собранного llama.cpp, указав `OLLAMA_HOST=0.0.0.0:11434` на отдельный порт (не конфликтует с llama-server на 8081). Это даст API-совместимость без повторной установки моделей: модели можно импортировать через `ollama create` с `FROM /path/to/qwen3-coder-next.gguf`.

### Альтернатива: LiteLLM

Если нужно «Ollama-API-совместимость без установки Ollama» -- есть [LiteLLM](https://github.com/BerriAI/litellm), который транслирует OpenAI / Ollama API в любой backend (в том числе llama-server). Это чище, чем держать два inference-сервера.

## Связанные статьи

- [llama.cpp (профиль проекта)](llama-cpp.md) -- inference-движок, на котором работает Ollama
- [Lemonade (профиль проекта)](lemonade.md) -- альтернативный стек с поддержкой Ryzen AI NPU, в Generic mode использует Ollama как backend
- [LM Studio](lm-studio.md) -- конкурирующая GUI-обёртка над llama.cpp
- [vulkan-llama-cpp.md](vulkan-llama-cpp.md) -- как собрать llama-server на платформе вручную
- [backends-comparison.md](backends-comparison.md) -- сравнение backend'ов на Strix Halo
- [model-selection.md](model-selection.md) -- GGUF vs safetensors, выбор моделей
- [../llm-guide/function-calling.md](../llm-guide/function-calling.md) -- tool use, templates
- [../llm-guide/quantization.md](../llm-guide/quantization.md) -- K-quants и IQ-quants в контексте GGML
- [../ai-agents/agents/continue-dev.md](../ai-agents/agents/continue-dev.md) -- IDE-агент с native Ollama-поддержкой
