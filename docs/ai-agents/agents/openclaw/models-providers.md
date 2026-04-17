# Провайдеры и модели: настройка model-agnostic стека

Контекст: [README.md](README.md). Ключевое преимущество OpenClaw -- работа с любой моделью,
любым провайдером. В отличие от Claude Code (привязан к Anthropic) или GitHub Copilot
(привязан к OpenAI/Azure), OpenClaw предоставляет единый интерфейс поверх произвольного
backend.

---

## Поддерживаемые провайдеры

| Провайдер | Модели | Тип | Статус (апрель 2026) |
|-----------|--------|-----|---------------------|
| Anthropic | Claude Opus 4.6, Sonnet 4.5 | API | Подписка заблокирована, API key работает |
| OpenAI | GPT-5.3, GPT-4.1, o3 | API | Полная поддержка |
| Kimi (Moonshot) | Kimi K2.5 | API | Рекомендуемый default |
| Qwen (Alibaba) | Qwen 3.6, Qwen3-Coder | API | Полная поддержка |
| Google | Gemini 3.x | API | Поддерживается |
| DeepSeek | DeepSeek R2, Coder V3 | API | Поддерживается |
| Mistral | Devstral 2, Large 3 | API | Поддерживается |
| Локальные | llama-server, Ollama, vLLM | OpenAI-compatible | Полная поддержка |

---

## Anthropic (Claude)

### Настройка

Settings -- Providers -- Anthropic. Указать API key.

```yaml
providers:
  anthropic:
    api_key: "${ANTHROPIC_API_KEY}"
    default_model: claude-opus-4-6-20260401
```

### Статус после блокировки апреля 2026

С 4 апреля 2026 Anthropic заблокировал доступ OpenClaw через подписку
Claude Pro/Max. Подробная хронология -- в [news.md](news.md).

Текущая ситуация:

| Способ доступа | Статус | Стоимость |
|---------------|--------|-----------|
| API key (pay-as-you-go) | Работает | $3/M input, $15/M output (Opus 4.6) |
| Claude Pro ($20/мес) | Заблокирован | -- |
| Claude Max ($100/мес) | Заблокирован | -- |

**Юридические риски:**
- Anthropic активно мониторит third-party usage через API
- Peter Steinberger (создатель OpenClaw) получил временный бан аккаунта
- Terms of Service запрещают "automated access" через consumer подписку
- API usage пока легален, но Anthropic может изменить условия

### Рекомендация

Использовать Anthropic API только при готовности к pay-as-you-go тарификации.
При активном использовании (500K+ tokens/день) стоимость быстро растёт.
Для экономии -- Kimi K2.5 или локальная модель.

---

## OpenAI

### Настройка

```yaml
providers:
  openai:
    api_key: "${OPENAI_API_KEY}"
    default_model: gpt-5.3-codex
```

### Рекомендуемые модели

| Модель | Назначение | Цена (input/output за 1M) | SWE-bench |
|--------|-----------|--------------------------|-----------|
| GPT-5.3 Codex | Coding | $2/$8 | 86% |
| GPT-4.1 | Баланс цены/качества | $2/$8 | 55% |
| o3 | Complex reasoning | $10/$40 | 70% |
| GPT-4.1 mini | Простые задачи | $0.4/$1.6 | 35% |

### Контекст

Peter Steinberger (создатель OpenClaw) присоединился к OpenAI в феврале 2026.
Это обеспечивает хорошую совместимость OpenClaw с OpenAI API и приоритетный
доступ к новым моделям.

---

## Kimi (Moonshot)

### Настройка

API key от Moonshot (kimi.moonshot.cn):

```yaml
providers:
  kimi:
    api_key: "${KIMI_API_KEY}"
    base_url: "https://api.moonshot.cn/v1"
    default_model: kimi-k2.5
```

### Kimi K2.5 -- рекомендуемый default

После блокировки Anthropic, Kimi K2.5 стал de facto standard для OpenClaw:

- Архитектура: 1T MoE (Mixture of Experts)
- SWE-bench Verified: ~75%
- Стоимость: значительно дешевле Claude Opus
- Context window: 256K tokens
- Качество reasoning: сопоставимо с GPT-5.3 на большинстве задач

Подробнее: [карточка Kimi K2.5](../../../models/families/kimi-k25.md)

### Ограничения

