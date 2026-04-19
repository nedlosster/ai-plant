# Qwen3.6 (Alibaba, апрель 2026)

> "First real agentic LLM" (Alibaba). Флагман нового поколения Qwen для агентного кодинга и multimodal reasoning. Open weights ожидаются.

**Тип**: не раскрыто (предположительно MoE)
**Лицензия**: API-only пока (open-варианты обещаны)
**Статус на сервере**: **ожидается open-weights**
**Направления**: [coding](../coding.md), [llm](../llm.md), [vision](../vision.md)

## Обзор

Qwen3.6-Plus -- релиз от Alibaba / Tongyi Lab (2 апреля 2026). Позиционируется как "first real agentic LLM" -- флагман нового поколения, ориентированный на agentic coding и multimodal задачи. По заявлению Alibaba -- "в одном весовом классе с Claude 4.5 Opus" на agentic coding benchmarks.

Ключевое отличие от предшественников -- полный цикл автономной разработки: планирование, написание кода, тестирование и итеративная доработка без вмешательства пользователя. Модель способна работать на уровне репозитория (repository-level engineering) -- от декомпозиции задачи до финальной интеграции.

**На момент апреля 2026 модель API-only** -- весов на HuggingFace ещё нет. Alibaba обещает: *"продолжим поддерживать open-source community с отдельными Qwen3.6 моделями в developer-friendly размерах"*.

По аналогии с релизом Qwen3.5 (где сначала был большой 397B-MoE через API, потом открыли 27B / 35B-A3B / 122B-A10B варианты) -- через 1-3 месяца можно ожидать open-варианты в диапазоне 30-122B.

## Варианты

