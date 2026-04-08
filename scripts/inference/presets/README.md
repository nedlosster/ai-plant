# scripts/inference/presets/ -- готовые конфигурации запуска

Скрипты-обёртки с подобранными параметрами для конкретных моделей. Все запускают `llama-server` на порту **8081**.

| Скрипт | Модель | Контекст | Особенности |
|--------|--------|----------|-------------|
| `qwen-coder-next.sh` | Qwen3-Coder-Next 80B-A3B Q4_K_M | 256K | стабильно, MoE A3B, через `run_server` |
| `gemma4.sh` | Gemma 4 26B-A4B Q6_K_XL | 64K | `--parallel 1 --no-mmap --jinja`, защита от OOM |

## Использование

```bash
# Foreground
./scripts/inference/presets/qwen-coder-next.sh
./scripts/inference/presets/gemma4.sh

# Daemon
./scripts/inference/presets/qwen-coder-next.sh --daemon
./scripts/inference/presets/gemma4.sh -d
```

Если порт 8081 занят -- остановить текущий сервер: `./scripts/inference/stop-servers.sh`.

## Почему Gemma 4 нужны спец. параметры

Запуск Gemma 4 со стандартными параметрами (`-c 256000 --parallel 4`) приводит к **OOM-kill**:

1. **Sliding window attention** -- llama-server создаёт context checkpoints (~765 MiB каждый, до 32 штук = 24 GiB)
2. **`cache reuse is not supported`** -- KV-shifting между запросами не работает на Gemma 4, потому checkpoints разрастаются
3. **4 параллельных слота** мультиплицируют KV cache
4. **mmap** добавляет 27 GiB виртуальной памяти под GGUF поверх анонимной RSS

Пресет ограничивает:
- `-c 65536` -- контекст 64K (вместо 256K)
- `--parallel 1` -- один слот вместо 4
- `--no-mmap` -- модель в анонимной RAM, без mmap-overhead
- `--jinja` -- обязателен для function calling Gemma 4

## Почему Qwen Coder Next работает с 256K

Архитектура `qwen3next` корректно поддерживает KV-shifting и `--cache-reuse 256`. Контекст 256K помещается в 120 GiB GPU-памяти даже с 4 слотами.
