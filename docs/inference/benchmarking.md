# Бенчмарки и оценка производительности

Платформа: Radeon 8060S (40 CU, 120 GiB GPU-доступной памяти, 256 GB/s), Ryzen AI MAX+ 395 (16C/32T).

## Метрики

| Метрика | Описание | Единица |
|---------|----------|---------|
| **pp** (prompt processing) | Скорость обработки входного контекста | tok/s |
| **tg** (token generation) | Скорость генерации ответа | tok/s |
| **TTFT** (time to first token) | Время до первого сгенерированного токена | ms |
| **Throughput** | Общая пропускная способность (для batch) | tok/s |

**tg** -- основная метрика для интерактивного использования. Определяет скорость "печати" ответа.

**pp** -- важна для длинных промптов и RAG-сценариев.

## Теоретический анализ

LLM token generation -- memory-bound операция. Каждый токен требует чтения всех весов модели из памяти.

### Формула

```
tg_max (tok/s) = bandwidth (GB/s) / model_size (GB)
```

Для данной платформы (256 GB/s):

| Модель | Квантизация | Размер | Теор. tg | Реальные (70-90%) |
|--------|------------|--------|----------|-------------------|
| 7B | Q4_K_M | 4.1 GiB | ~60 | 42--54 |
| 7B | Q8_0 | 7.2 GiB | ~34 | 24--30 |
| 13B | Q4_K_M | 7.3 GiB | ~34 | 24--30 |
| 34B | Q4_K_M | 19 GiB | ~13 | 9--12 |
| 70B | Q4_K_M | 40 GiB | ~6.2 | 4--5 |
| 70B | Q8_0 | 70 GiB | ~3.5 | 2--3 |

Потеря 10-30% от теоретического максимума -- накладные расходы на KV-cache, attention computation, overhead фреймворка.

### Prompt processing

pp -- compute-bound для коротких промптов, переходит в memory-bound для длинных. Типично pp >> tg.

## Реальные результаты (2026-04-06)

Платформа: Radeon 8060S (gfx1151), llama.cpp b8541, ngl=99, t=16.

### Vulkan vs HIP (ROCm 7.2.1)

| Модель | Тип | Размер | Vulkan pp512 | Vulkan tg128 | HIP pp512 | HIP tg128 |
|--------|-----|--------|-------------|-------------|-----------|-----------|
| Qwen2.5-Coder-1.5B Q8_0 | dense | 1.5 GiB | 5242 | 121 | 5140 | 105 |
| Qwen3.5-27B Q4_K_M | dense | 15.6 GiB | 305 | 12.6 | 297 | 11.3 |
| Qwen3-Coder-30B-A3B Q4_K_M | MoE | 17.3 GiB | 1029 | 86 | 899 | 59 |

### Vulkan (расширенный набор, 2026-03-27)

| Модель | Тип | Размер | pp512 tok/s | tg128 tok/s |
|--------|-----|--------|-------------|-------------|
| Qwen3-Coder-Next-80B-A3B Q4_K_M | MoE | 45.1 GiB | 590 | 53.2 |
| Qwen3.5-122B-A10B Q4_K_M | MoE | 71.3 GiB | 300 | 22.2 |

### Разница HIP vs Vulkan

| Модель | pp512 | tg128 |
|--------|-------|-------|
| 1.5B Q8_0 (dense) | -2% | -13% |
| 27B Q4_K_M (dense) | -3% | -10% |
| 30B MoE Q4_K_M | -13% | -31% |

Vulkan быстрее во всех тестах. На MoE-моделях разрыв значительный (-31% tg). На dense-моделях разница меньше (-10-13% tg).

### Наблюдения

