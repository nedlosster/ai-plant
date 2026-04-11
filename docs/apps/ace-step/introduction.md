# ACE-Step: введение

## Что это как платформа

**ACE-Step** -- это не просто diffusion-модель для генерации песен. Это **целостный софтверный стек**, включающий:

1. **Нейросетевую модель** -- dual-component diffusion (DiT 3.5B + Language Model 4B для conditioning)
2. **Inference-движок** -- Python package `acestep` с PyTorch backend (CUDA / ROCm / CPU)
3. **Gradio UI** -- веб-интерфейс для интерактивной генерации с контролем всех параметров
4. **LoRA trainer** -- встроенный скрипт для файнтюна под свой стиль / голос
5. **Model downloader** -- утилита для скачивания весов из HuggingFace с правильной структурой

Это отличает ACE-Step от "просто модели" (где ты получаешь `.safetensors` и сам пишешь inference-код). Пользователю даётся **готовое приложение**: скачал, запустил `python -m acestep`, открыл браузер -- работает.

На нашей платформе [docs/models/families/ace-step.md](../../models/families/ace-step.md) описывает **саму нейросеть** (веса, архитектуру, квантизации). Этот раздел -- про **софтверный стек вокруг неё**.

## Краткая история

- **Май 2025** -- первый публичный релиз ACE-Step 1.0 от команды ACE-Step (Moonshot-related). Монолитная модель без LM conditioning. Качество вокала среднее, часто "плывёт" на длинных lyrics
- **Июль 2025** -- ACE-Step 1.5 с **dual-component** архитектурой: DiT + отдельная Language Model для conditioning. Вокал становится значительно более согласованным с текстом
- **Октябрь 2025** -- **turbo** вариант DiT с 8 шагами sampling вместо 50. Генерация в ~6x быстрее, качество сравнимо
- **Декабрь 2025** -- поддержка **50+ языков** включая русский, японский, китайский, испанский, арабский
- **2025-2026** -- активное развитие community: LoRA-тренировка под конкретных вокалистов, cover/remix режимы, интеграция с DAW (Digital Audio Workstations) через Python API
- **2026** -- стабильная версия 1.5-turbo -- основной рекомендованный вариант для production и self-host

## Как устроен стек: краткий обзор

```
+---------------------------+
|  Gradio UI (Python)       |      <- пользователь взаимодействует здесь
|  :7860                    |
+-------------+-------------+
              |
              v
+---------------------------+
|  acestep package (Python) |      <- inference-движок
|  - tokenize tags + lyrics |
|  - sampler (8 steps turbo)|
|  - audio VAE decode       |
|  - WAV output             |
+-------+-----+-------------+
        |     |
        v     v
+---------+ +----------------+
| DiT 3.5B| | LM 4B          |
| (dit-   | | (lyrics-       |
|  turbo) | |  conditioning) |
+---------+ +----------------+
        |     |
        v     v
+---------------------------+
|  PyTorch (CUDA/ROCm/CPU)  |
+---------------------------+
```

Детальная архитектура -- в [architecture.md](architecture.md).

## Позиционирование против альтернатив

Music-генерация в open-source 2025-2026 разделена на категории:

| Продукт | Тип | Что даёт | Минус |
|---------|-----|----------|-------|
| **ACE-Step 1.5** | Vocal songs (DiT + LM) | Полные песни с вокалом, 50+ языков, ROCm support | Качество вокала уступает Suno/Udio |
| **[MusicGen](../../models/families/musicgen.md)** | Instrumental (transformer) | Инструментальная музыка, быстрый, стабильный | Нет вокала |
| **[YuE](../../models/families/yue.md)** | Vocal songs (flow matching) | Альтернатива ACE-Step, другой подход | Меньше community, ограниченные языки |
| **[Stable Audio](../../models/families/stable-audio.md)** | Sound effects + short music | SFX и короткие loops | Не для песен |
| **[SongGeneration](../../models/families/songgeneration.md)** | Text-to-song | Expérimental, early stage | Не mature |

**Закрытые альтернативы для контекста**:
- **Suno** -- cloud SaaS, лучшее качество вокала на рынке, $10/мес
- **Udio** -- cloud SaaS, конкурент Suno, похожее качество
- **Riffusion (v3)** -- частично open, частично cloud

### Где ACE-Step выигрывает

1. **Open-source с Apache 2.0** весами -- можно использовать коммерчески
2. **Native AMD ROCm support** -- редкость в music-моделях (большинство только CUDA)
3. **50+ языков** включая русский, японский, китайский -- больше чем у Suno на момент релиза
4. **LoRA-тренировка** -- можно сделать свой "voice fine-tune" на датасете из ~100-500 песен
5. **Полный контроль над процессом** -- sampling parameters, seed, step count, lyrics intensity
6. **Self-hosted privacy** -- никакие тексты и генерации не уходят на чужой сервер

