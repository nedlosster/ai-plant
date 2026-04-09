# Qwen Code (Alibaba/Qwen team, 2025-2026)

> CLI-агент от Qwen team, multi-protocol (OpenAI/Anthropic/Gemini), optimized для Qwen3-Coder и Qwen3.6.

**Тип**: CLI (terminal)
**Лицензия**: Apache 2.0
**Backend**: Multi-protocol (OpenAI / Anthropic / Gemini-compatible)
**Совместим с локальным llama-server**: **да** (через OpenAI endpoint)
**Цена**: Free open-source + Qwen OAuth (1000 req/день бесплатно)

## Обзор

Qwen Code -- открытый CLI агент от команды Qwen. "Лежит в твоём терминале" и помогает понимать большие кодбейзы, автоматизировать рутину, доставлять фичи быстрее. По духу аналог Claude Code и opencode -- agentic loop с tool use, planning, sub-agents.

Главная фишка -- **multi-protocol authentication**: можно подключить любой OpenAI/Anthropic/Gemini-compatible endpoint, или авторизоваться через Qwen OAuth (1000 free requests/день на их облако). Для платформы это значит: подключается к локальному llama-server без танцев с прокси.

Заточен под Qwen-модели (Qwen3-Coder Next, Qwen3.6-Plus), но работает с любыми. Имеет GitHub Action для интеграции в CI.

## Возможности

- **Skills** -- переиспользуемые "инструкции-навыки" (аналог Claude Skills)
- **SubAgents** -- параллельные специализированные агенты
- **Plan Mode** -- режим планирования перед действием
- **Built-in tools** -- file ops, bash, search, edit, MCP
- **GitHub Action** -- code review, issue triage, modification в CI
- **Multi-protocol auth** -- OpenAI/Anthropic/Gemini APIs или Qwen OAuth
- **MCP support** -- расширение функциональности через MCP-серверы

## Сильные стороны

- **Native интеграция с Qwen-моделями** -- лучший опыт с Qwen3-Coder Next и Qwen3.6
- **Free tier через Qwen OAuth** -- 1000 запросов/день к Qwen3-Coder без оплаты, удобно для прототипирования
- **Multi-protocol** -- любой OpenAI-compatible endpoint, не привязан к одному провайдеру
- **GitHub Action из коробки** -- готовая CI/CD интеграция
- **Active development** от первой команды, делающей передовые open модели

## Слабые стороны / ограничения

- **Свежий проект** -- экосистема меньше чем у Claude Code или opencode
- **Лучше всего работает с Qwen-моделями** -- на других провайдерах могут быть quirks
- **Документация в основном на английском/китайском**
- **Меньше готовых MCP-серверов** в каталоге сообщества чем у Claude Code

## Базовые сценарии

- "Объясни этот кодбейз" -- модель читает дерево проекта и резюмирует архитектуру
- "Найди и исправь баг в X" -- read → analyze → edit → test
- "Сгенерируй тесты для модуля Y"
- "Обнови все импорты после переименования"
- "Рефактор файла X с применением паттерна Z"

## Сложные сценарии

- **Code review через GitHub Action** -- автоматический ревью PR с использованием Qwen-моделей
- **Issue triage** -- классификация и предложение fixes
- **Repo-level refactoring** через SubAgents -- параллельные подзадачи в разных файлах
- **Skills для повторяющихся задач** -- сохранить процесс как навык, переиспользовать
- **Migration major framework version** -- через Plan Mode + sub-agents

## Установка / запуск

```bash
# Установка через npm
npm install -g @qwen-code/qwen-code

# Или из исходников
git clone https://github.com/QwenLM/qwen-code
cd qwen-code && pnpm install && pnpm build

# Запуск с локальным llama-server
export OPENAI_BASE_URL=http://192.168.1.77:8081/v1
export OPENAI_API_KEY=local
qwen-code

# Запуск с Qwen OAuth (1000 free req/day)
qwen-code login  # OAuth flow
qwen-code

# В интерактивном режиме:
> Объясни архитектуру этого проекта
> Исправь баг в src/auth.ts
```

## Конфигурация

`~/.qwen/settings.json`:

```json
{
  "model": "qwen3-coder-next",
  "provider": "openai-compatible",
  "baseURL": "http://192.168.1.77:8081/v1",
  "apiKey": "local",
  "skills": ["code-review", "test-generation"],
  "subAgents": {
    "max_parallel": 4
  }
}
```

## Бенчмарки

Конкретных публичных бенчмарков самого CLI нет -- качество зависит от подключённой модели. С Qwen3-Coder Next:
- SWE-bench Verified: 70.6% (модель)
- Платформа: 53 tok/s генерации

## Анонсы и открытия

- **2026-03** -- интеграция с Qwen3.6-Plus (1M контекст) через Anthropic-protocol
- **2026-02** -- релиз GitHub Action для CI/CD
- **2026-01** -- добавлены SubAgents и Plan Mode
- **2025-Q4** -- первый публичный релиз CLI

## Ссылки

- [Официальный сайт](https://qwen.ai/qwencode)
- [GitHub: QwenLM/qwen-code](https://github.com/QwenLM/qwen-code)
- [Документация](https://qwenlm.github.io/qwen-code-docs/)
- [Tools intro](https://qwenlm.github.io/qwen-code-docs/en/developers/tools/introduction/)
- [GitHub Action integration](https://github.com/QwenLM/qwen-code/blob/main/docs/users/integration-github-action.md)
- [Qwen-Agent framework](https://github.com/QwenLM/Qwen-Agent) -- более широкий agent framework

## Связано

- **Альтернативы**: [opencode](opencode.md), [claude-code](claude-code.md), [cline](cline.md)
- **Лучшие модели для пары**: [qwen3-coder](../../models/families/qwen3-coder.md), [qwen36](../../models/families/qwen36.md)
- **Платформа**: [coding.md](../../models/coding.md)
- **Концепты**: [../README.md](../README.md)
