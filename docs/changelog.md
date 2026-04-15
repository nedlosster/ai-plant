# Changelog проекта ai-plant

Хроника значимых изменений в документации и инфраструктуре проекта. Группировка по дням (самые свежие сверху). Источник -- git history, курируется скиллом `/changelog`.

Актуализация: `/changelog update` (добавляет новые записи с последнего обновления) или `/changelog rebuild` (пересобрать с нуля).

---

## 2026-04-15

**Реорганизация документации Claude Code в dedicated папку**

- Создана папка [docs/ai-agents/agents/claude-code/](ai-agents/agents/claude-code/README.md) с 6 статьями (2460 строк):
  - [README.md](ai-agents/agents/claude-code/README.md) -- профиль + index
  - [news.md](ai-agents/agents/claude-code/news.md) -- хроника фич
  - [agent-teams.md](ai-agents/agents/claude-code/agent-teams.md) -- стратегия Agent Teams (3 паттерна, Code Kit v5.0 YAML, playbooks)
  - [skills-guide.md](ai-agents/agents/claude-code/skills-guide.md) -- как писать Skills, 7 best practices
  - [hooks-guide.md](ai-agents/agents/claude-code/hooks-guide.md) -- Hooks для safety (git guardrails, secret scanning, audit log)
  - [mcp-setup.md](ai-agents/agents/claude-code/mcp-setup.md) -- MCP-серверы (30+ популярных, Python/TypeScript SDK)
- Миграция через `git mv` -- история файлов сохранена
- Обновлено 17 inbound-ссылок, refresh-news skill знает про вложенную папку
- Коммиты: `c8cbd5f`, `3e4a69c`

## 2026-04-14

**GLM семейство, refresh news (GPT-6, GLM-5.1, GLM-5V-Turbo)**

- Создана [`docs/models/families/glm.md`](models/families/glm.md) (208 строк) -- полная карточка семейства Z.ai:
  - GLM-5.1 (open MIT) -- первый open-weight в топе SWE-Bench Pro (58.4%)
  - GLM-5V-Turbo (vision-coding) -- Design2Code 94.8% vs Opus 4.6 77.3%
  - Обучение на Huawei Ascend (без NVIDIA)
  - 744B MoE / 44B active, DSA attention, 203K context
- Refresh news models: GPT-6 (OpenAI, 2M context), GLM-5.1, GLM-5V-Turbo, Microsoft MAI Models
- Обновлены [`closed-source-coding.md`](models/closed-source-coding.md), [`coding.md`](models/coding.md), [`vision.md`](models/vision.md)
- Коммиты: `e3f0290`, `6dba5b9`

## 2026-04-13

**Refresh news: MiniMax M2.7, HappyHorse-1.0, VoxCPM2**

- [`docs/models/news.md`](models/news.md): три новые записи
  - MiniMax M2.7 open-sourced: SWE-Pro 56.2%, Terminal-Bench 57.0%
  - HappyHorse-1.0 (Alibaba): open-source video gen, #1 Artificial Analysis
  - VoxCPM2 (OpenBMB): tokenizer-free TTS
- Коммиты: `60af4c5`

## 2026-04-12

**Closed-source coding статья + Gemma 4 расширение**

- Создана [`docs/models/closed-source-coding.md`](models/closed-source-coding.md) (289 строк) -- обзор GPT-5.3 Codex, Claude Opus/Sonnet/Mythos, Gemini 3.1 Pro, Kimi K2.5. Decision matrix API vs local, pricing per-task
- Расширен [`docs/models/families/gemma4.md`](models/families/gemma4.md) (+170 строк): варианты E2B/E4B/26B/31B, adaptive image tokens, PLE, bounding box prediction, 4 новых сценария
- Refresh news: MCP 97M установок (де-факто стандарт), Gemma 4 перенесена из Q4 2025 → Q2 2026 (fix даты)
- Коммиты: `2fbc0ad`, `53d4463`

## 2026-04-11

**Большая сессия: [apps/](apps/README.md), TTS integration, review, inference profiles**

