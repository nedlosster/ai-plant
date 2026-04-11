# LTX-2 (Lightricks, 2026)

> Первая open-source foundation-модель с синхронизированной audio+video генерацией в одном forward pass. Dual-stream DiT 14B+5B, 4K 50fps, native 20-секундные клипы.

**Тип**: dual-stream Diffusion Transformer (14B video + 5B audio = 19B total)
**Лицензия**: Open weights + training code (первая truly open в сегменте)
**Статус на сервере**: не скачана
**Направления**: [video](../video.md)
**Дата**: soft-launch октябрь 2025, полный open-source с весами 6 января 2026

## Обзор

**LTX-2** от Lightricks -- следующее поколение семейства [LTX-Video](ltx-video.md), отдельная foundation-модель, а не инкрементальная версия. Главное отличие от 2.3 и любых других open-source видеомоделей 2025-2026: **аудио и видео генерируются совместно в одном проходе через трансформер**, а не стыкуются на post-processing этапе. Это делает LTX-2 первой моделью, у которой звук эффектов, диалог и моушен объективно синхронны на уровне архитектуры.

История релиза:
- **Октябрь 2025** -- первый soft-launch (limited access, закрытые веса, API-only)
- **6 января 2026** -- полный open-source: веса, training code, benchmarks. [Пресс-релиз Lightricks](https://www.globenewswire.com/news-release/2026/01/06/3213304/0/en/Lightricks-Open-Sources-LTX-2-the-First-Production-Ready-Audio-and-Video-Generation-Model-With-Truly-Open-Weights.html)

Параллельно существует LTX-Video 2.3 (март 2026) -- это **не** LTX-2, а отдельная ветка серии, развивающая архитектуру LTX-1 с перестроенным VAE и увеличенным text connector. LTX-2 пошла по другому пути: новый foundation с 19B параметров и двухпоточной архитектурой.

## Архитектура: асимметричный dual-stream DiT

Ключевая инновация LTX-2 -- **асимметричная двухпоточная архитектура Diffusion Transformer**. 19B параметров модели разделены между двумя потоками:

- **Video stream**: 14B параметров -- обрабатывает латентные представления видео-кадров (через VAE из LTX-Video)
- **Audio stream**: 5B параметров -- обрабатывает латентные представления аудио (через отдельный audio autoencoder)

Размеры потоков обоснованы **информационной плотностью модальностей**: видео несёт в ~3 раза больше данных в секунду чем звук (разрешение × 3 канала × частота кадров vs 2 канала × sample rate). Поэтому разделение 14B/5B ≈ 3:1, а не 50/50.

### Cross-attention как связующий механизм

Потоки не живут изолированно -- они **обмениваются информацией через cross-attention** на каждом уровне диффузионного процесса. Схема, упрощённо:

```
                 timestep t
                     |
    +----------------+----------------+
    |                                 |
    v                                 v
[Video tokens]  <--cross-attention--> [Audio tokens]
    |   ^                             ^    |
    |   |                             |    |
    v   +--<--self-attention + FFN----+    v
[Video tokens']                         [Audio tokens']
    |                                        |
    +----------------+-----------------------+
                     |
                 timestep t-1
```

В каждом блоке:
1. **Self-attention** внутри потока (video-kernel смотрит на video, audio на audio)
2. **Cross-attention** -- video-tokens смотрят на audio-tokens и наоборот. Это позволяет motion "учитывать" удар барабана, и наоборот -- звук автомобиля "знать" о скорости движения на кадре
3. **Feed-forward** -- независимо в каждом потоке

Результат: **в одном forward pass генерируются и кадры, и звук, полностью синхронно**. Это принципиально отличается от подхода 2025 года, когда видео генерировалось одной моделью, а затем audio отдельно дорисовывалось через specialized model (пример: MMAudio для HunyuanVideo).

### Hybrid diffusion-transformer backbone

Базовая архитектура -- DiT (Diffusion Transformer), впервые представленный в 2023 году (Peebles & Xie, Meta). В LTX-2 он **гибридизован**:
- Часть блоков -- классический self-attention (global awareness)
- Часть блоков -- locality-aware (convolution-like) для эффективной обработки высокого разрешения
- Cross-attention между потоками в отдельных dedicated блоках

Это называется "distilled hybrid" архитектурой -- комбинация эффективности CNN на высоких разрешениях и выразительности attention на long-range зависимостях. По официальным метрикам Lightricks, это даёт **в ~1.8x выше throughput** чем чистый DiT при той же визуальной чёткости.

## Возможности

| Параметр | Значение |
|----------|----------|
| **Разрешение (макс)** | 4K (3840×2160) |
| **Частота кадров (макс)** | 50 fps |
| **Длительность (макс)** | **20 секунд** (15 секунд с audio sync в стабильном режиме) |
| **Audio** | Синхронизированный в одном forward pass, до 10 секунд |
| **Условия** | text-to-video (T2V), image-to-video (I2V), text+image-to-video |
| **Audio-типы** | диалог, ambience, SFX, music elements |
| **Языки промптов** | English основной, multilingual через T5/UMT5 text encoder |
| **VAE** | Унаследован из LTX-Video (spatial + temporal compression ~32×) |

### Что делает LTX-2 уникальным

1. **Синхронизированный audio-video в одном проходе** -- единственная открытая модель, которая это умеет на foundation уровне (без pipeline из двух моделей)
2. **4K нативно**, без upscaling как post-process
3. **До 20 секунд single clip** -- рекорд для open-source video моделей на апрель 2026 (Wan 2.7 -- 15 сек, HunyuanVideo 1.5 -- 5 сек)
4. **Полностью открытое** -- веса, training code, benchmarks. Это первое "truly open" в сегменте (Wan 2.7 Apache 2.0 без training кода, LTX-Video 2.3 под своей LTX License)
5. **Quality на уровне commercial моделей** -- по benchmarks Lightricks, приближается к Runway Gen-4 и Veo 3 в слепых A/B тестах

## Квантизация и VRAM

LTX-2 в полном BF16 весит **~38 GB** (19B * 2 bytes). Это больше чем влезает в 24 GB consumer GPU, поэтому проект с самого начала поддерживает **агрессивные квантизации**:

### NVFP-квантизации (проприетарный NVIDIA формат)

Lightricks совместно с NVIDIA подготовил специальные FP4/FP8 варианты, оптимизированные под Blackwell Tensor Cores:

| Формат | Размер | VRAM (720p 24fps) | Производительность | Platforms |
|--------|--------|-------------------|--------------------|-----------|
| **BF16** | ~38 GB | 24+ GB | baseline | любой |
| **NVFP8** | ~27 GB | ~15-18 GB | **2x vs BF16** | RTX 50xx с native FP8, H100+ |
| **NVFP4** | ~17 GB | ~10-12 GB | ~1.5x vs BF16 | RTX 50xx, B200 |

**NVFP4** особенно интересен -- 60% уменьшение VRAM без заметного качественного падения (по benchmarks NVIDIA при анонсе CES 2026). Это позволяет запустить LTX-2 даже на 12-16 GiB consumer картах.

### GGUF-варианты (community)

Unsloth и сообщество выпустили GGUF-квантизации для использования через ComfyUI-GGUF и прочие GGUF-loaders:

| Вариант | Размер | VRAM (приблизительно) | Качество | Repo |
|---------|--------|----------------------|----------|------|
| **Q3_K_S** | 9.28 GB | ~14 GB | ощутимая деградация | [unsloth/LTX-2-GGUF](https://huggingface.co/unsloth/LTX-2-GGUF) |
| **Q4_K_S** | 11.8 GB | ~16 GB | хороший компромисс | -- |
| **Q5_K_M** | 14.4 GB | ~19 GB | near-BF16 | -- |
| **Q8_0** | 20.4 GB | ~26 GB | lossless | -- |

На consumer GPU (RTX 3090/4090, 24 GB) рабочая точка -- **Q5_K_M**: 14 GB весов + ~5 GB latents + overhead = ~24 GB VRAM для 720p 24fps.

На **нашей платформе** (Strix Halo, 120 GiB unified) -- помещается **Q8_0 с огромным запасом**. Квантизация нужна только для скорости (меньше весов → быстрее чтение из LPDDR5), не для фитирования в память.

## На нашей платформе

Ключевой вопрос: стоит ли это моделью заниматься на Strix Halo.

### Что работает теоретически

- **VRAM**: 120 GiB >> 20 GB для Q8_0 или 38 GB для BF16 -- помещается с запасом
- **Формат**: GGUF через ComfyUI-GGUF -- поддерживается на Vulkan/ROCm
- **VAE decode**: классическая diffusion-модель, подобна FLUX и Wan которые уже работают

### Что станет проблемой

- **Производительность**: LPDDR5 256 GB/s -- это fundamental limit для diffusion-моделей. На каждом шаге denoising нужно прочитать все 38 GB весов (или 20 GB для Q8). Для 50 шагов denoising это 50 × 20 = 1000 GB чтения на один кадр → **~4 секунды на кадр** при полной утилизации bandwidth. Для 4K 50fps это **~3 минуты генерации на одну секунду видео**
- **Распределение нагрузки**: dual-stream архитектура может дробить вычисления между iGPU и CPU неоптимально на Vulkan (scheduler ggml может попасть в горячую точку)
- **ROCm или Vulkan?**: для diffusion на Strix Halo ROCm 7.2.1 обычно стабильнее -- см. [rocm-setup.md](../../inference/rocm-setup.md), но LTX-2 не тестировалась на gfx1151

### Что даст выигрыш

- **Энергоэффективность генерации**: лучше чем aircooled RTX 4090 (575W) -- весь APU пьёт ~120W под максимальной нагрузкой
- **Возможность параллельно держать LLM + LTX-2**: 20 GB LTX-2 + 45 GB Qwen3-Coder Next = 65 GB. Остаётся ~55 GiB для других задач
- **Audio в одном проходе** -- no post-processing pipeline нужен

### Практические ожидания

Для генерации 5-секундного клипа в 1080p 30fps через LTX-2 Q8_0 на Strix Halo оценка (пересчёт от 720p бенчмарков Lightricks на RTX 4090):

| Режим | Время генерации | Примечание |
|-------|-----------------|------------|
| **720p 24fps 5s no audio** | ~4-6 минут | аналогично Wan на той же платформе |
| **720p 30fps 5s + audio** | ~6-10 минут | cross-attention overhead ~30% |
| **1080p 24fps 5s + audio** | ~12-18 минут | bandwidth-bound |
| **1080p 30fps 10s + audio** | ~40-60 минут | upper bound практичности |
| **4K 50fps 5s** | ~3-4 часа | теоретически, практически бессмысленно |

**Вывод**: на нашей платформе LTX-2 имеет смысл для **720p / 1080p с audio**, но не для 4K. За real-time 4K 50fps нужен RTX 5090 или H100. Это известная особенность Strix Halo -- bandwidth 256 GB/s оптимизирован под LLM inference (memory-bound, но модель весь раз читается за токен), а не diffusion (50+ чтений на кадр).

## Сравнение с другими video-моделями

| Параметр | LTX-2 | Wan 2.7 | HunyuanVideo 1.5 | LTX-Video 2.3 |
|----------|-------|---------|-------------------|---------------|
| **Параметры** | 19B (14B+5B) | 14B MoE | 8.3B | ~13B |
| **Разрешение макс** | **4K** | 1080p | 720p | **4K** |
| **FPS макс** | **50** | 30 | 24 | **50** |
| **Длительность** | **20s** | 15s | 5s | 10s |
| **Audio** | **single-pass sync** | native | нет | native |
| **Архитектура** | dual-stream DiT | MoE DiT | unified DiT | DiT |
| **Open-source уровень** | **веса + код + benchmarks** | Apache 2.0 (веса) | проп. license | LTX license |
| **Community GGUF** | да | да | да | да |
| **RTX 4090 (24GB)** | Q5_K_M | fp8 | fp16 | fp8 |
| **Strix Halo (120GB)** | Q8_0 | bf16 | bf16 | bf16 |
| **Лучший use case** | Audio+video storytelling | Cinematic multi-shot | Text alignment | Real-time 4K |

### Когда LTX-2, а не Wan 2.7

Если нужен **синхронизированный звук как часть foundation-модели** (диалог персонажей, звуковые эффекты, которые точно попадают в действие на кадре) -- LTX-2. Wan 2.7 имеет native audio, но он генерируется как отдельный модуль поверх видео, менее надёжно синхронизирован.

### Когда Wan 2.7, а не LTX-2

Для **cinematic multi-shot** историй с character consistency и длительности 15 секунд в 1080p -- Wan 2.7 предпочтительнее. LTX-2 пока не специализирована под multi-shot.

## Загрузка

### Основной BF16

```bash
hf download Lightricks/LTX-2 --local-dir ~/models/ltx-2-bf16
```

~38 GB. Полные веса.

### GGUF (community)

```bash
# Q5_K_M как рабочая точка
hf download unsloth/LTX-2-GGUF --include "LTX-2-Q5_K_M.gguf" --local-dir ~/models/ltx-2-gguf

# Q8_0 на Strix Halo (20.4 GB)
hf download unsloth/LTX-2-GGUF --include "LTX-2-Q8_0.gguf" --local-dir ~/models/ltx-2-gguf
```

### NVFP8 / NVFP4 (NVIDIA)

```bash
# NVFP8 для RTX 50xx (на AMD не работает -- нет native FP8)
hf download Lightricks/LTX-2-NVFP8 --local-dir ~/models/ltx-2-fp8
```

На AMD это бесполезно -- нет hardware FP8 support в RDNA 3.5. Strix Halo использует GGUF-путь.

## Использование: ComfyUI

LTX-2 интегрирована в ComfyUI через nodes от Lightricks. Базовый workflow:

1. Load LTX-2 model (через `LTXModelLoader` или `UnetLoaderGGUF` для квантизаций)
2. Text Encoder (T5-XXL, тот же что в FLUX и Wan -- переиспользуется если уже скачан)
3. Prompt → text encoder → cross-attention input
4. (опционально) Reference image → image encoder → extra conditioning
5. Sampler (Euler/DPM++) → denoising loop
6. VAE decode (LTX VAE, spatial+temporal compression)
7. Audio decode (LTX Audio AE)
8. Combine video + audio → output mp4

Сообщество публикует workflow'ы в [awesome-ltx2](https://github.com/wildminder/awesome-ltx2) -- коллекция workflows, encoders, LoRA.

## Сильные стороны

- **Единственная open-source с sync audio+video в one-pass** -- революционно для storytelling workflows
- **20-секундные клипы** -- в 2x дольше чем ближайшие конкуренты (Wan 15s)
- **4K 50fps** native
- **Truly open-source**: веса + training code + benchmarks (можно файнтюнить)
- **Dual-stream allocation 14B/5B** оптимальна под информационную плотность модальностей
- **Качество приближается к Runway/Veo** по blind tests
- **Community-квантизации** доступны с первого дня (GGUF Q3-Q8)
- **Training code опубликован** -- можно тренировать свои LoRA и файнтюны

## Слабые стороны

- **19B параметров** -- крупнее чем Wan и HunyuanVideo, медленнее на consumer GPU
- **Multi-shot не специализация** -- Wan 2.7 лучше для длинных историй с character consistency
- **Text alignment** -- по метрикам Lightricks хорошее, но не лидер (HunyuanVideo 1.5 следует сложным промптам точнее)
- **NVFP4/NVFP8 только для NVIDIA** -- AMD пропускает hardware-оптимизации, полагается на GGUF path
- **Long-range sync** -- для клипов >15 секунд audio-video synchronization деградирует (известная limitation в официальном model card)
- **Новая архитектура** -- меньше накопленного community knowledge, LoRA и ControlNet примеров чем у Wan или HunyuanVideo

## Идеальные сценарии

- **Short-form storytelling**: 10-20 секундные ролики с диалогом или ambient звуком
- **SFX-heavy контент**: взрывы, удары, природные явления, где важна sync звук+кадр
- **Учебный контент**: образовательные клипы где нужен narration + визуал синхронно
- **Концепт-арт для кино**: быстрые preview сцен с диалогом
- **Замена двухмодельных pipeline**: раньше нужно было video-model + MMAudio, теперь одна LTX-2

## Ссылки

**Официальные**:
- [GitHub: Lightricks/LTX-2](https://github.com/Lightricks/LTX-2) -- inference, training code, LoRA trainer
- [HuggingFace: Lightricks/LTX-2](https://huggingface.co/Lightricks/LTX-2) -- веса BF16
- [HuggingFace: Lightricks](https://huggingface.co/Lightricks) -- организация, все модели
- [ltx.io/model/ltx-2](https://ltx.io/model/ltx-2) -- product page
- [ltx-2.ai](https://ltx-2.ai/) -- дополнительный landing
- [Пресс-релиз 6 января 2026](https://www.globenewswire.com/news-release/2026/01/06/3213304/0/en/Lightricks-Open-Sources-LTX-2-the-First-Production-Ready-Audio-and-Video-Generation-Model-With-Truly-Open-Weights.html)

**Community**:
- [unsloth/LTX-2-GGUF](https://huggingface.co/unsloth/LTX-2-GGUF) -- GGUF квантизации
- [vantagewithai/LTX-2-GGUF](https://huggingface.co/vantagewithai/LTX-2-GGUF) -- альтернативные GGUF
- [wildminder/awesome-ltx2](https://github.com/wildminder/awesome-ltx2) -- workflow'ы, LoRA, encoders для ComfyUI
- [Civitai: LTX 2 19B](https://civitai.com/models/2291679/ltx-2-19b-all-you-need-is-here) -- полный пакет

**Аналитика**:
- [Wikipedia: LTX-2](https://en.wikipedia.org/wiki/LTX-2) -- общий обзор
- [Stable Diffusion Tutorials: LTX-2 Video+Audio Gen locally](https://www.stablediffusiontutorials.com/2026/01/ltx2-video-generation.html) -- практическое руководство
- [Medium: LTX-2 Open-Source Video Generation Finally Gets Sound Right](https://medium.com/@ljingshan6/ltx-2-open-source-video-generation-finally-gets-sound-right-64d23dfc2ff8)

## Связано

- Направления: [video](../video.md), [music](../music.md)
- Предыдущее поколение: [ltx-video](ltx-video.md) (LTX-Video 2.3, отдельная ветка)
- Альтернативы: [wan](wan.md) (cinematic multi-shot), [hunyuanvideo](hunyuanvideo.md) (text alignment)
- Новости: [../news.md](../news.md) -- хроника релизов моделей
