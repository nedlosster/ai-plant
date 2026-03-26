# Выбор и загрузка моделей

Платформа: Radeon 8060S, 120 GiB GPU-доступной памяти (96 GiB carved-out + GTT, LPDDR5 8000MT/s, 256 GB/s).

## Форматы моделей

### GGUF

Формат llama.cpp. Единый файл, содержит веса и метаданные. Поддерживает встроенную квантизацию. Используется в llama.cpp, LM Studio, Ollama.

```
model-7b-q4_k_m.gguf    # один файл, готов к запуску
```

### safetensors

Формат PyTorch / HuggingFace. Набор файлов (веса + config.json + tokenizer). Используется в vLLM, transformers, text-generation-inference. Требует ROCm или CUDA для GPU-инференса.

```
model/
  config.json
  tokenizer.json
  model-00001-of-00003.safetensors
  model-00002-of-00003.safetensors
  model-00003-of-00003.safetensors
```

Для данной платформы **GGUF -- основной формат**: работает через Vulkan без ROCm.

## Квантизация

Квантизация -- снижение точности весов модели для экономии памяти и ускорения инференса. Оригинальные веса хранятся в FP16/BF16 (2 байта на параметр). Квантизация сжимает до 2--8 бит.

| Формат | Бит | Размер 7B | Размер 70B | Качество | Скорость |
|--------|-----|-----------|------------|----------|----------|
| Q4_K_M | 4.83 | ~4.1 GiB | ~40 GiB | хорошее | высокая |
| Q5_K_M | 5.69 | ~4.8 GiB | ~48 GiB | выше среднего | средняя |
| Q6_K | 6.57 | ~5.5 GiB | ~55 GiB | высокое | средняя |
| Q8_0 | 8.50 | ~7.2 GiB | ~70 GiB | близко к оригиналу | ниже |
| F16 | 16 | ~14 GiB | ~140 GiB | оригинал | низкая |
| BF16 | 16 | ~14 GiB | ~140 GiB | оригинал | низкая |

**Q4_K_M** -- оптимальный баланс размера и качества. Рекомендуется по умолчанию.

**Q5_K_M** -- если VRAM позволяет, чуть лучше качество при небольшом увеличении размера.

**Q8_0** -- минимальные потери качества, хорошо работает с AVX-512 VNNI на CPU.

## Расчет VRAM

Формула:

```
VRAM = размер_модели + KV_cache + overhead (~500 MiB)
```

KV-cache зависит от размера контекста (-c):

```
KV_cache (GiB) ~ n_layers * n_heads * head_dim * 2 * context_size * 2 / 1024^3
```

Примерные значения KV-cache:

| Модель | -c 4096 | -c 8192 | -c 32768 |
|--------|---------|---------|----------|
| 7B (32 layers) | ~0.5 GiB | ~1 GiB | ~4 GiB |
| 13B (40 layers) | ~0.8 GiB | ~1.6 GiB | ~6.4 GiB |
| 70B (80 layers) | ~2.5 GiB | ~5 GiB | ~20 GiB |

### Таблица: что помещается в 120 GiB

GPU-доступная память = 120 GiB (BIOS carved-out 96 GiB + GTT, лимит через `ttm.pages_limit`).

| Модель | Q4_K_M | Q5_K_M | Q8_0 | F16 |
|--------|--------|--------|------|-----|
| 7B | ~4 GiB | ~5 GiB | ~7 GiB | ~14 GiB |
| 13B | ~7 GiB | ~9 GiB | ~13 GiB | ~26 GiB |
| 34B | ~19 GiB | ~23 GiB | ~35 GiB | ~68 GiB |
| 70B | ~40 GiB | ~48 GiB | ~70 GiB | не помещается |
| 70B + ctx 32k | ~60 GiB | ~68 GiB | ~90 GiB | не помещается |
| 122B MoE (A10B) | ~71 GiB | -- | -- | не помещается |
| 80B MoE (A3B) | ~45 GiB | -- | -- | -- |

120 GiB GPU-памяти позволяет:
- 122B MoE Q4_K_M целиком на GPU (~71 GiB весов + KV-cache)
- 70B Q8_0 с контекстом 32k (~90 GiB) -- с запасом
- 70B Q4_K_M с контекстом 32k (~60 GiB)
- Несколько моделей 7B--13B одновременно

## Рекомендации

| Задача | Модель | Квантизация |
|--------|--------|------------|
| Универсальный ассистент | Llama 3.1 70B, Qwen 2.5 72B | Q4_K_M |
| Кодирование | DeepSeek Coder V2, Qwen 2.5 Coder 32B | Q5_K_M |
| Легкие задачи, быстрый отклик | Llama 3.1 8B, Gemma 2 9B | Q5_K_M -- Q8_0 |
| Максимальное качество | Qwen 2.5 72B | Q5_K_M |
| Эксперименты с длинным контекстом | Llama 3.1 8B (128k) | Q8_0 |

## Источники моделей

### HuggingFace

Основной источник моделей. Авторы GGUF-версий:
- **bartowski** -- широкий выбор моделей, качественная квантизация
- **unsloth** -- оптимизированные квантизации
- **TheBloke** -- классический автор GGUF (архив, новые модели у bartowski)

### Загрузка через CLI

```bash
# Установка huggingface-cli
pip install huggingface-hub

# Загрузка конкретной квантизации
huggingface-cli download bartowski/Llama-3.1-70B-Instruct-GGUF \
    --include "*Q4_K_M*" \
    --local-dir ./models/llama-3.1-70b

# Загрузка через LM Studio (встроенный менеджер)
# Модели сохраняются в ~/.cache/lm-studio/models/
```

### Структура хранения

```
~/models/
  llama-3.1-70b/
    Llama-3.1-70B-Instruct-Q4_K_M.gguf
  qwen-2.5-72b/
    Qwen2.5-72B-Instruct-Q4_K_M.gguf
```

## Связанные статьи

- [llama.cpp + Vulkan](vulkan-llama-cpp.md)
- [llama.cpp + ROCm](rocm-llama-cpp.md)
- [CPU-инференс](cpu-inference.md)
- [LM Studio](lm-studio.md)
- [Квантизация](../llm-guide/quantization.md)
- [Анатомия LLM](../llm-guide/model-anatomy.md)
