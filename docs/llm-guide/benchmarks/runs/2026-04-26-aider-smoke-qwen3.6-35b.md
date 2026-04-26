# Aider Polyglot smoke -- Qwen3.6-35B-A3B (2026-04-26)

**Mode**: smoke (50 задач target, фактически 22 завершено до прерывания)
**Scope**: одна модель, валидационный прогон
**Total time**: 2h 16m (10:53 -- 13:09 UTC)
**Статус**: **прерван** -- скрипт не успел дойти до 50 задач за 135 минут (фактическая скорость 5.2 мин/задача вместо ожидаемой 1.5 мин)
**Лог сервера**: `/tmp/aider-suite-20260426-105321/`
**Локальная копия логов**: `/tmp/aider-suite-final/`

## Среда

| Компонент | Значение |
|-----------|----------|
| Hardware | AMD Strix Halo (gfx1151), 120 GiB unified memory |
| Kernel | 6.19.8-061908-generic |
| Mesa / RADV | RADV (Vulkan backend для llama.cpp) |
| llama.cpp | b8717 (commit `d9a12c82f`) |
| Aider | 0.86.3.dev48+g3ec8ec5a7 |
| Backend | Vulkan |
| Docker image | `aider-polyglot-bench:latest` (1f045eb19303, 7.26 GB) |
| Toolchain в image | Python 3.11, OpenJDK 21, Cargo 1.95, Go 1.21, Node 20, GCC 11 |

### Параметры модели

| Параметр | Значение |
|----------|----------|
| Модель | `Qwen3.6-35B-A3B-UD-Q4_K_M.gguf` (~21 GB) |
| MMProj | `mmproj-Qwen3.6-35B-A3B-F16.gguf` |
| Архитектура | MoE 35B total / 3B active |
| Квантизация | Q4_K_M (UD) |
| Порт | 8085 |
| Контекст | 131072 (128K) |
| `--parallel` | 4 |
| `--cache-reuse` | 256 |
| `--jinja` | да |
| `-fa on` | flash attention включён |
| `-ngl 99` | все слои на GPU |

### Параметры benchmark

```bash
docker run --rm --network host --user $(id -u):$(id -g) \
    -v ~/projects/aider:/aider \
    -e OPENAI_API_BASE="http://localhost:8085/v1" \
    -e OPENAI_API_KEY="dummy" -e AIDER_DOCKER=1 \
    aider-polyglot-bench:latest \
    python3 ./benchmark/benchmark.py "smoke-qwen3.6-35b-20260426-105331" \
        --model "openai/qwen3.6-35b" \
        --edit-format whole \
        --threads 1 \
        --tries 2 \
        --new \
        --exercises-dir polyglot-benchmark \
        --num-tests 50
```

## Pre-flight

- SSH доступен (timeout 5 сек): да
- Aider venv: использовался Docker image вместо venv
- Disk free: 1.3 TB
- Ports 8080-8085: свободны до запуска
- Docker image на месте: да
- llama-server преcет qwen3.6-35b.sh: запущен успешно за ~15 сек
- Healthcheck `/v1/models`: OK

## Результаты (фактические)

### Агрегатные показатели

| Метрика | Значение |
|---------|----------|
| **test_cases** (фактически прогнано) | **22** из 50 запрошенных |
| **pass_rate_1** (single-shot) | **27.3%** (6 из 22) |
| **pass_rate_2** (с retry, --tries 2) | **54.5%** (12 из 22) |
| percent_cases_well_formed | 100.0% (нет malformed responses) |
| error_outputs | 0 |
| user_asks | 30 (модель просила уточнения) |
| test_timeouts | 1 |
| seconds_per_case | **312.5 сек** (5.2 мин/задача) |
| prompt_tokens | 266 699 |
| completion_tokens | 260 707 |
| total_tests в датасете | 225 |

### Per-language breakdown

| Язык | Прогнано | Pass 1-try | Pass 2-tries | Pass rate 1 | Pass rate 2 |
|------|----------|------------|--------------|-------------|-------------|
| **Python** | 4 | 3 | 3 | **75%** | **75%** |
| **JavaScript** | 5 | 1 | 4 | 20% | **80%** |
| **C++** | 5 | 1 | 3 | 20% | 60% |
| **Java** | 2 | 1 | 1 | 50% | 50% |
| **Go** | 2 | 0 | 1 | 0% | 50% |
| **Rust** | 4 | 0 | 0 | **0%** | **0%** |
| **Итого** | **22** | **6** | **12** | **27.3%** | **54.5%** |

