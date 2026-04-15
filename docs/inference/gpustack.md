# GPUStack: управление GPU-кластером для inference

Платформа: Radeon 8060S (gfx1151, 120 GiB GPU-доступной памяти). Статус: требует проверки совместимости с gfx1151.

## Что такое GPUStack

Open-source менеджер GPU-кластеров для развертывания AI-моделей. Оркестрирует inference-движки на распределенной инфраструктуре.

| Параметр | Значение |
|----------|---------|
| Разработчик | Seal, Inc. (Sheng Liang, ex-Rancher Labs) |
| Лицензия | Apache 2.0 |
| Версия | 2.1.1 (март 2026) |
| GitHub | [gpustack/gpustack](https://github.com/gpustack/gpustack) (~4.7k stars) |
| Документация | [docs.gpustack.ai](https://docs.gpustack.ai) |
| Сайт | [gpustack.ai](https://gpustack.ai) |

## Зачем GPUStack

| Задача | Без GPUStack | С GPUStack |
|--------|-------------|-----------|
| Запуск модели | Ручной запуск llama-server с параметрами | Web UI: выбрать модель из каталога, нажать Deploy |
| Мониторинг | Ручные скрипты ([`scripts/inference/monitor.sh`](../../scripts/inference/monitor.sh)) | Grafana + Prometheus, Web dashboard |
| Несколько моделей | Несколько терминалов, разные порты | Автоматический load balancing, единый API |
| Несколько GPU/нод | Ручная настройка каждой ноды | Автоматическое распределение по кластеру |
| API-ключи | Нет | RBAC, пользователи, API-ключи |

Для single GPU (данная платформа) -- удобство Web UI и каталога моделей. Для кластера -- оркестрация.

## Архитектура

```
GPUStack Server (Web UI + API + Scheduler)
    |
    +-- Worker 1 (GPU 1)
    |     +-- vLLM / llama-box / SGLang
    |     +-- Модель A
    |
    +-- Worker 2 (GPU 2)
    |     +-- vLLM / llama-box
    |     +-- Модель B
    |
    +-- Worker N...
```

Inference backend выбирается автоматически:
- **GGUF** -> llama-box (обертка над llama.cpp + stable-diffusion.cpp)
- **safetensors / HF** -> vLLM / SGLang

## Возможности

### Inference
- Подключаемые движки: vLLM, SGLang, TensorRT-LLM, llama-box
- GGUF и safetensors форматы
- LLM, VLM (vision), embedding, reranker, image generation, TTS, STT
- Extended KV cache (LMCache, HiCache)
- Speculative decoding (EAGLE3, MTP, N-grams)
- Low-latency и high-throughput режимы

### Управление
- Web UI: каталог моделей, playground (chat), мониторинг
- Загрузка моделей из HuggingFace и ModelScope
- OpenAI-совместимый API
- RBAC: admin/user, API-ключи
- Автоматический failure recovery
- Load balancing между worker-нодами

### Мониторинг
- GPU utilization, VRAM, температура
- Token throughput, API requests
- Grafana + Prometheus интеграция
- Логи развертывания

## Поддержка AMD GPU

Минимальная версия: **ROCm 6.4+** (GPUStack v2.1).

Поддерживаемые GPU:
- **Instinct**: MI325X, MI300X, MI300A, MI250X, MI210, MI100
- **Radeon**: RX 7900/7800/7700/7600 (RDNA3), RX 6900/6800 XT (RDNA2)

**gfx1151 (Radeon 8060S)**: не в официальном списке. Требует проверки -- возможно работает через HSA_OVERRIDE_GFX_VERSION.

GPUStack через Vulkan не работает -- только ROCm/HIP.

## Установка

### Docker (основной метод)

```bash
# Стандартная установка
sudo docker run -d --name gpustack \
    --restart unless-stopped \
    -p 80:80 -p 10161:10161 \
    --volume gpustack-data:/var/lib/gpustack \
    gpustack/gpustack

# AMD ROCm
docker run -d --name gpustack \
    --device /dev/kfd --device /dev/dri \
    --network host --ipc host \
    --group-add video --group-add render \
    -e HSA_OVERRIDE_GFX_VERSION=11.5.0 \
    --volume gpustack-data:/var/lib/gpustack \
    gpustack/gpustack:latest-rocm
```

Web UI: `http://localhost` (порт 80). Логин: `admin`, пароль генерируется при первом запуске.

### Добавление worker-ноды

На дополнительных машинах с GPU:

```bash
docker run -d --name gpustack-worker \
    --device /dev/kfd --device /dev/dri \
    --network host --ipc host \
    --group-add video --group-add render \
    gpustack/gpustack:latest-rocm \
    --server http://SERVER_IP --token YOUR_TOKEN
```

## Использование

### Развертывание модели

1. Открыть Web UI -> Models -> Deploy Model
2. Выбрать из каталога (HuggingFace) или указать имя
3. GPUStack автоматически выберет backend и распределит по GPU
4. Модель доступна через API

### API

```bash
# Список моделей
curl http://localhost/v1/models \
    -H "Authorization: Bearer YOUR_API_KEY"

# Chat completion
curl http://localhost/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer YOUR_API_KEY" \
    -d '{
        "model": "qwen2.5-32b-instruct",
        "messages": [{"role": "user", "content": "Hello"}]
    }'
```

### Playground

Web UI включает chat-интерфейс для тестирования моделей без curl/API.

## Сравнение

| Параметр | GPUStack | Ollama | llama-server | LM Studio |
|----------|---------|--------|-------------|-----------|
| Назначение | Кластерная оркестрация | Локальный LLM | Inference API | GUI для LLM |
| Web UI | да (dashboard) | нет (CLI) | нет | да (desktop) |
| Мульти-GPU | да | нет | нет | нет |
| Мульти-нода | да | нет | нет | нет |
| Форматы | GGUF + safetensors | GGUF | GGUF | GGUF |
| Backend-ы | vLLM, SGLang, llama-box | llama.cpp | llama.cpp | llama.cpp |
| RBAC | да | нет | нет | нет |
| Мониторинг | Grafana + Prometheus | нет | нет | базовый |
| Сложность | средняя (Docker) | минимальная | минимальная | минимальная |
| AMD ROCm | да (RDNA2/3) | ограничено | через Vulkan | через Vulkan |

GPUStack -- уровень оркестрации поверх inference-движков. Для single GPU на данной платформе основное преимущество -- Web UI и каталог моделей.

## Совместимость с данной платформой

### Что работает

- Docker-контейнер запускается
- llama-box backend (GGUF-модели)
- Web UI, API, playground
- Мониторинг GPU через ROCm

### Что требует проверки

- gfx1151 не в официальном списке поддержки
- HSA_OVERRIDE_GFX_VERSION=11.5.0 в Docker-контейнере
- vLLM backend для safetensors-моделей (зависит от ROCm для gfx1151)
- Производительность llama-box vs standalone llama-server через Vulkan

### Рекомендация

Для данной платформы (single GPU, gfx1151):
- **Основной workflow**: standalone llama-server + Vulkan (проверено, стабильно)
- **GPUStack**: эксперимент -- попробовать Docker-контейнер с ROCm, проверить совместимость
- **Когда GPUStack оправдан**: несколько серверов Strix Halo в кластере, или интеграция с vLLM

## Связанные статьи

- [llama.cpp + Vulkan](vulkan-llama-cpp.md)
- [Установка ROCm](rocm-setup.md)
- [LM Studio](lm-studio.md)
- [Справочник LLM](../models/llm.md)
