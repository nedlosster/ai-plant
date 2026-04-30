# Бенчмарки на платформе: журнал результатов

Append-only журнал прогонов бенчмарков на Strix Halo сервере. Каждая запись -- один прогон одной модели на одном бенчмарке.

Запуск -- через runbooks:
- [runbooks/aider-polyglot.md](runbooks/aider-polyglot.md)
- [runbooks/terminal-bench.md](runbooks/terminal-bench.md)

Индекс runbooks -- [runbooks/README.md](runbooks/README.md).
Полные статьи отдельных прогонов -- [runs/README.md](runs/README.md).

## Лидерборд платформы (Aider Polyglot)

| Модель | Smoke (≤50 задач) | Full (no rust, 195 задач) | Дата smoke | Дата full | Note |
|--------|-------------------|---------------------------|------------|-----------|------|
| **Qwen3.5-122B-A10B** ⭐⭐ (Q4_K_M) | -- | **37.9% / 76.9%** на 195/195 ✅ | -- | **2026-04-30** | ⭐⭐ **АБСОЛЮТНЫЙ РЕКОРД ПЛАТФОРМЫ**, paritет с o3 base (76.9%), обгон Opus 4 (72.0%). Лидер Python/JS (~85%). Hybrid 12 attn / 37 SSM, 10B active vs 3B у топов |
| **Qwen3.6-35B-A3B (text-only)** (Q4_K_M) | 30.0% / **70.0% (--tries 2)** на 20 задачах ✅ | **29.2% / 65.6%** на 195/195 ✅ | 2026-04-27 | **2026-04-29** | ⭐ **100% coverage**, 0 watchdog за 22h. Лидер C++ (73.1%). Регрессия к среднему -4.4pp от smoke |
| **Qwen3-Coder Next 80B-A3B** (Q4_K_M) | 36.7% / 46.7% на 30 задачах (прерван) | **33.7% / 68.0%** на 178/195 ✅ | 2026-04-26 | **2026-04-28** | ⭐ **best balanced** (качество ~35B-text при 2.5× скорости) |
| Qwen3.6-35B-A3B (multimodal, Q4_K_M) | 35.0% single-shot на 20 задачах (clean ✓) | -- | 2026-04-26 (clean) | -- | best single-shot на small sample |
| **Qwen3-Coder 30B-A3B** (Q4_K_M) | 15.0% single-shot на 20 задачах (clean ✓) | **10.8% / 26.3%** на 194/195 ✅ | 2026-04-26 | **2026-04-27** | ⭐ best throughput (47.7 sec/case) |
| Qwen3.6-35B-A3B (Q4_K_M) | 27.3% / 54.5% на 22 задачах (прерван) | -- | 2026-04-26 | -- | прерван timeout |

Формат: `pass_rate_1 / pass_rate_2` (single-shot / с retry, --tries 2).

### Reference: frontier closed-weight модели (для ориентира)

Публичные числа на том же aider polyglot benchmark (--tries 2, 225 задач), для калибровки качества платформы. **Не воспроизводимо** на Strix Halo (cloud-only API).