Самый активный день -- 7 коммитов. Основные события:

- **Новый раздел [docs/apps/](apps/README.md)** (4873 строки в 21 файле): профили end-user приложений
  - [comfyui/](apps/comfyui/README.md), [open-webui/](apps/open-webui/README.md), [lobe-chat/](apps/lobe-chat/README.md), [ace-step/](apps/ace-step/README.md) -- каждый с README + introduction + architecture + simple/advanced use-cases
- **TTS integration** (733 строки): [`open-webui/tts-integration.md`](apps/open-webui/tts-integration.md) + [`lobe-chat/tts-integration.md`](apps/lobe-chat/tts-integration.md) -- Kokoro, Chatterbox, XTTS, Whisper setup
- **Глоссарий обновлён** (+67 строк, ~45 новых терминов): RAG, Embeddings, Speculative decoding, MLA, SWA, K-quants, IQ-quants, AWQ, Ollama, Open WebUI, LobeChat, Lemonade, DiT, и др.
- **LTX-2** статья (277 строк): dual-stream audio-video DiT, 19B (14B+5B), sync single-pass
- **Inference profiles** (1722 строки):
  - [`llama-cpp.md`](inference/llama-cpp.md) (585) -- история, GGML, GGUF, квантизации, бэкенды
  - [`ollama.md`](inference/ollama.md) (606) -- docker-стиль, OCI-registry, content-addressed storage
  - [`lemonade.md`](inference/lemonade.md) (531) -- NPU-ускорение для Ryzen AI, hybrid prefill/decode
- **Refresh news Apr 2026**: Cursor 3, Devin 2.0, SWE-bench 93.9%, Claude Code 41% market share
- **Хроника релизов моделей**: [`docs/models/news.md`](models/news.md) создан (142 строки)
- Коммиты: `6b1dcf2`, `60b3cee`, `87b513e`, `2cb0045`, `526742e`, `19b25f1`, `4f07d83`, `6cf8e90`, `f1cbd13`

## 2026-04-10

**Hardware / benchmarks / inference infrastructure**

- **Бенчмарки** ([llm-guide/benchmarks/](llm-guide/benchmarks/README.md)):
  - [`humaneval.md`](llm-guide/benchmarks/humaneval.md), [`swe-bench.md`](llm-guide/benchmarks/swe-bench.md) перенесены в [benchmarks/](llm-guide/benchmarks/README.md)
  - Новые: [`livecodebench.md`](llm-guide/benchmarks/livecodebench.md), [`mmmu.md`](llm-guide/benchmarks/mmmu.md)
  - [`README.md`](llm-guide/benchmarks/README.md) -- классификация бенчмарков, рейтинговые сайты
- **Сравнение моделей платформы с frontier closed-source** ([`models/README.md`](models/README.md) -- таблицы бенчмарков)
- **Hardware**:
  - [`enterprise-inference.md`](platform/enterprise-inference.md) -- datacenter GPU, API pricing, self-hosted vs cloud
  - [`hardware-alternatives.md`](platform/hardware-alternatives.md) -- RTX 5090, Mac M4 Max, DGX Spark, M3 Ultra
  - [`acceleration-outlook.md`](inference/acceleration-outlook.md) -- перспективы GPU/CPU/NPU
- **ROCm фиксы**:
  - ROCm HIP бенчмарки Qwen3-Coder 30B-A3B (63.5 tok/s)
  - KFD видит 120 GiB после fix `ttm.pages_limit`
  - Sync-status: InternVL3-38B скачан
- **Статья про плотность знаний в моделях** ([`llm-guide/model-information-density.md`](llm-guide/model-information-density.md)) -- парадокс сжатия, биты на параметр, MoE
- **Presets**: Devstral 2, InternVL3-38B, Qwen3.5-35B; удалён orphan qwen3.5-27b. InternVL3-38B порт 8084 → 8081
- **Community-вариант Qwen3-14B-Claude-4.5-Opus-Reasoning-Distill** (TeichAI)
- Коммиты: `b112d70`, `b5f02a6`, `90e4004`, `66cc4b8`, `78a7285`, `1ca2260`, `93296b1`, `e8f5bd5`, `aa50cdc`, `804c84a`, `385808a`, `fdfe99d`, `8eec40a`, `38c2ddf`, `3c27194`, `10410f2`, `66bb1eb`

