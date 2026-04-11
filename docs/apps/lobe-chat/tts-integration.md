# LobeChat: подключение TTS (text-to-speech)

Руководство по интеграции text-to-speech в LobeChat на Strix Halo. LobeChat поддерживает TTS/STT нативно в настройках Speech, но с некоторыми особенностями отличными от [Open WebUI](../open-webui/tts-integration.md).

Предусловия: LobeChat установлен и работает ([simple-use-cases.md](simple-use-cases.md)), базовый чат с llama-server функционирует.

## Зачем это

LobeChat имеет встроенный **voice mode** для полноценного голосового диалога с LLM. В отличие от Open WebUI, где TTS/STT реализованы как сменные backends через OpenAI-compat API, LobeChat работает через **abstract speech provider layer** и поддерживает несколько путей:

- **Web Speech API** -- native browser TTS/STT (без backend)
- **OpenAI Speech API** -- cloud или любой совместимый сервер
- **Custom plugins** -- через Plugin Market для voice-related задач
- **Локальный backend через plugins** -- обёртки вокруг whisper.cpp, TTS-WebUI

## Архитектура

LobeChat -- Next.js приложение. Speech-layer абстрагирован как "Speech Provider" который маппится на конкретную реализацию:

```
LobeChat UI
    |
    |  User кликает микрофон / запускает TTS
    v
Speech Provider Layer (abstraction)
    |
    +--> Browser Web Speech API (native)
    |        |
    |        v
    |   OS-level voice engine (no network)
    |
    +--> OpenAI API provider
    |        |
    |        v
    |   HTTP POST /v1/audio/speech
    |   HTTP POST /v1/audio/transcriptions
    |        |
    |        v
    |   Cloud OpenAI или локальный OpenAI-compat сервер
    |
    +--> Plugin-based provider
             |
             v
         Plugin API endpoint (custom TTS/STT logic)
```

## Варианты TTS-провайдеров

LobeChat поддерживает несколько провайдеров для TTS:

| Провайдер | Качество | Latency | Языки | Локально | Setup сложность |
|-----------|----------|---------|-------|----------|-----------------|
| **Browser Web Speech API** | низкое-среднее | минимальный | зависит от OS | да (OS voices) | ноль |
| **OpenAI TTS API** (cloud) | высокое | низкий | 30+ | нет | минимальный |
| **ElevenLabs API** (cloud) | очень высокое | средний | 30+ | нет | API key |
| **Microsoft Edge TTS** (через plugin) | высокое | низкий | 100+ | нет (но бесплатно) | plugin install |
| **Local OpenAI-compat server** | зависит | средний-низкий | зависит | да | развернуть backend |

На Strix Halo рекомендуется **локальный OpenAI-compat server** (чтобы всё оставалось в LAN).

## Рекомендованный setup: локальный Chatterbox / Kokoro / XTTS

LobeChat использует OpenAI-compat API для локального TTS. Шаги идентичны настройке Open WebUI.

### Шаг 1. Запуск TTS backend

Выбрать один из вариантов:

**Для voice cloning**: Resemble Chatterbox
```bash
docker run -d --name chatterbox \
  --device /dev/kfd --device /dev/dri \
  -e HSA_OVERRIDE_GFX_VERSION=11.5.1 \
  -p 8880:8880 \
  ghcr.io/resemble-ai/chatterbox:latest
```

**Для максимальной скорости**: Kokoro-FastAPI
```bash
docker run -d --name kokoro \
  --device /dev/kfd --device /dev/dri \
  -e HSA_OVERRIDE_GFX_VERSION=11.5.1 \
  -p 8880:8880 \
  ghcr.io/remsky/kokoro-fastapi:latest
```

**Для русского языка**: openedai-speech с XTTS
```bash
docker run -d --name openedai-speech \
  --device /dev/kfd --device /dev/dri \
  -e HSA_OVERRIDE_GFX_VERSION=11.5.1 \
  -p 8000:8000 \
  -v voices:/app/voices \
  ghcr.io/matatonic/openedai-speech:latest
```

