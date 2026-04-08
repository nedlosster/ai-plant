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

**Архитектура**: Qwen3-base language model + neural vocoder. Token-based audio generation -- такой же подход как у LLM, поэтому естественно генерирует длинные тексты без артефактов.

**Что умеет:**
- **Voice cloning** -- голос по 10 сек reference аудио
- **Free-form voice design** -- описать желаемый голос ТЕКСТОМ: "молодой женский с лёгкой усталостью, тёплый тембр" -- модель сгенерирует именно такой
- **Streaming generation** -- output по мере генерации, не ждать конца предложения
- **Стабильная работа на длинных текстах** -- может озвучить целую статью без срыва голоса
- **10 языков нативно** -- не нужны отдельные модели под каждый язык
- **Русский без потери качества** -- стресс-акценты, интонации, абсолютно естественное звучание

**Сильные кейсы:**
- **Длинные аудиокниги на русском** -- 10+ часов одним голосом, без срывов
- **Описать голос словами без референса** -- уникальная фича: не нужно искать образец, просто пишешь промпт
- **Стабильный voice cloning из плохого reference** -- работает даже с шумной записью
- **Многоязычные проекты** -- один сервер на 10 языков

**Слабые кейсы:**
- Самая большая (~8 GiB), медленнее F5-TTS
- Свежий релиз -- инструменты и тюнинг ещё нарабатываются
- Эмоциональный контроль слабее IndexTTS-2

**Команда загрузки:**
```bash
hf download Qwen/Qwen3-TTS --local-dir ~/models/Qwen3-TTS
git clone https://github.com/QwenLM/Qwen3-TTS ~/projects/Qwen3-TTS
```

**Идеальные сценарии:**
- Озвучка постов/статей на русском фирменным голосом
- Многоязычный TTS-сервис в продукте (10 языков -- одна модель)
- Аудиокниги с одним устойчивым голосом на 8+ часов
- Брендовый голос для проекта, описанный текстом без референса

---

### 2. F5-TTS (самая популярная open-source)

Эталон open-source TTS 2024-2025, "fairytaler that fakes fluent and faithful speech".

