# Aider Polyglot full -- Qwen3.6-35B-A3B (text-only) (2026-04-28 → 2026-04-29)

**Mode**: full (cpp,go,java,javascript,python = 195 из 225, --tries 2)
**Scope**: одна модель, leaderboard-quality замер на text-only варианте Qwen3.6-35B-A3B
**Total time**: **~22 часа wall clock** (13:53 UTC 2026-04-28 → ~12:00 UTC 2026-04-29)
**Статус**: ✅ **завершён** -- **195/195 задач (100% coverage)**, watchdog 0 срабатываний, 0 manual resume циклов
**Логи**: `/tmp/aider-full-35b-text-20260428-1353/`, llama-server `/tmp/llama-server-8084.log`

## Контекст и цель

Qwen3.6-35B-A3B-text smoke на 20 задачах (2026-04-27) показал **70.0% pass_rate_2** -- абсолютный рекорд платформы. Этот full прогон проверяет:

1. **Регрессия к среднему**: 70% на 20 задачах -- статистическая ошибка ±10pp. На 195 задачах reasonable expectation 60-67%
2. **Стабильность hybrid-модели на 22+ часах**: Coder Next 80B-A3B потребовал 52 watchdog kill + 14 manual resume на 16h. 35B-text меньшая модель -- ожидание меньше reasoning loops
3. **Профиль качества по языкам**: где 35B-text сильнее/слабее Coder Next 80B-A3B
4. **Сопоставление с Coder Next** при 100% покрытии задач (Coder Next остановлен на 178/195 из-за stuck loops)

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
| Модель | `Qwen3.6-35B-A3B-UD-Q4_K_M.gguf` (~22 GB) |
| Архитектура | **`qwen35moe`** (по llama-server log: 40 blocks, 256 experts, 8 used, hybrid Gated DeltaNet с SSM) |
| Layers | 10 / 40 full attention, 30 SSM (recurrent) |
| KV cache | 2.5 GiB (32768 cells × 10 attention layers × 4 seqs) |
| Context window | 131072 (128K) |
| Recurrent memory | **есть** (Gated DeltaNet) -- блокирует inter-task cache reuse |
| Mmproj | **отсутствует** (text-only вариант) |
| Квантизация | Q4_K_M (Unsloth Dynamic 2.0) |
| Порт | 8084 |
| `--parallel` | 4 |
| `--cache-reuse` | 256 (intra-task через встроенный checkpoint механизм llama-server) |
| `--batch-size / --ubatch-size` | 4096 / 4096 |
| `--keep` | 1500 |
| `--jinja` | да |
| `-fa on` | да |

### Параметры benchmark

```bash
./scripts/inference/bench-aider.sh --full --tries 2 \
    --languages cpp,go,java,javascript,python \
    --model qwen3.6-35b-text --port 8084 \
    --output /tmp/aider-full-35b-text-20260428-1353
```

Watchdog: default `--task-timeout 900s` (15 мин), max-resumes 3.

## Результаты

### Агрегатные показатели

| Метрика | Значение |
|---------|----------|
| **test_cases** | **195/195** ✅ (100% coverage) |
| **pass_rate_1** (single-shot) | **29.2%** (57/195) |
| **pass_rate_2** (с retry, --tries 2) | **65.6%** (128/195) |
| Retry effect (pass_2 - pass_1) | **+36.4pp** |
| percent_cases_well_formed | **100.0%** ✅ (0 malformed) |
| num_malformed_responses | 0 |
| error_outputs | 14 (сетевые сбои) |
| user_asks | 156 (~0.80 / задача) |
| seconds_per_case | **~407** (22h × 60 / 195) |
| **Watchdog kills** | **0** ⭐ (за весь прогон) |
| **Manual resumes** | **0** (полностью без вмешательства) |

### Per-language breakdown

| Язык | Прогнано / в датасете | Pass 1-try | Pass 2-tries | Rate 1 | Rate 2 |
|------|----------------------|------------|--------------|--------|--------|
| **JavaScript** | 49/49 ✅ | 14 | **37** | 28.6% | **75.5%** ⭐ |
| **C++** | 26/26 ✅ | 8 | **19** | 30.8% | **73.1%** ⭐ |
| **Python** | 34/34 ✅ | 12 | **24** | 35.3% | **70.6%** ⭐ |
| **Go** | 39/39 ✅ | 12 | 24 | 30.8% | 61.5% |
| **Java** | 47/47 ✅ | 11 | 24 | 23.4% | 51.1% |
| **Итого** | **195/195** | **57** | **128** | **29.2%** | **65.6%** |

