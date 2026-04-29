# Бенчмарки на платформе Strix Halo

Прогоны coding-бенчмарков на inference-сервере: leaderboard платформы, runbooks для запуска, история запусков с детальными отчётами.

**Методология самих бенчмарков** (что измеряет HumanEval, как устроен SWE-bench, проблемы contamination/насыщения) -- в [docs/llm-guide/benchmarks/](../../llm-guide/benchmarks/). Это разделение: там -- "что такое benchmark X", здесь -- "как мы тестировали модель Y на нашей платформе".

## Содержимое

| Раздел | Назначение |
|--------|------------|
| [results.md](results.md) | Лидерборд платформы и журнал прогонов (append-only) |
| [runbooks/](runbooks/README.md) | Инструкции по запуску бенчмарков локально (Aider Polyglot, Terminal-Bench 2.0) |
| [runs/](runs/README.md) | Полные статьи по конкретным прогонам (среда, параметры, результаты, анализ) |

## Бенчмарки на платформе

Для практического тестирования моделей на Strix Halo сервере подготовлены runbooks:

| Бенчмарк | Задач | Время | Уровень | Runbook |
|----------|-------|-------|---------|---------|
| Aider Polyglot smoke | 20-50 | 1-5 ч | быстрая проверка | [runbooks/aider-polyglot.md](runbooks/aider-polyglot.md) |
| Aider Polyglot full | 195-225 | 14-25 ч | полный leaderboard-quality | [runbooks/aider-polyglot.md](runbooks/aider-polyglot.md) |
| Terminal-Bench 2.0 | 56 | 1-2 ч | tool use в shell | [runbooks/terminal-bench.md](runbooks/terminal-bench.md) |

Стандартный порядок: smoke → full → tool-use. Результаты накапливаются в [results.md](results.md).

Подробности и decision tree -- в [runbooks/README.md](runbooks/README.md).

## Стратегия выбора бенчмарков для платформы

| Бенчмарк | Когда использовать |
|----------|-------------------|
| **Aider Polyglot --tries 2** | Основной критерий выбора agent-coding модели. Включает retry с error feedback (реалистично для production aider/opencode/Cline) |
| **Aider Polyglot --tries 1** | Single-shot оценка -- для FIM сценариев и быстрой sanity check |
| **Terminal-Bench 2.0** | Замер tool use на bash/git/debugging задачах -- для opencode-сценариев |
| llama-bench (pp/tg) | Не оценка качества, но критично для выбора квантизации и параметров запуска |

## Связано

- [docs/llm-guide/benchmarks/](../../llm-guide/benchmarks/) -- методология бенчмарков (что измеряет HumanEval, SWE-bench, MMMU и др.)
- [docs/models/coding.md](../../models/coding.md) -- каталог coding-моделей платформы
- [docs/models/closed-source-coding.md](../../models/closed-source-coding.md) -- closed-source frontier для сравнения
- [docs/ai-agents/comparison.md](../../ai-agents/comparison.md) -- сравнение AI-агентов (использует Faros.ai bench)
- [docs/inference/optimization-backlog.md](../../inference/optimization-backlog.md) -- бэклог оптимизаций по результатам прогонов
- [coding/news.md](../news.md) -- хроника AI-кодинга (новые модели, релизы, важные обновления)
- [coding/workflows.md](../workflows.md) -- workflow рекомендации (FIM + agent, multi-agent)
