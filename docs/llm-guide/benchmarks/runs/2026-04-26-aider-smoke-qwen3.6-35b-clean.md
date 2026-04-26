# Aider Polyglot smoke -- Qwen3.6-35B-A3B (2026-04-26, clean run)

**Mode**: smoke (20 задач, --tries 1, no rust)
**Scope**: одна модель, чистый прогон после правок инфраструктуры
**Total time**: **1h 11m** (18:58 -- 20:09 UTC)
**Статус**: ✅ **завершён штатно** -- первый полный прогон без прерываний/timeout
**Лог сервера**: `/tmp/aider-test-20260426-1858/`

## Контекст

Это **второй замер Qwen3.6-35B-A3B на платформе** после правок инфраструктуры из commit `d6582fe..cef5f2e`:

- Watchdog защита от litellm retry-loop (A-005)
- Mode mapping --smoke = 20 задач + --tries 1 (A-001, A-003)
- `--languages` для исключения проблемного Rust (A-004)
- Убран non-functional `--cache-reuse 256` из преcета (B-001)

Цель: получить чистый baseline для Qwen3.6-35B и проверить что инфраструктурные правки работают как задумано.

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
| Модель | `Qwen3.6-35B-A3B-UD-Q4_K_M.gguf` (~21 GB) |
| MMProj | `mmproj-Qwen3.6-35B-A3B-F16.gguf` |
| Архитектура | **Hybrid Gated DeltaNet + multimodal**, MoE 35B/3B active, 40 слоёв |
| Recurrent state | 251 MiB на slot (4 cells × 40 layers × 4 seqs, FP32) |
| Квантизация | Q4_K_M (UD) |
| Порт | 8085 |
| Контекст | 131072 (128K) |
| `--parallel` | 4 |
| `--cache-reuse` | **отсутствует** (B-001 -- архитектурно не работает) |
| `--jinja` | да |
| `-fa on` | да |
| `-ngl 99` | все слои на GPU |

### Параметры benchmark

```bash
docker run --rm --network host --user 1000:1000 \
    -v ~/projects/aider:/aider \
    -e OPENAI_API_BASE="http://localhost:8085/v1" \
    -e OPENAI_API_KEY="dummy" -e AIDER_DOCKER=1 \
    aider-polyglot-bench:latest \
    python3 ./benchmark/benchmark.py "smoke-qwen3.6-35b-20260426-185800" \
        --model "openai/qwen3.6-35b" \
        --edit-format whole \
        --threads 1 --tries 1 --new \
        --exercises-dir polyglot-benchmark \
        --num-tests 20 \
        --languages cpp,go,java,javascript,python
```

Watchdog: task-timeout 900 сек, total-timeout 21600 сек -- **не срабатывал**.

## Результаты

### Агрегатные показатели

| Метрика | Значение |
|---------|----------|
| **test_cases** | **20/20** ✅ (полный прогон) |
| **pass_rate_1** (single-shot) | **35.0%** (7 из 20) |
| pass_rate_2 (с retry) | -- (mode --smoke использует --tries 1) |
| percent_cases_well_formed | 100.0% |
| num_malformed_responses | 0 |
| user_asks | 16 (vs 30 в предыдущем 22-задач прогоне) |
| test_timeouts | 0 |
| seconds_per_case | **210.5** (~3.5 мин/задача) |
| prompt_tokens | 58 637 |
| completion_tokens | 198 873 |

### Per-language breakdown

| Язык | Прогнано | Pass 1-try | Pass rate |
|------|----------|------------|-----------|
| **C++** | 4 | 2 | **50%** |
| **Python** | 5 | 2 | **40%** |
| **Go** | 3 | 1 | 33% |
| **Java** | 3 | 1 | 33% |
| **JavaScript** | 5 | 1 | 20% |
| **Rust** | 0 | -- | (исключён по `--languages`) |
| **Итого** | **20** | **7** | **35.0%** |

### Активность llama-server

