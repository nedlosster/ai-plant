# ACE-Step: архитектура

Внутреннее устройство ACE-Step как софтверного стека: dual-component модель, Python package, sampling loop, audio VAE, LM conditioning, tier detection, интеграция Gradio UI. Самая техническая часть профиля.

Этот документ фокусируется на **софтверной архитектуре**. Про саму нейросеть (параметры, слои, метрики) -- см. [карточку модели](../../models/families/ace-step.md).

## Общая схема компонентов

```
+------------------------------------------+
|  Gradio UI (Python + Web)                 |
|  - Input: tags, lyrics, parameters        |
|  - Output: audio player, download         |
|  - :7860                                   |
+-----------------+------------------------+
                  |
                  |  gradio.Interface callback
                  v
+------------------------------------------+
|  acestep.pipeline (Python)                |
|  - Tokenize lyrics → tokens               |
|  - Encode tags → conditioning vector      |
|  - Initialize latent noise                 |
|  - Sampling loop (8 steps for turbo)      |
|  - Audio VAE decode                       |
|  - WAV output                             |
+--------+-----------+---------------------+
         |           |
         v           v
+---------------+ +---------------------+
| DiT 3.5B      | | Language Model 4B   |
| (turbo, 8     | | (lyrics-aware       |
|  steps)       | |  conditioning)      |
|               | |                     |
| - denoising   | | - understand lyrics |
| - lyrics cond | | - semantic context  |
| - tags cond   | | - rhyme/meter       |
+-------+-------+ +------+--------------+
        |                |
        +--------+-------+
                 |
                 v
+------------------------------------------+
|  Audio VAE                                |
|  - latent → mel spectrogram              |
|  - mel → waveform (via vocoder)          |
+-----------------+------------------------+
                  |
                  v
+------------------------------------------+
|  PyTorch backend                          |
|  - CUDA (native)                          |
|  - ROCm 6.2.4 (нативно поддерживается)    |
|  - CPU fallback                           |
+------------------------------------------+
```

## Dual-component модель: DiT + LM

Главная архитектурная фишка ACE-Step 1.5 -- **разделение на два компонента**:

### DiT 3.5B (Diffusion Transformer для аудио)

Основная denoising-сетка. Работает в **latent audio space** -- не в сыром waveform или mel-спектрограмме, а в компрессированном латенте Audio VAE (~32x меньше по времени).

**Вход в каждом sampling шаге**:
- `x_t` -- текущий латент с шумом
- `t` -- timestep
- `tags_cond` -- encoding тегов (жанр, инструменты, темп)
- `lyrics_cond` -- encoding лирики **из LM 4B** (это key insight!)

**Выход**:
- `epsilon` -- предсказанный шум, из которого вычисляется `x_{t-1}`

**Архитектура DiT**:
- Transformer-based (аналогично image DiT как в Stable Diffusion 3)
- Rotary position embeddings (RoPE) для времени
- Cross-attention на condition embeddings
- 8 блоков в turbo-варианте vs 40 в full
- ~3.5B параметров

### LM 4B (Language Model для conditioning)

**Вот где инновация 1.5**. Вместо того чтобы токенизировать lyrics напрямую и подавать в DiT как text tokens (что делали 1.0 и большинство конкурентов), ACE-Step 1.5 использует **отдельную Language Model**, которая "понимает" lyrics:

- **Базовая архитектура**: ~4B параметров, transformer (аналог Llama 3)
- **Задача**: получить lyrics → вернуть **богатое semantic представление** (embedding vector per phoneme или per word), учитывающее:
  - Смысл слов
  - Ритм и метр
  - Эмоциональную окраску
  - Рифмы
  - Длину такта
  - Ударения (где они в языке различают значение)
- **Обучение**: contrastive learning на парах `(lyrics, audio-of-singing-these-lyrics)` -- LM учится генерировать embedding, из которого DiT может восстановить правильный вокал

### Почему это работает лучше чем "просто tokenize"

Если подать lyrics напрямую в DiT как токены (как делают более простые архитектуры), DiT должен **одновременно**:
1. Понимать семантику текста
2. Понимать музыкальную структуру
3. Генерировать аудио

Это перегружает DiT и распыляет параметры. В 1.5 LM 4B **заранее** выполняет (1), оставляя DiT для (2) и (3). Результат: более чёткий вокал, лучшее следование lyrics, меньше ошибок произношения.

### Cross-attention между DiT и LM

Cross-attention в DiT работает на выходе LM 4B. На каждом timestep DiT "смотрит" на lyrics embedding, решая какой звук (фонему) генерировать сейчас. Это приблизительно аналог cross-attention в image diffusion между U-Net и CLIP text encoder, только для аудио и с гораздо более богатым encoder'ом.

## Python package структура

