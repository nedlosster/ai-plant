# TTS с клонированием голоса

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти), ROCm 7.2.1 (PyTorch) / CPU.

Text-to-Speech с **voice cloning** -- модели, которые синтезируют речь голосом конкретного человека по короткому референсному аудио (zero-shot, 6-30 сек). Все модели ниже работают локально, без облачных API, открытые лицензии.

## Особенности платформы для TTS

В отличие от LLM, эти модели -- **PyTorch-based**, не GGUF/llama.cpp. Запуск:

- **PyTorch ROCm** (рекомендуется) -- ROCm 7.2.1 уже стоит, см. [docs/inference/rocm-setup.md](../inference/rocm-setup.md)
- **CPU-fallback** -- медленнее, но не требует GPU
- **Vulkan не поддерживается** -- TTS-фреймворки идут только через CUDA/ROCm/CPU

VRAM-аппетиты у всех моделей умеренные (4-8 GiB), поместятся даже в HIP-лимит.

## Топ-модели

### 1. Qwen3-TTS (рекомендую для русского)

**Свежайшая**, выпущена командой Qwen в январе 2026.

- **Параметры**: ~7B
- **Языки**: 10, включая **русский нативно** (без дообучения)
- **Лицензия**: Open
- **Hub**: [Qwen/Qwen3-TTS](https://huggingface.co/Qwen/Qwen3-TTS)
- **GitHub**: [QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS)
- **VRAM**: ~8 GiB

**Что умеет:**
- Voice cloning по референсу (10 сек аудио)
- Free-form voice design -- описать голос текстом ("молодой женский с усталостью")
- Streaming generation -- output по мере генерации, не ждать конца
- Стабильная работа на длинных текстах

**Команда загрузки:**
```bash
hf download Qwen/Qwen3-TTS --local-dir ~/models/Qwen3-TTS
git clone https://github.com/QwenLM/Qwen3-TTS ~/projects/Qwen3-TTS
```

**Сценарии:**
- Озвучка статей/постов на русском голосом любого диктора
- Аудиокниги с разными персонажами по референсам
- Голосовой помощник с фирменным голосом проекта
- Real-time TTS для голосовых интерфейсов

---

### 2. F5-TTS (самая популярная open-source)

Эталон open-source TTS 2024-2025, "fairytaler that fakes fluent and faithful speech".

- **Параметры**: ~330M
- **Языки**: английский, китайский нативно. Русский -- через community-форки
- **Лицензия**: MIT
- **Hub**: [SWivid/F5-TTS_v1_Base](https://huggingface.co/SWivid/F5-TTS), [Misha24-10/F5-TTS_RUSSIAN](https://huggingface.co/Misha24-10/F5-TTS_RUSSIAN)
- **GitHub**: [SWivid/F5-TTS](https://github.com/SWivid/F5-TTS)
- **VRAM**: ~6 GiB

**Что умеет:**
- Zero-shot voice cloning (6-15 сек reference)
- Очень натуральные интонации
- Flow matching architecture -- быстрее diffusion
- Огромное community: дообученные веса для русского, японского, корейского

**Команда загрузки:**
```bash
# Базовая модель
hf download SWivid/F5-TTS --local-dir ~/models/F5-TTS

# Русская версия (рекомендую)
hf download Misha24-10/F5-TTS_RUSSIAN --local-dir ~/models/F5-TTS-RU

git clone https://github.com/SWivid/F5-TTS ~/projects/F5-TTS
```

**Сценарии:**
- Дубляж видео своим голосом
- "Озвучь как Тарантино" по 10-секундному образцу
- Быстрая прототипная озвучка
- Подкасты с цифровыми ведущими

---

### 3. Fish Speech 1.5

Apache 2.0, 8 языков (включая русский), один из самых быстрых.

- **Параметры**: ~500M
- **Языки**: 8 (англ, кит, рус, япон, корей, фр, нем, исп)
- **Лицензия**: Apache 2.0 (полная коммерческая свобода)
- **Hub**: [fishaudio/fish-speech-1.5](https://huggingface.co/fishaudio/fish-speech-1.5)
- **GitHub**: [fishaudio/fish-speech](https://github.com/fishaudio/fish-speech)
- **VRAM**: ~6 GiB
- **TTS Arena ELO**: 1339 (один из лидеров)

**Что умеет:**
- VQGAN tokenizer + Llama-based decoder (необычная архитектура)
- Voice cloning из 10-30 сек reference
- Хорошее качество эмоций
- Apache 2.0 -- можно встраивать в коммерческие продукты без оговорок

**Команда загрузки:**
```bash
hf download fishaudio/fish-speech-1.5 --local-dir ~/models/fish-speech-1.5
git clone https://github.com/fishaudio/fish-speech ~/projects/fish-speech
```

**Сценарии:**
- Коммерческие проекты (благодаря Apache 2.0)
- Многоязычные продукты -- одна модель на 8 языков
- API-сервис озвучки внутри компании
- Локализация контента

---

### 4. IndexTTS-2 (новейшая, топ по метрикам)

Превосходит state-of-the-art по WER, speaker similarity, emotional fidelity.

- **Параметры**: ~1.5B
- **Языки**: английский, китайский, русский, и др.
- **Лицензия**: Open
- **Hub**: [IndexTeam/IndexTTS-1.5](https://huggingface.co/IndexTeam/IndexTTS-1.5) (актуальная стабильная), [IndexTeam/IndexTTS-2](https://huggingface.co/IndexTeam/IndexTTS-2)
- **GitHub**: [index-tts/index-tts](https://github.com/index-tts/index-tts)
- **VRAM**: ~8 GiB

**Что умеет:**
- Контроль **длительности** генерации (можно задать tempo)
- Контроль **эмоций**: радость, грусть, нейтрально, агрессия, удивление
- Контроль характеристик голоса (возраст, пол, акцент)
- Лучшая в классе zero-shot voice cloning

**Команда загрузки:**
```bash
hf download IndexTeam/IndexTTS-1.5 --local-dir ~/models/IndexTTS-1.5
git clone https://github.com/index-tts/index-tts ~/projects/index-tts
```

**Сценарии:**
- Эмоциональные аудиокниги (грустные сцены / весёлые)
- Кино-дубляж с подгонкой под движение губ (контроль длительности)
- Игровые персонажи с разными настроениями
- Когда нужна не просто речь, а актёрская игра

---

### 5. XTTS v2 (Coqui) -- классика

Самый скачиваемый TTS на HuggingFace, проверенный временем.

- **Параметры**: ~750M
- **Языки**: 16 (включая русский)
- **Лицензия**: CPML (для коммерции -- проверить условия)
- **Hub**: [coqui/XTTS-v2](https://huggingface.co/coqui/XTTS-v2)
- **GitHub**: [coqui-ai/TTS](https://github.com/coqui-ai/TTS) (community fork: [idiap/coqui-ai-TTS](https://github.com/idiap/coqui-ai-TTS))
- **VRAM**: ~4 GiB
- **Reference**: 6 секунд

**Что умеет:**
- Voice cloning из самого короткого reference (6 сек)
- 16 языков из коробки
- Streaming поддержка для real-time
- Огромная экосистема туториалов и интеграций

**Команда загрузки:**
```bash
hf download coqui/XTTS-v2 --local-dir ~/models/XTTS-v2
git clone https://github.com/idiap/coqui-ai-TTS ~/projects/coqui-tts
```

**Замечание**: Coqui (компания) закрылась в 2024 году. Проект поддерживается community через форки. Активность снижена, но модель работает стабильно.

**Сценарии:**
- Проекты, где нужна минимальная длина reference (6 сек -- меньше чем у всех)
- Real-time стриминг
- Многоязычные приложения

---

## Сравнение

| Модель | Языки | Русский | Reference | Лицензия | VRAM | Особенность |
|--------|-------|---------|-----------|----------|------|-------------|
| **Qwen3-TTS** ⭐ | 10 | нативно | ~10 сек | Open | ~8 GiB | свежайшая, voice design текстом |
| **F5-TTS** | 2 + community | через форки | 6-15 сек | MIT | ~6 GiB | эталон, мощное community |
| Fish Speech 1.5 | 8 | да | 10-30 сек | Apache 2.0 | ~6 GiB | коммерческая свобода |
| IndexTTS-2 | 5+ | да | ~10 сек | Open | ~8 GiB | контроль эмоций и длительности |
| XTTS v2 | 16 | да | 6 сек | CPML | ~4 GiB | минимальный reference, 16 языков |

## Что нужно для запуска на платформе

1. **PyTorch с ROCm 7.2.1** (уже стоит). Установка для отдельного venv:
   ```bash
   python3 -m venv ~/.venv/tts
   source ~/.venv/tts/bin/activate
   pip install torch torchaudio --index-url https://download.pytorch.org/whl/rocm6.2
   ```
   (точную версию whl-канала уточнить под ROCm 7.2.1)

2. **HSA_OVERRIDE_GFX_VERSION=11.5.1** для gfx1151

3. **Длительный reference** -- чем дольше, тем лучше клонирование (хотя минимум 6 сек)

4. **Чистое аудио** -- без шумов, эха, музыки. Желательно studio quality

## Идеи проектов

| Проект | Стек |
|--------|------|
| Аудиокнига своим голосом | Qwen3-TTS / F5-TTS-RU |
| Дубляж YouTube видео на русский | F5-TTS-RU + ASR (Whisper) |
| Локальный голосовой ассистент | Qwen3-TTS + Qwen3-VL + Whisper |
| Подкаст с виртуальными гостями | F5-TTS / IndexTTS-2 |
| Озвучка для игры (несколько персонажей) | IndexTTS-2 (контроль эмоций) |
| TTS-сервис в локальной сети | Fish Speech 1.5 (Apache 2.0) |
| Инструмент для слабовидящих | XTTS v2 (быстро + 16 языков) |
| Восстановление голоса умершего родственника | F5-TTS + reference из старых записей |

## Веб-интерфейсы для TTS

Все модели выше -- это веса. Чтобы пользоваться, нужен фронтенд. Варианты:

### 1. TTS-WebUI (рекомендую -- "всё в одном")

**Один Gradio-интерфейс с поддержкой 20+ моделей**: F5-TTS, XTTS v2, Fish Speech, ACE-Step, GPT-SoVITS, CosyVoice, Kokoro, OpenVoice, ParlerTTS, StyleTTS2, Tortoise, Bark, Voicecraft, RVC, Demucs и др.

- **GitHub**: [rsxdalv/TTS-WebUI](https://github.com/rsxdalv/TTS-WebUI)
- **Стек**: Conda + Python venv + Gradio (+ опционально React frontend в Docker)
- **Установка**: один installer ставит всё, включая зависимости моделей
- **Подходит для**: универсальная лаборатория, сравнение моделей на одном reference

```bash
# Установка через готовый скрипт (см. секцию ниже)
./scripts/tts/install.sh
./scripts/tts/start.sh -d
# Web UI: http://localhost:7770
```

### 2. Open WebUI -> Custom TTS Engine

В уже стоящей Open WebUI:

1. Settings -> Audio -> Text-to-Speech Engine -> **Custom (OpenAI compatible)**
2. Custom TTS API Base URL: `http://192.168.1.77:8880/v1` (или где запущен TTS)

Любой TTS с OpenAI-совместимым API подойдёт. Backends:

- **[remsky/Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI)** -- Kokoro, очень быстрый, без cloning
- **[matatonic/openedai-speech](https://github.com/matatonic/openedai-speech)** -- XTTS/Piper в OpenAI API формате
- **[Resemble Chatterbox](https://docs.openwebui.com/features/media-generation/audio/text-to-speech/chatterbox-tts-api-integration/)** -- voice cloning, native гайд для Open WebUI

### 3. AllTalk TTS v2

Standalone-сервер именно под voice cloning. Поддерживает XTTS, F5-TTS, Piper.

- **GitHub**: [erew123/alltalk_tts](https://github.com/erew123/alltalk_tts)
- Менеджер voice library, finetune XTTS, batch-обработка
- Интегрируется с SillyTavern, Text-Generation-WebUI, Open WebUI

### 4. Standalone Gradio каждой модели

| Модель | Команда |
|--------|---------|
| F5-TTS | `f5-tts_infer-gradio --port 7860` |
| Fish Speech | `python tools/run_webui.py` |
| IndexTTS | `python webui.py` (в репо) |
| XTTS | [daswer123/xtts-webui](https://github.com/daswer123/xtts-webui) |
| Qwen3-TTS | `python qwen3_tts_webui.py` |

Самое простое если нужна **одна модель**.

### 5. SillyTavern (для ролеплея/чата)

Встроенная TTS-интеграция с XTTS, AllTalk, F5-TTS, Coqui. Озвучка реплик голосами персонажей.

### 6. Home Assistant

Через Wyoming Protocol -- TTS становится backend голосового ассистента в умном доме.

## Сравнение веб-стеков

| Решение | Моделей | Voice cloning | Сложность | Лучше для |
|---------|---------|---------------|-----------|-----------|
| **TTS-WebUI** ⭐ | 20+ | да (XTTS, F5, Fish, ...) | средняя | универсальная лаборатория |
| Open WebUI + Chatterbox | 1 | да | низкая | чат с озвучкой ответов LLM |
| AllTalk TTS v2 | 3-5 | да | низкая | специализированный voice cloning |
| Standalone Gradio | 1 | да | очень низкая | быстрый запуск одной модели |
| Kokoro-FastAPI | 1 | нет | очень низкая | быстрая озвучка чата без клона |

## Рекомендуемая схема

**Двухуровневая:**

1. **TTS-WebUI** -- основной хаб для экспериментов и проб. Удобно сравнить F5-TTS vs XTTS vs Fish Speech на одном reference, выбрать фаворита.
2. **Open WebUI -> Custom TTS** -- продакшн-озвучка ответов LLM в чате. Подключить F5-TTS-сервер из TTS-WebUI как backend.

## Скрипты на платформе

В репо есть готовые скрипты для TTS-WebUI:

```
scripts/tts/
├── install.sh      # Установка TTS-WebUI + PyTorch ROCm
├── start.sh        # Запуск Gradio (порт 7770)
├── stop.sh         # Остановка
├── status.sh       # Статус
└── config.sh       # Переменные окружения (HSA_OVERRIDE и т.п.)
```

## Связанные статьи

- [Vision LLM](vision.md) -- для голос+картинки см. Qwen2.5-Omni
- [Музыка и вокал](music.md) -- ACE-Step (генерация песен с вокалом)
- [Русский вокал](russian-vocals.md)
- [LLM общего назначения](llm.md)
