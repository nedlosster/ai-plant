# Aider Polyglot full -- Qwen3.5-122B-A10B (2026-04-29 → 2026-04-30)

**Mode**: full (cpp,go,java,javascript,python = 195 из 225, --tries 2)
**Scope**: одна модель, рекордный замер для самой большой open-weight MoE на платформе
**Total time**: **~36 часов wall clock** (4 resume сессии: orig 09:38 → resume2 → resume3 → resume4 → finish)
**Статус**: ✅ **завершён** -- **195/195 задач (100% coverage)**, **pass_rate_2 = 76.9%** -- абсолютный рекорд платформы
**Логи**: `/tmp/aider-full-122b-*/`, llama-server `/tmp/llama-server-8081.log`

## Контекст и цель

Qwen3.5-122B-A10B -- самая большая MoE-модель на платформе (122B total / 10B active vs 3B active у Coder Next и 35B-A3B). Гипотеза: больший active size при тех же параметрах MoE-архитектуры даёт качественный jump на agentic-coding задачах.

Цели прогона:

1. **Проверить гипотезу 10B active > 3B active** на benchmark (близко к 70-75% leaderboard SWE-V)
2. **Получить новый рекорд платформы** для full + --tries 2 (текущий рекорд -- Coder Next 68.0% на 178/195)
3. **Подтвердить paritет с frontier mid-tier** (o3 base, DeepSeek V3.2-Exp ~74-77%)
4. **Тест A-006 fix** в bench-aider.sh (LITELLM_REQUEST_TIMEOUT + retry-loop detector) на 122B где responses длиннее

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
| Модель | `Qwen3.5-122B-A10B-Q4_K_M-*-of-3.gguf` (split, ~71 GB total) |
| Архитектура (по llama-server log) | `qwen35moe`, **HYBRID Gated DeltaNet** -- 12 attention layers из 49, остальные 37 -- recurrent SSM |
| Active params | 10B (top-8 из 128 экспертов) |
| Total params | 122B |
| n_ctx_train | 262144 (256K native) |
| n_embd | 3072, head_count_kv = 2 (агрессивный GQA) |
| Контекст в пресете | **131072** (128K) -- preset обновлён до 256K в commit a85169f, но прогон шёл на старом 128K |
| Mmproj | отсутствует (text-only) |
| Квантизация | Q4_K_M (Unsloth) |
| Порт | 8081 |
| `--parallel` | 2 |
| `--cache-reuse` | 256 (intra-task через встроенный checkpoint) |
| `--cache-type-k/v` | q8_0 |
| `--keep` | 1500 |
| `--no-mmap` | да |
| `--reasoning off` | **да** (применено после observation что встроенный thinking ломает single-shot) |
| `-fa on` | да |

### Параметры benchmark

```bash
./scripts/inference/bench-aider.sh --full --tries 2 \
    --languages cpp,go,java,javascript,python \
    --model qwen3.5-122b --port 8081 \
    --task-timeout 1200 \
    --output /tmp/aider-full-122b-*
```

Watchdog: `task-timeout 1200` (20 мин/задача), max-resumes 3.

## Результаты

### Финальные агрегатные показатели

| Метрика | Значение |
|---------|----------|
| **test_cases** | **195/195** ✅ (100% coverage) |
| **pass_rate_1** (single-shot) | **37.9%** (74/195) |
| **pass_rate_2** (с retry, --tries 2) | **76.9%** (150/195) ⭐⭐ |
| Retry effect (pass_2 - pass_1) | **+39.0pp** |
| percent_cases_well_formed | 100% |
| Watchdog kills | 0 (за 36h после reasoning off!) |
| Manual resumes | 4 (через --cont, max-resumes цикл) |

### Per-language breakdown

