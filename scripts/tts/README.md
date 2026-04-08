# scripts/tts/ -- TTS-WebUI (text-to-speech с voice cloning)

Веб-интерфейс [rsxdalv/TTS-WebUI](https://github.com/rsxdalv/TTS-WebUI) -- единый Gradio для 20+ TTS-моделей: F5-TTS, XTTS v2, Fish Speech, IndexTTS, GPT-SoVITS, Kokoro, OpenVoice, ParlerTTS, StyleTTS2, Tortoise, Bark, Voicecraft, RVC, Demucs и др.

## Скрипты

| Скрипт | Назначение |
|--------|-----------|
| `install.sh` | Установка: клонирование репо, штатный installer, замена PyTorch на ROCm |
| `start.sh` | Запуск Gradio UI на порту 7770 (`--daemon` для фона) |
| `stop.sh` | Остановка |
| `status.sh` | Статус: установка, процесс, доступность UI, размер кэша моделей |
| `config.sh` | Переменные: `TTS_DIR`, `TTS_PORT`, `HSA_OVERRIDE_GFX_VERSION` и т.п. |

## Установка

```bash
cd ~/projects/ai-plant
./scripts/tts/install.sh
```

Что делает:
1. Клонирует [rsxdalv/TTS-WebUI](https://github.com/rsxdalv/TTS-WebUI) в `~/projects/tts-webui`
2. Запускает штатный installer (Conda + Python venv + зависимости)
3. Заменяет PyTorch на ROCm-вариант (`whl/rocm6.2`) для gfx1151
4. Проверяет доступность GPU

В процессе installer попросит выбрать TTS-движки -- рекомендую F5-TTS, XTTS v2, Fish Speech.

## Запуск

```bash
# Foreground
./scripts/tts/start.sh

# Daemon (фоновый)
./scripts/tts/start.sh -d

# Открыть UI
xdg-open http://localhost:7770
```

## Кэш моделей

`HF_HOME=${HOME}/models` -- кэш в общей папке, чтобы переиспользовать с другими проектами (Qwen3-TTS, F5-TTS-RU и т.д.).

## Конфигурация

Переопределить через env-переменные перед запуском:

```bash
TTS_PORT=7860 ./scripts/tts/start.sh -d         # другой порт
TTS_DIR=~/my-tts ./scripts/tts/install.sh       # другая директория
```

Постоянные переменные -- в `config.sh`.

## Связанные статьи

- [docs/models/tts.md](../../docs/models/tts.md) -- обзор TTS-моделей и веб-стеков
- [scripts/music/ace-step/](../music/ace-step/) -- ACE-Step (генерация музыки/вокала, не TTS)
- [scripts/inference/](../inference/) -- llama-server (LLM)
