# ai-plant

Локальный inference-сервер на базе AMD Ryzen AI MAX+ 395 (Strix Halo). Документация, скрипты автоматизации, руководства по AI/ML.

## Платформа

| Параметр | Значение |
|----------|---------|
| Корпус | Meigao MS-S1 MAX |
| CPU | AMD Ryzen AI MAX+ 395 (Zen 5, 16C/32T, до 5.2 GHz) |
| GPU | Radeon 8060S (RDNA 3.5, 40 CU, gfx1151) |
| RAM | 128 GiB LPDDR5 (unified, 256 GB/s) |
| VRAM | 96 GiB (из общего пула RAM) |
| NPU | XDNA 2 (50 TOPS INT8) |
| ОС | Ubuntu 24.04.4 LTS, ядро 6.19.8 |

96 GiB VRAM -- загрузка моделей до 70B в Q4 без квантизации до Q2.

## Быстрый старт

```bash
# Подключение к серверу (настроить SSH-доступ по инструкции в docs/platform/)
ssh <user>@<host>

# Проверка окружения
cd ~/projects/ai-plant
./scripts/inference/vulkan/check.sh

# Запуск inference-сервера
./scripts/inference/start-server.sh Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf --daemon

# Проверка
curl http://localhost:8080/health
```

## Документация

Полная документация: [docs/README.md](docs/README.md)

| Раздел | Описание |
|--------|----------|
| [Платформа](docs/platform/README.md) | Аппаратная часть, BIOS, ядро, драйверы |
| [Inference](docs/inference/README.md) | llama.cpp, Vulkan, ROCm, бенчмарки |
| [Модели](docs/models/README.md) | LLM, кодинг, музыка, картинки, видео |
| [Основы LLM](docs/llm-guide/README.md) | Теория: transformer, токенизация, RAG, prompt engineering |
| [Training](docs/training/README.md) | Fine-tuning: LoRA, QLoRA, DPO, alignment |
| [Прикладные задачи](docs/use-cases/README.md) | Музыка, кодинг, картинки, видео |
| [Глоссарий](docs/glossary.md) | Термины AI/ML |

## Скрипты

| Папка | Описание |
|-------|----------|
| [scripts/status.sh](scripts/status.sh) | Общий статус: GPU, inference, веб-интерфейсы, модели |
| [scripts/inference/](scripts/inference/) | llama.cpp: запуск серверов, модели, бенчмарк, мониторинг |
| [scripts/inference/vulkan/](scripts/inference/vulkan/README.md) | Vulkan backend: сборка, проверка |
| [scripts/inference/rocm/](scripts/inference/rocm/README.md) | ROCm/HIP backend: установка, проверка, сборка |
| [scripts/webui/](scripts/webui/README.md) | Веб-интерфейсы: Open WebUI, Lobe Chat |
| [scripts/music/ace-step/](scripts/music/ace-step/README.md) | ACE-Step 1.5: генерация песен |
| [scripts/power/](scripts/power/) | Режимы энергосбережения |
| [scripts/docs/](scripts/docs/) | Валидация документации |
| [scripts/diagrams/](scripts/diagrams/) | Рендеринг Mermaid-диаграмм |

## Настройка

### Pre-commit hook

Репозиторий содержит pre-commit hook для предотвращения утечки персональных данных. Установка:

```bash
cp scripts/hooks/pre-commit-public.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Плейсхолдеры

В документации используются плейсхолдеры вместо реальных сетевых адресов:

| Плейсхолдер | Описание |
|-------------|----------|
| `<SERVER_IP>` | IP-адрес inference-сервера |
| `<SSH_PORT>` | Порт SSH-тунеля |
| `<user>` | Имя пользователя на сервере |

Замените плейсхолдеры на значения своей инфраструктуры.