| Язык | Прогнано | Pass-1 | Pass-2 |
|------|----------|--------|--------|
| **JavaScript** | 49/49 ✅ | 25 (51.0%) | **42 (85.7%)** ⭐⭐ |
| **Python** | 34/34 ✅ | 18 (52.9%) | **29 (85.3%)** ⭐⭐ |
| **C++** | 26/26 ✅ | 10 (38.5%) | **20 (76.9%)** ⭐ |
| **Go** | 39/39 ✅ | 11 (28.2%) | **28 (71.8%)** |
| **Java** | 47/47 ✅ | 10 (21.3%) | **31 (66.0%)** |
| **Итого** | **195/195** | **74** (37.9%) | **150** (76.9%) ⭐⭐ |

**Лидеры**: Python и JavaScript ~85% pass_2 -- **сопоставимо с frontier closed-weight** на этих языках.

## Лидерборд платформы после этого прогона

| Модель | Coverage | pass_2 |
|--------|----------|--------|
| **Qwen3.5-122B-A10B** ⭐⭐ | **195/195** | **76.9%** -- НОВЫЙ ЛИДЕР |
| Qwen3-Coder Next 80B-A3B | 178/195 (91.3%) | 68.0% |
| Qwen3.6-35B-text 35B-A3B | 195/195 | 65.6% |
| Qwen3-Coder 30B-A3B | 194/195 (99.5%) | 26.3% |
| Devstral 2 24B (dense) | 20/20 smoke | 15.0% |

## Сравнение с frontier closed-weight

Aider Polyglot leaderboard на 2026-04-30:

| Модель | Pass_2 | Δ от нашего 122B |
|--------|--------|--------------------|
| Claude Opus 4.5 | 89.4% | -12.5pp |
| GPT-5 (high) | 88.0% | -11.1pp |
| o3-pro (high) | 84.9% | -8.0pp |
| Gemini 2.5 Pro (32k think) | 83.1% | -6.2pp |
| GPT-5 (low) / o3 (high) | 81.3% | -4.4pp |
| Grok 4 (high) | 79.6% | -2.7pp |
| Gemini 2.5 Pro (default) | 79.1% | -2.2pp |
| **Qwen3.5-122B-A10B (наш)** | **76.9%** | -- |
| **o3 base** | **76.9%** | **PARITY** ⭐ |
| DeepSeek V3.2-Exp | 74.2% | +2.7pp |
| Claude Opus 4 (старший) | 72.0% | +4.9pp |

**Достижения**:
- **Paритет с o3 base** -- frontier mid-tier на локальном Strix Halo железе
- **Обгон Claude Opus 4** (старший) на 4.9pp
- **Обгон DeepSeek V3.2-Exp** на 2.7pp при $0 cost
- **Лучшее open-weight на нашей платформе**

## Архитектурное наблюдение -- 122B-A10B HYBRID

В процессе прогона обнаружено через llama-server log:

```
general.architecture = qwen35moe
n_ctx_train = 262144
12 attention layers / 49 total -- остальные 37 SSM (Gated DeltaNet)
```