- Региональная доступность: основной datacenter в Китае, latency из Европы выше
- Rate limits: зависят от тарифного плана
- Tool use: хороший, но не на уровне Claude Opus

---

## Qwen (Alibaba)

### Настройка

API key от DashScope:

```yaml
providers:
  qwen:
    api_key: "${DASHSCOPE_API_KEY}"
    base_url: "https://dashscope.aliyuncs.com/compatible-mode/v1"
    default_model: qwen-3.6-plus
```

### Рекомендуемые модели

| Модель | Назначение | Доступность | Подробнее |
|--------|-----------|-------------|-----------|
| Qwen 3.6-Plus | General purpose | API-only | [карточка](../../../models/families/qwen36.md) |
| Qwen3-Coder Next | Coding | API + локально (GGUF) | [карточка](../../../models/families/qwen3-coder.md) |
| Qwen3.5-35B | Лёгкая модель | Локально (GGUF) | -- |

### Qwen3-Coder для локального inference

Qwen3-Coder Next (80B-A3B MoE) -- одна из лучших моделей для локального
запуска на ai-plant сервере. В формате Q4_K_M помещается в 96 GiB VRAM
Strix Halo. Подробнее в разделе "Локальные модели".

---

## Google (Gemini)

### Настройка

```yaml
providers:
  google:
    api_key: "${GOOGLE_API_KEY}"
    default_model: gemini-3.0-pro
```

### Модели

- Gemini 3.0 Pro -- general purpose, хороший multimodal
- Gemini 3.0 Flash -- быстрый и дешёвый

### Ограничения в OpenClaw

- Tool use: менее стабильный, чем у Anthropic/OpenAI
- Streaming: поддерживается, но с особенностями
- Context window: 2M tokens (максимальный среди провайдеров)

---

## DeepSeek

### Настройка

```yaml
providers:
  deepseek:
    api_key: "${DEEPSEEK_API_KEY}"
    base_url: "https://api.deepseek.com/v1"
    default_model: deepseek-r2
```

### Модели

- DeepSeek R2 -- reasoning, сильный на математике и коде
- DeepSeek Coder V3 -- специализированный coding

### Особенности

- Дешевле большинства конкурентов
- Доступность: основной datacenter в Китае
- Open weights: можно запускать локально

---

## Локальные модели (llama-server, Ollama, vLLM)

### Подключение к OpenAI-compatible endpoint

Settings -- Providers -- OpenAI Compatible:

```yaml
providers:
  local:
    type: openai-compatible
    base_url: "http://192.168.1.77:8081/v1"
    api_key: "not-needed"  # dummy, требуется синтаксически
    default_model: "qwen3-coder-next"
```

Адрес `192.168.1.77:8081` -- inference-сервер ai-plant (Strix Halo).

### Настройка для ai-plant сервера

Inference-сервер на AMD Ryzen AI Max+ 395 с 96 GiB unified VRAM,
llama-server + Vulkan backend:

**Рекомендуемые модели для OpenClaw:**

| Модель | Размер (Q4_K_M) | Назначение | Карточка |
|--------|----------------|-----------|----------|
| Qwen3-Coder Next | ~45 GiB | Coding, tool use | [qwen3-coder.md](../../../models/families/qwen3-coder.md) |
| Devstral 2 | ~40 GiB | Coding | [devstral2.md](../../../models/families/devstral.md) |
| InternVL3-38B | ~22 GiB | Vision (Computer Use) | [internvl.md](../../../models/families/internvl.md) |

**Запуск:**

Использовать пресеты из [`scripts/inference/vulkan/preset/`](../../../../scripts/inference/vulkan/preset/).

**URL:** `http://192.168.1.77:8081/v1`

### Ollama

```yaml
providers:
  ollama:
    type: openai-compatible
    base_url: "http://localhost:11434/v1"
    api_key: "ollama"
    default_model: "qwen3-coder:latest"
```

### vLLM

```yaml
providers:
  vllm:
    type: openai-compatible
    base_url: "http://localhost:8000/v1"
    api_key: "not-needed"
    default_model: "qwen3-coder-next"
```

### Ограничения локальных моделей

| Параметр | Cloud (Kimi K2.5) | Локальная (Qwen3-Coder) |
|----------|-------------------|------------------------|
| Context window | 256K | 32K-128K |
| Tool use quality | Высокое | Зависит от модели |
| Vision | Встроенное | Отдельный mmproj |
| Скорость (t/s) | ~80-100 | ~15-40 (Strix Halo) |
| Стоимость | Pay-per-token | Электричество |
| Приватность | Данные уходят в cloud | Полная приватность |