Подробности каждого варианта -- в [open-webui/tts-integration.md](../open-webui/tts-integration.md#backend-options) (backend-серверы одинаковы, конфигурируются одинаково).

### Шаг 2. Настройка LobeChat

1. Открыть LobeChat
2. Settings (шестерёнка слева внизу) → **Speech**
3. **TTS Provider**: OpenAI (ВАЖНО: это "OpenAI compatibility mode", не обязательно настоящий OpenAI)
4. **TTS API Base URL**: `http://<SERVER_IP>:8880/v1` (или `:8000/v1` для openedai-speech)
5. **TTS API Key**: `dummy` (LobeChat требует непустое поле)
6. **TTS Model**: `tts-1` (или название модели из списка backend'а)
7. **TTS Voice**: имя голоса из backend (например `alloy`, `af_sarah`, `chatterbox-default`)
8. Save

### Шаг 3. Проверка

В чате:
1. Отправить любой промпт модели
2. Навести курсор на ответ assistant'а
3. Появится иконка "Play" (динамик)
4. Клик → ответ озвучивается

Если работает -- всё настроено.

## LobeChat-specific фишки: auto-voice и voice mode

### Auto-voice (автоматическое озвучивание)

Settings → Speech → **Auto Play**: On

После этого каждый ответ LLM автоматически озвучивается по завершении generation'а. Удобно для "читай всё что генерируется" сценариев.

### Voice Mode (full-duplex голосовой диалог)

LobeChat имеет специальный **Voice Mode** -- режим где пользователь разговаривает с LLM голосом непрерывно. Активация:

1. Settings → Speech → **Enable Voice Mode**: On
2. Настроить STT (см. следующий раздел)
3. В чате -- большая кнопка микрофона (не обычный input)

Поведение:
1. Клик → запись начинается
2. Говоришь → Whisper транскрибирует → промпт идёт в LLM
3. LLM streaming ответ → auto-TTS проигрывает по мере генерации
4. После ответа -- запись возобновляется (если включён full-duplex)
5. Клик для остановки

Это приближается к опыту Alexa/Siri -- hands-free разговор с LLM.

## STT (speech-to-text) для голосового ввода

LobeChat поддерживает несколько STT-провайдеров.

### Вариант A: Browser Web Speech API

Settings → Speech → **STT Provider**: Web Speech API

Используется нативная реализация browser'а (в Chrome -- Google online, в Safari -- Apple). Ноль setup, но:
- Работает только в поддерживаемых browsers (Chrome, Edge, Safari)
- Качество зависит от browser/OS
- Privacy: речь уходит в облако vendor'а browser'а

### Вариант B: OpenAI Whisper API (cloud)

Settings → Speech → **STT Provider**: OpenAI
- **API Base URL**: `https://api.openai.com/v1`
- **API Key**: OpenAI key

Качественно, но платно ($0.006/мин).

### Вариант C: Local Whisper (рекомендуется)

Запустить faster-whisper-server локально:

```bash
docker run -d --name whisper \
  --device /dev/kfd --device /dev/dri \
  -e HSA_OVERRIDE_GFX_VERSION=11.5.1 \
  -p 8881:8000 \
  ghcr.io/fedirz/faster-whisper-server:latest-cuda
```

В LobeChat:
- **STT Provider**: OpenAI
- **STT API Base URL**: `http://<SERVER_IP>:8881/v1`
- **STT API Key**: `dummy`
- **STT Model**: `large-v3` или `distil-large-v3`

### Вариант D: Local Whisper через transformers.js (in-browser)

LobeChat может использовать **transformers.js** для running Whisper прямо в browser через WebAssembly. Преимущество: ноль серверного setup, всё локально. Недостаток: медленнее и ниже качество чем server-side.

Settings → Speech → **STT Provider**: Transformers.js (Local)

После первого использования browser скачает модель (~200 MB), кэширует её в IndexedDB, последующие transcription'ы идут мгновенно.

Хорошо для privacy-sensitive сценариев, когда не хочется держать отдельный whisper-сервер.

## Plugin-based TTS/STT

LobeChat ecosystem имеет Plugin Market, где можно найти готовые voice-plugins:

### Популярные voice plugins

| Plugin | Что делает |
|--------|-----------|
| **Microsoft Edge TTS** | Использует бесплатный Edge Cloud TTS (доступно через API без auth). 100+ языков, высокое качество |
| **Azure Speech** | Enterprise-grade TTS/STT от Microsoft Azure |
| **Google Cloud TTS** | Google's cloud TTS voices (WaveNet quality) |
| **Local Whisper (plugin)** | Локальный Whisper через browser WebAssembly |
| **Realtime Voice** | OpenAI Realtime API integration -- low-latency voice chat |

### Установка plugin

1. Sidebar → Plugin Store (или `/plugins` в URL)
2. Поиск: "TTS", "voice", "speech"
3. Install → Enable
4. Plugin появится в Settings → Speech Providers (если это TTS/STT плагин)

### Custom plugin для TTS-WebUI

На Strix Halo уже установлен **[TTS-WebUI](../../../scripts/tts/README.md)** -- единый Gradio с 20+ моделями. Чтобы использовать его в LobeChat, можно написать custom plugin.

Manifest (упрощённо):

```json
{
  "identifier": "tts-webui-proxy",
  "version": "1.0.0",
  "author": "local",
  "homepage": "local",
  "api": [
    {
      "name": "synthesizeSpeech",
      "description": "Synthesize speech via local TTS-WebUI",
      "url": "http://host.docker.internal:8880/v1/audio/speech",
      "parameters": {
        "type": "object",
        "properties": {
          "text": { "type": "string" },
          "voice": { "type": "string", "enum": ["f5_ru", "xtts_male", "fish_neutral"] }
        }
      }
    }
  ],
  "meta": {
    "avatar": "🎙",
    "title": "TTS-WebUI Proxy",
    "description": "Local TTS через F5-TTS / XTTS / Fish Speech"
  }
}
```

Бэкенд -- proxy-сервер, транслирующий OpenAI API → Gradio client TTS-WebUI (пример см. в [open-webui/tts-integration.md](../open-webui/tts-integration.md#альтернатива-tts-webui-через-proxy)).

Это даёт доступ к ВСЕМ моделям TTS-WebUI (включая русскоязычные community-форки F5-TTS) из LobeChat UI.

## Полный голосовой диалог: workflow

Setup:
- LobeChat на :3211
- faster-whisper-server на :8881
- Chatterbox на :8880
- llama-server на :8081

Конфигурация LobeChat:
- LLM provider: OpenAI-compat, Base URL `http://localhost:8081/v1`
- TTS: OpenAI, Base URL `http://localhost:8880/v1`, Voice "default"
- STT: OpenAI, Base URL `http://localhost:8881/v1`, Model "large-v3"
- Voice Mode: enabled
- Auto-play: enabled

Пользовательский flow:
1. Клик микрофона
2. Говорит "Расскажи про архитектуру Strix Halo"
3. Whisper транскрибирует (~500 мс)
4. Qwen3.5-27B генерирует ответ streaming
5. По мере готовности первых предложений -- Chatterbox озвучивает
6. Пользователь слушает ответ параллельно с продолжением генерации
7. После завершения ответа микрофон снова активен
8. Диалог продолжается

Total latency от голоса до начала воспроизведения -- **2-4 секунды** на Strix Halo (Whisper 500ms + LLM prefill 300ms + TTS chunk start 500ms + streaming overhead).

## Сравнение с Open WebUI

| Критерий | Open WebUI | LobeChat |
|----------|------------|----------|
| **TTS/STT как first-class фича** | да, в Settings → Audio | да, в Settings → Speech |
| **Voice Mode (full-duplex)** | через streaming + microphone loop | **native Voice Mode** |
| **Browser Web Speech API** | поддерживается | поддерживается |
| **OpenAI-compat API** | основной путь | основной путь |
| **Auto-play** | да, с streaming по предложениям | да |
| **Plugin-based** | нет (Functions/Pipelines вместо) | **да, через Plugin Market** |
| **In-browser Whisper** | нет | через Transformers.js plugin |
| **Voice cloning UX** | через backend configure | через backend configure |
| **Best for** | продвинутые setup, Functions | casual users, готовые plugins |

**Open WebUI выигрывает**: для production с множеством пользователей, когда нужен детальный контроль.

**LobeChat выигрывает**: для индивидуального использования с красивым voice mode и готовыми plugins.

## Troubleshooting

### "Voice Mode не активируется"

**Причина**: browser permissions или STT не настроен.

**Решение**:
- Разрешить access к микрофону в browser settings
- Проверить что STT provider выбран и работает (test через обычный микрофон-кнопку)

### "Голос звучит неестественно / роботизированно"

**Причина**: используется Browser Web Speech API (низкое качество).

**Решение**: переключиться на OpenAI-compat backend (Chatterbox/XTTS/Kokoro) -- качественно выше.

### "Русский TTS даёт ошибки в словах"

**Причина**: backend не поддерживает русский или использует неподходящую voice.

**Решение**:
- Использовать **openedai-speech с XTTS** (XTTS поддерживает русский)
- Или **TTS-WebUI proxy с F5-TTS RU-форками** (лучшее качество для русского)
- Указать русскоязычную voice в настройках

### "CORS errors при подключении локального backend"

**Причина**: TTS backend не разрешает CORS requests из LobeChat domain.

**Решение**:
- Запустить backend с `--cors-origins "*"` или добавить LobeChat origin в whitelist
- Либо использовать reverse proxy (nginx) с правильными CORS headers
- Либо подключать через Docker network где оба контейнера видят друг друга

## Связанные статьи

- [README.md](README.md) -- обзор профиля LobeChat
- [architecture.md](architecture.md) -- внутреннее устройство
- [simple-use-cases.md](simple-use-cases.md) -- базовые сценарии чата
- [advanced-use-cases.md](advanced-use-cases.md) -- Plugin Market, custom plugins
- [../open-webui/tts-integration.md](../open-webui/tts-integration.md) -- аналог для Open WebUI (больше деталей по backends)
- [../../models/tts.md](../../models/tts.md) -- обзор TTS-моделей на платформе
- [../../models/families/f5-tts.md](../../models/families/f5-tts.md) -- F5-TTS для русского
- [../../models/families/xtts.md](../../models/families/xtts.md) -- XTTS v2
- [../../../scripts/tts/README.md](../../../scripts/tts/README.md) -- TTS-WebUI на платформе
