# Запуск бенчмарков на платформе: runbooks

Подраздел [docs/llm-guide/benchmarks/](../README.md) с пошаговыми инструкциями для запуска бенчмарков локально на Strix Halo сервере. В отличие от [теоретических статей про SWE-bench / HumanEval / LiveCodeBench / MMMU](../README.md#статьи-раздела), здесь -- **practical guides**: какие команды запустить, как интерпретировать результаты, как сравнить модели на твоих задачах.

## Зачем это нужно

Публичные лидерборды дают агрегированную оценку. Прогон на платформе показывает:
- Как модель работает с твоей квантизацией (Q4_K_M на Vulkan vs FP16 у вендора)
- Скорость в реальных условиях inference (а не только tg/pp в llama-bench)
- Сравнение нескольких моделей на одной аппаратной базе
- Влияние твоей конфигурации (`--parallel`, `--cache-reuse`, `-fa on`)
- Контроль регрессий после обновления llama.cpp / квантизаций

## Сравнительная таблица

| Бенчмарк | Задач | Время на платформе | Тип нагрузки | Сложность setup |
|----------|-------|---------------------|---------------|-----------------|
| [Aider Polyglot smoke](aider-polyglot.md#smoke-test-runbook-50-задач-15-ч) | 50 (random subset) | ~1.5 ч | edit-loop, 6 языков | низкая |
| [Aider Polyglot full](aider-polyglot.md#full-benchmark-runbook-225-задач-6-12-ч) | 225 | 6-12 ч | edit-loop, 6 языков | низкая |
| [Terminal-Bench 2.0](terminal-bench.md) | 56 | 1-2 ч | tool use в shell | средняя (Docker) |

## Стандартный порядок запуска

1. **Smoke test первым** -- 1.5 часа, быстрая проверка что:
   - Модель загружена и отвечает
   - Aider/harness корректно подключен к llama-server
   - Edit format правильный (нет фолбеков)
   - Базовый score даёт sanity check
2. **Full eval** -- если smoke прошёл нормально, запустить полный прогон в tmux на ночь
3. **Tool-use eval** (Terminal-Bench) -- отдельная метрика, не зависит от Aider, оценивает agent capability

## Decision tree

| Цель | Что запускать |
|------|---------------|
| Сравнить 2-3 модели на коде | Aider Polyglot smoke |
| Получить точный SWE-V proxy | Aider Polyglot full |
| Оценить tool use / agent capability | Terminal-Bench 2.0 |
| Проверить регрессию после обновления llama.cpp | Aider Polyglot smoke |
| Полная оценка перед production | Все три последовательно |

## Минимальные требования

| Ресурс | Smoke (Aider 50) | Full (Aider 225) | Terminal-Bench (56) |
|--------|------------------|-------------------|---------------------|
| Время | 1.5 ч | 6-12 ч | 1-2 ч |
| VRAM | 20-25 GiB (model + KV) | то же | то же |
| Disk | ~2 GiB (dataset) | то же | ~5-10 GiB (Docker images) |
| RAM | 4-8 GiB | то же | 4-8 GiB + Docker overhead |
| Зависимости | Python 3.10+, `aider-chat` | то же | Python, Docker, `terminal-bench` |
| Сеть | один раз скачать dataset | то же | Docker pull при первом запуске |

## Где хранить результаты

- Краткий лидерборд + журнал записей -- в [`results.md`](../results.md), append-only с шаблоном записи в файле
- Полные статьи отдельных прогонов (со средой, per-language breakdown, анализом, root cause) -- в [`runs/`](../runs/README.md). Создаются после каждого значимого прогона.

## Процесс работы

1. Запустить llama-server: [`vulkan/preset/<preset>.sh`](../../../../scripts/inference/vulkan/preset/) `-d --port 8085`
2. Проверить здоровье: [`scripts/inference/status.sh`](../../../../scripts/inference/status.sh)
3. Запустить wrapper: [`scripts/inference/bench-aider.sh`](../../../../scripts/inference/bench-aider.sh) `--smoke --model qwen3.6-35b --port 8085`
4. Дождаться завершения, парсить вывод
5. Записать результат в [`../results.md`](../results.md)
6. Остановить сервер: [`scripts/inference/stop-servers.sh`](../../../../scripts/inference/stop-servers.sh)

Подробности в каждом отдельном runbook.

## Ограничения и допущения

- **Не SWE-bench Verified/Lite на платформе** -- требует Docker + 150-300 GB storage + 30-60 часов на прогон. Реалистично только в облаке. См. [swe-bench.md](../swe-bench.md) для теории.
- **Не HumanEval/MBPP** -- contamination, неинформативно. См. [humaneval.md](../humaneval.md).
- **LiveCodeBench** -- требует API доступ к свежему snapshot, не настроено в проекте. Возможно добавить позже. См. [livecodebench.md](../livecodebench.md).
- Aider Polyglot -- best signal/effort ratio для local sanity check.

## Связанные статьи

- [benchmarks/README.md](../README.md) -- классификация и теория бенчмарков
- [results.md](../results.md) -- журнал результатов на платформе (лидерборд)
- [runs/](../runs/README.md) -- полные статьи отдельных прогонов
- [coding/README.md](../../../coding/README.md) -- раздел AI-кодинга
- [coding/outlook.md](../../../coding/outlook.md) -- прогнозы и тренды
- [models/coding.md](../../../models/coding.md) -- каталог моделей
