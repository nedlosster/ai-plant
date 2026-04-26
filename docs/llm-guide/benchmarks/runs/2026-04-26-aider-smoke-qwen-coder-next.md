# Aider Polyglot smoke -- Qwen3-Coder Next 80B-A3B (2026-04-26)

**Mode**: smoke (50 задач target, фактически 30 завершено до прерывания)
**Scope**: одна модель, baseline сравнение с [Qwen3.6-35B](2026-04-26-aider-smoke-qwen3.6-35b.md) того же дня
**Total time**: 5h 3m (13:34 -- ~18:35 UTC, фактическая работа закончилась в 15:44, остальное -- retry-loop)
**Статус**: **прерван** -- aider завис в retry-loop после 30-й задачи на ~3 часа без прогресса
**Лог сервера**: `/tmp/aider-suite-20260426-133428/`

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
| Модель | `Qwen3-Coder-Next-Q4_K_M` (4 split, ~46 GB) |
| Архитектура | **MoE 80B / 3B active, hybrid Gated DeltaNet + full attention** (48 слоёв) |
| Квантизация | Q4_K_M |
| Порт | 8081 |
| `-c` | 256000 (256K) |
| `--parallel` | 4 |
| `--cache-reuse` | 256 (игнорируется -- recurrent memory, см. [optimization-backlog.md U-001](../../../inference/optimization-backlog.md#u-001-llamacpp-pr-13194--hybrid-memory-checkpointing)) |
| `--jinja` | да |
| `-fa on` | да |
| `-ngl 99` | все слои на GPU |

### Параметры benchmark

```
docker run --rm --network host --user 1000:1000 \
    -v ~/projects/aider:/aider \
    -e OPENAI_API_BASE="http://localhost:8081/v1" \
    -e OPENAI_API_KEY="dummy" -e AIDER_DOCKER=1 \
    aider-polyglot-bench:latest \
    python3 ./benchmark/benchmark.py "smoke-qwen-coder-next-20260426-133519" \
        --model "openai/qwen-coder-next" \
        --edit-format whole \
        --threads 1 --tries 2 --new \
        --exercises-dir polyglot-benchmark \
        --num-tests 50
```

## Pre-flight

- SSH доступен: ✓
- Preset `qwen-coder-next.sh`: ✓
- Модель (4 split, 46 GB): ✓
- Disk free: 1.3 TB
- Ports 8080-8085: свободны
- llama.cpp build: ✓
- Docker image: ✓
- Healthcheck `/v1/models`: OK (через 51 сек после старта preset)

## Результаты (фактические)

### Агрегатные показатели

| Метрика | Значение |
|---------|----------|
| **test_cases** (фактически прогнано) | **30** из 50 запрошенных |
| **pass_rate_1** (single-shot) | **36.7%** (11 из 30) |
| **pass_rate_2** (с retry, --tries 2) | **46.7%** (14 из 30) |
| percent_cases_well_formed | 100.0% (нет malformed responses) |
| num_malformed_responses | 0 |
| user_asks | 67 (модель просила уточнения чаще чем Qwen3.6) |
| test_timeouts | 1 |
| seconds_per_case | **243.5 сек** (~4.1 мин/задача -- быстрее чем Qwen3.6 312.5 сек) |
| prompt_tokens | 225 738 |
| completion_tokens | 69 469 |
| total_tests в датасете | 225 |

### Per-language breakdown

| Язык | Прогнано | Pass 1-try | Pass 2-tries | Pass rate 1 | Pass rate 2 |
|------|----------|------------|--------------|-------------|-------------|
| **Python** | 8 | 7 | 7 | **87.5%** | **87.5%** |
| **Java** | 5 | 2 | 2 | 40% | 40% |
| **C++** | 3 | 1 | 1 | 33% | 33% |
| **Go** | 5 | 1 | 2 | 20% | 40% |
| **JavaScript** | 4 | 0 | 2 | 0% | 50% |
| **Rust** | 5 | 0 | 0 | **0%** | **0%** |
| **Итого** | **30** | **11** | **14** | **36.7%** | **46.7%** |

### Хронология (последние 15 завершённых)

| Время (UTC) | Язык / задача |
|-------------|----------------|
| 15:25:10 | rust/pig-latin |
| 15:30:46 | cpp/gigasecond |
| 15:35:05 | cpp/linked-list |
| 15:35:51 | go/word-search |
| 15:36:21 | python/beer-song |
| 15:36:56 | python/zipper |
| 15:37:16 | rust/alphametics |
| 15:37:31 | go/food-chain |
| 15:38:15 | java/state-of-tic-tac-toe |
| 15:38:39 | python/simple-linked-list |
| 15:39:04 | java/resistor-color-trio |
| 15:39:21 | rust/variable-length-quantity |
| 15:39:59 | rust/nucleotide-codons |
| 15:43:39 | javascript/twelve-days |
| **15:43:45** | **python/zebra-puzzle (последняя)** |
| 15:44 - 18:35 | **застрял в retry-loop** (3 часа) |

## Сравнение с Qwen3.6-35B (тот же день, тот же бенчмарк)

| Метрика | Qwen3.6-35B-A3B | **Qwen3-Coder Next 80B-A3B** | Дельта |
|---------|-------------------|--------------------------------|--------|
| test_cases | 22 | **30** | +8 |
| pass_rate_1 | 27.3% | **36.7%** | **+9.4pp** |
| pass_rate_2 | **54.5%** | 46.7% | -7.8pp |
| Retry effect (pass_2 - pass_1) | +27.2pp | +10.0pp | -17.2pp |
| seconds_per_case | 312.5 | **243.5** | -22% |
| Python | 75% / 75% | **87.5% / 87.5%** | +12.5pp |
| Rust | 0% / 0% | **0% / 0%** | равно |
| JavaScript | 20% / 80% | 0% / 50% | -30pp на retry |
| Java | 50% / 50% | 40% / 40% | -10pp |
| user_asks | 30 | **67** | +37 |
| 100% well-formed | да | **да** | -- |

## Анализ

### Сильные стороны

- **Python -- профильная сила** (87.5% vs 75% у Qwen3.6) -- согласуется со статусом coding-специализированной модели
- **Single-shot выше** на 9.4pp -- модель чаще пишет корректный код с первого раза
- **Скорость 243.5 сек/задача** -- на 22% быстрее Qwen3.6 несмотря на бо́льший размер (80B vs 35B). MoE 3B active даёт сравнимую скорость с тонкой моделью при качестве крупной
- **100% well-formed** -- нет malformed JSON / broken edits

### Слабые стороны

- **Retry почти не помогает** (+10pp vs +27pp у Qwen3.6) -- модель если ошиблась с первого раза, плохо корректируется по test feedback. Это **критичный признак** для agent-coding workflow с iterative refinement
- **Rust 0/5** -- та же катастрофа что у Qwen3.6 (0/4). Модель не справляется с Rust borrow checker / typing
- **JavaScript single-shot 0%** -- на 4 задачах ни одного попадания в первый раз (Qwen3.6 был 20%)
- **user_asks: 67 на 30 задач** -- модель чаще запрашивает уточнения (2.2 раза/задача vs 1.4 у Qwen3.6). В benchmark-режиме это нейтрально, в production агенте -- больше interruption

### Edit format quality

**0 malformed responses** -- идеальная обработка `--edit-format whole`. Это надёжная модель для генерации полных файлов.

### Why retry помогает меньше

Гипотеза: **hybrid memory architecture** (Gated DeltaNet) на повторных запросах вынуждает llama.cpp пересчитывать весь recurrent state с нуля (cache-reuse невозможен -- см. [optimization-backlog U-001](../../../inference/optimization-backlog.md#u-001-llamacpp-pr-13194--hybrid-memory-checkpointing)). Это значит, что при retry модель НЕ "помнит" предыдущий контекст лучше -- она получает только текстовый prompt с test failure, и должна заново "вкатиться". В отличие от full-attention моделей, где KV-cache shifting сохраняет более глубокий контекст.

Practical implication: для Coder Next эффект `--tries 2` существенно ниже чем для standard attention моделей. Можно использовать `--tries 1` без больших потерь в pass-rate -- это сэкономит ~50% времени suite.

## Root cause: почему завис на 30-й задаче

### Симптом

После 15:43:45 (последняя завершённая задача -- python/zebra-puzzle) suite перестал обновлять прогресс. Aider начал серию `litellm.Timeout: APITimeoutError` с exponential backoff (`Retrying in 0.2s → 0.5s → 1s → ...`). За ~3 часа поступило **8 timeout событий**, прогресс остался на 30. Suite был принудительно остановлен в 18:33.

### Анализ

llama-server в это время **продолжал обрабатывать запросы** (в логе видна активная работа slot'ов, restored context checkpoints, prompt processing 4-8K токенов). Запросы доходили до сервера, но клиент aider не получал ответ за свой timeout (default litellm ~60 сек).

Возможные причины:

1. **Long-tail задача** -- модель "залипла" на сложной задаче (sgf-parsing Java или follow-up после twelve-days), генерируя 5K+ токенов. На 50 tok/s = 100+ сек, выходит за client timeout.
2. **Параллельные слоты конфликтуют** -- `--parallel 4` в llama-server vs `--threads 1` в benchmark означает что в очереди стоит 1 запрос, но llama-server планирует под 4. Когда задача длинная, slot ресурсы фрагментируются.
3. **Recurrent state pressure** -- 4 slot'а × 75 MiB checkpoint = 300 MiB KV cache. На retry с длинным prefix (~8K токенов) пересчёт становится compute-bound и медленным.

### Почему aider не вышел из retry-loop

litellm exponential backoff cap на 30 сек, но между retry клиент **не помечает задачу как failed** -- продолжает крутиться бесконечно. В benchmark.py нет hard timeout per-task. Это архитектурный недостаток bench-aider.sh:

- Нет `--max-test-timeout N` параметра
- Нет watchdog который убивал бы зависшие задачи

Это пополняет [optimization-backlog](../../../inference/optimization-backlog.md) новой записью **A-005: hard timeout per task в benchmark.py wrapper**.

## Выводы

1. **Coder Next быстрее и точнее на single-shot**, чем Qwen3.6-35B на одинаковом бенчмарке -- но **retry feedback не поможет** улучшить результат (hybrid memory не сохраняет state между turns)
2. **Python -- лидерство** (87.5%) подтверждает позицию модели как coding-specialist
3. **Rust 0/5 на двух подряд моделях** -- проблема не в модели, а в архитектуре polyglot (или специфика Rust-задач в датасете), требует отдельного расследования
4. **Скорость 243 сек/задача** делает full smoke 50 задач реалистичным: ~3.4 часа
5. **Hybrid memory limitation** -- ключевой фактор замедления и снижения retry-effectiveness. Ждём llama.cpp PR 13194
6. **Need watchdog в benchmark** -- три часа потеряны на retry-loop, нужен hard timeout

## Next steps

- [ ] **A-005** (новая запись в optimization-backlog): добавить `--max-task-timeout 600` в bench-aider.sh, чтобы прервать застрявшие задачи через 10 мин
- [ ] **A-001**: применить `--tries 1` в smoke -- особенно полезно для hybrid моделей где retry неэффективен
- [ ] **B-001**: убрать `--cache-reuse 256` из [`vulkan/preset/qwen-coder-next.sh`](../../../../scripts/inference/vulkan/preset/qwen-coder-next.sh) (не работает на recurrent memory, создаёт ложное ощущение)
- [ ] **U-001**: следить за llama.cpp PR 13194 (hybrid memory checkpointing) -- merge решит проблему cache-reuse для Coder Next + Qwen 3.6-27B
- [ ] Расследовать **Rust 0/5 у двух моделей подряд** -- запустить отдельно `--num-tests 8 --languages rust`, посмотреть failure modes (модель пишет код vs модель не понимает Cargo conventions vs специфика polyglot Rust dataset)
- [ ] Сравнить с **Qwen3-Coder 30B-A3B** (без "Next", чистая MoE attention) -- ожидаем что cache-reuse там работает и retry эффективнее
- [ ] Полный baseline на 50 задач для Coder Next -- запустить с применённой watchdog защитой A-005

## Связанные статьи

- [runbooks/aider-polyglot.md](../runbooks/aider-polyglot.md) -- runbook запуска
- [results.md](../results.md) -- журнал прогонов и лидерборд платформы
- [2026-04-26-aider-smoke-qwen3.6-35b.md](2026-04-26-aider-smoke-qwen3.6-35b.md) -- сравнительный baseline того же дня
- [families/qwen3-coder.md](../../../models/families/qwen3-coder.md) -- описание модели
- [inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- бэклог оптимизаций (исходник для A-001/A-005, B-001, U-001)