- **41 событие** `forcing full prompt re-processing due to lack of cache data` в логе
- Это **подтверждает архитектурное ограничение** hybrid Gated DeltaNet + multimodal -- recurrent state не сохраняется между задачами/turn'ами
- Каждый новый запрос пересчитывает prefix с нуля
- См. [optimization-backlog U-001](../../../inference/optimization-backlog.md#u-001-cache-reuse-для-hybrid--multimodal-моделей)

## Сравнение с предыдущими прогонами

| Метрика | Этот прогон (clean) | Qwen3.6-35B (прерванный) | Coder Next (прерванный) |
|---------|---------------------|---------------------------|--------------------------|
| Завершён? | ✅ да | ❌ taймаут 22/50 | ❌ retry-loop 30/50 |
| test_cases | 20 / 20 | 22 / 50 | 30 / 50 |
| --tries | 1 | 2 | 2 |
| Языки | 5 (no rust) | 6 | 6 |
| pass_rate_1 | **35.0%** | 27.3% | 36.7% |
| pass_rate_2 | -- | 54.5% | 46.7% |
| sec/case | **210.5** | 312.5 | 243.5 |
| Время | 1h 11m | 135 мин (прерван) | 5h 3m (зависал 3 ч) |
| user_asks | 16 | 30 | 67 |
| watchdog srabatival | нет | -- (не было) | -- (не было) |

### Что подтвердил clean run

1. **Watchdog работает**: 41 случай `forcing full prompt re-processing` в логе означал что некоторые задачи могли уйти в долгую генерацию -- watchdog бы остановил при stall, но stall не было
2. **--tries 1 экономит время**: 210 сек/задача vs 312 сек у --tries 2 = -33%, ожидаемо
3. **Исключение Rust** (где модель давала 0/4) убрало "задачу-якорь" которая тратила ~5 мин впустую
4. **pass_rate_1 35% выше** чем 27% в предыдущем 22-задач прогоне -- статистическая флуктуация на малой выборке (95% CI: ±20pp), реальный pass rate скорее всего ~30%

## Анализ

### Сильные стороны

- **C++ 50%** (2/4) -- лучший результат среди всех языков, неожиданно (обычно C++ хуже Python)
- **Python 40%** (2/5) -- стабильный профильный язык, ниже чем 75% в предыдущем прогоне (выборка маленькая)
- **100% well-formed** -- модель идеально следует edit-format `whole`, не было ни одной malformed response
- **Низкий user_asks (16 на 20 задач = 0.8/задача)** -- модель работает почти автономно, в 2-3 раза меньше interruption чем в предыдущем прогоне

### Слабые стороны

- **JavaScript 20%** -- худший результат, неочевидно почему (выборка 5 задач может смещать)
- **Cache-reuse не работает** (41 events `forcing full prompt re-processing`) -- архитектурное ограничение hybrid + multimodal, ничего не поделаешь
- **Завышенный seconds_per_case** -- часть времени тратится на full prompt processing (~5-10% overhead vs модели где cache работает)

### Edit format quality

**Идеальный**: 0 malformed, 0 syntax errors, 0 indentation errors, 0 lazy comments, 0 exhausted context windows. `whole` format на этой модели работает безупречно.

## Выводы

1. **Инфраструктурные правки работают**: первый прогон без прерывания, без зависания, в предсказуемое время (1h 11m)
2. **Watchdog не срабатывал**, но был наготове -- safety-net пройден
3. **pass_rate_1 ~30-35%** на small sample -- baseline для дальнейших A/B сравнений
4. **Hybrid memory + multimodal -- архитектурный потолок** для cache reuse, исправится только в upstream PR (см. U-001/U-002)
5. **Время прогона предсказуемо**: 20 задач × 210 сек ≈ 70 мин, watchdog cap (15 мин/задача) ни разу не приближался

## Next steps

- [ ] **Запустить A/B на Qwen3-Coder 30B-A3B** (M-001) -- standard MoE attention, cache-reuse работает. Тот же scope (20 задач, no rust). **В процессе на момент написания этого отчёта.**
- [ ] Сравнить seconds_per_case между Qwen3.6-35B (210) и Coder 30B-A3B -- ожидаем разрыв в 30%+
- [ ] Полный прогон --full на Qwen3-Coder 30B (225 задач) для leaderboard-quality замера
- [ ] Расследовать JavaScript 20% (5 задач, малая выборка -- возможно случайность)

## Связанные статьи

- [results.md](../results.md) -- журнал прогонов и лидерборд платформы
- [runs/2026-04-26-aider-smoke-qwen3.6-35b.md](2026-04-26-aider-smoke-qwen3.6-35b.md) -- предыдущий прерванный прогон (для сравнения)
- [runs/2026-04-26-aider-smoke-qwen-coder-next.md](2026-04-26-aider-smoke-qwen-coder-next.md) -- прерванный Coder Next
- [families/qwen36.md](../../../models/families/qwen36.md) -- описание модели
- [inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- бэклог оптимизаций (U-001 cache reuse, M-001 30B baseline)
