# AI-кодинг: локальный inference для разработки

Платформа: Radeon 8060S (96 GiB VRAM), llama-server + Vulkan.

## Что дает AI для кодинга

- **Автодополнение** -- предсказание следующего кода по контексту (аналог GitHub Copilot)
- **Chat** -- объяснение кода, генерация по описанию, ответы на вопросы
- **Рефакторинг** -- автоматическое изменение кода в нескольких файлах
- **Code review** -- поиск ошибок, уязвимостей, стилевых нарушений
- **Генерация тестов** -- unit-тесты по исходному коду
- **Debugging** -- анализ трейсбеков, поиск причин ошибок
- **AI-агенты** -- автономное решение задач (Aider, SWE-agent)

Все это работает локально, без облачных сервисов, на данной платформе.

## Архитектура

Рекомендуемая схема -- два экземпляра llama-server:

```
IDE (VS Code / Neovim / JetBrains)
  |
  +-- Continue.dev / llama.vscode
  |     |
  |     +-- [autocomplete] --> llama-server :8081
  |     |                      Qwen2.5-Coder-1.5B (FIM)
  |     |                      /infill endpoint
  |     |
  |     +-- [chat/edit]    --> llama-server :8080
  |                            Qwen2.5-Coder-32B
  |                            /v1/chat/completions
  |
  +-- Cline / Roo Code     --> llama-server :8080
  |
Terminal
  +-- Aider                --> llama-server :8080
  +-- SWE-agent            --> llama-server :8080
```

Маленькая модель (1.5-7B) для быстрого автодополнения (<500ms). Большая модель (32B+) для chat, рефакторинга, агентных задач.

## Что выбрать

| Задача | Инструмент | Модель |
|--------|-----------|--------|
| Автодополнение в IDE | Continue.dev / llama.vscode | Qwen2.5-Coder-1.5B (FIM) |
| Chat в IDE | Continue.dev / Cline | Qwen2.5-Coder-32B |
| Рефакторинг (терминал) | Aider | Qwen2.5-Coder-32B |
| Рефакторинг (IDE) | Cline / Roo Code | Qwen2.5-Coder-32B |
| Решение issues | SWE-agent | Qwen3-Coder-Next 80B MoE |
| Code review | Roo Code (Security Reviewer) | Qwen2.5-Coder-32B |

## Документация

| N | Документ | Описание |
|---|----------|----------|
| 1 | [Модели](models.md) | Рейтинг, FIM-совместимость, VRAM, рекомендации |
| 2 | [Настройка сервера](server-setup.md) | llama-server: два экземпляра, router mode, systemd |
| 3 | [IDE-интеграция](ide-integration.md) | Continue.dev, llama.vscode, Cline, Roo Code, avante.nvim |
| 4 | [AI-агенты](agents.md) | Aider, SWE-agent, OpenHands, Mistral Vibe |
| 5 | [Сценарии](scenarios.md) | Автодополнение, chat, рефакторинг, review, тесты, debug |
| 6 | [Промпт-инжиниринг](prompts.md) | Системные промпты, шаблоны, best practices |
| 7 | [OpenCode](opencode/) | TUI-агент: установка, конфигурация, стратегии, сравнение с Claude Code |

Рекомендуемый порядок: 1 -> 2 -> 3 -> 5 -> 4 -> 7 -> 6.
