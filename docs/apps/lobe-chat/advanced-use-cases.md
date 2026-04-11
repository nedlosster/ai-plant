# LobeChat: сложные сценарии

Продвинутые use-cases: Plugin Market интеграция, custom assistants, voice mode, image generation plugins, self-hosted market server, background tasks, multi-agent collaboration.

## 1. Глубокая работа с Plugin Market

### Анатомия плагина

Plugin в LobeChat состоит из трёх частей:
1. **Manifest** (`lobe-plugin.json`) -- описание для LobeChat: какие tools, какие settings, где API-endpoint
2. **Server** -- HTTP endpoint (обычно serverless на Vercel/Cloudflare), который реально выполняет логику
3. **UI** (опционально) -- custom React компонент для рендеринга plugin output

Процесс работы:
```
User promt → LLM sees tool description from manifest →
    LLM generates tool call (with args) → LobeChat sends HTTP to plugin server →
        plugin does work → returns JSON → LLM sees result → formulates final answer
```

### Категории плагинов в маркете

| Категория | Примеры |
|-----------|---------|
| **Поиск и информация** | Google Search, Bing, Wikipedia, Perplexity |
| **Academic** | Arxiv, Semantic Scholar, Google Scholar |
| **Code / Dev** | GitHub, GitLab, Stack Overflow, npm, PyPI |
| **Media** | YouTube, Bilibili, Vimeo, SoundCloud |
| **Finance** | Stock prices, crypto, forex |
| **Weather** | OpenWeatherMap, WeatherAPI |
| **Translation** | DeepL, Google Translate |
| **Image generation** | DALL-E, Stable Diffusion, Midjourney |
| **Office** | Notion, Google Docs, Confluence |
| **E-commerce** | Amazon, AliExpress, Taobao |
| **Travel** | Flights, hotels, maps |
| **Scientific** | Wolfram Alpha, ChemPy, LaTeX |

### Установка плагина

1. Sidebar → Plugin Store (или /plugins в URL)
2. Поиск: `github`
3. Выбрать "GitHub Integration"
4. Install
5. Если plugin требует API key -- появляется форма в Settings для ввода ($GITHUB_TOKEN и т.д.)
6. В chat Settings → Plugins → активировать для текущего чата

### Использование

Plugin подключён к чату → LLM видит его tools (например `get_repo_stats`, `list_issues`, `create_issue`) → может их вызывать в процессе разговора.

Пример разговора:

> Промпт: "Какой сейчас статус issues в `myorg/myrepo`?"
>
> Модель: (вызывает `list_issues(repo="myorg/myrepo", state="open")`)
>
> Plugin возвращает JSON со списком issues
>
> Модель: "Сейчас открыто 23 issue. Самый активный -- #142 'Memory leak in worker', последний комментарий час назад. Issue #87 'Design proposal' -- 5 комментариев за последнюю неделю..."

### Создание своего плагина

Для создания plugin'а нужно:

1. Написать **manifest**:
```json
{
  "identifier": "my-weather-plugin",
  "version": "1.0.0",
  "author": "me",
  "homepage": "https://github.com/me/lobe-plugin-weather",
  "api": [
    {
      "name": "getCurrentWeather",
      "description": "Get current weather for a location",
      "url": "https://my-weather-plugin.vercel.app/api/weather",
      "parameters": {
        "type": "object",
        "properties": {
          "location": { "type": "string", "description": "City name" },
          "unit": { "type": "string", "enum": ["celsius", "fahrenheit"] }
        },
        "required": ["location"]
      }
    }
  ],
  "meta": {
    "avatar": "🌤",
    "title": "Weather",
    "description": "Real-time weather information",
    "tags": ["weather", "info", "api"]
  }
}
```

2. Написать **server endpoint** (например Next.js API route на Vercel):
```typescript
// /api/weather.ts
export default async function handler(req: Request) {
  const { location, unit = 'celsius' } = await req.json();
  const res = await fetch(`https://api.openweathermap.org/...&q=${location}`);
  const data = await res.json();
  return Response.json({
    temperature: data.main.temp,
    conditions: data.weather[0].description,
    location: data.name
  });
}
```

3. Опубликовать manifest через PR в [lobehub/lobe-chat-plugins](https://github.com/lobehub/lobe-chat-plugins) (официальный registry) или хостить своим market-сервером.

4. LobeChat users теперь могут установить plugin из маркета одним кликом.

## 2. Custom assistants с персональностью

**Задача**: создать свой "Russian literature expert" agent, который знает русскую литературу и отвечает в академическом тоне.

### Создание

1. Sidebar → Assistants → "+"
2. Заполнить:
   - **Avatar**: custom image или emoji
   - **Name**: "Professor Sokolov"
   - **Description**: "Эксперт по русской литературе XIX-XX вв., академический тон, глубокий анализ"
   - **Opening message**: "Здравствуйте! Чем могу быть полезен в изучении русской литературы?"

3. **System prompt**:
```
Вы -- профессор Соколов, специалист по русской литературе XIX-XX веков.