- MoE-модели при генерации активируют часть экспертов (~3B из 30B), поэтому tg значительно выше dense-моделей того же размера
- Dense 27B: 12.6 t/s (Vulkan) -- близко к теоретическому пределу (256 GB/s / 15.6 GB = 16.4 t/s, ~77% эффективность)
- HIP-бэкенд на gfx1151 работает стабильно с ROCm 7.2.1 (segfault устранён), но уступает Vulkan по скорости
- 122B MoE полностью помещается в GPU-память (71.3 GiB весов + KV-cache из 120 GiB доступных)

## Инструменты

### llama-bench

Встроенный бенчмарк llama.cpp:

```bash
./build/bin/llama-bench \
    -m ./models/model.gguf \
    -ngl 99 \
    -t 16 \
    -p 512 \
    -n 128
```

Параметры:
- `-p 512` -- длина промпта (замер pp)
- `-n 128` -- число генерируемых токенов (замер tg)
- `-t 16` -- потоки CPU
- `-ngl 99` -- все слои на GPU

### llama-cli со статистикой

```bash
./build/bin/llama-cli \
    -m model.gguf \
    -ngl 99 \
    -p "Explain the theory of relativity in detail." \
    -n 256

# В конце вывода:
# llama_perf_sampler_print: ...
# llama_perf_context_print:
#   eval time = ... ms / ... tokens (... ms per token, ... tokens per second)
#   sample time = ...
```

## Методика сравнения бэкендов

1. Одна модель, одна квантизация
2. Одинаковые параметры: `-c`, `-ngl`, `--temp 0` (детерминированный)
3. Фиксированный промпт (одинаковая длина входа)
4. Минимум 3 прогона, взять медиану
5. Прогрев: первый прогон не считается (загрузка модели, JIT)

```bash
# Vulkan
./scripts/inference/vulkan/bench.sh model.gguf

# HIP (ROCm)
./scripts/inference/rocm/bench.sh model.gguf

# Или напрямую через llama-bench
./build/bin/llama-bench -m model.gguf -ngl 99 -p 512 -n 128      # Vulkan
./build-hip/bin/llama-bench -m model.gguf -ngl 99 -p 512 -n 128  # HIP
```

## Влияние параметров

### Размер контекста (-c)

Увеличение контекста увеличивает KV-cache, снижает tg:

| -c | VRAM overhead (70B) | Влияние на tg |
|----|---------------------|---------------|
| 4096 | ~2.5 GiB | baseline |
| 8192 | ~5 GiB | -5% |
| 32768 | ~20 GiB | -15-20% |

### Batch size (-b)

Влияет на pp (не на tg):

| -b | pp влияние |
|----|-----------|
| 128 | baseline |
| 512 | +20-40% pp |
| 2048 | +30-50% pp |

### Квантизация

| Формат | tg (относительно Q4_K_M) | Качество |
|--------|--------------------------|----------|
| Q4_K_M | 1.0x (baseline) | хорошее |
| Q5_K_M | ~0.85x | лучше |
| Q8_0 | ~0.55x | высокое |
| F16 | ~0.28x | оригинал |

Меньшая квантизация = меньший размер = быстрее tg (memory-bound).

## Мониторинг во время бенчмарка

```bash
# Терминал 1: бенчмарк
./build/bin/llama-bench -m model.gguf -ngl 99

# Терминал 2: мониторинг GPU
watch -n 1 'echo "GPU: $(cat /sys/class/drm/card1/device/gpu_busy_percent)%  \
VRAM: $(($(cat /sys/class/drm/card1/device/mem_info_vram_used) / 1048576)) MiB  \
Temp: $(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input) / 1000))C  \
Power: $(($(cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_average) / 1000000))W"'

# Терминал 3: мониторинг CPU
htop
# или
perf stat -e cycles,instructions,cache-misses ./build/bin/llama-bench ...
```

## Связанные статьи

- [llama.cpp + Vulkan](vulkan-llama-cpp.md)
- [llama.cpp + ROCm](rocm-llama-cpp.md)
- [CPU-инференс](cpu-inference.md)
- [Выбор моделей](model-selection.md)
- [Анатомия LLM](../llm-guide/model-anatomy.md)
