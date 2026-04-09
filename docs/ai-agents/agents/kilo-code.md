# Kilo Code (kilocode.app, 2025-2026)

> Open-source AI coding agent для VS Code/JetBrains/CLI, форк Roo Code (который форк Cline). Orchestrator mode и multi-agent.

**Тип**: VS Code extension + JetBrains plugin + CLI
**Лицензия**: Apache 2.0
**Backend**: 500+ моделей через OpenAI/Anthropic/local APIs
**Совместим с локальным llama-server**: **да** (OpenAI-compatible)
**Цена**: Free + bring-your-own-key, или Kilo Pass от $19/мес (zero markup)

## Обзор

Kilo Code -- быстрорастущий open-source coding agent для VS Code (плюс JetBrains и CLI). Форк Roo Code, который сам форк Cline. Стартовал с целью **rapid iteration** -- быстрое экспериментирование с фичами, которое раскачали в полноценный agent.

Главная фишка -- **Orchestrator mode**: разбивает сложную задачу на под-задачи и распределяет их между специализированными суб-агентами (planner, coder, debugger). Это аналог multi-agent подхода, но в одном продукте без необходимости настраивать инфраструктуру.

В 2026: 1.5M+ пользователей, 302B токенов/день, $8M seed funding -- самый быстрорастущий VS Code AI extension.

## Возможности

- **Orchestrator mode** -- автоматическая декомпозиция задачи на planner/coder/debugger sub-agents
- **Inline autocomplete** -- FIM-стиль автодополнение
- **Browser automation** -- agent может управлять браузером
- **Automated refactoring** -- multi-file refactoring с пониманием зависимостей
- **Custom modes** -- planning, coding, debugging как отдельные режимы
- **500+ моделей** -- OpenAI, Anthropic, Google, локальные через OpenAI-compatible
- **Memory Bank** -- персистентная память между сессиями
- **Voice commands** -- голосовой ввод задач
- **Cloud agents** -- запуск на серверах Kilo (опционально)
- **VS Code, JetBrains, CLI** -- три интерфейса в одном продукте
- **Custom modes** -- определять свои режимы под задачи

## Сильные стороны

- **Orchestrator mode уникален в open-source** -- multi-agent декомпозиция в коробке
- **Самый быстрорастущий VS Code AI** -- активная разработка, регулярные релизы
- **Поддержка локальных моделей** через OpenAI-compatible API
- **Zero markup на pay-as-you-go** через Kilo Pass -- честная цена
- **Voice + Memory Bank** -- accessibility и контекст между сессиями
- **Три интерфейса** (VS Code, JetBrains, CLI) -- покрытие всех IDE
- **Browser use** -- web research и тестирование UI прямо из агента

## Слабые стороны / ограничения

- **Сложнее в настройке** чем Cline из-за большого количества фич
- **Custom modes требуют времени** на освоение
- **Документация догоняет фичи** -- что-то приходится разбираться через GitHub
- **Cloud agents** -- ещё в раннем development
- **Зависит от качества модели** -- Orchestrator особенно хорош с большими (Claude Sonnet, GPT-5, Qwen3.6)

## Базовые сценарии

- "Создай React-компонент Button с TypeScript и тестами"
- "Найди и исправь все TypeScript ошибки в файле"
- "Объясни этот код" с inline-подсветкой
- Inline autocomplete во время написания

## Сложные сценарии

- **"Реализуй фичу X"** -- Orchestrator разбивает на: 
  1. Planner → дизайн архитектуры
  2. Coder → реализация
  3. Debugger → тесты и багфиксы
- **Migration framework version** -- координация изменений в десятках файлов
- **Browser-driven testing** -- agent открывает браузер, проверяет UI, исправляет CSS
- **Refactoring legacy code** через Memory Bank -- помнит контекст между сессиями
- **Voice-driven coding** -- "сделай вот этот endpoint POST с авторизацией" голосом

## Установка / запуск

### VS Code

```
1. Открыть VS Code
2. Extensions → искать "Kilo Code"
3. Install
4. Открыть Kilo Code panel (sidebar)
5. Settings → Provider → выбрать backend
```

### Подключение к локальному llama-server

```
Provider: OpenAI Compatible
Base URL: http://192.168.1.77:8081/v1
API Key: local (любая строка)
Model: qwen3-coder-next
```

### CLI

```bash
npm install -g @kilocode/cli
kilo --help
```

### JetBrains

Plugin Marketplace → искать "Kilo Code" → Install.

## Конфигурация

В Settings panel:
- **Provider**: OpenAI / Anthropic / OpenAI Compatible / Google / etc
- **Custom Modes**: создать свой режим (например "PR Reviewer")
- **Memory Bank**: файлы для контекста проекта
- **Auto-approve**: какие действия выполнять без подтверждения
- **Voice Commands**: enable/disable

## Бенчмарки

Бенчмарки агента отдельно не публикуются -- зависят от модели. С Claude Sonnet 4.5 в Orchestrator mode -- сравним с Claude Code на сложных задачах.

## Анонсы и открытия

- **2026-04** -- 1.5M пользователей, 302B токенов/день
- **2026-03** -- $8M seed funding announcement
- **2026-Q1** -- Voice commands, Memory Bank, JetBrains support
- **2025-Q4** -- Orchestrator mode (флагманская фича)
- **2025** -- форк Roo Code, начало разработки

## Ссылки

- [Официальный сайт](https://kilocode.app/) ([альтернативный домен](https://kilo.ai/))
- [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=kilocode.Kilo-Code)
- [Сравнение Kilo vs Cline vs Roo Code](https://adam.holter.com/kilo-code-the-hybrid-ai-coding-assistant-that-combines-cline-and-roo-code-for-cost-effective-development/)
- [Review (vibecoding)](https://vibecoding.app/blog/kilo-code-review)
- [GitHub Kilo Code](https://github.com/Kilo-Org/kilocode)

## Связано

- **Альтернативы**: [cline](cline.md), [roo-code](roo-code.md), [continue-dev](continue-dev.md)
- **Лучшие модели для пары**: [qwen3-coder](../../models/families/qwen3-coder.md), [claude-code](claude-code.md) для платных моделей
- **Платформа**: [coding.md](../../models/coding.md)
- **Концепты**: [../README.md](../README.md)