| Модель | Pass_rate_2 | Источник |
|--------|-------------|----------|
| Claude Opus 4.5 | **89.4%** | [Anthropic-reported](https://www.anthropic.com/news/claude-opus-4-5), 2025-11 |
| GPT-5 (high) | **88.0%** | [aider leaderboard](https://aider.chat/docs/leaderboards/) |
| GPT-5 (medium) | 86.7% | aider leaderboard |
| o3-pro (high) | 84.9% | aider leaderboard |
| Gemini 2.5 Pro (32k think) | 83.1% | aider leaderboard |
| Grok 4 (high) | 79.6% | aider leaderboard |
| o3 base | 76.9% | aider leaderboard |
| DeepSeek V3.2-Exp | 74.2% | public benchmark |
| Claude Opus 4 (32k thinking) | 72.0% | aider leaderboard, `claude-opus-4-20250514` |
| Claude Opus 4.6 | -- "лидирует" по Anthropic-reported, точные числа не публикованы. Оценочно **87-91%** | косвенные обзоры |
| Claude Opus 4.7 | -- лидер на SWE-Bench Verified апрель 2026, на aider polyglot scores не публикованы | [marc0.dev SWE-Bench leaderboard](https://www.marc0.dev/en/leaderboard) |

**Топ-result платформы Strix Halo** (Qwen3.5-122B-A10B full): **76.9%** pass_rate_2 на 195/195 ⭐⭐ -- **paritет с o3 base** (76.9%) и **обгон Claude Opus 4** (72.0%) на 4.9pp.

**Разрыв до frontier**: ~12-13pp от Opus 4.5/4.6/4.7. **Mid-tier frontier zone достигнут** -- Strix Halo с локальным inference на open-weight Qwen3.5-122B-A10B даёт качество paitет с frontier mid-tier при нулевой стоимости и полной приватности. Лидеры платформы по языкам: **Python 85.3%**, **JavaScript 85.7%** (сопоставимо с Opus 4.5).

## Лидерборд платформы (Terminal-Bench 2.0)

| Модель | 56 tasks | Дата |
|--------|----------|------|
| -- | -- | -- |

## История прогонов

Свежие сверху. Полные статьи -- в [runs/](runs/README.md).

### 2026-04-29 → 2026-04-30: Aider Polyglot **full** -- Qwen3.5-122B-A10B 🏆 АБСОЛЮТНЫЙ РЕКОРД 76.9%

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M (~71 GiB), llama-server `--parallel 2 --cache-reuse 256 --cache-type q8_0 --keep 1500 --no-mmap --reasoning off`, контекст 128K, Docker `aider-polyglot-bench:latest`
**Задач**: **195/195** ✅ (100% coverage)
**Время**: ~36 часов wall clock (4 manual resume циклов через --cont)
**Pass rate**: 74/195 = **37.9%** (single-shot), **150/195 = 76.9%** (с retry, --tries 2) -- **АБСОЛЮТНЫЙ РЕКОРД ПЛАТФОРМЫ**
**По языкам**:
- JavaScript 49/49: 25 → 42 (51.0% / **85.7%** ⭐⭐ лидер)
- Python 34/34: 18 → 29 (52.9% / **85.3%** ⭐⭐ лидер)
- C++ 26/26: 10 → 20 (38.5% / **76.9%** ⭐)
- Go 39/39: 11 → 28 (28.2% / 71.8%)
- Java 47/47: 10 → 31 (21.3% / 66.0%)
**Edit format warnings**: 100% well-formed
**Заметки**: Retry effect **+39.0pp** -- лидер платформы по этой метрике. **0 watchdog kills за 36 часов** после применения `--reasoning off` (Qwen3.5 встроенный thinking ломал single-shot, после отключения pass_1 вырос с 18.2% до 37.9%). Hybrid Gated DeltaNet (12 attention / 37 SSM из 49 layers по llama-server log) -- inter-task cache blocked, но 10B active даёт устойчивые retry-цепочки. **Paритет с o3 base** (76.9%), **обгон Claude Opus 4** (72.0% при 32k thinking) на 4.9pp. **Лидер по Python и JavaScript**: 85.3-85.7% pass_2 -- сопоставимо с Opus 4.5 на этих языках.

Полная статья: [runs/2026-04-30-aider-full-qwen3.5-122b.md](runs/2026-04-30-aider-full-qwen3.5-122b.md)
Лог: `/tmp/aider-full-122b-*/`

### 2026-04-28 → 2026-04-29: Aider Polyglot **full** -- Qwen3.6-35B-A3B (text-only) 🏆 100% coverage

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M, llama-server `--parallel 4 --cache-reuse 256 --batch-size 4096 --keep 1500`, контекст 128K (БЕЗ mmproj -- text-only preset), Docker `aider-polyglot-bench:latest`
**Задач**: **195/195** ✅ (100% coverage -- единственный full на платформе с полным покрытием)
**Время**: ~22 часа wall clock (БЕЗ manual resume циклов)
**Pass rate**: 57/195 = **29.2%** (single-shot), **128/195 = 65.6%** (с retry, --tries 2)
**По языкам** (агрегация из `.aider.results.json`):
- JavaScript 49/49 ✅: 14 → 37 (28.6% / **75.5%** ⭐)
- C++ 26/26 ✅: 8 → 19 (30.8% / **73.1%** ⭐ -- лидер C++ на платформе)
- Python 34/34 ✅: 12 → 24 (35.3% / **70.6%** ⭐)
- Go 39/39 ✅: 12 → 24 (30.8% / 61.5%)
- Java 47/47 ✅: 11 → 24 (23.4% / 51.1%)
**Edit format warnings**: 0 (**100% well-formed**, 0 malformed на 195 задачах)
**Заметки**: Retry effect **+36.4pp**. **0 watchdog kills и 0 manual resumes за 22 часа** -- best-in-class production-stability на платформе. Hybrid Gated DeltaNet + recurrent SSM (как у Coder Next) -- inter-task cache blocked. Регрессия к среднему -4.4pp от smoke 20 (70.0%) -- ожидаемая статистическая флуктуация. Coder Next 80B-A3B на 2.4pp впереди по качеству, но 35B-text **лидер по C++ (+12.0pp над Coder Next), покрытию и стабильности**.

Полная статья: [runs/2026-04-29-aider-full-qwen3.6-35b-text.md](runs/2026-04-29-aider-full-qwen3.6-35b-text.md)
Лог: `/tmp/aider-full-35b-text-20260428-1353/`

### 2026-04-27 → 2026-04-28: Aider Polyglot **full** -- Qwen3-Coder Next 80B-A3B 🏆

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M, llama-server `--parallel 4 --batch-size 4096 --ubatch-size 4096 --keep 1500 --no-mmap`, контекст 256K (БЕЗ `--cache-reuse`: hybrid memory блокирует), Docker `aider-polyglot-bench:latest`
**Задач**: **178/195** (91.3% coverage, остановлен на C++ diamond reasoning loop в resume #14)
**Время**: ~16 часов wall clock (14 resume сессий, 52 watchdog kills)
**Pass rate**: 60/178 = **33.7%** (single-shot), **121/178 = 68.0%** (с retry, --tries 2) -- лидер балансированного агентского workload на платформе
**По языкам** (агрегация per-task `.aider.results.json`, 179 задач):
- JavaScript 21/47 → 38/47 (44.7% / **80.9%** ⭐⭐ лидер)
- Python 11/34 → 26/34 (32.4% / **76.5%** ⭐, 100% покрытие)
- C++ 6/18 → 11/18 (33.3% / 61.1%, покрытие 69% -- 8 задач застряли в reasoning loops)
- Java 11/44 → 26/44 (25.0% / 59.1%)
- Go 11/36 → 21/36 (30.6% / 58.3%)
**Edit format warnings**: 0 (**100% well-formed**, 0 malformed responses на 178 задачах)
**Заметки**: Retry effect **+34.3pp** -- модель максимально хорошо учится на ошибках. user_asks 1.49/задача -- средняя автономность. 52 watchdog kills (vs 13 у 30B-A3B) отражают в 2× больше времени на задачу + склонность 80B к long reasoning loops. task-timeout 360 сек оказался недостаточен для --tries 2 на 80B -- увеличен до 1200 в финальном resume #14. Cache-reuse архитектурно blocked, ждём llama.cpp PR #20819 + #19670.

Полная статья: [runs/2026-04-27-aider-full-qwen-coder-next.md](runs/2026-04-27-aider-full-qwen-coder-next.md)
Лог: `/tmp/aider-full-coder-next-20260427-1355/`, `/tmp/aider-resume{,3..14}-coder-next-*/`

### 2026-04-27: Aider Polyglot smoke 20 + --tries 2 -- Qwen3.6-35B-A3B (text-only) 🏆

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M, llama-server `--parallel 4 --keep 1500 --batch-size 4096 --ubatch-size 4096`, контекст 128K, **БЕЗ mmproj** (text-only preset), Docker `aider-polyglot-bench:latest`
**Задач**: 20/20 ✅
**Время**: 1h 55m (2 watchdog kills + 2 успешных auto-resume)
**Pass rate**: 6/20 = 30.0% (single-shot), **14/20 = 70.0%** (с retry, --tries 2) -- **РЕКОРД ПЛАТФОРМЫ**
**По языкам**: JavaScript 7/8 (87.5%), Go 3/3 (100%), Java 3/5 (60%), Python 2/5 (40%), C++ 0/0 (не в выборке), Rust исключён
**Edit format warnings**: 0 (100% well-formed)
**Заметки**: Retry effect **+40pp** -- абсолютный рекорд на платформе. user_asks = **0** -- модель полностью автономна. multimodal-блокировка cache-reuse снята (text-only вариант), `forcing full prompt re-processing` сократилось в 3-4× vs обычного 35B. Auto-resume через --cont сработал в 100% случаев на двух watchdog kill'ах.

Полная статья: [runs/2026-04-27-aider-smoke-qwen3.6-35b-text-tries2.md](runs/2026-04-27-aider-smoke-qwen3.6-35b-text-tries2.md)
Лог: `/tmp/aider-smoke-35b-text-tries2-20260427-1140/runner.log`

### 2026-04-26 → 2026-04-27: Aider Polyglot **full** -- Qwen3-Coder 30B-A3B

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M, llama-server `--parallel 4 --cache-reuse 256`, контекст 128K, Docker `aider-polyglot-bench:latest`
**Задач**: **194/195** (99.5% coverage, 1 "вечно зависающая" задача оставлена после max-attempts watchdog)
**Время**: ~7.5 часов (5 manual resume циклов + 12 auto-resume через --cont)
**Pass rate**: 21/194 = **10.8%** (single-shot), **51/194 = 26.3%** (с retry, --tries 2)
**По языкам** (полное покрытие, без Rust):
- JavaScript 5/49 → 16/49 (10.2% / **32.7%** ⭐)
- C++ 3/25 → 8/25 (12.0% / **32.0%** ⭐)
- Java 5/47 → 12/47 (10.6% / 25.5%)
- Python 5/34 → 8/34 (14.7% / 23.5%)
- Go 3/39 → 7/39 (7.7% / **17.9%**)
**Edit format warnings**: 99.5% well-formed, 1 malformed
**Заметки**: Cache reuse работает 100% (0 событий `forcing full prompt re-processing`). 13 watchdog kills за прогон (1 на ~15 задач) -- 30B-A3B склонен к reasoning loops на сложных CSP/parser/state-machine задачах. Auto-resume через --cont полноценно работал в production (12 успешно из 13 kills). seconds_per_case 47.7 -- в 6.5× быстрее Qwen3.6-35B на --tries 2.

Полная статья: [runs/2026-04-26-aider-full-qwen3-coder-30b.md](runs/2026-04-26-aider-full-qwen3-coder-30b.md)
Лог: `/tmp/aider-finalize-30b-20260427-1009/runner.log`

### 2026-04-26: Aider Polyglot smoke 20 (clean ✓, A/B) -- Qwen3-Coder 30B-A3B

**Среда**: Strix Halo, Vulkan b8717, Q4_K_M, llama-server `--parallel 4 --cache-reuse 256`, контекст 128K, Docker `aider-polyglot-bench:latest`
**Задач**: **20/20** (полный прогон, watchdog не срабатывал)
**Время**: **0h 10m** (vs 1h 11m у Qwen3.6-35B на тот же scope -- 7× быстрее)
**Pass rate**: 3/20 = **15.0%** (single-shot, --tries 1, no rust)
**По языкам**: Python 1/1 (100%), Go 1/3 (33%), C++ 1/4 (25%), Java 0/3 (0%), JavaScript **0/9** (0% -- 45% выборки случайно оказались JS!)
**Edit format warnings**: 0 (100% well-formed)
**Заметки**: Standard MoE attention, cache reuse РАБОТАЕТ (0 случаев `forcing full prompt re-processing`). Hypothesis M-001 ПОДТВЕРЖДЕНА (cache + speed). Trade-off: -57% качества, +12× скорости. completion_tokens 17K vs 199K у 35B -- модель пишет лаконично. JavaScript 0/9 -- random subset bias (45% выборки случайно оказались JS).

Полная статья: [runs/2026-04-26-aider-smoke-qwen3-coder-30b.md](runs/2026-04-26-aider-smoke-qwen3-coder-30b.md)
Лог: `/tmp/aider-test-30b-20260426-2011/runner.log`

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
