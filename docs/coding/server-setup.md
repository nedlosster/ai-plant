# Настройка llama-server для кодинга

Платформа: Radeon 8060S (96 GiB VRAM), llama-server + Vulkan. Предварительно: [vulkan-llama-cpp.md](../inference/vulkan-llama-cpp.md).

## Сборка llama.cpp

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
cmake -B build -DGGML_VULKAN=ON
cmake --build build -j$(nproc)
```

## Два экземпляра

### FIM-сервер (порт 8081)

Маленькая модель для автодополнения. Быстрый отклик (<500ms).

```bash
./build/bin/llama-server \
    -m ~/models/qwen2.5-coder-1.5b-instruct-q8_0.gguf \
    --port 8081 \
    -ngl 99 \
    -fa on \
    -c 4096 \
    --host 0.0.0.0
```

Эндпоинт `/infill` -- для FIM-запросов.

### Chat-сервер (порт 8080)

Большая модель для chat, рефакторинга, агентов.

```bash
./build/bin/llama-server \
    -m ~/models/qwen2.5-coder-32b-instruct-q4_k_m.gguf \
    --port 8080 \
    -ngl 99 \
    -fa on \
    -c 32768 \
    --host 0.0.0.0
```

Эндпоинт `/v1/chat/completions` -- OpenAI-compatible API.

## Router mode (альтернатива)

Один экземпляр llama-server с автоматической загрузкой/выгрузкой моделей по запросу.

### Конфигурация

```ini
# models.ini
[DEFAULT]
n-gpu-layers = 99
flash-attn = on

[qwen2.5-coder-1.5b]
model = ~/models/qwen2.5-coder-1.5b-instruct-q8_0.gguf
ctx-size = 4096

[qwen2.5-coder-32b]
model = ~/models/qwen2.5-coder-32b-instruct-q4_k_m.gguf
ctx-size = 32768
```

### Запуск

```bash
./build/bin/llama-server \
    --models-dir ~/models \
    --models-max 4 \
    -ngl 99 \
    --port 8080 \
    --host 0.0.0.0
```

Модели загружаются при первом запросе. При превышении `--models-max` -- LRU-вытеснение. Выбор модели -- через поле `model` в запросе.

### Управление моделями

```bash
# Список загруженных
curl http://localhost:8080/v1/models

# Загрузка модели
curl -X POST http://localhost:8080/models/load \
    -H "Content-Type: application/json" \
    -d '{"model": "qwen2.5-coder-32b"}'

# Выгрузка
curl -X POST http://localhost:8080/models/unload \
    -H "Content-Type: application/json" \
    -d '{"model": "qwen2.5-coder-1.5b"}'
```

## Systemd-сервисы

### FIM-сервер

```ini
# /etc/systemd/system/llama-fim.service
[Unit]
Description=llama.cpp FIM server (autocomplete)
After=network.target

[Service]
Type=simple
User=<user>
ExecStart=~/projects/llama.cpp/build/bin/llama-server \
    -m ~/models/qwen2.5-coder-1.5b-instruct-q8_0.gguf \
    --port 8081 -ngl 99 -fa on -c 4096 --host 0.0.0.0
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Chat-сервер

```ini
# /etc/systemd/system/llama-chat.service
[Unit]
Description=llama.cpp Chat server (coding)
After=network.target

[Service]
Type=simple
User=<user>
ExecStart=~/projects/llama.cpp/build/bin/llama-server \
    -m ~/models/qwen2.5-coder-32b-instruct-q4_k_m.gguf \
    --port 8080 -ngl 99 -fa on -c 32768 --host 0.0.0.0
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Активация

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now llama-fim llama-chat
```

## Эндпоинты

| Эндпоинт | Метод | Назначение |
|----------|-------|-----------|
| `/v1/chat/completions` | POST | Chat (OpenAI-compatible) |
| `/v1/completions` | POST | Completion |
| `/infill` | POST | Fill-in-Middle (автодополнение) |
| `/v1/models` | GET | Список моделей |
| `/health` | GET | Статус сервера |

## Проверка

```bash
# FIM-сервер
curl http://localhost:8081/health
curl http://localhost:8081/v1/models

# Chat-сервер
curl http://localhost:8080/health
curl http://localhost:8080/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "qwen2.5-coder-32b", "messages": [{"role": "user", "content": "Write a Python hello world"}]}'
```

## Параметры для кодинга

| Параметр | FIM-сервер | Chat-сервер | Описание |
|----------|-----------|------------|----------|
| `-c` | 4096 | 32768 | Контекст. FIM -- короткий, Chat -- длинный |
| `-ngl` | 99 | 99 | Все слои на GPU |
| `-fa on` | да | да | Flash Attention (inference). Обязателен аргумент `on` |
| `--host` | 0.0.0.0 | 0.0.0.0 | Доступ с других машин |
| `-b` | 512 | 512 | Batch size для prompt processing |

## Связанные статьи

- [Модели для кодинга](../models/coding.md)
- [IDE-интеграция](ide-setup.md)
- [llama.cpp + Vulkan](../inference/vulkan-llama-cpp.md)