```
acestep/
├── __init__.py                 # entry points
├── pipeline.py                 # основной pipeline (tokenize → sample → decode)
├── models/
│   ├── dit.py                  # DiT architecture
│   ├── lm.py                   # Language Model wrapper
│   ├── vae.py                  # Audio VAE
│   └── vocoder.py              # mel → waveform
├── sampling/
│   ├── schedulers.py           # denoising schedules
│   ├── samplers.py             # sampler implementations (DDIM, DPM-solver, etc)
│   └── guidance.py             # classifier-free guidance
├── tokenizer/
│   ├── lyrics.py               # lyrics tokenizer (multilingual)
│   └── tags.py                 # tags tokenizer
├── trainer/
│   ├── lora.py                 # LoRA trainer для fine-tuning
│   ├── dataset.py              # dataset loading
│   └── loss.py                 # training losses
├── downloader/
│   └── model_downloader.py     # HuggingFace download
├── ui/
│   └── gradio_app.py           # Gradio UI definition
└── __main__.py                 # python -m acestep entry
```

## Sampling loop: что происходит при "Generate"

Когда пользователь нажимает Generate в Gradio UI, выполняется следующий Python flow:

### 1. Tokenize input

```python
tags = "upbeat electronic dance, female vocals, 128bpm"
lyrics = "Dancing in the moonlight\nStars are shining bright\n..."

tags_tokens = tokenizer_tags.encode(tags)      # → [int, int, ...]
lyrics_tokens = tokenizer_lyrics.encode(lyrics)  # → [int, int, ...]
```

### 2. Encode через LM 4B (если активирован)

```python
if lm_enabled:
    lyrics_embedding = lm_model(lyrics_tokens)   # → tensor [seq_len, dim=4096]
else:
    # Fallback: напрямую в DiT как токены
    lyrics_embedding = embed_tokens(lyrics_tokens)
```

Это **ключевая точка различия** между full-режимом (LM enabled) и DiT-only режимом.

### 3. Initialize noise

```python
duration_sec = 120  # 2-минутный трек
latent_length = duration_sec * LATENT_FPS  # примерно 30 fps в latent space
latent_shape = (batch, 32, latent_length)  # 32 latent channels
x_T = torch.randn(latent_shape)             # начальный шум
```

### 4. Sampling loop (turbo = 8 шагов)

```python
scheduler = DPMSolverScheduler(num_steps=8)
timesteps = scheduler.get_timesteps()  # [999, 860, 720, 580, 440, 300, 160, 20]

x = x_T
for t in timesteps:
    # DiT predict noise
    noise_pred = dit_model(
        x=x,
        t=t,
        tags_cond=tags_embedding,
        lyrics_cond=lyrics_embedding  # from LM или direct embedding
    )

    # Classifier-free guidance (optional)
    if cfg_scale > 1.0:
        noise_pred_uncond = dit_model(x, t, tags_cond=None, lyrics_cond=None)
        noise_pred = noise_pred_uncond + cfg_scale * (noise_pred - noise_pred_uncond)

    # Denoising step
    x = scheduler.step(noise_pred, t, x)

# x теперь -- финальный denoised латент
```

Для turbo-варианта 8 шагов достаточно благодаря distillation в обучении -- full-варианту нужно 50.

### 5. VAE decode

```python
# Latent → mel spectrogram
mel = audio_vae.decode(x)    # → [batch, n_mel, time]

# Mel → raw waveform через vocoder
waveform = vocoder(mel)       # → [batch, samples] at 44.1kHz
```

### 6. Save WAV

```python
torchaudio.save(
    output_path,
    waveform.cpu(),
    sample_rate=44100,
    encoding='PCM_S',
    bits_per_sample=16
)
```

### Total time на RTX 4090 (с LM)

- Tokenize: <100 ms
- LM 4B forward pass: ~1 sec
- Sampling loop (8 steps × 3.5B DiT): ~60 sec
- VAE decode: ~3 sec
- Vocoder: ~2 sec
- Total: **~66 sec для 2-минутного трека**

На CPU (Strix Halo tier1, DiT-only): **5-10 минут** для того же трека.

## Tier detection и автоконфиг

Вот здесь возникает **ограничение на Strix Halo**. ACE-Step имеет встроенный **tier detection**:

```python
# acestep/tier_detection.py (упрощённо)

def detect_tier():
    if not torch.cuda.is_available():
        return "tier1"   # CPU

    vram_gb = torch.cuda.get_device_properties(0).total_memory / 1e9

    if vram_gb < 8:
        return "tier2"   # 4-8 GB: DiT-only, no LM
    elif vram_gb < 16:
        return "tier3"   # 8-16 GB: DiT + small LM
    elif vram_gb < 24:
        return "tier4"   # 16-24 GB: DiT + full LM 4B
    else:
        return "tier5"   # 24+ GB: всё + каск. large model
```

