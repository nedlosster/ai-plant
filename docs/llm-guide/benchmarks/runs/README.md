# Прогоны бенчмарков на платформе

Каталог отчётов о прогонах бенчмарков на Strix Halo сервере. Каждая статья -- один прогон одной модели на одном бенчмарке, с полным контекстом: версии стека, параметры, результаты, анализ.

## Назначение

В отличие от `results.md` (краткий лидерборд), статьи в этом каталоге сохраняют **полный контекст**:

- Версии llama.cpp, ядра, Mesa, aider
- Параметры llama-server (контекст, parallel, cache-reuse)
- Per-language / per-category breakdown
- Хронологию выполнения
- Анализ сильных и слабых сторон модели
- Что пошло не так и почему
- Что делать дальше (next steps)

Это позволяет:

- **Сравнивать прогоны** между собой (например, после обновления llama.cpp)
- **Отслеживать регрессии** при апгрейдах
- **Воспроизводить** прогон с теми же параметрами через несколько месяцев

## Соглашение об именовании

```
<YYYY-MM-DD>-<benchmark>-<mode>-<model>.md
```

Примеры:

- [2026-04-26-aider-smoke-qwen3.6-35b.md](2026-04-26-aider-smoke-qwen3.6-35b.md) -- реальный
- `2026-05-15-aider-full-qwen-coder-next.md` (гипотетический)
- `2026-06-01-terminal-bench-devstral.md` (гипотетический)

## Шаблон статьи

См. [2026-04-26-aider-smoke-qwen3.6-35b.md](2026-04-26-aider-smoke-qwen3.6-35b.md) как референс. Обязательные секции:

- **Шапка**: дата, mode, scope, total time, статус (завершён / прерван), ссылки на лог
- **Среда**: hardware, kernel, Mesa, llama.cpp, aider/harness, Docker image
- **Параметры модели и benchmark**: точные команды для воспроизводимости
- **Pre-flight**: чек-лист готовности
- **Результаты**: агрегатные показатели, per-language/category breakdown, хронология
- **Анализ**: сильные стороны, слабые стороны, edit format quality
- **Root cause**: если что-то пошло не так -- разобраться почему
- **Выводы**: 5-7 пунктов
- **Next steps**: что делать дальше -- как чек-лист

## Доступные прогоны

| Дата | Бенчмарк | Mode | Модель | Pass rate | Статья |
|------|----------|------|--------|-----------|--------|
| 2026-04-26 | Aider Polyglot | smoke 20 (clean ✓, A/B) | Qwen3-Coder 30B-A3B | **15.0%** (3/20, **17 сек/задача!**) | [2026-04-26-aider-smoke-qwen3-coder-30b](2026-04-26-aider-smoke-qwen3-coder-30b.md) |
| 2026-04-26 | Aider Polyglot | smoke 20 (clean ✓) | Qwen3.6-35B-A3B | **35.0%** (single-shot, 20/20) | [2026-04-26-aider-smoke-qwen3.6-35b-clean](2026-04-26-aider-smoke-qwen3.6-35b-clean.md) |
| 2026-04-26 | Aider Polyglot | smoke (прерван) | Qwen3-Coder Next 80B-A3B | 36.7% / 46.7% (на 30 задачах) | [2026-04-26-aider-smoke-qwen-coder-next](2026-04-26-aider-smoke-qwen-coder-next.md) |
| 2026-04-26 | Aider Polyglot | smoke (прерван) | Qwen3.6-35B-A3B | 27.3% / 54.5% (на 22 задачах) | [2026-04-26-aider-smoke-qwen3.6-35b](2026-04-26-aider-smoke-qwen3.6-35b.md) |

## Связанные статьи

- [results.md](../results.md) -- лидерборд и краткий журнал
- [runbooks/](../runbooks/README.md) -- инструкции запуска бенчмарков
- [README.md](../README.md) -- индекс бенчмарков
- [inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- бэклог идей ускорения на базе наблюдений из прогонов
