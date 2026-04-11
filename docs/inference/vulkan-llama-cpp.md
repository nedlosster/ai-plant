# Inference через Vulkan: standalone llama.cpp

Платформа: Radeon 8060S (gfx1151), Vulkan 1.4.318, Mesa 26.0.0, Ubuntu 24.04.4.

## Vulkan как GPU backend для LLM

Vulkan -- кроссплатформенный графический API от Khronos Group (2016), наследник OpenGL. Изначально создан для игр и рендеринга, но благодаря поддержке compute shaders стал полноценным GPGPU backend'ом. В llama.cpp Vulkan backend реализован через SPIR-V compute shaders и работает на любом GPU с драйвером Vulkan 1.2+ -- AMD, NVIDIA, Intel, без привязки к проприетарным SDK.

Для AMD GPU на Linux Vulkan работает через открытый драйвер Mesa (RADV). Это принципиальное отличие от ROCm: Mesa поддерживает новые GPU раньше, чем AMD добавляет их в матрицу ROCm. Radeon 8060S (gfx1151, Strix Halo) полностью поддерживается Mesa 26.0.0 с Vulkan 1.4.318 и cooperative matrix extensions (KHR_coopmat), что ускоряет матричные операции. В отличие от ROCm, Vulkan через Mesa видит всю unified memory (120 GiB GPU-доступных через ttm.pages_limit).

На практике Vulkan -- рекомендуемый backend для данной платформы: стабильная работа, полная видимость VRAM, отсутствие зависимости от ROCm. Производительность достаточна для интерактивной работы: 5230 tok/s prompt processing и 120 tok/s token generation на модели 1.5B Q8_0; 292 pp / 12.5 tg на модели 27B Q4_K_M. Подробное сравнение backend'ов: [backends-comparison.md](backends-comparison.md).

## Предварительные требования

- Vulkan работает (Mesa 26.0.0+)
- Пользователь в группах `video` и `render` (доступ к /dev/dri/card1 и renderD128)
- cmake >= 3.28, git, build-essential, libvulkan-dev, glslc

## Настройка прав доступа

```bash
# Добавить пользователя в группы video и render
sudo usermod -aG video,render $USER

# Проверка (после перелогина или через sg)
groups
# ... video render ...

# Если не перелогинивались -- sg для текущей сессии
sg render -c 'vulkaninfo --summary'
```

Без группы `render` Vulkan не видит GPU: `Permission denied` на `/dev/dri/renderD128`.

## Проверка Vulkan

```bash
vulkaninfo --summary 2>&1 | grep -E 'deviceName|apiVersion'
# deviceName = AMD Radeon Graphics (RADV GFX1151)
# apiVersion = 1.4.318
```

Если `vulkaninfo` не найден или нет устройств:

```bash
sudo apt install vulkan-tools mesa-vulkan-drivers
```

## Установка зависимостей

```bash
sudo apt install cmake build-essential git libvulkan-dev glslc
```

`glslc` -- Vulkan shader compiler, обязателен для сборки. Без него cmake выдает: `Could NOT find Vulkan (missing: glslc)`.

## Сборка llama.cpp

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

cmake -B build -DGGML_VULKAN=ON
cmake --build build -j$(nproc)

# Проверка (через sg если не перелогинивались)
sg render -c './build/bin/llama-cli --version'
# ggml_vulkan: Found 1 Vulkan devices:
# ggml_vulkan: 0 = AMD Radeon Graphics (RADV GFX1151) | uma: 1 | fp16: 1
```

### Предупреждения при cmake (нормально)

```
GL_NV_cooperative_matrix2 not supported by glslc   # NVIDIA-специфичное, игнорировать
GL_EXT_integer_dot_product not supported by glslc   # не критично
GL_EXT_bfloat16 not supported by glslc              # BF16 шейдеры недоступны, FP16 используется
Could NOT find OpenSSL                              # HTTPS для llama-server отключен
```

Эти предупреждения не влияют на работоспособность.

## Загрузка модели

См. [model-selection.md](model-selection.md).

```bash
# Установка huggingface-hub (новые версии используют команду hf вместо huggingface-cli)
pip install huggingface-hub

# Загрузка модели (hf -- актуальная команда, huggingface-cli -- устаревшая)
hf download bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF \
    --include "*Q8_0.gguf" \
    --local-dir ~/models/

# Если hf не в PATH:
~/.local/bin/hf download bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF \
    --include "*Q8_0.gguf" \
    --local-dir ~/models/
```

Модели сохраняются в `~/models/`. При использовании `--break-system-packages` (Ubuntu 24.04) скрипты устанавливаются в `~/.local/bin/` -- добавить в PATH:

```bash
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Запуск: интерактивный режим

```bash
./build/bin/llama-cli \
    -m ./models/Llama-3.1-8B-Instruct-Q4_K_M.gguf \
    -ngl 99 \
    -c 8192 \
    --temp 0.7 \
    -p "You are a helpful assistant." \
    --interactive-first
```

## Запуск: API-сервер

```bash
./build/bin/llama-server \
    -m ./models/Llama-3.1-8B-Instruct-Q4_K_M.gguf \
    -ngl 99 \
    -c 8192 \
    --host 0.0.0.0 \
    --port 8080
```

Сервер предоставляет OpenAI-совместимый API:

```bash
# Проверка
curl http://localhost:8080/v1/models

# Chat completion
curl http://localhost:8080/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "llama-3.1-8b",
        "messages": [{"role": "user", "content": "Hello"}],
        "temperature": 0.7
    }'
```

## Ключевые параметры

