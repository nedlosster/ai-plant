# Прогоны бенчмарков на платформе

Каталог отчётов о прогонах бенчмарков на Strix Halo сервере. Каждая статья -- один прогон одной модели на одном бенчмарке, с полным контекстом: версии стека, параметры, результаты, анализ.

## Назначение

В отличие от `results.md` (краткий лидерборд), статьи в этом каталоге сохраняют **полный контекст**:

- Версии llama.cpp, ядра, Mesa, aider
- Параметры llama-server (контекст, parallel, cache-reuse)
- Per-language / per-category breakdown
- Хронологию выполнения
- Анализ сильных и слабых сторон модели
- Что пошло не так и почему
- Что делать дальше (next steps)

Это позволяет:

- **Сравнивать прогоны** между собой (например, после обновления llama.cpp)
- **Отслеживать регрессии** при апгрейдах
- **Воспроизводить** прогон с теми же параметрами через несколько месяцев

## Соглашение об именовании

```
<YYYY-MM-DD>-<benchmark>-<mode>-<model>.md
```

Примеры:

- [2026-04-26-aider-smoke-qwen3.6-35b.md](2026-04-26-aider-smoke-qwen3.6-35b.md) -- реальный
- `2026-05-15-aider-full-qwen-coder-next.md` (гипотетический)
- `2026-06-01-terminal-bench-devstral.md` (гипотетический)

## Шаблон статьи

См. [2026-04-26-aider-smoke-qwen3.6-35b.md](2026-04-26-aider-smoke-qwen3.6-35b.md) как референс. Обязательные секции:

- **Шапка**: дата, mode, scope, total time, статус (завершён / прерван), ссылки на лог
- **Среда**: hardware, kernel, Mesa, llama.cpp, aider/harness, Docker image
- **Параметры модели и benchmark**: точные команды для воспроизводимости
- **Pre-flight**: чек-лист готовности
- **Результаты**: агрегатные показатели, per-language/category breakdown, хронология
- **Анализ**: сильные стороны, слабые стороны, edit format quality
- **Root cause**: если что-то пошло не так -- разобраться почему
- **Выводы**: 5-7 пунктов
- **Next steps**: что делать дальше -- как чек-лист

## Покрытие тестами agent-coding моделей платформы

Сводка по моделям, подходящим для agent-coding workflows (multi-turn aider/opencode/Continue.dev). Vision-only, FIM-only и general-purpose LLM в этой таблице не учитываются -- для них Aider Polyglot не подходящий бенчмарк.

Маркеры покрытия:

- ✅ **Полное покрытие** -- завершён --full прогон (>= 100 задач) с --tries 2
- 🟡 **Частичное** -- только smoke (10-20 задач) или прерванный full
- 🔴 **Не тестировано** -- модель скачана, бенчмарк не проводился