Это значит **122B-A10B тоже hybrid Gated DeltaNet** -- ранее ошибочно предполагалось что standard MoE attention. Inter-task cache reuse blocked, как у Coder Next и 35B-text. Корректировка применена в [optimization-backlog.md](../../../inference/optimization-backlog.md#u-001) и preset header.

## Анализ

### Сильные стороны

- **76.9% pass_rate_2** -- абсолютный рекорд платформы. На +8.9pp выше Coder Next (68.0%), +11.3pp выше 35B-text (65.6%)
- **100% покрытие** всех 195 задач во всех 5 языках
- **Лидер в Python/JavaScript** -- 85.3-85.7% pass_2, сопоставимо с frontier
- **Pass_rate_1 = 37.9%** -- лучший single-shot среди топов платформы (vs 33.7% у Coder Next, 29.2% у 35B-text)
- **Retry effect +39.0pp** -- лидер платформы. 10B active даёт устойчивые retry-цепочки на сложных задачах
- **0 watchdog kills за 36 часов** -- стабильность после применения `--reasoning off` и A-006 fix
- **Best balanced для production agent**: качество ~85% Opus 4 при $0 cost

### Слабые стороны

- **Скорость ~22 tok/s tg** -- в 2-3× медленнее MoE A3B (Coder Next 53, 35B-text 58). 10B active vs 3B active = больше compute на token
- **Память 71 GiB** + KV cache = ~78 GiB -- основная память Strix Halo. Не оставляет места для параллельного второго server (нужно >100 GiB вместе)
- **Сложность Java и Go** -- 66-72% pass_2, на 13-19pp ниже Python/JS. Reasoning на сильно типизированных языках слабее
- **36 часов wall clock** -- слишком долго для daily benchmark (был сорван 4 раза, потребовал 4 manual resume)

### Ключевые подтверждения

1. **Гипотеза "10B active > 3B active" подтверждена**: +8.9pp pass_2 vs Coder Next 80B-A3B при том же бенчмарке. Active size критичен для качества reasoning
2. **`--reasoning off` критичен** для open-weight моделей с встроенным thinking: после применения single-shot вырос с 18.2% до 37.9% (+19.7pp за счёт более прямых code edits)
3. **A-006 fix** (LITELLM_REQUEST_TIMEOUT + retry-loop detector) сработал: 0 stall'ов в litellm retry-loop за 36 часов на самой медленной модели платформы
4. **Hybrid Gated DeltaNet -- общая черта Qwen 3.x**: 122B-A10B тоже hybrid, как 35B-text и Coder Next. Inter-task cache blocked везде
5. **Production-grade stability**: 4 manual resume + 0 watchdog kills = workflow требует periodic re-launch, но autonomous работа стабильна

## Выводы

1. **Qwen3.5-122B-A10B -- best quality default на платформе** для critical задач, где разрыв 8-11pp над текущими топами оправдывает 2-3× медленнее скорость
2. **Coder Next 80B-A3B остаётся best balanced** для daily fast iteration -- 68.0% при 53 tok/s vs 76.9% при 22 tok/s
3. **Open-weight на Strix Halo достигла mid-tier frontier** (paритет с o3 base) -- больше нет огромного разрыва с cloud
4. **Architectural ceiling reached** для open-weight на 120 GiB unified -- следующий jump возможен через PR #19670 (cache reuse) и Coder fine-tune Qwen3.6 (ETA июнь-июль 2026)
5. **На production preset 8081 рекомендуется** Coder Next для daily, 122B на 8081 параллельно с быстрой моделью на отдельном порту -- multi-model orchestration в opencode

## Next steps

- [x] Зафиксировать в [results.md](../results.md): новый абсолютный рекорд платформы
- [x] Обновить таблицу покрытия в [runs/README.md](README.md)
- [x] Обновить [families/qwen35.md](../../../models/families/qwen35.md): финальные числа full
- [ ] Обновить [coding/README.md](../../README.md) -- Qwen3.5-122B-A10B как "Heavy reasoning" вариант
- [ ] Обновить [opencode/README.md](../../../ai-agents/agents/opencode/README.md) -- 122B-A10B как quality-tier рекомендация
- [ ] **Запустить multi-model setup** opencode + 122B-A10B (planner) + 30B-A3B (executor) -- проверить пользу архитектурно
- [ ] После merge llama.cpp PR #19670 -- replay для замера эффекта inter-task cache на 36-часовом workflow
- [ ] Рассмотреть **MXFP4_MOE quant** Qwen3.5-122B-A10B (~45 GiB вместо 71) -- освободит память для параллельной модели

## Связанные статьи

- [results.md](../results.md) -- журнал прогонов и лидерборд платформы
- [2026-04-29-aider-full-qwen3.6-35b-text.md](2026-04-29-aider-full-qwen3.6-35b-text.md) -- 35B-text full (65.6%)
- [2026-04-27-aider-full-qwen-coder-next.md](2026-04-27-aider-full-qwen-coder-next.md) -- Coder Next full (68.0%)
- [2026-04-26-aider-full-qwen3-coder-30b.md](2026-04-26-aider-full-qwen3-coder-30b.md) -- 30B-A3B full с cache (26.3%)
- [families/qwen35.md](../../../models/families/qwen35.md#122b-a10b) -- описание модели
- [optimization-backlog.md](../../../inference/optimization-backlog.md) -- A-006 (litellm retry-loop), U-001 (PR tracking), сводная cache reuse table
