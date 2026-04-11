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

## Новости и состояние рынка

Статьи, отражающие состояние рынка на конкретную дату. Обновляются регулярно через скилл `/refresh-news`.

### Хроники и тренды

| Документ | О чём |
|----------|-------|
| [docs/ai-agents/news.md](docs/ai-agents/news.md) | Хроника релизов AI-агентов и моделей по кварталам |
| [docs/ai-agents/trends.md](docs/ai-agents/trends.md) | Долгосрочные тренды: multi-agent, bounded autonomy, context race, SWE-bench |

### Рынок AI-агентов

| Документ | О чём |
|----------|-------|
| [docs/ai-agents/commercial.md](docs/ai-agents/commercial.md) | Платные агенты: цены, доли рынка, бенчмарки |
| [docs/ai-agents/open-source.md](docs/ai-agents/open-source.md) | Открытые агенты: индекс, статус |
| [docs/ai-agents/comparison.md](docs/ai-agents/comparison.md) | Сводные таблицы и Faros.ai/SWE-bench |
| [docs/ai-agents/agents/](docs/ai-agents/agents/) | Per-agent страницы (Claude Code, Cursor, Devin, Codex, ...) |

### Рынок моделей

| Документ | О чём |
|----------|-------|
| [docs/models/llm.md](docs/models/llm.md) | LLM общего назначения (Qwen3.5, Llama 4, GLM-5, Mistral Large 3) |
| [docs/models/coding.md](docs/models/coding.md) | Coding LLM (Qwen3-Coder, Devstral, DeepSeek-Coder) |
| [docs/models/vision.md](docs/models/vision.md) | Vision LLM (InternVL, Qwen3-VL, Pixtral) |
| [docs/models/images.md](docs/models/images.md) | Image gen (FLUX, SD, HiDream) |
| [docs/models/video.md](docs/models/video.md) | Video gen (Wan, LTX-Video, CogVideoX) |
| [docs/models/music.md](docs/models/music.md) | Music gen (ACE-Step, MusicGen, YuE) |
| [docs/models/russian-llm.md](docs/models/russian-llm.md) | Российские LLM (Saiga, T-Bank, Vikhr, GigaChat) |
| [docs/models/russian-vocals.md](docs/models/russian-vocals.md) | Русский вокал |
| [docs/models/tts.md](docs/models/tts.md) | TTS (XTTS, F5-TTS, IndexTTS) |

### Hardware-рынок

| Документ | О чём |
|----------|-------|
| [docs/platform/enterprise-inference.md](docs/platform/enterprise-inference.md) | Datacenter GPU: NVIDIA/AMD/Intel/Google -- VRAM, цены, cloud $/hr |
| [docs/platform/hardware-alternatives.md](docs/platform/hardware-alternatives.md) | Consumer альтернативы: RTX 50xx, Mac M-серия, DGX Spark |
| [docs/inference/acceleration-outlook.md](docs/inference/acceleration-outlook.md) | Прогнозы ROCm/Vulkan/NPU на платформе |

### Бенчмарки (лидерборды)

| Документ | О чём |
|----------|-------|
| [docs/llm-guide/benchmarks/swe-bench.md](docs/llm-guide/benchmarks/swe-bench.md) | SWE-bench Verified -- agentic coding |
| [docs/llm-guide/benchmarks/livecodebench.md](docs/llm-guide/benchmarks/livecodebench.md) | LiveCodeBench -- competitive coding |
| [docs/llm-guide/benchmarks/humaneval.md](docs/llm-guide/benchmarks/humaneval.md) | HumanEval -- function-level coding |
| [docs/llm-guide/benchmarks/mmmu.md](docs/llm-guide/benchmarks/mmmu.md) | MMMU -- multimodal reasoning |

Обновление: `/refresh-news <agents|models|hardware|benchmarks|news|all>` -- см. [.claude/skills/refresh-news/SKILL.md](.claude/skills/refresh-news/SKILL.md).

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