## 2026-04-09

**Models deep dive: Gemma 4, InternVL, Qwen3-VL, coding стратегия**

- **Gemma 4** ([`models/families/gemma4.md`](models/families/gemma4.md)): оптимальная стратегия, 7 простых + 8 сложных кейсов, антипаттерны
- **InternVL** ([`models/families/internvl.md`](models/families/internvl.md)): InternVL3.5 38B, простые/сложные кейсы
- **Qwen3-VL**:
  - Платформы и клиенты для работы
  - Workflow обратного инжиниринга UI по скриншоту (4 фазы, 30B-A3B + 235B-A22B)
  - Топ-10 vision-моделей, вердикт по 235B
- **Coding стратегия** ([`models/coding.md`](models/coding.md)): топ open-моделей, strategy opencode, open vs cloud, слухи Q2-Q3 2026
- **Qwen3.5**: раздел про агенты кодинга
- **Kimi K2.5** добавлена в families
- **AI-agents раздел**:
  - [README.md](ai-agents/README.md) навигация
  - Markdown-ссылки на [agents/](ai-agents/agents/README.md) из [models/](models/README.md)
  - Удалён `use-cases/coding/opencode/` (консолидировано в [agents/opencode.md](ai-agents/agents/opencode.md))
  - [`commercial.md`](ai-agents/commercial.md), [`open-source.md`](ai-agents/open-source.md) как индексы
- **Function calling** ([`llm-guide/function-calling.md`](llm-guide/function-calling.md)) -- раздел про платформу, колонка FC в таблицах, поле в шапках
- **Документы** -- статья про обработку документов (PDF/Word/Excel, pipelines)
- **Sync-status**: Devstral 2 + Qwen3.5-35B-A3B скачаны, InternVL3-38B
- Коммиты: `aff6a0a`, `1800f8d`, `43a219a`, `1963d8d`, `b8fa3cc`, `6f684da`, `3522a01`, `eb51db8`, `a4a12fd`, `b65b15d`, `774ed85`, `b0a04ff`, `a26e3a9`, `adc022b`, `69d44f1`, `9dd02ae`, `d3aafae`, `e5d6d22`, `10b6941`, `e0ae230`, `c9b406e`

## 2026-04-08

**Полный день: Gemma 4 vision, пресеты, TTS, inference-инфраструктура**

Самый массивный ранний день -- 19 коммитов за ~8 часов.

- **Inference-пресеты** (10 коммитов):
  - `--cache-reuse 256` в run_server
  - `--jinja` по умолчанию для совместимости с Gemma 4
  - opencode toolParser добавлен, затем убран как невалидное поле
  - Пресеты Qwen Coder Next и Gemma 4
  - Рефакторинг пресетов в [`scripts/inference/vulkan/preset/`](../scripts/inference/vulkan/preset/) и [`scripts/inference/rocm/preset/`](../scripts/inference/rocm/preset/)
  - Все llama-server флаги через массив ARGS
  - Пресеты для Qwen 1.5B, 27B, 30B MoE, 122B
- **Webui** (3 коммита):
  - URL inference-сервера через локальный `inference.env`
  - `LLAMA_API_URL` зависит от `LLAMA_HOST` (поддержка remote inference)
  - echo Backend показывает реальный URL
- **Gemma 4 vision через `--mmproj`**: создана статья [`docs/models/vision.md`](models/vision.md)
- **TTS**: статья про voice cloning + [`scripts/tts/`](../scripts/tts/) для TTS-WebUI
- **Docs**: расширены [`vision.md`](models/vision.md), [`llm.md`](models/llm.md), [`coding.md`](models/coding.md), [`video.md`](models/video.md) актуализацией 2026
- Коммиты: `4823f1a`, `9ad84d2`, `b4d84ac`, `3e43dee`, `32ee827`, `7e77e2b`, `bd4d0b3`, `06ddca1`, `ffb3841`, `423e1d8`, `850ddea`, `b818e6a`, `2946989`, `8a5be40`, `96b05e1`, `29be230`, `780d29d`, `852c909`, `44daae5`, `c9b75fe`

