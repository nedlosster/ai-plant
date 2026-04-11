# Open WebUI: подключение TTS (text-to-speech)

Руководство по интеграции text-to-speech движков в Open WebUI на Strix Halo. Позволяет озвучивать ответы LLM голосом (включая voice cloning), а также принимать голосовой ввод через STT (Whisper).

Предусловия: Open WebUI установлен и работает ([simple-use-cases.md](simple-use-cases.md)), базовый чат с llama-server функционирует.

## Зачем это

По умолчанию Open WebUI -- text-first chat. TTS-интеграция даёт:

- **Audio output**: ответы LLM озвучиваются автоматически или по клику. Удобно для "чтения в фоне", accessibility, подкаст-подобного потребления контента
- **Voice cloning**: ответы могут звучать любым голосом (ваш, диктор, персонаж), если backend поддерживает
- **Voice input**: говоришь в микрофон → Whisper транскрибирует → промпт идёт в LLM. Hands-free interaction
- **Полный голосовой диалог**: microphone → STT → LLM → TTS → speaker. Все локально, без облака

Open WebUI поддерживает **OpenAI-совместимый TTS API** как основной способ подключения. Это означает что можно использовать любой backend, который эмулирует `/v1/audio/speech` endpoint OpenAI.

## Архитектура

```
                            Browser (Open WebUI frontend)
                                      |
                                      | HTTP
                                      v
                            Open WebUI Backend (FastAPI)
                                      |
                  +-------------------+--------------------+
                  |                   |                    |
                  v                   v                    v
          TTS Engine            STT Engine          LLM Backend
     (OpenAI-compat API)    (OpenAI Whisper или     (llama-server
                             local Whisper)          через :8081)
                  |
                  |  POST /v1/audio/speech
                  |  {"model": "...", "input": "text", "voice": "..."}
                  v
     +------------------------------+
     |  TTS server (Kokoro / XTTS / |
     |  Chatterbox / openedai-      |
     |  speech / custom)            |
     +------------------------------+
                  |
                  v
             audio bytes (MP3/WAV/OPUS)
                  |
                  v
            Back to browser
```

Ключ: **Open WebUI НЕ содержит TTS-движка в самом backend'е**. Он только делает HTTP-запросы к внешнему TTS-серверу, совместимому с OpenAI API. Поэтому TTS-backend запускается отдельным процессом/контейнером и конфигурируется в Settings.

## Backend options

Есть несколько OpenAI-совместимых TTS-серверов, которые работают на Strix Halo:

