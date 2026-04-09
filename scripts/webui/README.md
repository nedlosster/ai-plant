# scripts/webui/ -- веб-интерфейсы для LLM

Веб-интерфейсы подключаются к inference backend (llama.cpp) через OpenAI-совместимый API.
Inference -- нижний слой, управляется отдельно через `scripts/inference/`.

## Структура

```
webui/
  config.sh              # общее: Docker, проверка inference
  status.sh              # статус контейнеров и backend
  open-webui/            # Open WebUI (расширенный чат)
    install.sh / start.sh / stop.sh / config.sh
  lobe-chat/             # Lobe Chat (модульный интерфейс)
    install.sh / start.sh / stop.sh / config.sh
```

## Варианты интерфейсов

| Интерфейс | Порт | Описание |
|-----------|------|----------|
| Встроенный UI llama-server | 8080 | Минимальный чат, работает без установки |
| Open WebUI | 3210 | История, markdown, RAG, переключение моделей |
| Lobe Chat | 3211 | Красивый, модульный, поддержка плагинов |

## Быстрый старт

```bash
# 1. Запустить inference backend (обязательно)
./scripts/inference/start-server.sh model.gguf --daemon

# 2. Установить веб-интерфейс
./scripts/webui/open-webui/install.sh
./scripts/webui/lobe-chat/install.sh

# 3. Запустить
./scripts/webui/open-webui/start.sh
./scripts/webui/lobe-chat/start.sh

# 4. Статус
./scripts/webui/status.sh

# 5. Остановить
./scripts/webui/open-webui/stop.sh
./scripts/webui/lobe-chat/stop.sh
```

## Общий статус системы

```bash
./scripts/status.sh
```

Показывает GPU, inference серверы, веб-интерфейсы, модели.

## Локальная конфигурация inference

Если inference запущен на нестандартном порту (например 8081 через `vulkan/preset/*.sh`), задай его в `~/.config/ai-plant/inference.env`:

```bash
mkdir -p ~/.config/ai-plant
cp scripts/webui/inference.env.example ~/.config/ai-plant/inference.env
$EDITOR ~/.config/ai-plant/inference.env
```

Файл не в git, читается всеми web-UI скриптами через `webui/config.sh`. Переменные:

| Переменная | Дефолт | Назначение |
|-----------|--------|------------|
| `LLAMA_HOST` | `localhost` | хост llama-server (для health-check) |
| `LLAMA_PORT` | `8080` | порт chat API |
| `LLAMA_FIM_PORT` | `8081` | порт FIM-сервера |

## Function calling в веб-интерфейсах

Function calling (см. [docs/llm-guide/function-calling.md](../../docs/llm-guide/function-calling.md)) -- механизм, при котором модель возвращает structured tool calls вместо текста, а клиент выполняет реальные функции и возвращает результат. На уровне модели поддержку обеспечивают [Qwen3-Coder Next](../../docs/models/families/qwen3-coder.md), [Gemma 4](../../docs/models/families/gemma4.md), [Devstral 2](../../docs/models/families/devstral.md), [Qwen3-VL](../../docs/models/families/qwen3-vl.md), [Mistral Small 3.1](../../docs/models/families/mistral-small-31.md). На уровне веб-интерфейса -- разные клиенты делают это по-разному.

### Обязательное условие на стороне llama-server

Все наши пресеты в `scripts/inference/vulkan/preset/*.sh` запускаются с `--jinja`. Это критично: без него llama-server не парсит chat-template модели и не выделяет tool_calls в OpenAI-совместимый формат -- веб-интерфейс получит tool calls как обычный текст и не распознает их.

Проверка:

```bash
grep -l '\-\-jinja' scripts/inference/vulkan/preset/*.sh
# должны быть все пресеты для FC-моделей
```

### Open WebUI: tools и MCP

Open WebUI поддерживает три способа подключения функций:

#### 1. Built-in Tools (Python-функции)

Tools в Open WebUI -- это Python-файлы с декорированными функциями, которые система автоматически предлагает модели. Размещаются через UI: **Workspace → Tools → +**.

Пример простого инструмента (поиск по локальным заметкам):

```python
"""
title: Local Notes Search
author: <user>
description: Поиск по локальной директории заметок ~/notes
required_open_webui_version: 0.4.0
"""

from pydantic import BaseModel, Field
from pathlib import Path

class Tools:
    class Valves(BaseModel):
        notes_dir: str = Field(
            default="/data/notes",
            description="Путь к директории заметок (внутри контейнера)"
        )

    def __init__(self):
        self.valves = self.Valves()

    def search_notes(self, query: str) -> str:
        """
        Поиск по локальным markdown-заметкам.
        :param query: Поисковый запрос
        :return: Список найденных файлов с фрагментами
        """
        results = []
        for path in Path(self.valves.notes_dir).rglob("*.md"):
            text = path.read_text(errors="ignore")
            if query.lower() in text.lower():
                idx = text.lower().find(query.lower())
                snippet = text[max(0, idx - 100):idx + 200]
                results.append(f"**{path.name}**\n{snippet}\n")
        return "\n---\n".join(results) if results else "Ничего не найдено"
```

После добавления через UI:
1. Открыть чат
2. В меню модели включить tool (галочка рядом с названием)
3. Спросить "найди в моих заметках про X"
4. Open WebUI автоматически подставит JSON-схему функции в `tools` поле API-запроса к llama-server
5. Модель вернёт `tool_calls`, Open WebUI выполнит Python-функцию, передаст результат обратно

