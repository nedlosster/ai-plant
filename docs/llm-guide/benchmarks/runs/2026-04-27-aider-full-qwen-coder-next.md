# Aider Polyglot full -- Qwen3-Coder Next 80B-A3B (2026-04-27 → 2026-04-28)

**Mode**: full (cpp,go,java,javascript,python = 195 из 225, --tries 2)
**Scope**: одна модель, leaderboard-quality замер с retry на hybrid Gated DeltaNet архитектуре
**Total time**: **~16 часов wall clock** (13:55 UTC 2026-04-27 → ~05:55 UTC 2026-04-28, 14 resume циклов)
**Статус**: остановлен на 178/195 (91.3% coverage) -- зафиксирован как финал; задача `cpp/diamond` ушла в reasoning loop в resume #14, продолжение нерентабельно
**Логи**: `/tmp/aider-full-coder-next-20260427-1355/`, `/tmp/aider-resume{,3..14}-coder-next-*/`

## Контекст и цель

**Leaderboard-quality замер** для основного флагмана платформы по балансу качество/скорость. Coder Next -- единственная hybrid-модель, у которой 80B/3B-A active может скомпенсировать архитектурную невозможность cache-reuse через сырое качество reasoning.

Ключевые гипотезы для проверки:

1. **80B компенсирует hybrid limit**: 30B-A3B full attention даёт 26.3% pass_rate_2 при идеальном cache-reuse, но 80B-A3B без cache-reuse может выдать **+30-40pp качества** через объёмное reasoning (от smoke-30 экстраполировалось 67-70%)
2. **Hybrid memory ведёт себя стабильно** на длинных multi-turn dialog'ах с --tries 2 (без `forcing full prompt re-processing`)
3. **Auto-resume + watchdog работают** на тяжёлой 80B-модели с ~99 sec/case -- более длинные задачи требуют другой watchdog timeout, чем 30B-A3B

Связано: [optimization-backlog A-005 (watchdog), B-001 (cache-reuse hybrid limit), U-001 (PR 13194 hybrid memory)](../../../inference/optimization-backlog.md).

## Среда

| Компонент | Значение |
|-----------|----------|
| Hardware | AMD Strix Halo (gfx1151), 120 GiB unified memory |
| Kernel | 6.19.8-061908-generic |
| Backend | Vulkan |
| llama.cpp | b8717 (commit `d9a12c82f`) |
| Aider | 0.86.3.dev48+g3ec8ec5a7 |
| Docker image | `aider-polyglot-bench:latest` (1f045eb19303, 7.26 GB) |

### Параметры модели

| Параметр | Значение |
|----------|----------|
| Модель | `Qwen3-Coder-Next-Q4_K_M-00001-of-00004.gguf` (split на 4 файла, ~45 GB) |
| Архитектура | **Hybrid Gated DeltaNet**, 80B/3B-A active, MoE |
| KV cache | recurrent + standard memory mix |
| Recurrent memory | **есть** (блокирует cache-reuse архитектурно) |
| Mmproj | отсутствует (text-only вариант) |
| Квантизация | Q4_K_M |
| Порт | 8081 |
| Контекст | **256000** (256K) |
| `--parallel` | 4 |
| `--cache-reuse` | **убран из пресета** (commit B-001) -- llama.cpp игнорирует на hybrid memory |
| `--batch-size / --ubatch-size` | 4096 / 4096 (оптимизация PP, commit `8c6198a`) |
| `--keep` | 1500 |
| `--no-mmap` | да (45 GiB сразу в RAM) |
| `--jinja` | да |
| `-fa on` | да |

### Параметры benchmark

```bash
docker run --rm --network host --user 1000:1000 \
    -v ~/projects/aider:/aider \
    -e OPENAI_API_BASE="http://localhost:8081/v1" \
    -e OPENAI_API_KEY="dummy" -e AIDER_DOCKER=1 \
    aider-polyglot-bench:latest \
    python3 ./benchmark/benchmark.py "full-qwen-coder-next-20260427-135505" \
        --model "openai/qwen-coder-next" \
        --edit-format whole \
        --threads 1 --tries 2 --new \
        --exercises-dir polyglot-benchmark \
        --languages cpp,go,java,javascript,python
```