| Backend | Voice cloning | Скорость | ROCm | Подходит для |
|---------|---------------|----------|------|--------------|
| **[Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI)** | нет | очень быстрая (~100 tok/s) | да | Фоновый стриминг, быстрое чтение |
| **[openedai-speech](https://github.com/matatonic/openedai-speech)** | да (XTTS) | средняя | да | Voice cloning, XTTS/Piper |
| **[Resemble Chatterbox](https://github.com/resemble-ai/chatterbox)** | **да** | средняя | да | Лучший voice cloning, native гайд Open WebUI |
| **[AllTalk TTS v2](https://github.com/erew123/alltalk_tts)** | да (XTTS+finetune) | средняя | да | Voice library manager, finetune, batch |
| **[TTS-WebUI proxy](../../../scripts/tts/README.md)** | да (20+ моделей) | зависит от модели | да | Maximum choice, но нужна proxy-прослойка |

Локальная рекомендация для Strix Halo: **Resemble Chatterbox** (лучшее качество cloning) или **Kokoro-FastAPI** (максимальная скорость без cloning). Детали ниже.

## Рекомендованный setup: Resemble Chatterbox

**Chatterbox** -- open-source TTS-движок от Resemble AI с zero-shot voice cloning. Имеет официальный гайд интеграции в Open WebUI. Поддерживает ROCm на gfx1151.

### Шаг 1. Запуск Chatterbox-сервера

Chatterbox проще всего запустить через Docker:

```bash
# Запуск в отдельном контейнере
docker run -d \
  --name chatterbox \
  --device /dev/kfd --device /dev/dri \
  -e HSA_OVERRIDE_GFX_VERSION=11.5.1 \
  -p 8880:8880 \
  -v chatterbox-cache:/root/.cache \
  ghcr.io/resemble-ai/chatterbox:latest
```

Либо через Python venv (если нет Docker):

```bash
python3.11 -m venv ~/venvs/chatterbox
source ~/venvs/chatterbox/bin/activate
pip install chatterbox-tts
# запуск сервера
chatterbox-server --host 0.0.0.0 --port 8880 --device cuda
```

На Strix Halo `--device cuda` работает через ROCm благодаря HSA override. Первый запуск скачает модель (~2 GB).

### Шаг 2. Настройка Open WebUI

1. Открыть Open WebUI
2. Settings → Audio → TTS
3. **TTS Engine**: OpenAI
4. **API Base URL**: `http://<SERVER_IP>:8880/v1`
5. **API Key**: `dummy` (Chatterbox не проверяет)
6. **Model**: `chatterbox` (или название модели из списка которое сервер возвращает)
7. **Voice**: имя default-voice (обычно `default` или `neutral`)
8. Save

### Шаг 3. Проверка

1. В чате написать любой промпт модели
2. После ответа -- иконка динамика рядом с сообщением
3. Клик на иконку → проигрывается озвученный ответ

Если работает, но качество не устраивает -- настроить voice в Chatterbox (см. ниже).

### Voice cloning в Chatterbox

Chatterbox умеет клонировать голос из короткого референса (6-30 секунд чистой речи):

```bash
# Загрузить reference.wav на сервер Chatterbox
docker cp reference.wav chatterbox:/app/voices/my_voice.wav

# Или через volume при запуске:
docker run ... -v ./voices:/app/voices ghcr.io/resemble-ai/chatterbox:latest
```

Затем в Open WebUI settings:
- **Voice**: `my_voice` (имя файла без .wav)

Теперь ответы озвучиваются клонированным голосом. Качество зависит от длины и качества reference.

## Альтернатива: Kokoro-FastAPI (максимальная скорость)

Если voice cloning не нужен, но важна скорость (streaming в real-time), [Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI) -- лучший выбор. Kokoro -- маленькая модель (~80 MB), оптимизированная под скорость.

### Запуск

```bash
docker run -d \
  --name kokoro \
  --device /dev/kfd --device /dev/dri \
  -e HSA_OVERRIDE_GFX_VERSION=11.5.1 \
  -p 8880:8880 \
  ghcr.io/remsky/kokoro-fastapi:latest
```

### Конфигурация в Open WebUI

Settings → Audio → TTS:
- **TTS Engine**: OpenAI
- **API Base URL**: `http://<SERVER_IP>:8880/v1`
- **Model**: `tts-1` или `kokoro`
- **Voice**: `af_sarah`, `am_adam`, `bf_emma`, `bm_george` (доступные в Kokoro voices)

### Плюсы и минусы

**Плюсы**:
- Очень быстрая генерация -- streaming начинается через ~0.5 сек
- Низкий VRAM (~2 GiB)
- Несколько голосов из коробки
- Стабильная работа

**Минусы**:
- **Нет voice cloning** -- только preset voices
- Только английский и китайский (на момент апреля 2026)
- Качество ниже чем у XTTS или Chatterbox

## Альтернатива: openedai-speech (XTTS + Piper)

[openedai-speech](https://github.com/matatonic/openedai-speech) -- универсальный proxy с поддержкой нескольких движков:
- **XTTS v2** -- voice cloning, 16 языков, включая русский
- **Piper** -- быстрый, маленький, 30+ языков

### Запуск (Docker)

```bash
docker run -d \
  --name openedai-speech \
  --device /dev/kfd --device /dev/dri \
  -e HSA_OVERRIDE_GFX_VERSION=11.5.1 \
  -p 8000:8000 \
  -v voices:/app/voices \
  ghcr.io/matatonic/openedai-speech:latest
```

### Конфигурация в Open WebUI

Settings → Audio → TTS:
- **TTS Engine**: OpenAI
- **API Base URL**: `http://<SERVER_IP>:8000/v1`
- **Model**: `tts-1` (Piper) или `tts-1-hd` (XTTS)
- **Voice**: `alloy`, `echo`, `fable`, `onyx`, `nova`, `shimmer` (mapping на внутренние voices)

### Кастомный голос (XTTS)

XTTS поддерживает voice cloning. Положи WAV-файл с reference в volume `voices`, укажи его в config.yaml openedai-speech.

## Альтернатива: TTS-WebUI через proxy

На платформе уже установлен **[TTS-WebUI](../../../scripts/tts/README.md)** -- единый Gradio с 20+ моделями. Он запускается на :7770 как web UI, не как OpenAI-совместимый API.

Чтобы использовать его с Open WebUI, нужна **proxy-прослойка**, которая транслирует OpenAI API → Gradio API TTS-WebUI.

Простой python-прокси (пример):

```python
# tts-webui-proxy.py
from fastapi import FastAPI, Response
from gradio_client import Client

app = FastAPI()
gradio = Client("http://localhost:7770/")

@app.post("/v1/audio/speech")
async def speech(request: dict):
    text = request["input"]
    voice = request.get("voice", "default")

    # Вызвать F5-TTS через Gradio API
    audio_path = gradio.predict(
        text,
        f"/app/voices/{voice}.wav",  # reference audio
        api_name="/generate"
    )

    with open(audio_path, "rb") as f:
        audio_bytes = f.read()

    return Response(audio_bytes, media_type="audio/wav")
```

Запустить:
```bash
pip install fastapi uvicorn gradio-client
uvicorn tts-webui-proxy:app --host 0.0.0.0 --port 8880
```

Указать `http://<SERVER_IP>:8880/v1` в Open WebUI.

Это сложнее чем готовые серверы, но даёт доступ ко ВСЕМ моделям TTS-WebUI (F5-TTS, XTTS v2, Fish Speech, IndexTTS, GPT-SoVITS и др.), включая русскоязычные community-форки F5-TTS.

## Auto-TTS: автоматическое озвучивание ответов

По умолчанию Open WebUI не проигрывает TTS автоматически -- нужно кликать иконку. Для автоматического озвучивания:

### Включение

1. Settings → Audio → TTS
2. **Auto-play**: включить

После этого каждый ответ LLM автоматически озвучивается после завершения streaming'а.

### Streaming TTS (начинать проигрывание до конца генерации)

**Streaming TTS** -- проигрывание аудио параллельно с генерацией LLM, не дожидаясь полного ответа. Снижает perceived latency с секунд до миллисекунд.

Open WebUI поддерживает streaming TTS только если backend тоже стримит (не все умеют). Kokoro-FastAPI -- да, Chatterbox -- частично, XTTS -- нет.

Включение:
1. Settings → Audio → TTS
2. **Streaming**: On
3. **Split by**: `sentence` (проигрывать по предложениям) или `paragraph`

После этого первое предложение ответа LLM начинает проигрываться через ~500 мс, пока модель генерирует остальное. Это даёт realtime-chat feel.

## Настройка STT (Whisper) для голосового ввода

Кроме TTS, Open WebUI поддерживает STT (speech-to-text) для microphone input.

### Вариант A: Web Speech API (browser native)

Самый простой вариант -- использовать native browser API.

Settings → Audio → STT:
- **STT Engine**: Web API
- Без настроек -- Chrome/Edge используют встроенный STT (обычно Google online)

Плюсы: ноль setup, бесплатно
Минусы: качество хуже чем Whisper, требует online, privacy-issue (речь уходит в Google)

### Вариант B: OpenAI Whisper API (cloud)

Settings → Audio → STT:
- **STT Engine**: OpenAI
- **API Base URL**: `https://api.openai.com/v1`
- **API Key**: OpenAI API key

Качественно, но платно и не privacy-friendly.

### Вариант C: Local Whisper (рекомендуется)

Запустить локальный Whisper-сервер с OpenAI-compat API:

```bash
# Через faster-whisper-server
docker run -d \
  --name whisper \
  --device /dev/kfd --device /dev/dri \
  -e HSA_OVERRIDE_GFX_VERSION=11.5.1 \
  -p 8881:8000 \
  ghcr.io/fedirz/faster-whisper-server:latest-cuda
```

Settings → Audio → STT:
- **STT Engine**: OpenAI
- **API Base URL**: `http://<SERVER_IP>:8881/v1`
- **API Key**: `dummy`
- **Model**: `large-v3` или `distil-large-v3` (быстрее)

### Вариант D: whisper.cpp (часть ggml-семейства)

Если ты уже компилируешь llama.cpp, можно собрать whisper.cpp рядом:

```bash
git clone https://github.com/ggerganov/whisper.cpp.git ~/projects/whisper.cpp
cd ~/projects/whisper.cpp
cmake -B build -DGGML_VULKAN=ON
cmake --build build
bash models/download-ggml-model.sh large-v3
./build/bin/whisper-server -m models/ggml-large-v3.bin --port 8881
```

Это даёт whisper через ggml Vulkan backend -- тот же стек что llama.cpp. Очень хорошая производительность на Strix Halo.

## Полный голосовой workflow

Connected setup:

1. Пользователь кликает микрофон в Open WebUI
2. Browser записывает аудио
3. Аудио отправляется в STT (whisper-server) → транскрипт
4. Транскрипт идёт в LLM (llama-server) → ответ streaming
5. Ответ (по предложениям) идёт в TTS (Chatterbox/Kokoro) → аудио
6. Browser проигрывает аудио
7. После завершения -- повторная запись (если включён full-duplex mode)

Это даёт **локальный голосовой ассистент** уровня Alexa/Siri, но без облака. Latency от голоса к ответу обычно 2-4 секунды на Strix Halo (Whisper ~0.5s, LLM prefill ~0.3s, streaming TTS start ~0.5s).

## Troubleshooting

### "TTS generates gibberish / wrong language"

**Причина**: backend не понимает язык текста, или voice не настроен для этого языка.

**Решение**:
- Проверить что backend поддерживает нужный язык (Kokoro -- en/zh, XTTS -- 16 языков, Chatterbox -- en/de/fr/es/it/pt/pl/ru/ja/zh/ko)
- Для русского использовать XTTS через openedai-speech или F5-TTS через TTS-WebUI proxy
- Voice name должен соответствовать языку (например `ru_male` для русского)

### "403 Forbidden" от TTS backend

**Причина**: backend требует API key.

**Решение**: указать любую непустую строку в поле API Key (Open WebUI валидирует что поле заполнено).

### "Audio not playing in browser"

**Причина**: browser блокирует autoplay (политики Chrome/Firefox).

**Решение**:
- Первый раз кликнуть "Play" вручную -- после этого autoplay работает
- Для systemd-пользователей: проверить что audio output устройство работает

### "Streaming stops in middle"

**Причина**: WebSocket disconnect, или backend не поддерживает streaming.

**Решение**:
- Отключить streaming, использовать "wait for full response"
- Проверить stability backend'а (Chatterbox иногда падает на длинных text'ах)

### "OOM on TTS backend"

**Причина**: модель не помещается + другие процессы.

**Решение**:
- Убедиться что llama-server и ComfyUI не запущены одновременно
- Использовать Kokoro (меньше VRAM) вместо XTTS

## Связанные статьи

- [README.md](README.md) -- обзор профиля Open WebUI
- [architecture.md](architecture.md) -- внутреннее устройство
- [simple-use-cases.md](simple-use-cases.md) -- базовые сценарии чата
- [advanced-use-cases.md](advanced-use-cases.md) -- RAG, Functions, Pipelines
- [../lobe-chat/tts-integration.md](../lobe-chat/tts-integration.md) -- аналог для LobeChat
- [../../models/tts.md](../../models/tts.md) -- обзор TTS-моделей на платформе
- [../../models/families/f5-tts.md](../../models/families/f5-tts.md) -- F5-TTS для русского
- [../../models/families/xtts.md](../../models/families/xtts.md) -- XTTS v2
- [../../../scripts/tts/README.md](../../../scripts/tts/README.md) -- TTS-WebUI на платформе