- **Параметры**: ~330M
- **Языки**: английский, китайский нативно. Русский -- через community-форки
- **Лицензия**: MIT
- **Hub**: [SWivid/F5-TTS_v1_Base](https://huggingface.co/SWivid/F5-TTS), [Misha24-10/F5-TTS_RUSSIAN](https://huggingface.co/Misha24-10/F5-TTS_RUSSIAN)
- **GitHub**: [SWivid/F5-TTS](https://github.com/SWivid/F5-TTS)
- **VRAM**: ~6 GiB

**Архитектура**: Flow Matching (более быстрый аналог diffusion) + DiT-trans- former. Подход "представь голос -> сразу сгенерируй" вместо пошагового denoising.

**Что умеет:**
- **Zero-shot voice cloning** -- от 6 секунд reference, лучшее качество в этом сегменте
- **Очень натуральные интонации** -- вопросительные/восклицательные/паузы передаются естественно
- **Flow matching architecture** -- 2-3 секунды генерации на абзац (быстрее всех остальных в списке)
- **Маленькая модель** -- 330M параметров, легко fine-tune
- **Огромное community** -- дообученные веса для русского, японского, корейского, испанского, арабского, итальянского

**Сильные кейсы:**
- **Быстрая итерация** -- генерация секунды, не минуты. Подходит для интерактивных приложений
- **Самый быстрый старт** -- минимум зависимостей, простая API
- **Reference любого качества** -- работает даже с микрофонной записью на телефон
- **Точное копирование акцента** -- лучше всех передаёт особенности произношения
- **Локальные на CPU** -- благодаря размеру можно запустить даже без GPU (медленно, но реально)

**Слабые кейсы:**
- На длинных текстах (5+ минут) может терять характеристики голоса
- Русский только через community-форки -- качество зависит от датасета конкретного fine-tune
- Без emotional control
- Без free-form voice design (в отличие от Qwen3-TTS)

**Команда загрузки:**
```bash
# Базовая модель
hf download SWivid/F5-TTS --local-dir ~/models/F5-TTS

# Русская версия (рекомендую)
hf download Misha24-10/F5-TTS_RUSSIAN --local-dir ~/models/F5-TTS-RU

git clone https://github.com/SWivid/F5-TTS ~/projects/F5-TTS
```

**Идеальные сценарии:**
- **Дубляж видео** -- 10 сек оригинала актёра -> весь дубляж его голосом
- **"Озвучь как Тарантино"** -- по 10-секундному youtube образцу
- Быстрая прототипная озвучка для презентаций
- Реалтайм-аватары / virtual streamers с уникальным голосом
- Подкасты с цифровыми ведущими (низкая задержка между репликами)
- Рассинхрон голоса под движение губ (короткие сегменты)

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

**Архитектура**: Необычная: VQGAN audio tokenizer + Llama-based decoder. Аудио кодируется в дискретные токены, дальше Llama их генерирует -- получается почти как text generation.

**Что умеет:**
- **Voice cloning** из 10-30 сек reference
- **Эмоциональная окраска** -- если в reference аудио был эмоционально окрашенный голос, копирует энергию
- **Apache 2.0** -- единственная топовая модель с такой свободной лицензией
- **8 языков с приличным качеством** -- включая русский
- **TTS Arena ELO 1339** -- по слепым тестам один из самых натуральных
- **Streaming поддержка** -- можно встраивать в real-time системы

**Сильные кейсы:**
- **Коммерческое использование без оговорок** -- единственный топовый TTS с Apache 2.0
- **Быстрый inference** -- ~500M параметров, средняя скорость лучше большинства
- **Стабильная экосистема** -- проект давно развивается, много багфиксов и улучшений
- **Хороший крос-лингвистический voice cloning** -- голос с английского reference на русский текст
- **Эмоциональная согласованность** -- если в reference радость, в output тоже радость

**Слабые кейсы:**
- Без free-form voice design
- Русский немного хуже Qwen3-TTS (community-сравнения)
- Не лидер ни в одной отдельной нише -- "ровно хорош везде"

**Команда загрузки:**
```bash
hf download fishaudio/fish-speech-1.5 --local-dir ~/models/fish-speech-1.5
git clone https://github.com/fishaudio/fish-speech ~/projects/fish-speech
```

**Идеальные сценарии:**
- **Коммерческие SaaS-продукты** -- TTS как часть платного сервиса (Apache 2.0!)
- API-сервис озвучки внутри компании, без рисков лицензирования
- Локализация контента в маркетинге
- Многоязычные обучающие материалы
- Замена платных AWS Polly / Google TTS в production

---

### 4. IndexTTS-2 (новейшая, топ по метрикам)

Превосходит state-of-the-art по WER, speaker similarity, emotional fidelity.

- **Параметры**: ~1.5B
- **Языки**: английский, китайский, русский, и др.
- **Лицензия**: Open
- **Hub**: [IndexTeam/IndexTTS-1.5](https://huggingface.co/IndexTeam/IndexTTS-1.5) (актуальная стабильная), [IndexTeam/IndexTTS-2](https://huggingface.co/IndexTeam/IndexTTS-2)
- **GitHub**: [index-tts/index-tts](https://github.com/index-tts/index-tts)
- **VRAM**: ~8 GiB

**Архитектура**: GPT-based с дополнительным emotion conditioning module и duration controller. Продвинутая система контроля -- эмоция и tempo задаются как параметры, а не выводятся из reference.

**Что умеет:**
- **Контроль длительности** -- можно задать точное время произнесения фразы (для дубляжа под движение губ)
- **Контроль эмоций** через параметры: радость, грусть, нейтрально, агрессия, удивление, страх
- **Контроль характеристик голоса** -- возраст (молодой/средний/пожилой), пол, акцент
- **Лучшая в классе zero-shot voice cloning** по measurable метрикам (WER, speaker similarity)
- **Industrial-level controllable** -- название статьи неслучайное, реально продакшн-уровень

**Сильные кейсы:**
- **Кинодубляж с подгонкой губ (lip-sync)** -- единственная open-source модель с реальным контролем длительности
- **Игровая озвучка** -- один и тот же персонаж разными эмоциями для разных сцен
- **Audiobook narration** -- грустные сцены звучат грустно, экшен-сцены динамичнее
- **Best WER** -- лучшая разборчивость для людей с проблемами слуха
- **A/B тестирование голосов** -- можно генерировать варианты с разными параметрами для UX-исследований

**Слабые кейсы:**
- Самая большая в списке (~1.5B), VRAM ~8 GiB
- Сложнее в использовании (больше параметров для tuning)
- Русский может быть хуже Qwen3-TTS (зависит от датасета)
- Слабее на длинных монотонных текстах -- IndexTTS делает акцент на эмоциональности

**Команда загрузки:**
```bash
hf download IndexTeam/IndexTTS-1.5 --local-dir ~/models/IndexTTS-1.5
git clone https://github.com/index-tts/index-tts ~/projects/index-tts
```

**Идеальные сценарии:**
- **Профессиональный дубляж кино/видеоигр** с lip-sync
- **Аудиокниги нового уровня** -- эмоционально окрашенные, не "tts-роботный голос"
- **Game characters** -- 50 фраз одного NPC разными эмоциями
- **Локализация рекламы** -- одну фразу актёра разными эмоциями для разных рынков
- **Театральные постановки** -- цифровые актёры с разными состояниями

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

**Архитектура**: GPT-2-style decoder + HiFiGAN vocoder + speaker encoder. Проверенная классическая схема, возрастом 2-3 года, но качество всё ещё конкурентное.

**Что умеет:**
- **Voice cloning из самого короткого reference в индустрии** -- 6 секунд достаточно
- **16 языков из коробки** -- больше всех в списке
- **Streaming поддержка** для real-time приложений
- **Fine-tuning доступен** -- можно дообучить под свой голос на 30 минут датасета (через TTS-WebUI)
- **Огромная экосистема** -- туториалы, интеграции, плагины во множестве проектов
- **Самый поддерживаемый** -- даже после закрытия Coqui сообщество активно

**Сильные кейсы:**
- **Минимальный reference** -- 6 секунд достаточно. Когда нет долгого образца голоса
- **Максимум языков в одной модели** -- 16 языков (рус, англ, нем, исп, фр, ит, пор, пол, тур, чеш, нид, яп, кит, ара, корей, венг)
- **Real-time** -- streaming подходит для голосовых ассистентов
- **Самый низкий VRAM** -- ~4 GiB, можно крутить на слабых GPU
- **Fine-tuning из коробки** -- лучшая для создания "корпоративного голоса"
- **Стабильная и зрелая** -- никаких сюрпризов в production

**Слабые кейсы:**
- Самая старая в списке -- по чисто акустическому качеству уступает F5-TTS / IndexTTS-2
- **Coqui (компания) закрылась в 2024** -- проект community-maintained, новых релизов не будет
- CPML-лицензия -- для коммерции нужно проверить условия (формально не Apache)
- Без emotional control
- Без free-form voice design

**Команда загрузки:**
```bash
hf download coqui/XTTS-v2 --local-dir ~/models/XTTS-v2
git clone https://github.com/idiap/coqui-ai-TTS ~/projects/coqui-tts
```

**Идеальные сценарии:**
- **16-язычный TTS** для глобальных продуктов
- **Минимальный reference** -- 6 сек у тебя есть, больше нет
- **Самый зрелый production-ready вариант** -- если нужна стабильность сегодня
- **Слабый GPU** или CPU-only deployment
- **Fine-tuning под уникальный корпоративный голос** на 30 минут датасета

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
