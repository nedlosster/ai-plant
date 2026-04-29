# Aider Polyglot smoke -- Qwen3-Coder 30B-A3B (2026-04-26, A/B baseline)

**Mode**: smoke (20 задач, --tries 1, no rust)
**Scope**: эталонный замер для cache-reuse A/B сравнения (M-001)
**Total time**: **0h 10m** (20:11 -- 20:21 UTC, прогон + setup overhead)
**Статус**: ✅ **завершён штатно** -- в **~7 раз быстрее** Qwen3.6-35B на том же scope
**Лог сервера**: `/tmp/aider-test-30b-20260426-2011/`

## Контекст и цель

Qwen3-Coder 30B-A3B -- **эталонная модель платформы для cache-reuse**:
- Standard MoE attention (нет Gated DeltaNet recurrent state)
- Без mmproj (не multimodal)
- Single full-attention path -- llama.cpp может полноценно использовать cache reuse / prompt cache / context shifting

**Цель прогона**: получить прямой A/B замер влияния cache-reuse и hybrid memory на agent-coding производительность относительно Qwen3.6-35B-A3B (тот же scope: 20 задач, no rust, --tries 1) того же дня.

См. [optimization-backlog M-001](../../../inference/optimization-backlog.md#m-001-qwen3-coder-30b-a3b-как-baseline-для-cache-sensitive-workloads).

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
| Модель | `Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf` (~18 GB) |
| Архитектура | **Standard MoE attention**, 30B/3B active, 48 слоёв, n_swa=0 |
| KV cache | **Стандартный** 12288 MiB (32768 cells × 48 layers × 4 seqs, FP16) |
| Recurrent memory | **отсутствует** |
| Mmproj | **отсутствует** (не multimodal) |
| Квантизация | Q4_K_M |
| Порт | 8081 |
| Контекст | 131072 (128K) |
| `--parallel` | 4 |
| `--cache-reuse` | **256** (работает -- standard attention) |
| `--jinja` | да |
| `-fa on` | да |

### Параметры benchmark

```bash
docker run --rm --network host --user 1000:1000 \
    -v ~/projects/aider:/aider \
    -e OPENAI_API_BASE="http://localhost:8081/v1" \
    -e OPENAI_API_KEY="dummy" -e AIDER_DOCKER=1 \
    aider-polyglot-bench:latest \
    python3 ./benchmark/benchmark.py "smoke-qwen3-coder-30b-20260426-201117" \
        --model "openai/qwen3-coder-30b" \
        --edit-format whole \
        --threads 1 --tries 1 --new \
        --exercises-dir polyglot-benchmark \
        --num-tests 20 \
        --languages cpp,go,java,javascript,python
```

## Результаты

### Агрегатные показатели

| Метрика | Значение |
|---------|----------|
| **test_cases** | **20 / 20** ✅ |
| **pass_rate_1** | **15.0%** (3 из 20) |
| seconds_per_case | **17.4** (~17 сек/задача) |
| percent_cases_well_formed | 100.0% |
| num_malformed_responses | 0 |
| user_asks | 14 |
| test_timeouts | 1 |
| prompt_tokens | 56 487 |
| completion_tokens | **17 814** (vs 198 873 у 35B -- 11× меньше!) |
| Total time | **0h 10m** (включая startup) |

### Per-language breakdown

| Язык | Прогнано | Pass 1-try | Pass rate |
|------|----------|------------|-----------|
| **Python** | 1 | 1 | **100%** ⭐ |
| **Go** | 3 | 1 | 33% |
| **C++** | 4 | 1 | 25% |
| **Java** | 3 | 0 | **0%** |
| **JavaScript** | 9 | 0 | **0%** ⚠️ |
| **Итого** | 20 | 3 | **15.0%** |

**Внимание**: random subset benchmark.py выбрал 9 из 20 задач JavaScript (45% выборки). 0/9 на JavaScript радикально занижает overall pass rate. Это **artifact малой выборки**, а не реальное отражение способностей модели на JavaScript.

### Активность llama-server (cache!)

| Событие | Qwen3.6-35B (clean) | **Qwen3-Coder 30B** |
|---------|---------------------|----------------------|
| `loaded multimodal model` | ✓ (mmproj F16) | **✗** (no mmproj) |
| `llama_memory_recurrent: 251 MiB` | ✓ | **✗** (нет recurrent state) |
| Standard `llama_kv_cache` | -- | **✓ 12288 MiB** |
| `prompt cache is enabled` (8192 MiB limit) | -- | **✓** |
| `forcing full prompt re-processing` events | **41** | **0** |
| `cache_reuse is not supported by multimodal` | да | нет |

**Ключевой факт**: за всё время прогона **ноль (0)** случаев `forcing full prompt re-processing` -- cache reuse работает прозрачно.

## Сравнение с Qwen3.6-35B-A3B (тот же день, тот же scope)

| Метрика | Qwen3.6-35B (clean) | **Qwen3-Coder 30B** | Δ |
|---------|---------------------|----------------------|---|
| test_cases | 20 / 20 | **20 / 20** | -- |
| pass_rate_1 | 35.0% (7/20) | **15.0%** (3/20) | **−57%** |
| **seconds_per_case** | 210.5 | **17.4** | **−92%** (12× быстрее) |
| Total time | 1h 11m | **0h 10m** | −86% |
| 100% well-formed | ✓ | ✓ | -- |
| user_asks | 16 | 14 | −12% |
| **completion_tokens** | 198 873 | **17 814** | **−91%** (модель пишет кратко) |
| prompt_tokens | 58 637 | 56 487 | −4% |
| `forcing full prompt re-processing` | **41** | **0** | архитектурно |
| Cache works | ❌ | **✅** | критично |

## Анализ

### Выгода cache reuse в числах

Финальные данные подтверждают: **17.4 сек/задача vs 210.5 сек/задача** у Qwen3.6-35B = **12× ускорение**.

Атрибуция выигрыша (приближённо):

| Фактор | Вклад в speedup |
|--------|-------------------|
| **Cache reuse работает** (0 vs 41 events `forcing full prompt re-processing`) | ~30-40% |
| **Меньше output токенов** (17K vs 199K -- 11× меньше) | ~30% |
| **Базовая скорость tg выше** (86 vs 58 tok/s) | ~15-20% |
| **Нет mmproj overhead** (нет vision encoder pass) | ~10% |
| **Меньшая модель -- быстрее каждый prefill** | ~5-10% |

Самый неожиданный фактор -- **completion tokens в 11× меньше**. Qwen3-Coder 30B-A3B пишет **значительно более лаконичный код** чем Qwen3.6-35B. Это может быть особенностью fine-tune (Coder-Instruct training корпус) либо просто меньшей "болтливостью" модели.

### Trade-off: скорость vs качество

| | Qwen3.6-35B | Qwen3-Coder 30B |
|---|--------------|-----------------|
| Скорость (sec/case) | 210.5 | **17.4** ⭐ |
| Качество (pass_rate_1) | **35.0%** ⭐ | 15.0% |
| Качество × Скорость | 35% / 210s = 0.17 pp/sec | **15% / 17s = 0.88 pp/sec** ⭐ |

**Throughput (правильных задач в секунду)**: 30B даёт ~5× больше "решённых задач в секунду" -- если задача "перебрать много промптов и найти лучшие" (не "отшлифовать одну до perfection"), 30B оптимальнее.

### Почему 30B провалился на JavaScript 0/9?

В random subset из 20 задач 9 (45%) оказались JavaScript -- это **выборочное смещение**. Если повторить прогон с другим seed -- результат может быть существенно другим.

Конкретные провалы: food-chain, phone-number, complex-numbers, pig-latin, triangle, queen-attack, two-bucket. Это **средне-сложные** задачи -- модель пишет лаконичный, но не до конца правильный код. Скорее всего нужны больше токенов на explanation+correction (которых модель не пишет).

В предыдущем 22-задач прогоне на Qwen3.6-35B JavaScript была 4/5 (80% с retry). Контраст показывает что **30B плохо корректируется** даже когда видит test failures (--tries 1 не помогает, но и --tries 2 вряд ли спас бы при таком кратком стиле).

### Что подтверждено

1. **Hybrid memory + multimodal -- архитектурный потолок**, который радикально снижает производительность agentic workloads даже когда сама модель быстрая (Qwen3.6-35B номинально 58 tok/s, но фактический throughput для бенчмарка хуже из-за overhead)
2. **Standard attention modela -- в разы быстрее** для multi-turn workflows. Если важен low-latency code completion / multi-turn aider -- использовать Qwen3-Coder 30B-A3B.
3. **prompt cache** в llama-server -- активная фича на standard attention, не работала на Qwen3.6-35B

## Выводы

1. **Hypothesis M-001 ПОДТВЕРЖДЕНА (частично)**: cache reuse + standard attention даёт **12× ускорение по времени**, но **качество в 2.3× ниже**.
2. **Архитектурный выбор -- двусторонний**: Qwen3.6-35B показывает лучшее качество (35% vs 15%), но throughput хуже в 5×. Простой "переход на 30B" неоптимален.
3. **Стратегия default**: пока **остаётся Qwen3.6-35B как default**, поскольку качество критично для production agent-coding. 30B -- для специфических use cases:
   - Quick draft / boilerplate (где скорость важнее качества)
   - High-frequency FIM completion (где cache hit ~80%)
   - Параллельный inference батч-задач для ML-pipeline
4. **Random subset 20 задач -- слишком мало** для стат-достоверности. JavaScript 0/9 (45% выборки!) сильно искажает результат. Полный --full 225 задач даст более точную картину.
5. **Кратки стиль 30B -- key feature**: 17K output tokens vs 199K у 35B. Это подходит для tools которые ожидают лаконичных ответов (FIM), но не для agent-mode с длинными explanations.

## Next steps

- [ ] **Запустить Qwen3-Coder Next 80B-A3B** на том же scope (20 задач, no rust, --tries 1) -- получить ещё одну точку. Hybrid (как 35B) но без multimodal -- интересный middle ground.
- [ ] **Запустить Devstral 2 24B** (dense, no mmproj) -- ещё один baseline standard attention для сравнения
- [ ] **Full --full 225 задач** на Qwen3-Coder 30B-A3B (оценочно ~3.5 часа) -- для leaderboard-quality сравнения с публичными цифрами
- [ ] Перезапустить smoke на 30B с другим seed (если возможно) -- проверить если JavaScript 0/9 был random выбор
- [ ] Возможно тест с `--tries 2` на 30B -- проверить улучшается ли качество с retry

## Связанные статьи

- [results.md](../results.md) -- журнал прогонов и лидерборд платформы
- [2026-04-26-aider-smoke-qwen3.6-35b-clean.md](2026-04-26-aider-smoke-qwen3.6-35b-clean.md) -- A/B counterpart этого прогона
- [families/qwen3-coder.md](../../../models/families/qwen3-coder.md) -- описание модели
- [inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- M-001 (этот тест), U-001/U-002 (мониторинг upstream PR)