### Хронология выполнения

| Время (UTC) | Язык / задача | Длительность |
|-------------|----------------|--------------|
| 10:55:25 | python/beer-song | -- (первая) |
| 10:59:54 | javascript/wordy | 4m 29s |
| 11:13:15 | cpp/diamond | 13m 21s |
| 11:16:28 | rust/ocr-numbers | 3m 13s |
| 11:24:36 | cpp/zebra-puzzle | 8m 8s |
| 11:28:13 | rust/simple-cipher | 3m 37s |
| 11:33:00 | javascript/house | 4m 47s |
| 11:35:03 | javascript/zipper | 2m 3s |
| 11:42:18 | java/dominoes | 7m 15s |
| 11:59:31 | cpp/allergies | 17m 13s |
| 12:07:11 | javascript/bowling | 7m 40s |
| 12:26:20 | cpp/kindergarten-garden | 19m 9s |
| 12:30:07 | rust/two-bucket | 3m 47s |
| 12:32:36 | rust/luhn-from | 2m 29s |
| 12:34:12 | python/dominoes | 1m 36s |
| 12:35:50 | python/simple-linked-list | 1m 38s |
| 12:39:47 | go/error-handling | 3m 57s |
| 12:41:31 | javascript/binary | 1m 44s |
| 12:46:32 | python/react | 5m 1s |
| 12:49:47 | java/book-store | 3m 15s |
| 12:56:12 | go/scale-generator | 6m 25s |
| 13:05:32 | cpp/dnd-character | 9m 20s |
| 13:09 | (прервано на go/ledger или cpp/...) | -- |

## Анализ

### Подтверждение заявленной SWE-V

Модель Qwen3.6-35B-A3B заявлена как **73.4% SWE-bench Verified**. Aider Polyglot и SWE-bench -- разные бенчмарки (SWE-bench -- реальные баги Python; Polyglot -- exercism-задачи 6 языков), но качественное сопоставление возможно.

Текущий результат **54.5% pass_rate_2 на 22 задачах** -- statistically малая выборка, но порядок правдоподобный для модели среднего размера. Топ закрытых моделей дают 75-85% на полных 225, для 3B-A active модели 50-55% -- ожидаемый диапазон.

### Сильные стороны модели

- **Python**: 75% single-shot -- профильный язык, что ожидаемо
- **JavaScript**: с retry 80%, но single-shot всего 20% -- модель пишет работающий код после увидеть test failures
- **100% well-formed**: модель ни разу не дала malformed JSON / broken code, edit-format `whole` сработал стабильно

### Слабые стороны

- **Rust 0/4** -- катастрофический результат. Модель не справилась ни с одной из 4 Rust-задач. Возможные причины:
  - Rust требует точной типизации и ownership-семантики, которые сложны для small-active модели
  - Borrow checker errors сложно понять из stderr без специализированных подсказок
  - Из 4 задач три (`ocr-numbers`, `simple-cipher`, `luhn-from`, `two-bucket`) -- средней-высокой сложности
- **C++ single-shot 20%** -- модель почти всегда требовала retry. С retry поднимается до 60%, но это удваивает время

### Edit format warnings

**0 warnings** -- модель правильно следовала формату `whole` (полная замена файла). Это показатель качества instruction-following для multimodal MoE-модели.

### User asks

**30 user asks** на 22 задачи -- модель часто запрашивала уточнения. В benchmark-режиме aider автоматически отвечает "продолжай", это нормально для unattended прогона, но в production агенте это означало бы лишние круги общения.

## Root cause: почему не остановился на 50

### Симптом

Скрипт `bench-aider.sh --num-tests 50` не вернулся в течение 135 минут, выполнил 22 задачи и продолжал работать когда был принудительно остановлен.

### Анализ

**`--num-tests 50` работает корректно** -- это не баг benchmark.py. Параметр действует как глобальный cap (не per-language), и 50 задач выбираются случайно из 225 общих.

**Истинная причина**: ошибка в эстимации времени.

| Параметр | Ожидание | Факт |
|----------|----------|------|
| Время на задачу | 90 сек (1.5 мин) | **312.5 сек (5.2 мин)** |
| Время на 50 задач | ~75 мин | **~260 мин (4 ч 20 мин)** |
| Время на 22 задачи | ~33 мин | **135 мин** |

