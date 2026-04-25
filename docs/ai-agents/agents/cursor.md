# Cursor 3 (Anysphere, 2023-2026)

> Самый популярный AI IDE -- VS Code fork с глубокой AI-интеграцией, Composer 2, Background Agents, multi-agent workspace.

**Тип**: IDE (VS Code fork)
**Лицензия**: Proprietary
**Backend**: Composer 2 (proprietary, Kimi K2.5 base) / Anthropic / OpenAI / BYOK
**Совместим с локальным llama-server**: **частично** (через bring-your-own-key, но IDE проприетарная)
**Цена**: Free Hobby / $20 Pro / $40 Team
**ARR**: $500M (Q1 2026), вошёл в $1B+ ARR-клуб (декабрь 2025)

## Обзор

Cursor от Anysphere -- лидер AI IDE категории. Это fork VS Code с глубокой AI-интеграцией: всё что VS Code умеет + Composer (multi-file задачи), Tab (предсказательное автодополнение), Agent mode (автономные изменения), Background Agents (параллельная работа в фоне).

Самое большое community среди AI-IDE. Привлекает разработчиков знакомым VS Code интерфейсом и высоким качеством AI-фич.

В 2026 -- продолжает доминировать через регулярные обновления, недавнее приобретение Supermaven (быстрый autocomplete), и расширение Background Agents для параллельной работы.

## Возможности

- **Composer** -- интерфейс для multi-file задач, аналог agent panel
- **Tab** -- контекстное автодополнение с предсказанием следующего действия (Supermaven)
- **Agent mode** -- автономное multi-file редактирование по описанию
- **Background Agents** -- агент работает в фоне, пока разработчик занят другим
- **Cloud agents (Cursor 3)** -- запуск задач на изолированных VM в managed-окружении
- **Self-hosted agents (Cursor 3)** -- развёртывание агентов на собственной инфраструктуре
- **Parallel Agent Tabs (Cursor 3)** -- несколько вкладок-агентов параллельно, каждая со своим контекстом
- **/worktree (Cursor 3)** -- команда для isolated branch changes, агент работает в отдельном git-worktree
- **Chat** -- классический чат с моделью + контекст файлов
- **Cmd+K** -- inline edit прямо в коде
- **@-references** -- быстро добавить файлы/папки/документы в контекст
- **Codebase indexing** -- семантический поиск по проекту
- **Multi-tab Composer** -- несколько параллельных задач
- **Models bring-your-own-key** -- можно подключить Anthropic/OpenAI ключ или OpenAI-compatible

## Сильные стороны

- **$20/мес -- доступно** для большинства разработчиков
- **Background Agents** -- параллельная работа без блокировки IDE
- **Supermaven autocomplete** -- быстрейший в категории
- **Самое большое community** среди AI IDE
- **Знакомый VS Code интерфейс** -- нулевая кривая обучения для VS Code-пользователей
- **Composer** -- удобный интерфейс для агентных задач
- **Codebase indexing** -- быстрый семантический поиск
- **Стабильность** -- проверенный продукт в production у миллионов

## Слабые стороны / ограничения

- **Только VS Code fork** -- нет поддержки JetBrains, vim, emacs
- **Нет CLI-режима** -- терминальный workflow невозможен
- **Закрытый код** -- нельзя модифицировать
- **Проприетарные модели** для Tab autocomplete
- **Платный** -- $20+/мес (хотя есть Hobby)
- **Vendor lock-in** -- настройки и история привязаны к Cursor
- **Локальные модели сложнее настроить** чем у opencode/Cline

## Базовые сценарии

- Cmd+K → "convert this to TypeScript"
- @file references в чате -- "посмотри @auth.ts и @user.ts, объясни связь"
- Tab autocomplete во время написания
- Composer: "создай форму регистрации с валидацией"

## Сложные сценарии

- **Background Agents для длинных задач** -- "напиши тесты для всех модулей" в фоне, продолжаешь работать
- **Multi-tab Composer** -- 3-4 параллельных задачи в разных файлах
- **Refactor через Composer** -- "разделить большой класс на сервисы" с координацией across files
- **Codebase Q&A** -- "где у нас обрабатывается аутентификация" -- семантический поиск
- **Bring-your-own-key**: подключить Claude Opus или GPT-5 для сложных задач
- **Cursor Rules** (`.cursorrules`) -- проектные правила и предпочтения

## Установка / запуск

```bash
# Скачать с https://cursor.sh/
# Или через brew (macOS)
brew install --cask cursor

# Linux
# AppImage с https://cursor.sh/

# Открыть проект
cursor /path/to/project
```

### Подключение локального llama-server (через bring-your-own-key)

В Settings → Models → Add Custom Model:
- Provider: OpenAI Compatible
- Base URL: `http://192.168.1.77:8081/v1`
- API Key: `local`
- Model: `qwen3-coder-next`

## Конфигурация

`.cursorrules` в корне проекта -- проектные правила:

```
You are an expert React/TypeScript developer.
- Use functional components with hooks
- Always add JSDoc to public functions
- Prefer named exports
- Test with Vitest
```

`.cursor/rules/` -- многофайловые правила (новый формат).

## Бенчмарки

Конкретных бенчмарков самого Cursor не публикуется -- зависит от модели. С Claude Sonnet 4.5 -- сравним с Claude Code на большинстве задач.

## Анонсы и открытия

- **22 Apr 2026** -- **SpaceX подписал $60B option** на покупку Cursor (Anysphere). Совместная разработка AI-coding на суперкомпьютере **Colossus**. Cursor пока сохраняет операционную независимость до исполнения опциона. Источники: [9to5Mac](https://9to5mac.com/), [The New Stack](https://thenewstack.io/)
- **Apr 2026** -- релиз **Cursor 3**: unified workspace для управления командой агентов, **cloud agents** на изолированных VM, **/worktree** для isolated branch changes, **self-hosted agents**, **Parallel Agent Tabs**. Внутренняя метрика: **30% PR в самом Cursor сделаны агентами**
- **19 Mar 2026** -- релиз **Composer 2**: проприетарная coding-модель третьего поколения, построена поверх Moonshot AI Kimi K2.5 c continued pretraining и large-scale RL
- **2026-Q1** -- интеграция с Claude Sonnet 4.5 как default
- **Dec 2025** -- $1B+ ARR (одновременно с GitHub Copilot и Claude Code)
- **2025-Q4** -- приобретение Supermaven (быстрый autocomplete)
- **2025-Q3** -- Background Agents запущены
- **2025** -- Composer как основной интерфейс агентов
- **2023** -- первый релиз, быстрый рост

## Ссылки

- [Официальный сайт](https://cursor.sh/)
- [Pricing](https://cursor.sh/pricing)
- [Документация](https://docs.cursor.com/)
- [Cursor Forum](https://forum.cursor.com/)

## Связано

- **Альтернативы (IDE с открытым кодом)**: [cline](cline.md), [kilo-code](kilo-code.md), [continue-dev](continue-dev.md)
- **Альтернативы (CLI)**: [claude-code](claude-code/README.md), [opencode](opencode.md)
- **Платформа**: [coding.md](../../models/coding.md) -- если нужны локальные модели, лучше использовать VS Code + Cline/Continue
- **Концепты**: [../README.md](../README.md)