Документация: [docs.openwebui.com/features/plugin/tools](https://docs.openwebui.com/features/plugin/tools/)

#### 2. Native function calling (галочка в настройках модели)

В Open WebUI: **Settings → Models → <модель> → Advanced Params → Function Calling: Native**

Это переключает Open WebUI с режима "promp injection" (где tools описываются в system prompt) на режим использования native `tools` field в API-запросе. Для моделей с native FC (Qwen3-Coder Next, Gemma 4) -- обязательно включить.

```
Function Calling Mode:
  - Default (prompt injection)  -- работает на любых моделях, но менее надёжно
  - Native                       -- использует tools в API, требует native FC модель
```

#### 3. MCP-серверы (через Pipes / OpenAPI)

Open WebUI 0.5+ поддерживает MCP через **Pipes** или **OpenAPI tool spec**. Это даёт доступ к экосистеме готовых [MCP-серверов](https://github.com/modelcontextprotocol/servers): filesystem, github, postgres, slack и др.

Установка:

```bash
# Внутри контейнера Open WebUI или через volume mount
pip install mcp-server-filesystem mcp-server-github

# Запуск MCP-сервера как sidecar контейнера
docker run -d \
  --name mcp-filesystem \
  -v /home/nedlosster/notes:/data:ro \
  ghcr.io/modelcontextprotocol/server-filesystem /data
```

Затем подключить как OpenAPI tool в **Workspace → Tools → +OpenAPI**.

Подробнее: [docs.openwebui.com/openapi-servers/mcp](https://docs.openwebui.com/openapi-servers/mcp/)

### Lobe Chat: plugins и function calling

Lobe Chat имеет встроенную систему **plugins**, которая использует tool_calls под капотом. Подключение:

1. Открыть **Discover → Plugins**
2. Включить нужные (Web Browser, Search Engine, Image Generator, Calculator и др.)
3. Plugins автоматически передаются модели как tools

Для local llama-server **Lobe Chat требует включения OpenAI Function Calling режима**:

**Settings → Default Agent → Model Settings → Use Function Call → Enable**

Иначе plugins будут отправляться как prompt injection (хуже).

#### Кастомные plugins в Lobe Chat

Lobe Chat позволяет писать свои plugins. Структура -- TypeScript-проект с манифестом:

```json
{
  "identifier": "local-notes",
  "version": "1.0.0",
  "api": [{
    "name": "searchNotes",
    "description": "Поиск по локальным заметкам",
    "parameters": {
      "type": "object",
      "properties": {
        "query": {"type": "string"}
      },
      "required": ["query"]
    }
  }],
  "ui": {
    "url": "http://localhost:3400",
    "height": 400
  },
  "meta": {
    "title": "Local Notes",
    "description": "Поиск по личной базе заметок"
  }
}
```

И отдельный микросервис, реализующий API. Сложнее Open WebUI, но мощнее.

Документация: [lobehub.com/docs/usage/plugins](https://lobehub.com/docs/usage/plugins/basic)

### Встроенный UI llama-server (порт 8080)

Минимальный чат, **не поддерживает tools UI**. Function calling работает только если посылать запросы напрямую через `/v1/chat/completions` с полем `tools` (т.е. через свой Python-скрипт, не через webui llama-server). Подходит для теста "работает ли вообще FC у модели", не для production.

### Сравнение веб-интерфейсов по FC

| Интерфейс | Native FC | MCP | Свои tools | Multi-tool | Vision + FC |
|-----------|-----------|-----|------------|------------|-------------|
| **Open WebUI** | да (галочка) | да (через Pipes/OpenAPI) | да (Python) | да | да |
| **Lobe Chat** | да (галочка) | нет | да (TS plugins) | да | да |
| llama-server UI | нет | нет | нет | нет | да (только vision, без tools UI) |

### Рекомендация

- **Daily usage с готовыми инструментами** -- **Open WebUI**: проще писать Python-tools, поддерживает MCP, лучше документирована.
- **Красивый UX, plugin marketplace** -- **Lobe Chat**: визуально приятнее, но для своих tools нужен TypeScript.
- **Тест FC у модели без UI** -- встроенный llama-server UI или прямой curl/Python-скрипт против `/v1/chat/completions`.

### Типичные проблемы

1. **Модель возвращает tool_calls как текст** → не запущен `--jinja` в llama-server. Перезапустить пресет.
2. **Модель игнорирует tools** → температура слишком высокая (>0.7) или description функции невнятный. Снизить до 0.2, переписать description.
3. **Open WebUI не показывает результат tool_call** → проверить что включён режим Native в Function Calling settings.
4. **Lobe Chat plugins не работают** → не включён "Use Function Call" в model settings.
5. **MCP-сервер не подключается** → проверить, что MCP-сервер запущен на доступном порту, а Open WebUI имеет network access.
6. **tool_call с invalid arguments** → модель плохо натренирована на FC (например Qwen2.5-Coder 1.5B). Использовать модель с native FC из таблицы выше.

### Полезные ссылки

- [docs/llm-guide/function-calling.md](../../docs/llm-guide/function-calling.md) -- теория + per-model setup на платформе
- [Open WebUI Tools docs](https://docs.openwebui.com/features/plugin/tools/)
- [Open WebUI MCP docs](https://docs.openwebui.com/openapi-servers/mcp/)
- [Lobe Chat plugins](https://lobehub.com/docs/usage/plugins/basic)
- [MCP servers list](https://github.com/modelcontextprotocol/servers)

## Требования

- Docker (пользователь в группе docker)
- Inference backend запущен (`./scripts/inference/start-server.sh`)
- Для FC: пресет с `--jinja` (все vulkan/preset/*.sh уже настроены)