| Вариант | Параметры | Контекст | Output | Статус | Доступ |
|---------|-----------|----------|--------|--------|--------|
| Qwen3.6-Plus | не раскрыто | **1M токенов** | 65K | API-only | [Alibaba Cloud Model Studio](https://www.alibabacloud.com/product/modelstudio), [OpenRouter](https://openrouter.ai/) (бесплатно в preview) |
| Qwen3.6 (open variants) | -- | -- | -- | **ожидается** | -- |

## Архитектура и особенности

- **Контекст 1M токенов** по умолчанию (Qwen3.5 был 256K)
- **Output до 65K токенов** -- длинные ответы без обрезаний
- **Always-on chain-of-thought** -- thinking-режим включён по умолчанию
- **Reasoning preservation** -- сохранение thinking context между сообщениями (reasoning chain не теряется при multi-turn)
- **Native function calling**
- **Multimodal** -- text + vision
- **Screenshot-to-code** -- генерация фронтенда из скриншотов и дизайн-макетов
- **Anthropic API protocol** -- работает с [Claude Code](../../ai-agents/agents/claude-code/README.md) и совместимыми клиентами

## Сильные кейсы

- **Agentic coding** -- автономное планирование, написание, тестирование и итеративная доработка кода; production-ready решения
- **Repository-level engineering** -- полный цикл от декомпозиции задачи до финальной интеграции
- **Контекст 1M** -- весь репозиторий + история обсуждений + документация в одном запросе
- **Frontend development** -- интерпретация скриншотов UI, wireframes, прототипов и генерация функционального frontend-кода
- **Document understanding** + multimodal reasoning
- **Сложные workflow** в agent-инструментах ([Claude Code](../../ai-agents/agents/claude-code/README.md), [opencode](../../ai-agents/agents/opencode.md), [Aider](../../ai-agents/agents/aider.md), [Cline](../../ai-agents/agents/cline.md))

## Слабые стороны / ограничения

- **Сейчас нет open weights** -- только API
- **Параметры/архитектура не раскрыты** -- закрытый флагман
- **Конкретных бенчмарков нет** -- Alibaba делает акцент на "workflow performance", не на синтетических метриках
- **Зависимость от облака** -- privacy и стоимость

## Идеальные сценарии применения (когда появятся open weights)

- **[opencode](../../ai-agents/agents/opencode.md) / [Claude Code](../../ai-agents/agents/claude-code/README.md) / [Aider](../../ai-agents/agents/aider.md) / [Cline](../../ai-agents/agents/cline.md)** -- бэкенд для agent-style кодинга
- **Long-context RAG** на больших корпусах документов
- **Screenshot-to-code** -- генерация UI компонентов из дизайнов
- **Multimodal agents** -- задачи с visual вводом + tool use

## Доступ сейчас (API)

```bash
# Через Alibaba Cloud Model Studio
# Документация: https://www.alibabacloud.com/product/modelstudio

# Через OpenRouter (бесплатно в preview-период)
# https://openrouter.ai/

# Совместимые клиенты:
# - Claude Code (через Anthropic API protocol) -- ../../ai-agents/agents/claude-code/README.md
# - opencode (через OpenAI-compatible endpoint) -- ../../ai-agents/agents/opencode.md
# - Qwen Code, Kilo Code, Cline, OpenClaw -- см. ../../ai-agents/agents/
```

## Загрузка (когда появятся open weights)

Когда Alibaba опубликует open-варианты на HuggingFace Qwen org -- проверять:

- [https://huggingface.co/Qwen](https://huggingface.co/Qwen) -- основной канал релизов
- [https://github.com/QwenLM](https://github.com/QwenLM) -- анонсы
- [https://qwen.ai/](https://qwen.ai/) -- официальный сайт

После релиза создать пресет в [`scripts/inference/vulkan/preset/`](../../../scripts/inference/vulkan/preset/) (файл `qwen3.6-<variant>.sh`) и обновить этот файл (заполнить таблицу вариантов, переключить статус на "не скачана").

## Бенчмарки

| Бенч | Значение |
|------|----------|
| Agentic coding (Alibaba claim) | "в одном классе с Claude 4.5 Opus" |
| SWE-bench Verified | не публикуется |
| HumanEval | не публикуется |

## Что отслеживать

1. **Qwen org на HuggingFace** -- появление файлов с "Qwen3.6" в названии
2. **GitHub QwenLM** -- анонсы релизов
3. **Размер open-вариантов** -- по аналогии с Qwen3.5 ожидать 27B / 35B-A3B / 122B-A10B диапазон
4. **GGUF-квантизации** -- bartowski, unsloth, mradermacher обычно публикуют в течение недели после релиза

После релиза:
- Создать пресет в [`scripts/inference/vulkan/preset/`](../../../scripts/inference/vulkan/preset/) (файл `qwen3.6-*.sh`)
- Заполнить таблицу вариантов в этом файле
- Запустить `/models-catalog sync-status`
- Перенести запись в README из "Ожидается open weights" в "Стоит обратить внимание" или "Скачано"

## Источники

- [Qwen Blog: Qwen 3.6-Plus](https://qwen.ai/blog?id=qwen3.6)
- [Qwen 3.6-Plus Review (BuildFastWithAI)](https://www.buildfastwithai.com/blogs/qwen-3-6-plus-preview-review)
- [Constellation Research](https://www.constellationr.com/insights/news/alibabas-qwen-launches-new-flagship-llm-qwen-36-plus)
- [Alibaba Cloud blog: Qwen3.6-Plus Towards Real World Agents](https://www.alibabacloud.com/blog/qwen3-6-plus-towards-real-world-agents_603005)
- [Caixin Global: Enhanced Coding Capabilities](https://www.caixinglobal.com/2026-04-02/alibaba-releases-qwen-36-plus-ai-model-with-enhanced-coding-capabilities-102430395.html)

## Связано

- Направления: [coding](../coding.md), [llm](../llm.md), [vision](../vision.md)
- Предыдущее поколение: [qwen35](qwen35.md) (текущий лучший локальный general-purpose Qwen)
- Альтернатива для agent-coding локально: [qwen3-coder](qwen3-coder.md) (Next 80B-A3B, 70.6% SWE-V)
