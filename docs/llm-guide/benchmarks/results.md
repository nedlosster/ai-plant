# Бенчмарки на платформе: журнал результатов

Append-only журнал прогонов бенчмарков на Strix Halo сервере. Каждая запись -- один прогон одной модели на одном бенчмарке.

Запуск -- через runbooks:
- [runbooks/aider-polyglot.md](runbooks/aider-polyglot.md)
- [runbooks/terminal-bench.md](runbooks/terminal-bench.md)

Индекс runbooks -- [runbooks/README.md](runbooks/README.md).

## Лидерборд платформы (Aider Polyglot)

| Модель | Smoke 50 | Full 225 | Дата smoke | Дата full |
|--------|----------|----------|------------|-----------|
| -- | -- | -- | -- | -- |

## Лидерборд платформы (Terminal-Bench 2.0)

| Модель | 56 tasks | Дата |
|--------|----------|------|
| -- | -- | -- |

## История прогонов

(Записи добавляются в начало списка, самые свежие сверху)

---

### Шаблон записи

```markdown
## YYYY-MM-DD: <Бенчмарк> <вариант> -- <Модель>

**Среда**: Strix Halo, Vulkan b<номер>, <квантизация>, llama-server `--parallel <N>`, контекст <N>K
**Задач**: <выполнено>/<всего>
**Время**: <hh>h <mm>m
**Pass rate**: <X>/<Y> = <Z>% (single-shot)
**По категориям/языкам**:
- <category>: <X>/<Y> (<Z>%)
- ...
**Edit format warnings** (для Aider): <N>
**Заметки**: <observations, anomalies, sequence>

Лог: `/tmp/<bench>-<model>-<timestamp>.log`
```

---

## Связанные статьи

- [runbooks/](runbooks/README.md) -- инструкции запуска
- [README.md](README.md) -- индекс бенчмарков, теория
- [coding/news.md](../../coding/news.md) -- хроника релизов моделей
- [models/coding.md](../../models/coding.md) -- каталог моделей