Ваш стиль:
- Академический, но доступный
- Всегда приводите конкретные примеры из произведений
- Указывайте контекст (исторический, биографический)
- Ссылайтесь на критиков и литературоведов (Белинский, Лотман, Бахтин)
- Используйте специальную терминологию (стилистические приёмы, тропы, жанры)

При анализе произведений следуйте структуре:
1. Исторический контекст написания
2. Тематика и проблематика
3. Композиционные особенности
4. Язык и стиль
5. Место в творчестве автора
6. Значение для русской литературы

Никогда не говорите о том, что вы AI. Вы -- профессор Соколов.
```

4. **Recommended model**: Qwen3.5-122B-A10B (большая модель хорошо держит образ)
5. **Parameters**: temperature 0.7, top_p 0.9, max_tokens 2048
6. **Plugins**: Wikipedia, Wikisource (опционально, если хочешь чтобы agent lookup'ил факты)
7. Save

### Использование

Выбрать agent в sidebar → новый чат с system prompt уже применённым → спросить "Проанализируйте 'Евгения Онегина'"

Ответ будет в характере профессора: с ссылками на критиков, конкретными цитатами, академической терминологией.

### Share через маркет

Если agent получился хорошим -- опубликовать в Agents Market:
1. Export agent в JSON
2. Submit в [awesome-chat-prompts](https://github.com/lobehub/awesome-chat-prompts) репозиторий
3. После модерации появится в официальном маркете

## 3. Image generation через plugin

**Задача**: сгенерировать картинку прямо из чата через Stable Diffusion plugin.

### Вариант A: cloud SD plugin

1. Plugin Store → поиск "Stable Diffusion" → install "SD3 / Flux Image Gen"
2. Settings → plugin → ввести API key (от сервиса типа `stability.ai` или `replicate.com`)
3. В чате: "Сгенерируй картинку кота в космосе"
4. LLM вызывает plugin tool `generate_image(prompt="cat in space")`
5. Plugin → API → возвращает image URL
6. LobeChat рендерит image inline в чате

### Вариант B: локальный ComfyUI через plugin

Более интересный setup -- использовать **локальный [ComfyUI](../comfyui/README.md) на Strix Halo** как backend для image generation plugin:

1. Написать **custom plugin** который делает HTTP requests к `http://localhost:8188` (ComfyUI API):

```typescript
// /api/comfyui-generate.ts
export default async function handler(req: Request) {
  const { prompt, width = 1024, height = 1024 } = await req.json();

  // Load FLUX workflow template
  const workflow = JSON.parse(await readFile('flux-workflow.json', 'utf8'));
  workflow["2"]["inputs"]["text"] = prompt;
  workflow["3"]["inputs"]["seed"] = Math.floor(Math.random() * 1000000);

  // Queue в ComfyUI
  const promptRes = await fetch('http://host.docker.internal:8188/prompt', {
    method: 'POST',
    body: JSON.stringify({ prompt: workflow, client_id: 'lobechat' }),
  });
  const { prompt_id } = await promptRes.json();

  // Poll до завершения
  let result;
  while (!result?.outputs) {
    await new Promise(r => setTimeout(r, 1000));
    const hist = await fetch(`http://host.docker.internal:8188/history/${prompt_id}`);
    result = (await hist.json())[prompt_id];
  }

  // Получить URL картинки
  const filename = result.outputs["6"].images[0].filename;
  return Response.json({
    image_url: `http://localhost:8188/view?filename=${filename}`,
    prompt_id
  });
}
```

2. Зарегистрировать plugin в LobeChat с endpoint'ом своего server'а

3. Использовать: "Нарисуй картинку водопада в тропиках" → plugin вызывает ComfyUI → возвращает картинку → inline в чате

Это объединяет chat-интерфейс LobeChat с мощным diffusion-pipeline ComfyUI на одной машине. Всё локально, без облачных API.

## 4. Voice mode: full-duplex разговор

**Задача**: разговаривать с LLM голосом в реальном времени.

### Настройка

1. Settings → Speech
2. STT (speech-to-text): OpenAI Whisper API (или local Whisper через plugin)
3. TTS (text-to-speech): OpenAI TTS (или ElevenLabs)
4. Settings → Chat → Enable "Auto voice mode"

### Использование

1. В чате -- иконка микрофона (большая, не обычная для ввода)
2. Клик → начинается continuous recording
3. Говоришь → Whisper транскрибирует → текст отправляется в LLM
4. Ответ LLM автоматически озвучивается через TTS
5. После ответа -- recording возобновляется (full-duplex)
6. Klик кнопки stop для завершения

### Альтернатива: local Whisper + local TTS

Для privacy/offline сценариев:
- STT: local Whisper через `openai-whisper` или `whisper.cpp`, развёрнутый отдельно и проксируемый как endpoint
- TTS: local Piper TTS, XTTS, F5-TTS (см. [tts.md](../../models/tts.md))
- Всё через custom plugin как wrapper

## 5. Self-hosted Plugin Market server

**Задача**: развернуть свой plugin marketplace для enterprise -- только curated internal плагины, без подключения к общественному LobeHub маркету.

### Что нужно

1. **LobeChat** с env переменной `NEXT_PUBLIC_MARKET_BASE_URL=http://market.company.local`
2. **Market server** -- HTTP API совместимый с `@lobehub/market-sdk`