---

## Переключение между провайдерами

### Hot-switch

В UI: выбрать другого провайдера и модель в текущей сессии.
Контекст сессии сохраняется -- провайдер меняется "на лету".

### Fallback chains

Конфигурация автоматического переключения при недоступности primary провайдера:

```yaml
providers:
  primary: kimi
  fallback:
    - openai
    - local
  fallback_timeout_ms: 5000
```

При timeout от Kimi -- запрос автоматически перенаправляется в OpenAI.
При недоступности OpenAI -- на локальную модель.

### Cost optimization

Роутинг задач по стоимости и сложности:

| Категория задачи | Рекомендуемый провайдер | Стоимость |
|-----------------|----------------------|-----------|
| Простые вопросы, суммаризация | Локальная модель | Бесплатно |
| Coding, tool use | Qwen3-Coder local или Kimi K2.5 | Низкая |
| Complex reasoning, multi-step | GPT-5.3 или Claude Opus | Высокая |
| Vision, Computer Use | InternVL3 local или Gemini 3 | Низкая-средняя |

Конфигурация task-based routing:
```yaml
routing:
  rules:
    - pattern: "simple_question"
      provider: local
    - pattern: "coding"
      provider: kimi
    - pattern: "complex_reasoning"
      provider: openai
      model: gpt-5.3-codex
```

---

## Миграция с Claude Code на OpenClaw

### Что переносится

| Компонент | Совместимость | Примечания |
|-----------|--------------|------------|
| MCP-серверы | Полная | Конфигурация идентична |
| Workflow patterns | Частичная | Промпты и задачи переносятся, формат другой |
| Git-related workflows | Полная | GitHub MCP одинаковый |

### Что НЕ переносится

| Компонент | Причина | Альтернатива в OpenClaw |
|-----------|---------|----------------------|
| Claude Code Skills (`.claude/skills/`) | Формат несовместим | OpenClaw Skills (YAML) |
| Claude Code Hooks (`settings.json`) | Несовместимы | Webhook triggers |
| CLAUDE.md project instructions | Формат Claude-specific | OpenClaw config.yaml |
| Agent Teams (sub-agents) | Нет аналога | Single agent + MCP tools |
| `/compact`, `/clear` и др. UI-команды | CLI-specific | WebChat UI controls |

### Пошаговый план миграции

1. Установить OpenClaw ([deployment-guide.md](deployment-guide.md)).
2. Настроить провайдер: Kimi K2.5 (cloud) или Qwen3-Coder local (приватность).
3. Перенести MCP server definitions -- формат практически идентичен
   (`.claude/settings.json` -- `mcpServers` в OpenClaw `config.yaml` -- `mcp_servers`).
4. Воссоздать workflows из CLAUDE.md и `.claude/skills/` в OpenClaw Skills.
5. Протестировать: coding через WebChat, GitHub PR через MCP, мессенджеры.
6. Параллельная работа 1-2 недели, после стабилизации -- переключение.

### Выбор replacement-модели

| Задача в Claude Code | Модель Claude Code | Замена в OpenClaw | Обоснование |
|---------------------|-------------------|-------------------|-------------|
| Coding (основная) | Opus 4.6 | Kimi K2.5 / GPT-5.3 | Близкий SWE-bench, reasoning |
| Quick edits | Sonnet 4.5 | Qwen3-Coder local | Быстро, бесплатно |
| Code review | Opus 4.6 | GPT-4.1 | Баланс цены и качества |
| Multi-file refactor | Opus 4.6 | Kimi K2.5 | Long context + reasoning |
| Documentation | Sonnet 4.5 | Qwen 3.6-Plus | Дёшево, достаточное качество |

---

## Связанные статьи

- [README.md](README.md) -- профиль OpenClaw
- [deployment-guide.md](deployment-guide.md) -- Docker setup, подключение к llama-server
- [news.md](news.md) -- хронология блокировки Anthropic
- [integrations-guide.md](integrations-guide.md) -- настройка каналов и MCP
- [Кодинг модели](../../../models/coding.md) -- сравнительная таблица
- [Kimi K2.5](../../../models/families/kimi-k25.md) -- рекомендуемый default провайдер
