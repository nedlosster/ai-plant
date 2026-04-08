# Модели для генерации видео

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти, 256 GB/s), ROCm 7.2.1 (HSA_OVERRIDE_GFX_VERSION=11.5.1).

## Статус на платформе

Видеогенерация работает через **ComfyUI + PyTorch ROCm**. Большинство современных моделей имеют:
- Нативные `safetensors` (fp16/bf16) -- основной формат
- **GGUF/FP8 квантизации** -- значительно уменьшают VRAM (часто 2-3x)
- ComfyUI-нативные узлы или wrapper-плагины (kijai-серия)

ROCm 7.2.1 на gfx1151 теперь стабилен -- запуск через `HSA_OVERRIDE_GFX_VERSION=11.5.1` и `.venv/bin/python` (не `uv run`).

## Преимущество 120 GiB

На consumer GPU (8-24 GiB) видеомодели либо не помещаются вообще, либо требуют агрессивной квантизации с потерей качества. На 120 GiB:

- Wan 2.6 14B MoE в **fp16** без квантизации
- HunyuanVideo 1.5 8.3B в fp16
- LTX 2.3 в **4K 50fps** (требует 32-48 GB+, помещается комфортно)
- Можно запускать **несколько моделей одновременно** (LLM + видео)
- T2V + I2V + длинный context model в одной памяти

## Топ-набор для платформы (2026)

| Модель | Параметры | fp16 | Скорость | Сильная сторона |
|--------|-----------|------|----------|------------------|
| **Wan 2.6** ⭐ | 14B MoE | ~28 GB | 5 сек 720p за ~5-9 мин | Cinematic, multi-shot, audio sync |
| **Wan 2.7** | 14B MoE | ~28 GB | -- | 1080p, native audio, лучшая motion coherence |
| **HunyuanVideo 1.5** | 8.3B | ~16 GB | -- | Эффективная новая foundation, 14 GB VRAM с offloading |
| **LTX-Video 2.3** | ~13B | ~26 GB | реалтайм-генерация | 4K 50fps, native audio, real-time |
| **CogVideoX 1.5-5B** | 5B | ~10 GB | 6 сек за ~3 мин | 720p, ComfyUI-нативная, хорошие LoRA |
| **Open-Sora 2.0** | ~3B | ~6 GB | 30 сек за ~5 мин | Sora-like архитектура, длинные видео |

## Сравнение моделей по характеристикам

| Модель | Год | T2V | I2V | Audio | Длительность | Разрешение | Лицензия |
|--------|-----|-----|-----|-------|--------------|------------|----------|
| Wan 2.7 | Q1 2026 | да | да | native | до 15 сек | 1080p | Apache 2.0 |
| Wan 2.6 | Dec 2025 | да | да | native | до 15 сек | 720p | Apache 2.0 |
| Wan 2.2 | 2025 | да | да | нет | до 8 сек | 720p | Apache 2.0 |
| HunyuanVideo 1.5 | Nov 2025 | да | да | нет | до 5 сек | 720p | HunyuanVideo |
| LTX-Video 2.3 | Mar 2026 | да | да | native | до 10 сек | **4K 50fps** | LTX |
| CogVideoX 1.5-5B | 2025 | да | да | нет | 6 сек | 720x480 | Apache 2.0 |
| Mochi 1 | 2024 | да | нет | нет | 5 сек | 480p | Apache 2.0 |
| SVD | 2023 | нет | да | нет | 14-25 кадров | 576x1024 | Stability CL |

---

## Wan 2.6 / 2.7 (Alibaba) -- актуальный лидер

**Назначение**: cinematic text-to-video и image-to-video с native audio sync.