| Модель | Q4 size | Архитектура | Cache reuse | Best result | Sec/case | Покрытие | Вывод |
|--------|---------|-------------|-------------|-------------|----------|----------|-------|
| **Qwen3.6-35B-A3B (text-only)** 🏆 | 21 GiB | Hybrid Gated DeltaNet, MoE 35B/3B | ❌ (hybrid) | **29.2% / 65.6%** на 195/195 ✅ | ~407 | ✅ **full 100% coverage** | **Лидер C++ (73.1%) и стабильности**. 0 watchdog за 22h, 0 manual resumes. Регрессия к среднему -4.4pp от smoke 20. Coder Next +2.4pp по качеству, но 35B-text меньше (20.6 vs 45 GiB) и стабильнее. |
| Qwen3.6-35B-A3B (multimodal) | 21 GiB + mmproj 1.2 | Hybrid + multimodal | ❌❌ (hybrid+multimodal) | 35.0% pass_1 на smoke-20 (--tries 1) | 210.5 | 🟡 smoke clean | Замена есть -- text-only вариант на 8084. Этот пресет оставлен для vision tasks (когда нужны скриншоты в agent-mode). |
| Qwen3-Coder 30B-A3B | 18 GiB | Standard MoE attention | ✅ | **26.3%** pass_2 на 194/195 | 47.7 | ✅ **full** | **Best throughput**, 5-10× быстрее 35B. Качество 60% relative weakness. Использовать для batch / throughput-sensitive workloads. |
| **Qwen3-Coder Next 80B-A3B** | 45 GiB | Hybrid Gated DeltaNet | ❌ (hybrid) | **33.7% / 68.0%** pass_2 на 178/195 ✅ | **~99** | ✅ **full** | Hybrid но без multimodal. Финальный pass_rate_2 68.0% (CI ±7pp на 178) -- значимо лучше 30B-A3B (26.3% на 194). Retry effect **+34.3pp** -- лидер платформы. Размер 80B компенсирует hybrid limit. **Best balanced default**: качество ~35B-text при 2.5× скорости. |
| **Qwen3.6-27B (dense)** | 15.7 GiB | dense (по llama.cpp `qwen35`, без recurrent) | ✅ (cache-friendly) | -- | **12.4** ⚠️ | 🟠 замер выполнен, smoke не запущен | **Лидер open-weight SWE-V (77.2%)** на момент апреля 2026. Memory-bound (dense), реальный замер 12.4 tok/s -- в 4.7× медленнее MoE 35B-A3B. Aider smoke нерентабелен (>5 часов на 20 задач). Используется только для batch / точечных сравнений. См. [2026-04-28-bench-qwen3.6-27b.md](2026-04-28-bench-qwen3.6-27b.md). |
| Devstral 2 24B (dense) | 14 GiB | Standard dense attention | ✅ | **0% / 15.0%** pass_2 на 20/20 | ~110 | ✅ smoke + --tries 2 | **Аутсайдер** на agent-coding -- 0% pass_rate_1 на 20 задачах указывает на несовместимость с aider whole edit format. Стабильная скорость, но качество не подходит для production agent. Cache reuse работает (standard dense), но не помогает при низком качестве. |
| **Qwen3.5-122B-A10B** ⭐⭐ | 71 GiB | **Hybrid Gated DeltaNet** (12 attn / 37 SSM из 49) | ❌ (hybrid) | **37.9% / 76.9%** на 195/195 ✅ | ~660 | ✅ **full** | ⭐⭐ **АБСОЛЮТНЫЙ РЕКОРД ПЛАТФОРМЫ**. 10B active vs 3B у топов даёт +8.9pp pass_2 над Coder Next (68.0%). **Paритет с o3 base** (76.9%), **обгон Opus 4** (72.0%). Лидер Python (85.3%) / JavaScript (85.7%). 0 watchdog kills за 36h после `--reasoning off`. |

### Очередь следующих тестов (приоритет сверху)

1. ~~Qwen3.6-27B (dense) -- скачать + smoke + --tries 2~~ -- **выполнено 2026-04-28**, smoke не делался. Замер показал 12.4 tok/s -- в 4.7× медленнее MoE-альтернативы, prompt-based бенчмарк нерентабелен (>5 ч на 20 задач). См. [2026-04-28-bench-qwen3.6-27b.md](2026-04-28-bench-qwen3.6-27b.md).

### Очередь после завершения 35B-text full (приоритет сверху)

1. **Gemma 4 26B-A4B (text-only) smoke + --tries 2** ⭐ (~2 ч). Никогда не тестировалась на aider polyglot. Ожидаем 50-65% pass_rate_2 (LiveCodeBench 77.1%, AIME 88.3% -- топ среди 25-30B). Native function calling + 256K контекст. Preset: [`gemma4-text.sh`](../../../../scripts/inference/vulkan/preset/gemma4-text.sh) (порт 8083, без mmproj). Заполнит пробел "Mistral/Google" в leaderboard платформы.

2. **Qwen3.5-122B-A10B full + --tries 2** (running 2026-04-29). **Потенциальный абсолютный лидер** -- 10B active vs 3B у текущих топов. SWE-bench Verified ~75% leaderboard 2026. **ИСПРАВЛЕНИЕ 2026-04-29**: оказалась **HYBRID Gated DeltaNet** (12 attention / 37 SSM из 49 layers по llama-server log), inter-task cache **тоже blocked**. Это roll-back ранее заявленного "cache reuse работает". Preset обновлён: [`qwen3.5-122b.sh`](../../../../scripts/inference/vulkan/preset/qwen3.5-122b.sh) (порт 8081, 71 GiB модель, контекст **256K native**).

3. **UD-Q5_K_M Qwen3.6-35B-A3B smoke + --tries 2** (~2 ч). Quality A/B vs текущий Q4_K_M. Скачать через `download-model.sh unsloth/Qwen3.6-35B-A3B-GGUF --include '*UD-Q5_K_M*'` (~26.5 GiB). Preset: [`qwen3.6-35b-text-q5.sh`](../../../../scripts/inference/vulkan/preset/qwen3.6-35b-text-q5.sh) (порт 8087 для side-by-side с Q4 на 8084). Если +3-5pp pass_rate_2 -- переключаем default.
2. **Qwen3.6-35B-text -- full** (195 задач, --tries 2, ~14-17 ч). Leaderboard-quality оценка для рекордной модели. **Ожидаем 60-65% pass_2** (статистика на 195 vs 70% на 20 -- regression к среднему).
3. **Devstral 2 24B -- smoke + --tries 2** (~2 ч). Standard dense attention -- ещё одна точка hybrid vs dense vs MoE. **Ожидаем 30-50%** (dense не масштабируется как MoE).
4. **Qwen3-Coder 30B-A3B -- replay** после применения upstream PR #20376 (Vulkan f16 GATED_DELTA_NET). Замерить speedup, актуально через 1-3 мес.
5. **Qwen3.6-Coder (когда выйдет, ожидание июнь-июль 2026)** -- coder-specific вариант на той же hybrid Gated DeltaNet архитектуре. Скачать сразу, full --tries 2.

