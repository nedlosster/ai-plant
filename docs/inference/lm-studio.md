# LM Studio: быстрый старт

Платформа: Radeon 8060S (gfx1151), Vulkan 1.3.275, Ubuntu 24.04.4.

## Текущий статус

| Параметр | Значение |
|----------|---------|
| LM Studio | установлен |
| Backend | llama.cpp 2.7.1 / 2.8.0 (Vulkan) |
| Модели | Gemma 3 4B IT (Q4_K_M, 2.4 GiB) |
| Расположение моделей | ~/.cache/lm-studio/models/ |

## Что такое LM Studio

GUI-приложение для локального запуска LLM. Включает:
- Встроенный llama.cpp с поддержкой Vulkan
- Менеджер моделей (поиск и загрузка с HuggingFace)
- Chat-интерфейс
- OpenAI-совместимый API-сервер

## Установка

```bash
# Загрузка AppImage
wget https://releases.lmstudio.ai/linux/x86/0.3.14-2/LM-Studio-0.3.14-2-x86_64.AppImage

# Права на исполнение
chmod +x LM-Studio-*.AppImage

# Запуск
./LM-Studio-*.AppImage
```

Для постоянного использования -- создать .desktop файл или переместить в /opt/.

## Настройка для Radeon 8060S

1. **Backend**: Settings -> My Models -> Default backend -> выбрать llama.cpp с Vulkan
2. **GPU Offload**: при загрузке модели -> GPU Offload -> Maximum (все слои на GPU)
3. **Проверка GPU**: в логах при загрузке модели должно отображаться устройство AMD Vulkan

При 120 GiB GPU-доступной памяти рекомендуется загружать все слои на GPU (GPU Offload = Max).

## Загрузка моделей

1. В интерфейсе: поисковая строка -> ввести имя модели (например "Llama 3.1 70B")
2. Выбрать автора квантизации (bartowski, unsloth)
3. Выбрать формат: Q4_K_M (рекомендуется), Q5_K_M, Q8_0
4. Загрузить

Модели сохраняются в `~/.cache/lm-studio/models/`.

Подробнее о выборе квантизации: [model-selection.md](model-selection.md)

## Chat-интерфейс

1. Загрузить модель (выпадающее меню сверху)
2. Ввести промпт в текстовое поле
3. Настройки генерации (Temperature, Top-P, Max tokens) -- в правой панели

## API-сервер

LM Studio предоставляет OpenAI-совместимый API.

### Включение

Settings -> Developer -> Enable CORS -> включить. Или запуск из CLI:

```bash
# Запуск headless API-сервера (если поддерживается версией)
lms server start --port 1234
```

### Эндпоинты

```
POST http://localhost:1234/v1/chat/completions
POST http://localhost:1234/v1/completions
GET  http://localhost:1234/v1/models
```

### Примеры запросов

```bash
# Список моделей
curl http://localhost:1234/v1/models

# Chat completion
curl http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-3-4b-it",
    "messages": [
      {"role": "user", "content": "Explain quantum computing in 3 sentences."}
    ],
    "temperature": 0.7,
    "max_tokens": 256
  }'

# Completion (raw)
curl http://localhost:1234/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-3-4b-it",
    "prompt": "The meaning of life is",
    "max_tokens": 100
  }'
```

### Использование из Python

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:1234/v1",
    api_key="not-needed"
)

response = client.chat.completions.create(
    model="gemma-3-4b-it",
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)
print(response.choices[0].message.content)
```

## Ограничения

- Требует X11 или Wayland (GUI-приложение, headless-режим ограничен)
- Закрытый исходный код
- Для автоматизации и headless-серверов -- standalone llama.cpp ([vulkan-llama-cpp.md](vulkan-llama-cpp.md))
- Версии llama.cpp backend обновляются с задержкой относительно upstream

## Связанные статьи

- [llama.cpp (профиль проекта)](llama-cpp.md) -- inference-движок, на котором работает LM Studio
- [Ollama (профиль проекта)](ollama.md) -- другая обёртка над llama.cpp (CLI-first)
- [Выбор моделей](model-selection.md)
- [llama.cpp + Vulkan](vulkan-llama-cpp.md)
- [Диагностика](troubleshooting.md)
