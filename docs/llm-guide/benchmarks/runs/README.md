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
| **Qwen3.6-35B-A3B (text-only)** 🏆 | 21 GiB | Hybrid Gated DeltaNet, MoE 35B/3B | ❌ (hybrid) | **70.0%** pass_2 на smoke-20 | 248.8 | 🟡 smoke с --tries 2 | **Best quality, новый default**. Retry +40pp -- модель учится на ошибках. user_asks=0 (полная автономность). Нужен --full для leaderboard. |
| Qwen3.6-35B-A3B (multimodal) | 21 GiB + mmproj 1.2 | Hybrid + multimodal | ❌❌ (hybrid+multimodal) | 35.0% pass_1 на smoke-20 (--tries 1) | 210.5 | 🟡 smoke clean | Замена есть -- text-only вариант на 8084. Этот пресет оставлен для vision tasks (когда нужны скриншоты в agent-mode). |
| Qwen3-Coder 30B-A3B | 18 GiB | Standard MoE attention | ✅ | **26.3%** pass_2 на 194/195 | 47.7 | ✅ **full** | **Best throughput**, 5-10× быстрее 35B. Качество 60% relative weakness. Использовать для batch / throughput-sensitive workloads. |
| **Qwen3-Coder Next 80B-A3B** | 45 GiB | Hybrid Gated DeltaNet | ❌ (hybrid) | **33.7% / 68.0%** pass_2 на 178/195 ✅ | **~99** | ✅ **full** | Hybrid но без multimodal. Финальный pass_rate_2 68.0% (CI ±7pp на 178) -- значимо лучше 30B-A3B (26.3% на 194). Retry effect **+34.3pp** -- лидер платформы. Размер 80B компенсирует hybrid limit. **Best balanced default**: качество ~35B-text при 2.5× скорости. |
| **Qwen3.6-27B (dense)** | 17 GiB | dense + hybrid Gated DeltaNet | ❌ (hybrid) | -- | -- | 🔴 **не скачана** ⭐ | **Лидер open-weight SWE-V (77.2%)** на момент апреля 2026. Превосходит Devstral 2 (72.2%) и Coder Next (70.6%). Memory-bound (dense), оценка ~15 tok/s. Сильный кандидат к скачиванию + smoke + --tries 2. |
| Devstral 2 24B (dense) | 14 GiB | Standard dense attention | ✅ | -- | -- | 🔴 не тестировано | Кандидат для теста как coding-specialist на dense архитектуре. Эталонная "третья точка" для сравнения hybrid vs dense vs MoE. |

### Очередь следующих тестов (приоритет сверху)

1. **Qwen3.6-27B (dense) -- скачать + smoke + --tries 2** ⭐ (~3-4 ч). Лидер open-weight SWE-V (77.2%) на момент апреля 2026. **Ожидаем 70-78% pass_2** на 20 задачах. Скачать через `download-model.sh unsloth/Qwen3.6-27B-GGUF --include "*Q4_K_M*"`, создать `qwen3.6-27b.sh` preset (с `-c 131072 --keep 1500 --batch-size 4096 --ubatch-size 4096 --no-mmap`).
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