### Долгосрочно (после upstream merges)

- После llama.cpp PR #20376 (Vulkan f16 GATED_DELTA_NET): перезамерить **Qwen3.6-35B-text** -- ожидаем -10-20% sec/case.
- После PR #20819 + router-mode: перезамерить **Qwen3.6** + **Coder Next** в swap-сценарии.
- После cross-turn cache reuse fix для hybrid: радикальное переосмысление лидерборда.

## Доступные прогоны

| Дата | Бенчмарк | Mode | Модель | Pass rate | **Sec/case** | Total | Статья |
|------|----------|------|--------|-----------|--------------|-------|--------|
| 2026-04-29 → 2026-04-30 | Aider Polyglot | **full** (no rust) | **Qwen3.5-122B-A10B** 🏆🏆 | **37.9% / 76.9%** на **195/195** ✅⭐⭐ | ~660 | ~36h | [2026-04-30-aider-full-qwen3.5-122b](2026-04-30-aider-full-qwen3.5-122b.md) |
| 2026-04-28 → 2026-04-29 | Aider Polyglot | **full** (no rust) | **Qwen3.6-35B-text** 🏆 | 29.2% / **65.6%** на **195/195** ✅ | ~407 | ~22h | [2026-04-29-aider-full-qwen3.6-35b-text](2026-04-29-aider-full-qwen3.6-35b-text.md) |
| 2026-04-27 → 2026-04-28 | Aider Polyglot | **full** (no rust) | **Qwen3-Coder Next 80B-A3B** 🏆 | 33.7% / **68.0%** на 178/195 ✅ | ~99 | ~16h | [2026-04-27-aider-full-qwen-coder-next](2026-04-27-aider-full-qwen-coder-next.md) |
| 2026-04-27 | Aider Polyglot | smoke 20 + --tries 2 | **Qwen3.6-35B-text** 🏆 | 30.0% / **70.0%** (рекорд) | 248.8 | 1h 55m | [2026-04-27-aider-smoke-qwen3.6-35b-text-tries2](2026-04-27-aider-smoke-qwen3.6-35b-text-tries2.md) |
| 2026-04-26 → 2026-04-27 | Aider Polyglot | **full** (no rust) | Qwen3-Coder 30B-A3B | 10.8% / **26.3%** на 194/195 ✅ | **47.7** ⭐ | ~7.5h | [2026-04-26-aider-full-qwen3-coder-30b](2026-04-26-aider-full-qwen3-coder-30b.md) |
| 2026-04-26 | Aider Polyglot | smoke 20 (clean ✓, A/B) | Qwen3-Coder 30B-A3B | **15.0%** | **17.4** ⭐⭐ | 10m | [2026-04-26-aider-smoke-qwen3-coder-30b](2026-04-26-aider-smoke-qwen3-coder-30b.md) |
| 2026-04-26 | Aider Polyglot | smoke 20 (clean ✓) | Qwen3.6-35B-A3B | **35.0%** (single-shot) | 210.5 | 1h 11m | [2026-04-26-aider-smoke-qwen3.6-35b-clean](2026-04-26-aider-smoke-qwen3.6-35b-clean.md) |
| 2026-04-26 | Aider Polyglot | smoke (прерван) | Qwen3-Coder Next 80B-A3B | 36.7% / 46.7% (на 30) | 243.5 | -- (прерван) | [2026-04-26-aider-smoke-qwen-coder-next](2026-04-26-aider-smoke-qwen-coder-next.md) |
| 2026-04-26 | Aider Polyglot | smoke (прерван) | Qwen3.6-35B-A3B | 27.3% / 54.5% (на 22) | 312.5 | -- (прерван) | [2026-04-26-aider-smoke-qwen3.6-35b](2026-04-26-aider-smoke-qwen3.6-35b.md) |

## Связанные статьи

- [results.md](../results.md) -- лидерборд и краткий журнал
- [runbooks/](../runbooks/README.md) -- инструкции запуска бенчмарков
- [README.md](../README.md) -- индекс бенчмарков
- [inference/optimization-backlog.md](../../../inference/optimization-backlog.md) -- бэклог идей ускорения на базе наблюдений из прогонов