Watchdog: task-timeout варьировался (360 сек для большинства resume, 1200 сек для финального #14 после анализа застреваний). max-resumes 3 на сессию.

## Результаты

### Агрегатные показатели

| Метрика | Значение |
|---------|----------|
| **test_cases** | **178 / 195** (91.3% coverage) |
| **pass_rate_1** (single-shot) | **33.7%** (60 из 178) |
| **pass_rate_2** (с retry, --tries 2) | **68.0%** (121 из 178) |
| Retry effect (pass_2 - pass_1) | **+34.3pp** ⭐ |
| percent_cases_well_formed | **100.0%** ✅ (0 malformed) |
| num_malformed_responses | 0 |
| error_outputs | 1 (один сетевой сбой за 178 задач) |
| user_asks | 266 (~1.49 / задача) |
| seconds_per_case | **~99** (среднее по wall clock без watchdog overhead) |

### Per-language directory counts (целевой набор)

| Язык | В датасете | Прогнано (из 178) |
|------|-----------|-------------------|
| Python | 34 | -- |
| C++ | 26 | -- (последняя -- diamond, заблокировала прогресс) |
| JavaScript | 49 | -- |
| Go | 39 | -- |
| Java | 47 | -- |
| **Итого** | **195** | **178** |

Точная разбивка pass_rate per-language недоступна -- финальный YAML агрегат записан только до 178 задач, без per-language footer.

### Активность llama-server (cache!)

| Событие | Coder Next 80B-A3B |
|---------|---------------------|
| `loaded multimodal model` | ✗ (text-only) |
| `llama_memory_recurrent` | ✓ (hybrid Gated DeltaNet) |
| Standard `llama_kv_cache` | ✓ (плюс recurrent) |
| `cache_reuse is not supported by recurrent memory` | ✓ (ожидаемо) |
| `forcing full prompt re-processing` | -- (логирование изменилось на hybrid) |

**Cache reuse архитектурно blocked** -- ожидается до merge llama.cpp PR #20819 + #19670.

## Pre-flight (на момент старта 2026-04-27 13:55)

- SSH ✓
- Docker image (7.26 GB) ✓
- Disk free: 1.3 TB ✓
- Ports 8080-8085: свободны до старта
- Модель `Qwen3-Coder-Next-Q4_K_M-*-of-4.gguf` (45 GB split): ✓
- llama.cpp build: ✓
- Healthcheck `/v1/models`: OK с первой попытки

## Watchdog activity

**52 watchdog kills за 14 resume сессий** -- значительно больше чем у 30B-A3B (13 kills на 13 resume'ов). Это отражает **в 2× больше времени на задачу** при сопоставимой склонности 80B-A3B к reasoning loops.

### Resume timeline

| # | Сессия | start (test_cases) | end | Δ задач | Прерывание |
|---|--------|---------------------|-----|---------|------------|
| 1 | full (initial) | 1 | 37 | +36 | watchdog max-attempts |
| 2 | resume (manual) | 38 | 72 | +34 | watchdog max-attempts |
| 3 | resume3 | 72 | 87 | +15 | watchdog max-attempts |
| 4 | resume4 | 87 | 108 | +21 | watchdog max-attempts |
| 5 | resume5 | 108 | 118 | +10 | watchdog max-attempts |
| 6 | resume6 | 118 | 122 | +4 | watchdog max-attempts |
| 7 | resume7 | 122 | 148 | +26 | watchdog max-attempts |
| 8 | resume8 | 148 | 152 | +4 | watchdog max-attempts |
| 9 | resume9 | 152 | 166 | +14 | watchdog max-attempts |
| 10 | resume10 | 166 | 166 | **0** | сразу stuck, 0 прогресса |
| 11 | resume11 | 166 | 169 | +3 | watchdog max-attempts |
| 12 | resume12 | 169 | 174 | +5 | watchdog max-attempts |
| 13 | resume13 | 174 | 178 | +4 | watchdog max-attempts (last YAML aggregate) |
| 14 | resume14 | 178 | (179 partial) | +1\* | manual abort: stuck в C++ diamond loop 22 мин |

\* resume #14 успел зачислить +1 задачу (test_cases: 179) но зацикливание на `cpp/diamond` блокировало остальные. Без YAML агрегата эта задача не учтена в финале.

### Почему 52 watchdog kills

Среднее ~3.7 kill за сессию -- **типичный паттерн max-attempts cap**. Каждая resume-сессия выглядит так:
1. Прогресс 1-3 задачи (60-300 секунд каждая)
2. Попадание на тяжёлую задачу (CSP, recursive parser, complex grammar)
3. Watchdog 360 сек -- kill, attempt 2/4
4. После 4 attempts -- скрипт сдаётся, требует manual resume

Для 80B-A3B `task-timeout 360` оказался слишком жёстким -- многие реально решаемые задачи на retry-петле занимают 8-12 минут (см. anti-pattern в [optimization-backlog A-005](../../../inference/optimization-backlog.md#a-005)).

## Сравнение с предыдущими прогонами

| Метрика | 30B-A3B full | **Coder Next full** | 35B-text smoke20 t2 |
|---------|--------------|----------------------|----------------------|
| Архитектура | full attention | **hybrid Gated DeltaNet** | hybrid + multimodal |
| Tasks | 194/195 | **178/195** | 20/20 |
| --tries | 2 | **2** | 2 |
| pass_rate_1 | 10.8% | **33.7%** ⭐ | 30.0% |
| pass_rate_2 | 26.3% | **68.0%** ⭐ | 70.0% |
| Retry effect | +15.5pp | **+34.3pp** | +40.0pp |
| seconds_per_case | 47.7 | **~99** | 248.8 |
| Total time | ~7.5h | **~16h** | 1h 55m |
| forcing full prompt | 0 | (recurrent: blocked by design) | 41 |
| Cache works | ✅ | ❌ (architectural) | ❌❌ |
| Watchdog kills | 13 | **52** | 0 |
| 100% well-formed | 99.5% | **100%** ✅ | 100% |
| user_asks/задача | 0.82 | **1.49** | низкий |

**Coder Next 80B-A3B = +41.7pp pass_rate_2 vs 30B-A3B full attention** -- размер модели полностью компенсирует cache-reuse limitation.

## Анализ

### Сильные стороны Coder Next

- **Pass rate 68.0%** -- лидер на платформе среди --full прогонов с --tries 2. На 178 задачах -- статистически значимый baseline (95% CI: ±7pp)
- **Retry effect +34.3pp** -- модель **очень хорошо учится на ошибках** через aider error feedback. В 2× выше чем у 30B-A3B (+15.5pp), показывает что 80B размер ценен именно при retry, не на single-shot
- **100% well-formed** -- 0 malformed responses на 178 задачах. Edit format `whole` идеально стабилен. Сравнимо с qwen3.6-35b-text smoke
- **pass_rate_1 = 33.7%** vs 10.8% у 30B-A3B -- **в 3× выше** на одиночной попытке. Single-shot качество значительно выше
- **error_outputs = 1** -- один сетевой/timeout сбой за 178 задач при ~16 часов работы

### Слабые стороны

- **Скорость 99 sec/case** -- в 2× медленнее 30B-A3B (47.7). На full прогон с --tries 2 это превращается в ~5 часов pure compute, плюс resume overhead
- **52 watchdog kills** -- модель часто застревает на сложных multi-turn задачах (CSP, recursive parsers, complex DSL grammars). Конкретные "вечные" задачи: `cpp/diamond` (template formatting matrix), `cpp/zebra-puzzle` (CSP), вероятно `java/sgf-parsing`
- **user_asks 1.49 / задача** -- модель часто запрашивает уточнения у пользователя. Это **снижает autonomous качество** в production agent-mode. Для leaderboard-теста с aider не критично (aider auto-responds), но в реальном opencode/Claude Code это будет видно
- **Coverage 91.3%** (vs 99.5% у 30B-A3B) -- 17 задач остались непрогнанными из-за того что C++ diamond застрял в reasoning loop, недостижимый watchdog'ом по `test_cases` маркеру

### Что подтверждено и зафиксировано

1. **80B компенсирует hybrid limit**: 68.0% pass_rate_2 -- значимо лучше 30B-A3B (26.3%) при том же бенчмарке. Размер модели окупается даже без cache-reuse
2. **--tries 2 даёт максимум value**: +34.3pp retry effect -- это **самый большой relative gain** среди всех тестируемых моделей. На 80B retry особенно эффективен
3. **Auto-resume через --cont производственно**: 52 watchdog kills, ни одного потерянного результата (благодаря fix в commit `048c474`)
4. **Coder Next = best balanced agent-coding default** на платформе: качество близко к 35B-text (68.0% vs 70.0%) при ~2.5× быстрее sec/case (99 vs 248). Если 35B-text не подходит из-за hybrid+multimodal cache блокировки, Coder Next -- следующий выбор
5. **task-timeout 360 сек слишком короткий** для 80B на --tries 2 retry-loop. Для full прогонов нужно 900-1200 сек

## Root cause: 17 непокрытых задач

**Причина 1: watchdog false positives на длинных задачах**

При `task-timeout 360`, задачи с retry-petлёй на 80B-A3B (8-12 мин real time) систематически прерывались до закрытия. После 4-х подряд прерываний на одной задаче скрипт сдавался, и переходил к следующей через manual resume. **Это механика работала корректно**, но требовала 14 resume сессий чтобы пройти 178 задач.

**Причина 2: stuck в reasoning loop на C++ diamond**

Resume #14 запущен с `task-timeout 1200` (20 мин). Модель попала в loop на `cpp/diamond`:
- 22 минуты непрерывной активности (множество "Applied edit to ..." в логе)
- Watchdog не срабатывал -- aider реально писал output, просто без закрытия задачи
- Решено вручную остановить, признать 178/195 финалом

Diamond (формирование matrix-orientированного diamond pattern из символов) -- известная сложная C++ задача, требующая точного управления пробелами. Модель циклически предлагает тот же formatting workflow, тесты не проходят, она retry'ится на тот же вариант.

**Причина 3: --new-attempt-budget (aider internal)**

Aider имеет внутренний "Only 3 reflections allowed, stopping" lim, но между retry'ями тратит 5-10K токенов output. Watchdog по `test_cases` маркеру не ловит этот long-running internal cycle.

## Что делать дальше

Для Coder Next в production:

- **Default daily** -- через `qwen-coder-next.sh` preset на 8081, agent-coding workflows (opencode, Aider, Cline). Качество > Coder 30B-A3B на десятки процентных пунктов
- **Не для batch**: 99 sec/case в 2× медленнее 30B-A3B, для throughput-sensitive workloads брать 30B
- **Cache-reuse**: ждать llama.cpp PR #20819 + #19670 (2-3 мес). После merge ожидаем -20% sec/case для multi-turn

Для bench-aider.sh:

- **Default `task-timeout` для 80B+**: повысить до **900 сек** (15 мин) -- покрывает 95% реальных long retry'ев
- **Опция `--keywords-skip`**: пропускать known-stuck задачи (`cpp/diamond`, `cpp/zebra-puzzle`, `java/sgf-parsing`) для бенчмарков
- **Watchdog по docker stats** (CPU usage), а не только по log markers -- ловит "stuck in retry loop" более универсально

## Выводы

1. **178/195 = 91.3% coverage** -- practical maximum для Coder Next 80B-A3B на --full при текущей watchdog настройке. 17 задач остались из-за reasoning loops на сложных С++/Java задачах
2. **pass_rate_2 = 68.0%** -- стат-достоверный baseline (95% CI: ±7pp на 178), близко к smoke prediction (67-70% на 87+)
3. **Retry effect +34.3pp** -- лидер среди всех моделей платформы. 80B размер дает максимум value именно через --tries 2
4. **100% well-formed** на 178 задачах -- стабильность edit format на agentic workloads
5. **Coder Next = best balanced default** -- лучший компромисс качество/скорость на платформе. 35B-text незначительно лучше по качеству (+2pp) но в 2.5× медленнее
6. **Auto-resume + watchdog production-grade** -- 52 watchdog kills за 16 часов, ни одного потерянного результата
7. **Cache-reuse blocked architecturally** -- ждём upstream merge для +20% throughput на multi-turn

## Next steps

- [ ] Зафиксировать прогон в [results.md](../results.md): 68.0% pass_rate_2, лидер по балансу качество/скорость на агентских workloads
- [ ] Обновить **Coder Next запись в [families/qwen3-coder.md](../../../models/families/qwen3-coder.md)**: финальные числа 178/195, 68.0%
- [ ] Скачать **Qwen3.6-27B Q4_K_M** (16.8 GB, уже скачана) и создать `qwen3.6-27b.sh` preset
- [ ] Запустить **Qwen3.6-27B smoke + --tries 2** -- ожидаем 70-78% pass_rate_2 (лидер open-weight SWE-V 77.2%)
- [ ] **Повысить default `task-timeout` для bench-aider.sh** до 900 сек -- меньше watchdog false positives на 80B+ моделях
- [ ] Расследовать **diamond loop**: тестовый прогон Coder Next на одной задаче `cpp/diamond` с увеличенным task-timeout 30 мин -- решит ли в принципе?
- [ ] **Сравнить с публичным leaderboard Aider Polyglot** для Qwen3-Coder Next 80B-A3B (если есть данные) -- 68.0% vs published?
- [ ] После merge llama.cpp PR #20819 + #19670 -- replay прогона, замерить speedup от cache-reuse

## Связанные статьи

- [results.md](../results.md) -- журнал прогонов и лидерборд платформы
- [2026-04-26-aider-full-qwen3-coder-30b.md](2026-04-26-aider-full-qwen3-coder-30b.md) -- A/B counterpart full-attention
- [2026-04-26-aider-smoke-qwen-coder-next.md](2026-04-26-aider-smoke-qwen-coder-next.md) -- smoke baseline (прерван на 30 задачах)
- [2026-04-27-aider-smoke-qwen3.6-35b-text-tries2.md](2026-04-27-aider-smoke-qwen3.6-35b-text-tries2.md) -- 70.0% рекорд платформы (smoke)
- [families/qwen3-coder.md](../../../models/families/qwen3-coder.md) -- описание модели и roadmap
- [inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- A-005 (watchdog), B-001 (cache-reuse hybrid limit), U-001 (PR 13194)