Tier определяет конфигурацию по умолчанию:
- `tier1` (CPU): DiT-only, медленно, без LM
- `tier2`: DiT-only on GPU, без LM
- `tier3-5`: DiT + LM (полный режим)

### Проблема на Strix Halo gfx1151

Ядро amdgpu/KFD **экспозит только 15.5 GiB как "dedicated GPU memory"** из 96 GiB unified. Это связано с тем, что KFD firmware table для APU указывает carved-out сегмент, а не всю unified memory. Детали -- в [../../platform/vram-allocation.md](../../platform/vram-allocation.md).

В результате:
- `torch.cuda.get_device_properties(0).total_memory` = 15.5 GB (не 96!)
- Tier detection → tier3 (из-за < 16 GB)
- Но при инициализации LM 4B -- **OOM**, потому что tier3-конфиг считает что хватит, но hipMalloc не может аллоцировать 8 GiB (карта фрагментирована или limit ниже)

Результат: **LM не инициализируется**, ACE-Step автоматически fallback'ится в DiT-only. На Strix Halo tier-detection даёт ошибочный результат.

### Workarounds

1. **Принудительно tier1 (CPU)**: `export ACESTEP_TIER=tier1` -- работает но медленно
2. **Вручную отключить LM**: `--init_llm false` -- DiT-only, но быстро на ROCm
3. **GTT unlock через `ttm.pages_limit`**: на уровне ядра увеличить доступную GTT-память, это даёт ROCm видимость полных 120 GiB (см. [../../platform/vram-allocation.md](../../platform/vram-allocation.md)). Но даже с этим fix tier-detection не сразу подхватывает изменение
4. **Wait for ROCm 7.3**: ожидается fix KFD topology для Strix Halo

Текущий рекомендованный путь на платформе -- **DiT-only ROCm режим** (быстрый, без LM, чуть хуже lyrics следование) или **CPU mode с LM** (медленный, но с полным качеством).

## Gradio UI: wrapping over pipeline

`acestep/ui/gradio_app.py` создаёт Gradio Interface:

```python
import gradio as gr
from acestep.pipeline import generate_song

def gradio_generate(tags, lyrics, steps, cfg, seed):
    return generate_song(
        tags=tags,
        lyrics=lyrics,
        num_steps=steps,
        cfg_scale=cfg,
        seed=seed
    )

demo = gr.Interface(
    fn=gradio_generate,
    inputs=[
        gr.Textbox(label="Tags"),
        gr.Textbox(label="Lyrics", lines=10),
        gr.Slider(1, 50, value=8, label="Steps"),
        gr.Slider(0, 20, value=7.5, label="CFG scale"),
        gr.Number(label="Seed", value=-1)
    ],
    outputs=gr.Audio(label="Generated song"),
    title="ACE-Step Music Generator",
    description="Generate songs with vocals from text description"
)

demo.launch(server_name="0.0.0.0", server_port=7860)
```

Gradio обеспечивает:
- Web UI без frontend-кода
- Upload файлов (для cover mode)
- Audio player в browser
- Download результата
- Multi-user queueing (несколько пользователей могут генерировать последовательно)

## Audio VAE и vocoder

Два компонента для преобразования латента в waveform:

### Audio VAE

- **Encoder**: waveform (44.1 kHz) → mel spectrogram (80 bins, 64 fps) → compressed latent (32 channels, ~30 fps)
- **Decoder**: latent → mel spectrogram → waveform

Encoder нужен только при LoRA training (превратить датасет в латенты). При inference используется только decoder.

Compression ratio: **~32× по времени** (latent fps ≈ 30 vs audio fps 44100). Это делает sampling feasible -- 2 минуты аудио -- это ~3600 latent frames, что manageable для DiT.

### Vocoder

Vocoder -- небольшая сеть, которая преобразует mel spectrogram в waveform. ACE-Step использует вариант **HiFi-GAN** (или BigVGAN в последних версиях) -- стандартный neural vocoder для text-to-speech моделей.

Vocoder параметров -- ~100M, относительно маленький по сравнению с DiT 3.5B и LM 4B.

## Связанные статьи

- [README.md](README.md) -- обзор и статус на платформе
- [introduction.md](introduction.md) -- контекст стека
- [simple-use-cases.md](simple-use-cases.md) -- как это использовать
- [advanced-use-cases.md](advanced-use-cases.md) -- LoRA training, cover/remix
- [../../models/families/ace-step.md](../../models/families/ace-step.md) -- карточка модели (дополняет, не дублирует)
- [../../platform/vram-allocation.md](../../platform/vram-allocation.md) -- почему VRAM 15.5 vs 96 GiB на Strix Halo
- [../../inference/rocm-setup.md](../../inference/rocm-setup.md) -- настройка ROCm на gfx1151