### Market server requirements

Market server должен экспонировать endpoints:

- `GET /api/plugins` -- список всех плагинов (список manifest'ов)
- `GET /api/plugins/:identifier` -- детали конкретного плагина
- `GET /api/agents` -- список агентов
- `GET /api/agents/:identifier` -- детали агента
- `GET /api/plugins/search?q=...` -- поиск

Response format должен соответствовать [`@lobehub/market-types`](https://www.npmjs.com/package/@lobehub/market-types).

### Реализация (пример)

```typescript
// Minimal market server on Next.js
// pages/api/plugins/index.ts

import { readFileSync } from 'fs';
import { join } from 'path';

export default async function handler(req, res) {
  const pluginsDir = join(process.cwd(), 'plugins');
  const files = await fs.readdir(pluginsDir);

  const plugins = await Promise.all(files.map(async f => {
    const manifest = JSON.parse(
      await fs.readFile(join(pluginsDir, f, 'lobe-plugin.json'), 'utf8')
    );
    return manifest;
  }));

  res.json({ plugins });
}
```

1. Сложить manifest'ы для корпоративных плагинов в `plugins/` директорию
2. Запустить server на `http://market.company.local`
3. Обновить `NEXT_PUBLIC_MARKET_BASE_URL` в LobeChat deployment
4. LobeChat теперь читает только из этого reginal market

### Security

Для enterprise:
- Market server за VPN / private network
- Auth (не anonymous): JWT tokens, API keys
- Audit log: кто установил какой plugin когда
- Version control: plugin manifests в git repo, CI/CD для обновления

## 6. Background tasks (2026 feature)

**Задача**: запустить долгий анализ, продолжить работу, получить результат позже.

### Пример

Промпт: "Проанализируй все PDF в папке /documents и найди все упоминания термина 'authentication'. Создай summary report."

Нормально это бы заняло минуты-часы (много PDF, много LLM calls). В background mode:

1. Agent видит long-running task, создаёт background task
2. Возвращает task ID: "Started task bg-42. You'll be notified when done."
3. Пользователь может продолжить другие чаты
4. Agent в background обрабатывает PDF через plugin (RAG)
5. Результат сохраняется в task output
6. Notification в UI: "Task bg-42 completed -- see results"
7. Клик на notification → открывается view с summary

### Технически

- Task queue в Redis или PostgreSQL
- Background workers (отдельные Node.js процессы)
- WebSocket для push-уведомлений в UI
- Task timeouts и retry logic

## 7. Multi-agent collaboration (2026 preview)

**Задача**: дать задачу, которая требует нескольких агентов с разными ролями.

LobeChat движется к **multi-agent framework** через репозиторий [lobehub/lobehub](https://github.com/lobehub/lobehub). Идея: вместо одного assistant -- команда специализированных агентов, работающих совместно.

### Пример сценария

Промпт (в chat с "Team Lead" agent):
> "Мне нужно написать blog post про новую архитектуру. Тема -- LTX-2 dual-stream DiT. Нужна: техническая часть, примеры кода, метафоры для non-technical читателя, грамматическая проверка"

Team Lead agent:
1. Делегирует "Technical Writer" agent -- написать technical часть
2. Делегирует "Code Examples" agent -- собрать code samples
3. Делегирует "Metaphor Expert" agent -- придумать аналогии
4. Собирает результаты
5. Передаёт "Editor" agent для финальной вычитки
6. Возвращает финальный пост user'у

Каждый агент имеет свой system prompt, может использовать свои plugins, работает независимо. Team Lead координирует.

Это prototype-фича 2026 года, активно развивается.

## 8. Desktop app как "remote control"

**Задача**: использовать LobeHub Desktop app как клиент к локальному Strix Halo.

### Зачем

- LobeChat web -- нужно открывать browser, медленнее
- LobeHub Desktop -- native app, быстрее, better OS integration (menu bar, keyboard shortcuts, notifications)
- Всё равно inference на Strix Halo -- то есть качество моделей максимальное

### Setup

1. Скачать LobeHub Desktop с [lobehub.com/download](https://lobehub.com/download)
2. Установить на ноутбук / рабочую машину
3. Settings → Language Model → OpenAI-compatible
4. API Base URL: `http://<STRIX_HALO_IP>:8081/v1`
5. Models: указать вручную

Теперь Desktop app работает как tech-stack frontend, а за инференс отвечает Strix Halo. Latency в LAN -- считанные миллисекунды, UX как у native app.

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [architecture.md](architecture.md) -- как всё это работает под капотом
- [simple-use-cases.md](simple-use-cases.md) -- предусловия, базовые паттерны
- [../open-webui/advanced-use-cases.md](../open-webui/advanced-use-cases.md) -- для сравнения с Open WebUI
- [../comfyui/advanced-use-cases.md](../comfyui/advanced-use-cases.md) -- ComfyUI как backend для image gen plugin
- [../../inference/llama-cpp.md](../../inference/llama-cpp.md) -- backend