| Параметр | Значение | Описание |
|----------|---------|----------|
| `-m` | путь к .gguf | Файл модели |
| `-ngl` | 99 | Число слоев на GPU. 99 = все слои. 120 GiB GPU-памяти -- все слои для моделей до 122B MoE |
| `-c` | 8192 | Размер контекста (токены). Влияет на потребление VRAM через KV-cache |
| `--temp` | 0.7 | Температура генерации. 0 = детерминированный, 1+ = более случайный |
| `--threads` | 16 | Потоки CPU (для операций, не вынесенных на GPU) |
| `-b` | 512 | Batch size для prompt processing. Увеличение ускоряет pp |
| `-ub` | 512 | Micro-batch size |
| `--host` | 0.0.0.0 | Адрес для прослушивания (сервер) |
| `--port` | 8080 | Порт (сервер) |

### GPU offload (-ngl)

`-ngl` определяет сколько слоев модели загружается на GPU. Остальные -- на CPU.

- `-ngl 99` -- все слои на GPU (рекомендуется при достаточном VRAM)
- `-ngl 0` -- все на CPU (см. [cpu-inference.md](cpu-inference.md))
- `-ngl 40` -- partial offload: 40 слоев на GPU, остальные на CPU

120 GiB GPU-памяти: модели до 122B MoE Q4_K_M (71 GiB) помещаются целиком, 70B Q8_0 + ctx 32k (~90 GiB) -- с запасом.

### Размер контекста (-c)

Увеличение контекста увеличивает потребление VRAM (KV-cache). Примерное потребление KV-cache для Llama 70B:

| -c | KV-cache |
|----|----------|
| 4096 | ~2.5 GiB |
| 8192 | ~5 GiB |
| 16384 | ~10 GiB |
| 32768 | ~20 GiB |

## Systemd-сервис (опционально)

```bash
# /etc/systemd/system/llama-server.service
[Unit]
Description=llama.cpp inference server
After=network.target

[Service]
Type=simple
User=<user>
WorkingDirectory=~/projects/llama.cpp
ExecStart=~/projects/llama.cpp/build/bin/llama-server \
    -m ~/models/model.gguf \
    -ngl 99 -c 8192 \
    --host 0.0.0.0 --port 8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now llama-server
```

## Диагностика

```bash
# Отладка Vulkan-бэкенда
GGML_VK_DEBUG=1 ./build/bin/llama-cli -m model.gguf -ngl 99 -p "test" -n 10

# Проверка что GPU используется
# В выводе llama-cli должна быть строка:
# ggml_vulkan: Using AMD Radeon ...

# Мониторинг GPU во время инференса
watch -n 1 'cat /sys/class/drm/card1/device/gpu_busy_percent'
```

Типичные проблемы: [troubleshooting.md](troubleshooting.md)

## Скрипты автоматизации

Backend-специфичные скрипты в `scripts/inference/vulkan/`:

| Скрипт | Назначение |
|--------|-----------|
| `check.sh` | Проверка окружения: Vulkan, GPU, группы, зависимости |
| `build.sh` | Сборка/пересборка llama.cpp с GGML_VULKAN=ON |

Общие скрипты в `scripts/inference/` (автодетект backend'а):

| Скрипт | Назначение |
|--------|-----------|
| `start-server.sh` | Запуск chat-сервера (порт 8080) |
| `start-fim.sh` | Запуск FIM-сервера (порт 8081) |
| `stop-servers.sh` | Остановка всех серверов |
| `download-model.sh` | Загрузка модели из HuggingFace |
| `status.sh` | Статус: backend, GPU, серверы, модели |
| `bench.sh` | Бенчмарк модели (pp + tg) |
| `monitor.sh` | Мониторинг GPU в реальном времени |

```bash
# Пример использования на сервере
./scripts/inference/vulkan/check.sh
./scripts/inference/start-server.sh Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf
```

## Реальные замеры на платформе

Radeon 8060S (gfx1151), Vulkan 1.4.318, llama-server, все слои на GPU:

| Модель | Params | Размер | pp512 tok/s | tg128 tok/s |
|--------|--------|--------|-------------|-------------|
| Qwen2.5-Coder-1.5B Q8_0 | 1.5B | 1.5 GiB | 5245 | 120.6 |
| Qwen3-Coder-30B-A3B Q4_K_M (MoE) | 30.5B | 17.3 GiB | 1036 | 86.1 |
| Qwen3.5-27B Q4_K_M | 26.9B | 15.6 GiB | 309 | 12.6 |
| Qwen3-Coder-Next-80B-A3B Q4_K_M (MoE) | 79.7B | 45.1 GiB | 590 | 53.2 |
| Qwen3.5-122B-A10B Q4_K_M (MoE) | 122.1B | 71.3 GiB | 300 | 22.2 |

MoE-модели (A3B, A10B) при генерации активируют часть экспертов, потому tg значительно выше, чем у dense-моделей аналогичного размера.

Замер: llama-bench pp512/tg128, ngl=99, t=16, llama.cpp b8541 (Vulkan), 2026-03-27.

Характеристики GPU при инференсе:
```
ggml_vulkan: 0 = AMD Radeon Graphics (RADV GFX1151) (radv)
  uma: 1 | fp16: 1 | bf16: 0
  warp size: 64 | shared memory: 65536
  matrix cores: KHR_coopmat
```

## Связанные статьи

- [llama.cpp (профиль проекта)](llama-cpp.md) -- история, GGML, GGUF, квантизации, экосистема
- [Выбор моделей](model-selection.md)
- [llama.cpp + ROCm](rocm-llama-cpp.md)
- [CPU-инференс](cpu-inference.md)
- [Бенчмарки](benchmarking.md)
- [Диагностика](troubleshooting.md)
- [Настройка сервера для кодинга](../use-cases/coding/server-setup.md)