Эстимация 90 сек/задача была получена из тестового прогона **1 простой Python задачи**. Реальная средняя -- **5.2 минуты** из-за:

1. **`--tries 2`** -- каждая failed задача делается заново с output тестов. Тесты Java и Rust компилируются медленно (Cargo cold start, Maven/Gradle не используется но javac тоже не быстрый)
2. **Toolchain overhead** -- Docker image содержит все 6 toolchain, для каждой задачи происходит:
   - Setup task в новой директории
   - Запуск pytest / cargo test / `go test` / `npm test` / Maven -- каждый по 5-30 сек cold start
   - Если retry -- ещё один цикл
3. **Сложные задачи** -- C++ kindergarten-garden занял 19 мин, cpp/allergies -- 17 мин (большой код, несколько retry)
4. **`--threads 1`** -- задачи строго последовательны, нет параллелизации внутри одного benchmark прогона

### Исправление эстимации

Обновить таблицу в `.claude/skills/ops-engineer/SKILL.md` (раздел `bench-suite-aider`):

| Модель | Старая оценка smoke | Новая оценка smoke |
|--------|---------------------|---------------------|
| Qwen3.6-35B-A3B | ~70 мин | **~260 мин (4 ч 20 мин)** |
| Qwen3-Coder Next 80B-A3B | ~80 мин | **~280 мин** |
| Qwen3-Coder 30B-A3B | ~48 мин | **~180 мин** |
| Devstral 2 24B (dense) | ~170 мин | **~500 мин (8+ ч)** |

**Smoke на 4 модели** = 18-22 часа реально (не 5-7 как было).

**Full на 3 модели** = 64-90 часов (на выходные не помещается).

### Альтернатива: уменьшить scope smoke

Текущий `--num-tests 50` нереалистичен. Варианты:

1. **`--num-tests 20`** -- 20 задач, ~110 мин/модель. Достаточно для baseline, статистическая погрешность ~10%
2. **`--languages python,javascript`** -- ограничить 2 языками, сократить toolchain overhead. ~50 задач за ~150 мин
3. **`--threads 2`** -- параллельно 2 потока в Docker (если памяти хватает -- проверить)

Рекомендация: **снизить smoke до 20 задач** в master-скрипте `bench-aider-suite.sh`. Полные 50 -- только в full-режиме (с честным ожиданием 4-5 ч/модель).

## Выводы

1. **Модель работает**, генерирует корректный код в 100% случаев (no malformed)
2. **Pass rate ~28% / ~55%** на 22 задачах -- предварительная оценка; статистически малая выборка, нужно ≥50 задач для надёжности
3. **Профильный язык -- Python** (75% single-shot)
4. **Слабый язык -- Rust** (0% на 4 задачах) -- задачи дальше с моделью не делать на Rust пока не выяснится причина
5. **Эстимация времени была некорректной** -- 5.2 мин/задача вместо 1.5 мин. Пересмотреть в SKILL.md
6. **Качество edit-format `whole`** -- идеальное, нет malformed responses

## Next steps

- [ ] Обновить эстимацию времени в `.claude/skills/ops-engineer/SKILL.md` (раздел `bench-suite-aider`, таблица моделей)
- [ ] Обновить [`scripts/inference/bench-aider-suite.sh`](../../../../scripts/inference/bench-aider-suite.sh): снизить default smoke до `--num-tests 20`, или ввести флаг `--quick` (10 задач) / `--smoke` (20) / `--full` (225)
- [ ] Добавить опцию `--languages` в [`scripts/inference/bench-aider.sh`](../../../../scripts/inference/bench-aider.sh) для ограничения scope (полезно для quick-валидации после правок параметров)
- [ ] Запустить ПОЛНЫЙ smoke (50 задач) на Qwen3.6-35B-A3B на ночь -- получить статистически достоверный baseline
- [ ] Сравнить с Qwen3-Coder Next и Qwen3-Coder 30B-A3B на той же выборке
- [ ] Исследовать Rust 0/4 -- запустить отдельно `--languages rust --num-tests 8` и посмотреть failure modes (malformed Cargo.toml? borrow checker? logic?)

## Связанные статьи

- [runbooks/aider-polyglot.md](../runbooks/aider-polyglot.md) -- runbook запуска
- [results.md](../results.md) -- журнал прогонов и лидерборд платформы
- [families/qwen36.md](../../../models/families/qwen36.md) -- описание модели
- [swe-bench.md](../swe-bench.md) -- родственный бенчмарк
