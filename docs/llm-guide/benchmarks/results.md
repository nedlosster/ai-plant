# Бенчмарки на платформе: журнал результатов

Append-only журнал прогонов бенчмарков на Strix Halo сервере. Каждая запись -- один прогон одной модели на одном бенчмарке.

Запуск -- через runbooks:
- [runbooks/aider-polyglot.md](runbooks/aider-polyglot.md)
- [runbooks/terminal-bench.md](runbooks/terminal-bench.md)

Индекс runbooks -- [runbooks/README.md](runbooks/README.md).
Полные статьи отдельных прогонов -- [runs/README.md](runs/README.md).

## Лидерборд платформы (Aider Polyglot)

| Модель | Smoke (≤50 задач) | Full 225 | Дата smoke | Дата full |
|--------|-------------------|----------|------------|-----------|
| Qwen3.6-35B-A3B (Q4_K_M) | **35.0%** single-shot на 20 задачах (clean ✓, no rust) | -- | 2026-04-26 (clean) | -- |
| Qwen3-Coder Next 80B-A3B (Q4_K_M) | 36.7% / 46.7% на 30 задачах (прерван) | -- | 2026-04-26 | -- |
| Qwen3.6-35B-A3B (Q4_K_M) | 27.3% / 54.5% на 22 задачах (прерван) | -- | 2026-04-26 | -- |

Формат: `pass_rate_1 / pass_rate_2` (single-shot / с retry, --tries 2).

## Лидерборд платформы (Terminal-Bench 2.0)

| Модель | 56 tasks | Дата |
|--------|----------|------|
| -- | -- | -- |

## История прогонов

Свежие сверху. Полные статьи -- в [runs/](runs/README.md).

### 2026-04-26: Aider Polyglot smoke 20 (clean ✓) -- Qwen3.6-35B-A3B

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M, llama-server `--parallel 4`, контекст 128K, Docker `aider-polyglot-bench:latest`
**Задач**: **20/20** (полный прогон, watchdog не срабатывал)
**Время**: **1h 11m**
**Pass rate**: 7/20 = **35.0%** (single-shot, --tries 1, no rust)
**По языкам**: C++ **2/4 (50%)**, Python 2/5 (40%), Go 1/3 (33%), Java 1/3 (33%), JavaScript 1/5 (20%), Rust исключён
**Edit format warnings**: 0 (100% well-formed, 0 malformed responses)
**Заметки**: Первый чистый прогон после правок инфраструктуры (commit d6582fe..cef5f2e). Watchdog не сработал, прогон завершился штатно. seconds_per_case 210.5 (vs 312 в предыдущем прерванном). 41 случай "forcing full prompt re-processing" в логе llama-server -- подтверждает что cache-reuse не работает на hybrid+multimodal модели.

Полная статья: [runs/2026-04-26-aider-smoke-qwen3.6-35b-clean.md](runs/2026-04-26-aider-smoke-qwen3.6-35b-clean.md)
Лог: `/tmp/aider-test-20260426-1858/runner.log` (на сервере)

### 2026-04-26: Aider Polyglot smoke (прерван) -- Qwen3-Coder Next 80B-A3B

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M, llama-server `--parallel 4`, контекст 256K, Docker `aider-polyglot-bench:latest`
**Задач**: 30/50 (прерван по timeout retry-loop -- aider застрял после 30-й задачи на 3 часа)
**Время**: 5h 3m (фактическая работа 2h 9m: 13:34--15:43, остальное retry-loop)
**Pass rate**: 11/30 = **36.7%** (single-shot), 14/30 = **46.7%** (с retry)
**По языкам**: Python **7/8 (87.5%)**, Java 2/5 (40%), C++ 1/3 (33%), Go 1/5 → 2/5 (20% / 40%), JavaScript 0/4 → 2/4 (0% / 50%), **Rust 0/5 (0%)**
**Edit format warnings**: 0 (100% well-formed)
**Заметки**: Single-shot выше чем у Qwen3.6 (+9.4pp), но retry почти не помогает (+10pp vs +27pp у Qwen3.6) -- hybrid memory architecture не сохраняет состояние между retry. Cache-reuse на Coder Next архитектурно невозможен (Gated DeltaNet recurrent state). Зависание на 31-й задаче -- aider exponential-backoff retry-loop, нет watchdog в bench-aider.sh.

Полная статья: [runs/2026-04-26-aider-smoke-qwen-coder-next.md](runs/2026-04-26-aider-smoke-qwen-coder-next.md)
Лог: `/tmp/aider-suite-20260426-133428/qwen-coder-next.log` (3.0 MB на сервере)

### 2026-04-26: Aider Polyglot smoke (прерван) -- Qwen3.6-35B-A3B

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M, llama-server `--parallel 4`, контекст 128K, Docker `aider-polyglot-bench:latest`
**Задач**: 22/50 (прерван по таймауту -- 135 мин при ожидаемых 75)
**Время**: 2h 16m
**Pass rate**: 6/22 = **27.3%** (single-shot), 12/22 = **54.5%** (с retry)
**По языкам**: Python 3/4 (75% / 75%), JavaScript 1/5 → 4/5 (20% / 80% с retry), C++ 1/5 → 3/5 (20% / 60%), Java 1/2 (50% / 50%), Go 0/2 → 1/2 (0% / 50%), Rust **0/4 (0% / 0%)**
**Edit format warnings**: 0 (100% well-formed)
**Заметки**: Реальная скорость 5.2 мин/задача вместо ожидаемой 1.5; необходимо снизить smoke до 20 задач или планировать на 4-5 ч/модель. Rust 0/4 требует расследования.

Полная статья: [runs/2026-04-26-aider-smoke-qwen3.6-35b.md](runs/2026-04-26-aider-smoke-qwen3.6-35b.md)
Лог: `/tmp/aider-suite-20260426-105321/qwen3.6-35b.log` (3.0 MB на сервере)

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

Полная статья: runs/YYYY-MM-DD-bench-mode-model.md (см. runs/README.md)
Лог: `/tmp/<bench>-<model>-<timestamp>.log`
```

---

## Связанные статьи

- [runbooks/](runbooks/README.md) -- инструкции запуска
- [runs/](runs/README.md) -- полные статьи прогонов
- [README.md](README.md) -- индекс бенчмарков, теория
- [coding/news.md](../../coding/news.md) -- хроника релизов моделей
- [models/coding.md](../../models/coding.md) -- каталог моделей
- [inference/optimization-backlog.md](../../inference/optimization-backlog.md) -- бэклог идей ускорения на базе наблюдений
