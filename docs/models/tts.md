# TTS с клонированием голоса

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти), ROCm 7.2.1 (PyTorch) / CPU.

TTS с **voice cloning** -- модели, синтезирующие речь голосом конкретного человека по короткому референсному аудио (zero-shot, 6-30 сек).

Полные описания моделей -- в `families/`. Эта страница: архитектура, сравнительные таблицы, выбор под задачу, веб-стеки.

## Особенности платформы

В отличие от LLM, TTS-модели -- **PyTorch-based**, не GGUF. Запуск:

- **PyTorch ROCm** (рекомендуется) -- ROCm 7.2.1 уже стоит, см. [docs/inference/rocm-setup.md](../inference/rocm-setup.md)
- **CPU-fallback** -- медленнее, но без GPU
- **Vulkan не поддерживается** -- TTS-фреймворки идут только через CUDA/ROCm/CPU

VRAM-аппетиты у всех моделей умеренные (4-8 GiB).

## Сравнительная таблица

| Модель | Семейство | Языки | Reference | VRAM | Лицензия |
|--------|-----------|-------|-----------|------|----------|
| Qwen3-TTS | [qwen3-tts](families/qwen3-tts.md) | 10 (рус нативно) | 10 сек | ~8 GiB | Open |
| F5-TTS | [f5-tts](families/f5-tts.md) | 2 + RU community-форки | 6-15 сек | ~6 GiB | MIT |
| Fish Speech 1.5 | [fish-speech](families/fish-speech.md) | 8 | 10-30 сек | ~6 GiB | Apache 2.0 |
| IndexTTS-2 | [indextts2](families/indextts2.md) | 5+ | 10 сек | ~8 GiB | Open |
| XTTS v2 | [xtts](families/xtts.md) | 16 | **6 сек** | ~4 GiB | CPML |
| **VoxCPM2** (new) | -- | multilingual | voice cloning | -- | Open (OpenBMB) |

**VoxCPM2** (апрель 2026, OpenBMB) -- tokenizer-free TTS нового поколения. Устраняет этап токенизации из pipeline: вместо text → tokens → speech, работает text → continuous representation → speech. Multilingual, voice cloning, creative sound design. Детали на [OpenBMB GitHub](https://github.com/OpenBMB). См. [news.md](news.md).

## Выбор под задачу

### Лучший русский (нативный без дообучения)

[Qwen3-TTS](families/qwen3-tts.md) -- 10 языков нативно, voice cloning, free-form voice design (описать голос текстом).

### Эталонный voice cloning + community RU-форки

[F5-TTS](families/f5-tts.md) -- MIT, лучшее качество zero-shot, 6 сек reference, RU-форки от Misha24-10 и hotstone228.

### Apache 2.0 для коммерции

[Fish Speech 1.5](families/fish-speech.md) -- единственная топовая TTS с Apache 2.0, 8 языков, ELO 1339 на TTS Arena.

### Контроль эмоций и длительности (lip-sync)

[IndexTTS-2](families/indextts2.md) -- единственная open-source с реальным контролем длительности (для дубляжа под движение губ), эмоции как параметры.

### Максимум языков и минимальный reference

[XTTS v2](families/xtts.md) -- 16 языков, всего 6 секунд reference, ~4 GiB VRAM.

## Веб-интерфейсы для TTS

### TTS-WebUI (рекомендуется -- "всё в одном")

Один Gradio-интерфейс с поддержкой 20+ моделей: F5-TTS, XTTS v2, Fish Speech, ACE-Step, GPT-SoVITS, CosyVoice, Kokoro и др.

- **GitHub**: [rsxdalv/TTS-WebUI](https://github.com/rsxdalv/TTS-WebUI)
- На платформе: `./scripts/tts/install.sh && ./scripts/tts/start.sh -d`
- UI: http://localhost:7770

### Open WebUI -> Custom TTS Engine

В существующей Open WebUI: Settings -> Audio -> TTS -> Custom (OpenAI compatible). Backends:

- [remsky/Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI) -- быстрый, без cloning
- [matatonic/openedai-speech](https://github.com/matatonic/openedai-speech) -- XTTS/Piper в OpenAI API
- [Resemble Chatterbox](https://docs.openwebui.com/features/media-generation/audio/text-to-speech/chatterbox-tts-api-integration/) -- voice cloning, native гайд

Детальное руководство по подключению: [../apps/open-webui/tts-integration.md](../apps/open-webui/tts-integration.md).

### LobeChat -> Speech Provider

LobeChat Settings -> Speech -> TTS/STT Provider = OpenAI (совместимый). Поддерживает те же backends что Open WebUI, а также **Web Speech API** (native browser), **Transformers.js** (in-browser Whisper), **plugin-based** TTS через Plugin Market.

Детальное руководство: [../apps/lobe-chat/tts-integration.md](../apps/lobe-chat/tts-integration.md).

### AllTalk TTS v2

- [erew123/alltalk_tts](https://github.com/erew123/alltalk_tts)
- Менеджер voice library, finetune XTTS, batch-обработка
- Интегрируется с SillyTavern, Text-Generation-WebUI, Open WebUI

### Standalone Gradio каждой модели

Каждое семейство имеет встроенный UI, подробности в `families/<name>.md`.

## Скрипты на платформе

```
scripts/tts/
├── install.sh      # установка TTS-WebUI + PyTorch ROCm
├── start.sh        # запуск Gradio (порт 7770)
├── stop.sh
├── status.sh
└── config.sh       # TTS_DIR, TTS_PORT, HSA_OVERRIDE_GFX_VERSION
```

## Связанные направления

- [vision.md](vision.md) -- [Qwen2.5-Omni](families/qwen25-omni.md) для голос+картинки
- [music.md](music.md) -- ACE-Step (генерация песен с вокалом)
- [russian-vocals.md](russian-vocals.md) -- русскоязычные песни через AI
- [llm.md](llm.md) -- общие LLM