## 2026-04-06

**ROCm 7.2.1 актуализация**

- Обновление скриптов для ROCm 7.2.1 (gfx1151 нативная поддержка, segfault закрыт)
- Актуализация документации ROCm -- бенчмарки, gfx1151
- Бенчмарки Vulkan vs HIP на 3 моделях (1.5B, 27B, 30B MoE)
- [`docs/platform/processor.md`](platform/processor.md): макс память 128 GiB (8ch x 2rank x 16Gbit), бенчмарки
- Коммиты: `86cfedf`, `6aec1a2`, `e7ad6fd`, `e4d9cd6`, `d0c2020`

## 2026-03-30

**Раздел AI-агентов**

- Создан раздел [docs/ai-agents/](ai-agents/README.md) -- обзор индустрии AI-агентов для разработки
- Коммиты: `f1bd373`

## 2026-03-29

**RAG разделён на подстатьи**

- Монолитная статья `rag.md` разделена на 7 статей в [docs/llm-guide/rag/](llm-guide/rag/README.md):
  - chunking, embeddings, evaluation, pipeline, retrieval, vector-databases, advanced
- Каждая статья с фокусом на одном аспекте RAG
- Коммиты: `83fd847`

## 2026-03-28

**Initial commit -- проект стартовал**

- Первый коммит: inference-сервер на AMD Strix Halo
- Базовая структура [docs/](README.md): [platform](platform/README.md), [inference](inference/README.md), [models](models/README.md), [llm-guide](llm-guide/README.md), [training](training/README.md), [use-cases](use-cases/README.md)
- Скрипты: [`scripts/inference/`](../scripts/inference/), [`scripts/webui/`](../scripts/webui/), [`scripts/music/`](../scripts/music/), [`scripts/tts/`](../scripts/tts/)
- Документация: README, глоссарий, обзор платформы
- Коммиты: `1dd4bad`, `e168dd9` (RAM 128 GiB уточнение)

---

## Основные вехи проекта

| Дата | Событие |
|------|---------|
| 2026-03-28 | Старт проекта: initial commit с документацией и скриптами |
| 2026-04-09 | Большая сессия deep dive по моделям (Gemma 4, InternVL, Qwen3-VL) |
| 2026-04-10 | Бенчмарки раздел (SWE-bench, HumanEval, MMMU, LiveCodeBench), hardware-альтернативы |
| 2026-04-11 | **Самый активный день**: раздел [docs/apps/](apps/README.md), inference profiles, глоссарий, refresh news |
| 2026-04-12 | Closed-source coding статья, Gemma 4 расширение, MCP 97M |
| 2026-04-14 | GLM семейство, GPT-6 релиз, GLM-5.1 #1 на SWE-Bench Pro |
| 2026-04-15 | Dedicated папка для Claude Code (6 статей, 2460 строк) |

---

## Статистика

- **Первый коммит**: 2026-03-28
- **Всего коммитов**: 100+ (актуально на апрель 2026)
- **Размер документации**: ~15000+ строк
- **Разделов [docs/](README.md)**: 8 ([platform](platform/README.md), [inference](inference/README.md), [models](models/README.md), [llm-guide](llm-guide/README.md), [training](training/README.md), [ai-agents](ai-agents/README.md), [use-cases](use-cases/README.md), [apps](apps/README.md))

---

<!-- last-update: c8cbd5f -->
<!-- last-date: 2026-04-15 -->

## Как обновлять этот файл

- `/changelog update` -- добавить записи с последнего обновления (читает маркер `last-update` выше)
- `/changelog rebuild` -- пересобрать с нуля (из полной git history)
- `/changelog since <date>` -- обновить с конкретной даты

Подробности -- в `.claude/skills/changelog/SKILL.md`.