### Где ACE-Step проигрывает

- **Качество вокала уступает Suno** -- это ожидаемо, Suno -- 3+ года R&D с приватными данными
- **Длинные песни (>3 мин)** -- иногда теряет coherence в середине
- **Rap и hip-hop** -- flow не такой чёткий как у specialised моделей
- **Instrumental-only** -- лучше MusicGen или Stable Audio

## Философия проекта

### 1. End-to-end в одном Python package

Всё нужное для inference -- в package `acestep`. Не нужно скачивать 5 разных репозиториев, разбираться как связать DiT с LM, как правильно применять VAE. `pip install -e .` -- и готово.

### 2. Gradio UI из коробки

Не просто CLI или Python API, а полноценный web-интерфейс. Это делает проект доступным для non-developer пользователей: скачал, запустил start-скрипт, открыл браузер.

### 3. LoRA-first

В комплекте `acestep.trainer` -- можно тренировать LoRA поверх базовой модели на своём датасете (аудио + lyrics pairs). Это открывает:
- Fine-tune под конкретного вокалиста
- Адаптация под конкретный жанр
- Стилистическую адаптацию

### 4. Multi-language first-class

Языки не как "бонус", а как первый класс citizens. Датасет тренировки включает 50+ языков, токенизатор умеет их все, LM 4B обучена на мультиязычных lyrics. Русский язык поддерживается нативно -- см. [russian-vocals.md](../../models/russian-vocals.md) и [use-cases/music/russian-classics.md](../../use-cases/music/russian-classics.md).

### 5. ROCm как first-class backend

Большинство audio-моделей в open-source 2024-2025 были CUDA-only из-за зависимостей на `torchaudio` с CUDA kernels и специфичных CUDA-ops. ACE-Step изначально тестировался на AMD Instinct и RDNA GPU, что делает его одним из немногих music-генераторов с документированным ROCm путём.

## Что ожидать на Strix Halo

На нашей платформе ACE-Step сталкивается с **платформенным ограничением**, не своим собственным:

- **Strix Halo KFD VRAM limit**: из 96 GiB unified memory, KFD (AMD kernel driver) экспозит только **15.5 GiB** как "dedicated GPU memory" -- и это не хватает LM 4B (требует ~8 GiB VRAM + overhead + DiT + audio VAE = ~20+ GiB peak)
- **Автоконфиг ACE-Step** на tier1 (CPU) отключает LM, оставляя DiT-only режим (~4 GiB, работает)
- **Результат**: на Strix Halo ACE-Step работает **в CPU-режиме** (медленно -- минуты на песню) или **в DiT-only ROCm** (быстро, но без LM conditioning -- хуже согласованность с lyrics)

Это **временно**. Ожидается:
- ROCm 7.3+ с исправлением KFD VRAM exposure для gfx1151 (Strix Halo)
- Либо обновление ACE-Step с smarter tier-detection / CPU-LM offload
- Либо community-adapt'ация с `ttm.pages_limit=31457280` для GTT unlock (see [../../platform/vram-allocation.md](../../platform/vram-allocation.md))

Подробный статус -- в [`scripts/music/ace-step/README.md`](../../../scripts/music/ace-step/README.md) и в [README.md](README.md) этого раздела.

**На машинах без KFD issue** (RTX 4090, Mac M4) ACE-Step работает полноценно: LM 4B + DiT turbo, генерация 2-минутной песни за ~66 секунд.

## Экосистема

| Компонент | Что это |
|-----------|---------|
| **[ACE-Step/ACE-Step-1.5](https://github.com/ACE-Step/ACE-Step-1.5)** | Основной репозиторий: inference, trainer, UI |
| **[HuggingFace: ACE-Step](https://huggingface.co/ACE-Step)** | Веса и checkpoints (v1-3.5B, LM 4B, v1.5-turbo) |
| **[HF Space demo](https://huggingface.co/spaces/ACE-Step/ACE-Step)** | Online-демо для пробы без установки |
| **Community LoRA** | Fine-tune'ы опубликованные пользователями (на Civitai, HF) |
| **Discord community** | Поддержка, обмен workflow'ами |

## Связанные статьи

- [README.md](README.md) -- обзор профиля и статус на платформе
- [architecture.md](architecture.md) -- глубокое устройство dual-component стека
- [simple-use-cases.md](simple-use-cases.md) -- генерация первой песни
- [advanced-use-cases.md](advanced-use-cases.md) -- LoRA training, cover/remix, batch
- [../../models/families/ace-step.md](../../models/families/ace-step.md) -- карточка модели (веса, нейросеть)
- [../../use-cases/music/README.md](../../use-cases/music/README.md) -- use-case обзор
- [../../use-cases/music/quickstart.md](../../use-cases/music/quickstart.md) -- операционный quickstart
- [../../use-cases/music/russian-classics.md](../../use-cases/music/russian-classics.md) -- примеры русского вокала
