# Training и fine-tuning на Strix Halo

Платформа: Radeon 8060S (gfx1151, 40 CU, 120 GiB GPU-доступной памяти, 256 GB/s), ROCm 7.x.

## Возможности платформы

120 GiB GPU-доступной памяти (96 GiB carved-out + GTT через ttm.pages_limit) -- уникальное преимущество для training. На consumer-оборудовании позволяет:

| Метод | Максимальная модель | VRAM (примерно) |
|-------|-------------------|-----------------|
| Full fine-tuning (FP16) | 7-12B | 67-115 GiB |
| LoRA (FP16) | 30-40B | 63 GiB |
| QLoRA (4-bit) | 70B | ~46 GiB |

Для сравнения: RTX 4090 (24 GiB) ограничен full FT ~2B, LoRA ~7B, QLoRA ~13B.

## Ограничения

- **Bandwidth 256 GB/s** -- в 4x меньше RTX 4090 (1008 GB/s). Training медленнее.
- **hipMemcpy bottleneck** -- при рабочем наборе >15 GiB до 80-95% времени уходит на memcpy (баг PyTorch ROCm, в процессе исправления)
- **ROCm для gfx1151** -- экспериментальный, требует специальных сборок PyTorch
- **bitsandbytes** -- нестабилен на AMD, QLoRA 4-bit фактически работает в 16-bit
- **Flash Attention** -- для training доступен только `eager` attention
- **Single GPU** -- нет multi-GPU scaling (но возможен multi-node кластер)

## Практические результаты на Strix Halo

| Модель | Метод | VRAM | Время (2 эпохи) |
|--------|-------|------|------------------|
| Gemma-3 1B | Full FT | 19 GiB | ~3 мин |
| Gemma-3 1B | LoRA | 15 GiB | ~2 мин |
| Gemma-3 4B | Full FT | 46 GiB | ~9 мин |
| Gemma-3 4B | QLoRA | 13 GiB | ~9 мин |
| Gemma-3 12B | Full FT | 115 GiB | ~25 мин |
| Gemma-3 12B | QLoRA | 26 GiB | ~23 мин |
| Gemma-3 27B | QLoRA | 19 GiB | работает |
| GPT-OSS-20B | LoRA | 32-38 GiB | ~1 час |

## Документация

| N | Документ | Описание | Уровень |
|---|----------|----------|---------|
| 1 | [Обзор методов](methods.md) | Full FT, LoRA, QLoRA, DPO/RLHF -- что выбрать | вводный |
| 2 | [Подготовка окружения](environment.md) | PyTorch + ROCm для gfx1151, Docker, зависимости | базовый |
| 3 | [Подготовка данных](datasets.md) | Форматы (Alpaca, ShareGPT, ChatML), объемы, инструменты | базовый |
| 4 | [Fine-tuning LLM](llm-finetuning.md) | LoRA/QLoRA через Unsloth, LLaMA-Factory, Axolotl | базовый |
| 5 | [Fine-tuning Diffusion](diffusion-finetuning.md) | LoRA для SD/FLUX через kohya_ss, SimpleTuner | продвинутый |
| 6 | [RLHF и alignment](alignment.md) | DPO, GRPO через TRL + PEFT | продвинутый |
| 7 | [Известные проблемы](known-issues.md) | hipMemcpy, NaN loss, bitsandbytes, workarounds | справочный |

Рекомендуемый порядок: 1 -> 2 -> 3 -> 4 -> 7.

## Сравнение с конкурентами

| Параметр | Strix Halo 395 | RTX 4090 | A100 80GB | M4 Max |
|----------|---------------|----------|-----------|--------|
| VRAM | 120 GiB | 24 GiB | 80 GiB | 128 GiB |
| Bandwidth | 256 GB/s | 1,008 GB/s | 2,039 GB/s | 546 GB/s |
| Max model (Full FT) | 12B | 2B | 7B | 8B |
| Max model (QLoRA) | 70B | 13B | 30B | 70B |
| Цена (система) | ~$1,500-2,500 | ~$2,600+ | ~$15,000+ | ~$3,500+ |

## Ресурсы сообщества

- kyuz0/amd-strix-halo-llm-finetuning -- полный гайд с бенчмарками
- shantur/amd-strix-halo-fine-tuning-toolboxes -- Docker-toolbox для Strix Halo
- Framework Community -- подробные тесты fine-tuning на Strix Halo
- ROCm Strix Halo Optimization -- официальная документация AMD