**100% покрытие во всех 5 языках** -- единственный full прогон на платформе достигший этого без manual resume.

### Активность llama-server (cache!)

| Событие | Qwen3.6-35B-text |
|---------|-------------------|
| `loaded multimodal model` | ✗ (text-only) |
| `llama_memory_recurrent` | ✓ (Gated DeltaNet) |
| `cache_reuse is not supported by multimodal` | -- (не применимо) |
| `forcing full prompt re-processing` events | **15+** (между задачами aider'а) |
| `restored context checkpoint` events | many (intra-task multi-turn) |
| `created context checkpoint N of 32` | many |

**Cache reuse архитектурно ограничен** (как у Coder Next): inter-task blocked recurrent SSM state, intra-task работает через встроенный checkpoint механизм llama-server. Ждём llama.cpp PR #19670.

## Pre-flight

- SSH ✓
- Docker image (7.26 GB) ✓
- Disk free: 1.3 TB ✓
- Ports 8080-8085: свободны до старта
- Модель `Qwen3.6-35B-A3B-UD-Q4_K_M.gguf` (22 GB): ✓
- llama.cpp build: ✓
- Healthcheck `/v1/models`: OK с первой попытки

## Сравнение с Coder Next 80B-A3B (final)

| Метрика | Coder Next 80B-A3B | **35B-text** | Δ |
|---------|---------------------|---------------|---|
| **test_cases** | 178/195 (91.3%) | **195/195 (100%)** ✅ | +17 задач, +8.7pp coverage |
| pass_rate_1 | 33.7% | 29.2% | -4.5pp |
| **pass_rate_2** | **68.0%** | **65.6%** | -2.4pp |
| Retry effect | +34.3pp | **+36.4pp** | +2.1pp |
| seconds_per_case | ~99 | ~407 | в 4.1× медленнее |
| Total time | 16h | 22h | +6h |
| **Watchdog kills** | 52 | **0** | -52 ⭐ |
| **Manual resumes** | 14 | **0** | -14 |
| Размер модели | 45 GiB | **20.6 GiB** | в 2.2× меньше |
| 100% well-formed | 100% | **100%** | -- |

**35B-text проиграл на 2.4pp в pass_rate_2**, но:
- **+8.7pp coverage** (полное 100% vs 91.3%)
- **-52 watchdog kills** -- production-stability порядок выше
- **В 2.2× меньшая модель** -- занимает меньше памяти, оставляет место для других сервисов

### Per-language: 35B-text vs Coder Next

| Язык | Coder Next pass_2 | 35B-text pass_2 | Δ |
|------|-------------------|------------------|---|
| **C++** | 61.1% | **73.1%** | **+12.0pp** ⭐ |
| Python | 76.5% | 70.6% | -5.9pp |
| JavaScript | 80.9% | 75.5% | -5.4pp |
| Java | 59.1% | 51.1% | -8.0pp |
| **Go** | 58.3% | **61.5%** | **+3.2pp** ⭐ |

**Профили моделей дополняющие**:
- 35B-text **значимо сильнее** в C++ (+12pp) и Go (+3.2pp) -- лучше следует строгим типам и системному коду
- Coder Next **сильнее** в Java (+8pp), Python (+5.9pp), JavaScript (+5.4pp) -- больший active size помогает в диалоговых языках

## Анализ

### Сильные стороны 35B-text

- **100% покрытие на full** -- единственный прогон без потерянных задач из-за reasoning loops
- **0 watchdog kills за 22 часа** -- best-in-class production-stability на платформе
- **Retry effect +36.4pp** -- модель отлично учится на ошибках через aider error feedback. Близко к лидеру (Coder Next +34.3, 35B-text +36.4)
- **C++ лидерство (73.1%)** -- абсолютный лидер платформы на C++ задачах. Лучше Coder Next (61.1%), 30B-A3B (32.0%)
- **100% well-formed responses** -- 0 malformed на 195 задач, идеальная стабильность edit format
- **Размер 20.6 GiB** -- в 2.2× меньше Coder Next, оставляет 100 GiB для parallel сервисов

### Слабые стороны

- **Скорость ~407 sec/case** -- в 4.1× медленнее Coder Next (99 sec/case). Hybrid Gated DeltaNet архитектура без cache reuse сильно замедляет на full
- **pass_rate_2 = 65.6%** vs Coder Next 68.0% -- модель чуть слабее по качеству, особенно на языках с гибкой типизацией (Python/JS/Java)
- **22 часа wall clock** -- слишком долго для daily benchmark workflow
- **error_outputs = 14** -- 14 сетевых сбоев (vs 1 у Coder Next). Возможно длинные tcp-соединения retry'ев временами теряются

### Что подтверждено

1. **Регрессия к среднему ПОДТВЕРЖДЕНА**: smoke 20 (70.0%) → full 195 (65.6%) -- разница -4.4pp, в пределах статистической ошибки малой выборки
2. **Hybrid Gated DeltaNet -- стабильнее чем 80B-A3B**: 0 watchdog за 22h vs 52 kills у Coder Next за 16h. Меньшая модель = меньше long reasoning chains
3. **Production-grade workflow**: первый прогон на платформе **достигший 100% покрытия за один заход без manual intervention**
4. **C++ niche lock**: 35B-text -- абсолютный лидер C++ среди open-weight моделей платформы. Использовать для C++ workloads даже если медленнее
5. **Auto-resume инфраструктура работает**: за 22 часа watchdog не сработал ни разу -- значит max-resumes 3 не нужен был, базовый механизм достаточен

## Выводы

1. **195/195 = 100% coverage** -- первый прогон на платформе с полным покрытием без потерянных задач
2. **pass_rate_2 = 65.6%** -- статистически достоверный baseline на 195 задачах (95% CI ±6.7pp)
3. **Регрессия к среднему -4.4pp** vs smoke 20 (70.0%) -- ожидаемая флуктуация на маленькой выборке
4. **0 watchdog + 0 resume за 22 часа** -- best-in-class stability для long-running benchmarks
5. **Coder Next по качеству на 2.4pp впереди** при значительно бо́льшем размере и регулярном watchdog interventions
6. **35B-text лидер C++ (73.1%)** на платформе -- single-language workloads на C++ -- этот пресет
7. **Hybrid arch ограничивает скорость**: 407 sec/case в 4× медленнее Coder Next 99 sec/case несмотря на меньший размер

## Next steps

- [x] Зафиксировать прогон в [results.md](../results.md): pass_rate_2 65.6% на 195/195
- [x] Обновить запись 35B-A3B в [families/qwen36.md](../../../models/families/qwen36.md): финальные числа full
- [ ] Обновить таблицу покрытия в [runs/README.md](README.md): 35B-text → ✅ full 195/195, 65.6%
- [ ] Запустить **Qwen3.5-122B-A10B full + --tries 2** -- кандидат на абсолютный рекорд (10B active vs 3B). Cache reuse РАБОТАЕТ (standard MoE attention), потенциал 70-80% pass_2
- [ ] Запустить **Gemma 4 26B-A4B (text-only) smoke + --tries 2** -- заполнить пробел "не-Qwen" в leaderboard
- [ ] Скачать **UD-Q5_K_M Qwen3.6-35B-A3B** (~26.5 GiB) и smoke A/B vs Q4_K_M -- проверить +3-5pp гипотезу
- [ ] После merge llama.cpp PR #19670 (hybrid memory snapshot) -- replay прогона, ожидаем -50% sec/case на multi-turn

## Связанные статьи

- [results.md](../results.md) -- журнал прогонов и лидерборд платформы
- [2026-04-27-aider-smoke-qwen3.6-35b-text-tries2.md](2026-04-27-aider-smoke-qwen3.6-35b-text-tries2.md) -- smoke baseline (70.0% на 20 задачах)
- [2026-04-27-aider-full-qwen-coder-next.md](2026-04-27-aider-full-qwen-coder-next.md) -- A/B counterpart full (Coder Next 80B-A3B 68.0%)
- [2026-04-26-aider-full-qwen3-coder-30b.md](2026-04-26-aider-full-qwen3-coder-30b.md) -- 30B-A3B full с cache reuse (26.3%)
- [families/qwen36.md](../../../models/families/qwen36.md) -- описание модели и roadmap
- [inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- A-005 (watchdog), B-001 (cache-reuse), U-001 (PR tracking)
