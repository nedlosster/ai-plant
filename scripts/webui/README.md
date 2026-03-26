# scripts/webui/ -- веб-интерфейсы для LLM

Веб-интерфейсы подключаются к inference backend (llama.cpp) через OpenAI-совместимый API.
Inference -- нижний слой, управляется отдельно через `scripts/inference/`.

## Структура

```
webui/
  config.sh              # общее: Docker, проверка inference
  status.sh              # статус контейнеров и backend
  open-webui/            # Open WebUI (расширенный чат)
    install.sh / start.sh / stop.sh / config.sh
  lobe-chat/             # Lobe Chat (модульный интерфейс)
    install.sh / start.sh / stop.sh / config.sh
```

## Варианты интерфейсов

| Интерфейс | Порт | Описание |
|-----------|------|----------|
| Встроенный UI llama-server | 8080 | Минимальный чат, работает без установки |
| Open WebUI | 3210 | История, markdown, RAG, переключение моделей |
| Lobe Chat | 3211 | Красивый, модульный, поддержка плагинов |

## Быстрый старт

```bash
# 1. Запустить inference backend (обязательно)
./scripts/inference/start-server.sh model.gguf --daemon

# 2. Установить веб-интерфейс
./scripts/webui/open-webui/install.sh
./scripts/webui/lobe-chat/install.sh

# 3. Запустить
./scripts/webui/open-webui/start.sh
./scripts/webui/lobe-chat/start.sh

# 4. Статус
./scripts/webui/status.sh

# 5. Остановить
./scripts/webui/open-webui/stop.sh
./scripts/webui/lobe-chat/stop.sh
```

## Общий статус системы

```bash
./scripts/status.sh
```

Показывает GPU, inference серверы, веб-интерфейсы, модели.

## Требования

- Docker (пользователь в группе docker)
- Inference backend запущен (`./scripts/inference/start-server.sh`)
