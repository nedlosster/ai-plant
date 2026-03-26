# Inference на CPU: AVX-512 BF16

Платформа: AMD Ryzen AI MAX+ 395 (Zen 5, 16C/32T, AVX-512 BF16/VNNI), Ubuntu 24.04.4.

## Когда использовать

- GPU-бэкенд недоступен или нестабилен
- Baseline для сравнения с GPU
- Модель не помещается в VRAM целиком (partial offload: часть слоев на GPU, часть на CPU)
- Отладка без GPU-зависимостей

## Возможности CPU для инференса

| Инструкция | Назначение |
|-----------|-----------|
| AVX-512 BF16 | Аппаратное ускорение bfloat16 -- ключевой формат для LLM |
| AVX-512 VNNI | Ускорение INT8-операций (квантизованные модели Q8_0) |
| AVX-512 F/DQ/BW/VL | Базовые 512-bit SIMD-операции |
| AVX2 + FMA | Fallback для совместимости |

16 ядер, 64 MiB L3 кэш (2x32 MiB CCX), 256 GB/s bandwidth (shared с GPU).

## Сборка llama.cpp для CPU

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

cmake -B build \
    -DGGML_AVX512=ON \
    -DGGML_AVX512_BF16=ON \
    -DGGML_AVX512_VNNI=ON

cmake --build build -j$(nproc)
```

Проверка поддержки:

```bash
lscpu | grep -i avx
# Должны быть: avx512f avx512bw avx512vl avx512_bf16 avx512_vnni
```

## Запуск

```bash
./build/bin/llama-cli \
    -m ./models/model.gguf \
    -ngl 0 \
    --threads 16 \
    --threads-batch 32 \
    -c 4096 \
    --temp 0.7
```

`-ngl 0` -- все слои на CPU, GPU не используется.

## Оптимизация

### Потоки

| Параметр | Рекомендация | Описание |
|----------|-------------|----------|
| `--threads` | 16 | Token generation. Число физических ядер |
| `--threads-batch` | 32 | Prompt processing. Можно включить SMT (все логические ядра) |

Prompt processing параллелизуется лучше, поэтому `--threads-batch` может быть выше.

### NUMA

На данной платформе 1 NUMA-узел, привязка не требуется. Для многосокетных систем:

```bash
numactl --cpunodebind=0 --membind=0 ./build/bin/llama-cli ...
```

### HugePages

```bash
# Выделить 4096 hugepages (по 2 MiB = 8 GiB)
echo 4096 | sudo tee /proc/sys/vm/nr_hugepages

# Или через параметр ядра
# hugepages=4096 в GRUB
```

### jemalloc (опционально)

```bash
sudo apt install libjemalloc-dev
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so ./build/bin/llama-cli ...
```

## Квантизация для CPU

| Формат | Инструкция | Скорость | Качество |
|--------|-----------|----------|----------|
| Q4_K_M | AVX-512 | быстрый | хорошее |
| Q8_0 | AVX-512 VNNI | средний | высокое |
| BF16 | AVX-512 BF16 | медленный | оригинал |
| F16 | AVX-512 | медленный | оригинал |

Q4_K_M -- оптимальный по скорости. Q8_0 -- если VNNI ускорение дает выигрыш на данном CPU.

## Partial offload (CPU + GPU)

Если модель не помещается в VRAM целиком, часть слоев можно вынести на CPU:

```bash
# 70B Q8_0 (~70 GiB) при 120 GiB GPU-памяти с контекстом 32k
# KV-cache ~20 GiB, итого ~90 GiB -- помещается с запасом
# При необходимости вынести слои на CPU:
./build/bin/llama-cli -m model-70b-q8.gguf -ngl 70 -c 32768
```

При partial offload скорость tg определяется самым медленным звеном (CPU).

## Ожидаемая производительность

Примерные значения для CPU-only (`-ngl 0`, `--threads 16`):

| Модель | Квантизация | pp tok/s | tg tok/s |
|--------|------------|----------|----------|
| 7B | Q4_K_M | ~50-80 | ~8-12 |
| 13B | Q4_K_M | ~30-50 | ~5-8 |
| 70B | Q4_K_M | ~8-12 | ~1-2 |

Для сравнения: GPU (Vulkan) дает ~3-5x ускорение tg на данной платформе.

## Связанные статьи

- [llama.cpp + Vulkan](vulkan-llama-cpp.md)
- [Выбор моделей](model-selection.md)
- [Бенчмарки](benchmarking.md)