- **Параметры**: 14B (MoE)
- **Архитектура**: Mixture-of-Experts diffusion -- разные эксперты для разных timestep'ов denoising. Эффективное масштабирование без линейного роста compute.
- **Hub**: [Wan-AI/Wan2.6](https://huggingface.co/Wan-AI), [Wan-AI/Wan2.7](https://huggingface.co/Wan-AI)
- **GitHub**: [Wan-Video/Wan2.2](https://github.com/Wan-Video/Wan2.2) (база), [Wan2.6](https://github.com/Wan-Video/Wan2.6)
- **Лицензия**: Apache 2.0

**Что умеет (Wan 2.6):**
- Видео до 15 секунд из текста, картинки, или reference-видео
- **Multi-shot generation** -- несколько сцен в одном видео с сохранением персонажей
- **Native audio synchronization** -- звук синхронизирован с visual
- **Character consistency** между сценами (раньше Wan 2.5 делал morphing -- 2.6 чисто)
- 720p из коробки

**Что добавлено в Wan 2.7:**
- **1080p output**
- Улучшенная motion coherence (меньше flickering артефактов)
- Native audio sync лучшего качества

**Сильные кейсы:**
- **Cinematic качество** -- лучший среди open-source по визуальной целостности
- **Multi-shot stories** -- "сначала персонаж в кафе, потом выходит на улицу" -- сохраняет ту же одежду и лицо
- **MoE-эффективность** -- 14B params, но не вся модель активна одновременно
- **Native audio** -- music + ambient + speech без отдельных сервисов
- **Apache 2.0** для коммерческого использования

**Слабые кейсы:**
- На 12 GB VRAM требует FP8 + low-res. На 120 GiB -- fp16 без компромиссов
- 5 сек 720p ~5-9 мин -- не для live-генерации
- Большой инициализационный overhead (загрузка модели)

**Идеальные сценарии:**
- Короткие рекламные ролики
- Music videos с автогенерацией ambient
- Storytelling -- многосценные ролики с сюжетом
- Image-to-video для оживления статичных иллюстраций
- Концепт-арт для кино/игр (предвиз)

```bash
# Wan 2.6 T2V/I2V (~28 GB fp16)
hf download Wan-AI/Wan2.6-T2V-14B --local-dir ~/models/wan2.6-t2v
hf download Wan-AI/Wan2.6-I2V-14B --local-dir ~/models/wan2.6-i2v
```

---

## HunyuanVideo 1.5 (Tencent) -- новая эффективная foundation

**Назначение**: высококачественная foundation-модель, переписанная в эффективности.

- **Параметры**: 8.3B (было 13B в 1.0)
- **Релиз**: ноябрь 2025
- **Hub**: [tencent/HunyuanVideo](https://huggingface.co/tencent/HunyuanVideo)
- **GitHub**: [Tencent-Hunyuan/HunyuanVideo](https://github.com/Tencent-Hunyuan/HunyuanVideo)
- **Лицензия**: Tencent HunyuanVideo License

**Архитектура**: Унифицированная transformer-based архитектура для image и video. Dual-stream design (visual + text streams взаимодействуют). Foundation для дальнейших fine-tune.

**Что умеет:**
- T2V и I2V в одной модели
- 14 GB VRAM с offloading -- доступна для consumer GPU (но на 120 GiB можно без offload)
- Высокая точность text-video alignment
- Понимание кинематографических техник (углы, движение камеры)
- Понимание физики объектов (падение, столкновения)

**Сильные кейсы:**
- **Foundation для fine-tune** -- база для своих доменных моделей
- **Text-video alignment** -- очень точно следует промпту
- **Физика объектов** -- лучше других open-source
- **Понимание камеры** -- pan, zoom, dolly, tracking shots
- **Эффективность 1.5** -- в 1.5 раза меньше параметров без потери качества по сравнению с 1.0

**Слабые кейсы:**
- Без native audio (отдельная задача)
- Tencent-лицензия (не Apache)
- Длительность короче чем Wan 2.6 (до 5 сек vs 15)

**Идеальные сценарии:**
- Когда нужна точность следования сложному промпту
- Кинематографичные сцены с конкретными ракурсами камеры
- Fine-tuning под доменные данные (медицина, инженерия, реклама)
- Продакшн-pipeline где важна предсказуемость text-alignment

```bash
hf download tencent/HunyuanVideo --local-dir ~/models/hunyuan-video-1.5
```

---

## LTX-Video 2.3 (Lightricks) -- скорость и 4K

**Назначение**: real-time генерация видео с фокусом на скорость и итерации.

- **Релиз**: март 2026 (LTX-2 в январе 2026, LTX-2.3 -- последняя)
- **Hub**: [Lightricks/LTX-Video](https://huggingface.co/Lightricks/LTX-Video)
- **GitHub**: [Lightricks/LTX-Video](https://github.com/Lightricks/LTX-Video)
- **Лицензия**: LTX License (не Apache)
- **VRAM**: 32 GB+ минимум, 48 GB+ для стабильной 4K

**Архитектура (2.3)**: Перестроенный VAE, text connector в 4 раза больше, native audio generation. Оптимизировано на скорость как главную цель.

**Что умеет:**
- **4K 50fps** native -- единственная open-source с этим
- **Real-time generation** на достаточном железе
- **Native audio** -- генерация звука вместе с видео
- 30fps 1216x704 быстрее реального времени на capable hardware
- Iterative editing -- быстрая доводка результата

**Сильные кейсы:**
- **Скорость** -- быстрая итерация для контент-мейкеров
- **4K качество** -- профессиональный output без upscale
- **Real-time или близко** -- workflow без долгого ожидания
- **Native audio** -- звук + видео в одном вызове
- **Текстовое следование** -- большой text connector в 2.3

**Слабые кейсы:**
- LTX License -- не подходит для всех коммерческих сценариев
- Минимум 32 GB VRAM (на 120 GiB не проблема)
- Стилистика отличается от cinematic -- скорее коммерческая/clean
- Длительность скромная (до 10 сек)

**Идеальные сценарии:**
- Контент-мейкеры с большим объёмом видео в день
- Live brainstorming/preview видео-идей
- Социальные сети (быстрая итерация для тестирования)
- Реклама где важна скорость production
- Замена платных сервисов типа Runway/Pika для high-frequency пользователей

```bash
hf download Lightricks/LTX-Video --local-dir ~/models/ltx-video-2.3
```

---

## CogVideoX 1.5-5B (Tsinghua/THUDM) -- ComfyUI-классика

**Назначение**: компактная T2V/I2V модель с лучшей ComfyUI-экосистемой.

- **Параметры**: 5B (есть также 2B-вариант)
- **Hub**: [THUDM/CogVideoX1.5-5B](https://huggingface.co/THUDM/CogVideoX1.5-5B)
- **GitHub**: [THUDM/CogVideo](https://github.com/THUDM/CogVideo)
- **Лицензия**: Apache 2.0
- **Разрешение**: 720x480, 6 секунд, 8 fps
- **Архитектура**: 3D-трансформер с image+video pre-training

**Что умеет:**
- 6-секундные клипы 720x480
- T2V и I2V варианты
- bfloat16 + квантизация (Q4/Q8 GGUF доступны)
- Кастомные LoRA для стилей (большая community-библиотека)
- Лучшая интеграция с ComfyUI (kijai/ComfyUI-CogVideoXWrapper)

**Сильные кейсы:**
- **Лучшая ComfyUI-поддержка** -- готовые узлы, T2V/I2V/LoRA в одном wrapper
- **Зрелая экосистема** -- много туториалов, workflow-share
- **LoRA для стилей** -- можно найти community LoRA для аниме/реалистичных/CGI стилей
- **Низкий VRAM** -- работает на 18-30 GB
- **Apache 2.0** + стабильность

**Слабые кейсы:**
- Старее новых моделей (Wan 2.6, HunyuanVideo 1.5)
- Низкое разрешение (720x480) -- нужен upscale для production
- Только 6 секунд -- не для длинных историй
- Качество motion уступает Wan 2.6

**Идеальные сценарии:**
- **Эксперименты и обучение** -- мало VRAM, быстрый старт
- **Кастомные LoRA-стили** -- если уже в экосистеме SD/SDXL и хочется тот же flow
- **Прототипирование** -- быстрая проверка концепта перед запуском Wan 2.6
- **ComfyUI workflows** -- если цепочка уже на ComfyUI узлах

```bash
hf download THUDM/CogVideoX1.5-5B --local-dir ~/models/cogvideox-1.5-5b
```

---

## Open-Sora 2.0 (HPC-AI Tech) -- Sora-like архитектура

**Назначение**: open-source реализация Sora-подобной архитектуры с фокусом на длинные видео.

- **Параметры**: ~3B
- **Hub**: [hpcai-tech/Open-Sora](https://huggingface.co/hpcai-tech/Open-Sora)
- **GitHub**: [hpcaitech/Open-Sora](https://github.com/hpcaitech/Open-Sora)
- **Лицензия**: Apache 2.0

**Что умеет:**
- Различные разрешения и aspect ratio
- Длинные видео (до 30 секунд)
- DiT-архитектура (Diffusion Transformer) -- та же база что и у Sora

**Сильные кейсы:**
- **Длинные видео** -- лидер по длительности среди open-source
- **Variable aspect ratio** -- горизонталь, вертикаль, square без переобучения
- **Apache 2.0** + research-friendly
- **Open-source реализация Sora** -- интересно для исследователей и студентов

**Слабые кейсы:**
- Качество ниже Wan 2.6 / HunyuanVideo
- Не лидер ни в одной отдельной нише
- Slower development cycle (research, не product)

**Идеальные сценарии:**
- Исследовательские проекты в video generation
- Когда нужны длинные видео (>10 сек) с приемлемым качеством
- Эксперименты с DiT-архитектурой
- Образовательные проекты

```bash
hf download hpcai-tech/Open-Sora --local-dir ~/models/open-sora-2.0
```

---

## SVD (Stable Video Diffusion) -- I2V классика

**Назначение**: оживление статичных изображений в короткие видео.

- **Параметры**: ~1.5B
- **Hub**: [stabilityai/stable-video-diffusion-img2vid-xt](https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt)
- **Лицензия**: Stability AI Community License
- **Длительность**: 14-25 кадров (~1-2 сек)

**Что умеет:**
- Только Image-to-Video (нет text)
- Стабильный motion для статичных фото
- Быстро (~30 сек на клип)

**Сильные кейсы:**
- **Single-purpose tool** -- если нужен только I2V и ничего больше
- **Скорость** -- самая быстрая I2V
- **Низкий VRAM** -- работает на старом железе
- Хорошая coherence motion для портретов и пейзажей

**Слабые кейсы:**
- Только I2V (нет T2V)
- 1-2 секунды максимум
- Стилистика "natural" -- не подходит для cinematic
- Stability CL -- ограничения для коммерции
- **Устаревает на фоне Wan 2.6 I2V**

**Идеальные сценарии (когда выбирать вместо Wan 2.6):**
- Когда нужны очень короткие GIF-анимации из фото
- Batch-обработка тысяч фото за минимальное время
- Слабое железо (Wan 2.6 не помещается)

```bash
hf download stabilityai/stable-video-diffusion-img2vid-xt --local-dir ~/models/svd-xt
```

---

## Удалено из актуального списка

### Wan 2.1 (устарела)

Заменена Wan 2.2/2.6/2.7. Основные улучшения в новых версиях:
- 2.2 -- MoE backbone
- 2.6 -- multi-shot, character consistency, native audio
- 2.7 -- 1080p, лучшая motion

### HunyuanVideo 1.0 (устарела)

13B -> заменена на 1.5 (8.3B) с лучшей эффективностью при том же качестве.

### LTX-Video 1.x

Заменена LTX-Video 2.3 (4K, native audio).

### Mochi 1 (устарела)

10B, актуально только для исследовательских целей. Wan 2.6 покрывает все use cases с лучшим качеством.

### AnimateDiff v3

LoRA-подход к SD 1.5 устарел. Современные dedicated video-модели (Wan, Hunyuan, LTX) дают значительно лучшее качество. Имеет смысл только если уже в экосистеме SD 1.5 и нужна минимальная анимация.

### CogVideoX 2B (устарела)

Заменена CogVideoX 1.5-5B с лучшим качеством при том же VRAM на 120 GiB.

---

## Что выбрать для 120 GiB VRAM

| Задача | Рекомендация | Альтернатива |
|--------|--------------|--------------|
| Максимальное качество T2V | **Wan 2.7** (1080p) или **Wan 2.6** (720p) | HunyuanVideo 1.5 |
| Image-to-video | **Wan 2.6 I2V** | SVD (для очень коротких) |
| Скорость + 4K | **LTX-Video 2.3** | -- |
| Native audio | **Wan 2.6/2.7** или **LTX 2.3** | -- |
| Длинные видео (>10 сек) | **Open-Sora 2.0** | Wan 2.6 (15 сек limit) |
| ComfyUI-эксперименты | **CogVideoX 1.5-5B** (зрелые узлы) | Wan через wrapper |
| Multi-shot stories | **Wan 2.6** -- единственная с character consistency | -- |

## Загрузка топ-набора

```bash
cd ~/projects/ai-plant

# 1. Wan 2.6 (cinematic, multi-shot, audio) -- ~28 GB
hf download Wan-AI/Wan2.6-T2V-14B --local-dir ~/models/wan2.6-t2v
hf download Wan-AI/Wan2.6-I2V-14B --local-dir ~/models/wan2.6-i2v

# 2. HunyuanVideo 1.5 (foundation, точное alignment) -- ~16 GB
hf download tencent/HunyuanVideo --local-dir ~/models/hunyuan-video-1.5

# 3. LTX-Video 2.3 (4K, real-time, native audio) -- ~26 GB
hf download Lightricks/LTX-Video --local-dir ~/models/ltx-video-2.3

# 4. CogVideoX 1.5-5B (ComfyUI-классика, LoRA) -- ~10 GB
hf download THUDM/CogVideoX1.5-5B --local-dir ~/models/cogvideox-1.5-5b
```

## Источники моделей

| Ресурс | Что искать |
|--------|-----------|
| [HuggingFace Wan-AI](https://huggingface.co/Wan-AI) | Wan 2.6, 2.7, T2V/I2V варианты |
| [HuggingFace Tencent](https://huggingface.co/tencent) | HunyuanVideo 1.5 |
| [HuggingFace Lightricks](https://huggingface.co/Lightricks) | LTX-Video 2.3 |
| [HuggingFace THUDM](https://huggingface.co/THUDM) | CogVideoX 1.5 |
| [HuggingFace HPC-AI](https://huggingface.co/hpcai-tech) | Open-Sora 2.0 |
| [GitHub kijai](https://github.com/kijai) | ComfyUI wrappers (CogVideoX, Wan, Hunyuan) |
| [GitHub ComfyUI](https://github.com/comfyanonymous/ComfyUI) | Workflows, примеры |
| [Civitai](https://civitai.com/) | LoRA для стилей |

## Связанные статьи

- [Видео: быстрый старт](../use-cases/video/quickstart.md)
- [Видео: продвинутое](../use-cases/video/advanced.md)
- [Картинки](images.md) -- Flux, SD3, общая diffusion-экосистема
- [Vision LLM](vision.md) -- понимание видео (не генерация)
