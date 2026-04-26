# Бэклог оптимизаций инференса

Append-only журнал идей по ускорению inference на Strix Halo. Цель -- не забыть оптимизации, обнаруженные в ходе работы (бенчмарки, отладка, наблюдения за llama-server). Каждая запись имеет статус (idea / в работе / применено / отклонено) и оценку impact/effort.

В отличие от [acceleration-outlook.md](acceleration-outlook.md) (где отслеживание long-term трендов NPU/ROCm/Vulkan), здесь -- **конкретные tactical-идеи**, проверяемые в течение дней-недель.

## Контекст: где мы упираемся

На замере Aider Polyglot (Qwen3.6-35B, Qwen3-Coder Next 80B-A3B) обнаружились конкретные узкие места:

| Узкое место | Симптом | Корень |
|-------------|---------|--------|
| Prompt processing для retry-задач | seconds_per_case 312-450 при tg ~50-60 tok/s | Каждый retry пересчитывает весь prefix задачи (~2K токенов) |
| Cache reuse не работает | `forcing full prompt re-processing due to lack of cache data` | Hybrid memory (Gated DeltaNet, SWA) не поддержан в llama.cpp |
| Toolchain overhead в benchmark | 5-30 сек/задача на cargo cold start, javac, npm | Docker volume + per-test container init |
| Long-tail задачи 30+ минут | Одна сложная задача доминирует среднее | Модель уходит в circular reasoning, тратит весь generation budget |

Ниже -- идеи по каждому. Категории: **server params**, **benchmark params**, **архитектура моделей**, **hardware/backend**, **upstream tracking**, **infrastructure**.

## Карта оптимизаций

### Server params (llama-server)

#### B-001: убрать `--cache-reuse 256` из hybrid-пресетов

**Статус**: idea
**Impact**: косметика (логи), нулевой на performance
**Effort**: тривиальный (правка 3 пресетов)

llama.cpp молча игнорирует `--cache-reuse N` для моделей с recurrent memory (Gated DeltaNet) или sliding window attention. Параметр в пресете создаёт ложное впечатление, что фича работает.

Затрагивает: [`vulkan/preset/qwen-coder-next.sh`](../../scripts/inference/vulkan/preset/qwen-coder-next.sh), [`gemma4.sh`](../../scripts/inference/vulkan/preset/gemma4.sh), будущий `qwen36.sh`.

Действие: убрать строку `--cache-reuse 256`, в комментарии оставить пометку "не работает на hybrid memory".

#### B-002: увеличить `--ubatch-size` для PP throughput

**Статус**: idea
**Impact**: средний (если PP -- bottleneck)
**Effort**: эмпирический подбор

Default `--ubatch-size 512`. На GPU с большим bandwidth (256 GB/s unified) можно увеличить до 2048-4096 -- больше токенов обрабатывается за один Vulkan dispatch. Trade-off: больше VRAM на batch буфер.

Проверка: запустить `llama-bench` с `-ub 512,1024,2048,4096` и измерить pp tok/s.

Затрагивает: пресеты в [`scripts/inference/vulkan/preset/`](../../scripts/inference/vulkan/preset/).

#### B-003: `--threads-batch` для CPU prep

**Статус**: idea
**Impact**: малый-средний (если CPU видим в htop при PP)
**Effort**: тривиальный

Default `--threads-batch` обычно равен `--threads`. На Strix Halo 16 ядер Zen5 -- можно дать `--threads 8 --threads-batch 16` (генерация однопоточная по природе, но prep CPU-bound).

Проверка: htop во время PP. Если CPU < 50% -- увеличить `--threads-batch`.

#### B-004: speculative decoding с draft-моделью

**Статус**: idea
**Impact**: высокий (1.5-2× tg) для совместимых моделей
**Effort**: средний (нужна draft-модель, сборка llama-server с правильными флагами)

llama.cpp поддерживает `--draft-model` и `--draft-max`. Для Qwen3-Coder Next 80B-A3B потенциально draft-моделью может служить Qwen2.5-Coder 1.5B (схожий tokenizer). Для Qwen3.6-35B -- та же модель в Q3_K_S или меньшая Qwen3 1.5B.

Условия применимости:
- Совместимый tokenizer (одинаковый vocab)
- Tasks с предсказуемыми patterns (boilerplate code, JSON output)

Проверка: бенчмарк tg с `--draft-model Qwen2.5-Coder-1.5B-Q4_K_M.gguf --draft-max 8` и без.

#### B-005: `--keep N` для system prompt persistence

**Статус**: idea
**Impact**: средний для multi-turn чата
**Effort**: тривиальный

`--keep N` сохраняет первые N токенов в KV-cache между turn'ами. Для системного промпта (~500-1500 токенов) `--keep 1500` гарантирует, что system prompt не будет evicted при context shift.

Не помогает для hybrid моделей (вся проблема в recurrent state, не в KV).

### Benchmark params (Aider, Terminal-Bench)

#### A-001: `--tries 1` вместо 2 для smoke

**Статус**: planned (next steps от 2026-04-26 прогона)
**Impact**: -50% времени для retry-задач (~30-40% от всех)
**Effort**: тривиальный (правка [`scripts/inference/bench-aider.sh`](../../scripts/inference/bench-aider.sh))

В smoke-режиме `--tries 1` даёт чистую single-shot оценку, экономит ~25-30% времени suite. Full eval оставить с `--tries 2` для сравнения с публичным leaderboard.

#### A-002: `--edit-format diff` для меньших prompt'ов

**Статус**: idea
**Impact**: средний (-30-60% prompt size на retry)
**Effort**: тривиальный

`--edit-format whole` отправляет полный файл при каждом edit. `diff` -- только изменения. Для retry-задачи разница prompt size с 5K → 1.5K токенов.

Минус: некоторые модели хуже работают с diff format (генерируют невалидный patch). Проверять `percent_cases_well_formed` после смены.

#### A-003: `--num-tests` cap по умолчанию

**Статус**: planned (next steps от 2026-04-26 прогона)
**Impact**: предсказуемое время smoke
**Effort**: тривиальный

Текущий smoke = 50 задач, реально 4-5 ч/модель. Снизить до 20 для quick smoke (~1.5 ч), оставить 50 опционально через `--full-smoke`.

#### A-005: hard timeout per task в bench-aider.sh

**Статус**: planned (новая запись из прогона Coder Next 2026-04-26)
**Impact**: критический -- предотвращает потерю часов на retry-loop
**Effort**: средний (правка benchmark.py wrapper, либо `timeout` обёртка)

В прогоне Coder Next aider завис на 31-й задаче в `litellm.Timeout` retry-loop с exponential backoff (~30 сек cap). За **3 часа** не было ни прогресса ни ошибки -- aider бесконечно перезапрашивал. Suite пришлось убивать вручную.

Корень: benchmark.py не имеет `--max-task-timeout`. litellm экспоненциально откатывается, но не помечает задачу как failed.

Действие: добавить watchdog в [`scripts/inference/bench-aider.sh`](../../scripts/inference/bench-aider.sh) -- если test_cases счётчик не растёт >10 минут, kill docker container и переходить к следующей. Альтернатива -- patch benchmark.py с `--max-task-seconds N`.

Особенно критично для hybrid моделей (Coder Next, Qwen 3.6-27B), где cache-reuse не работает и retry потенциально ещё медленнее.

#### A-004: `--languages python,javascript` для quick валидации

**Статус**: idea
**Impact**: -67% времени (2 языка вместо 6)
**Effort**: средний (нужна правка `bench-aider.sh` для проброса флага)

Полезно для quick-sanity check после правок параметров (preset, llama.cpp build, modelfile). Полная multi-language оценка -- только в full-режиме.

### Архитектурный выбор моделей

#### M-001: Qwen3-Coder 30B-A3B как fallback для cache-sensitive workloads

**Статус**: observation
**Impact**: cache-reuse работает (чистая attention MoE)
**Effort**: смена preset

Qwen3-Coder 30B-A3B (без "Next") -- чистая attention MoE без Gated DeltaNet. cache-reuse 256 на нём действительно работает. Для long-running multi-turn workflow (например, agentic coding в opencode) даёт меньшую latency на повторных запросах.

Минус: меньше context understanding, отстаёт по сложным задачам.

Использовать когда: high-frequency tool calls в одной сессии, FIM-completion с шарингом prefix.

#### M-002: Q4_K_M vs Q5_K_M trade-off

**Статус**: idea (требует замера)
**Impact**: tg на 5-10% медленнее на Q5, но качество ближе к F16
**Effort**: малый (скачать Q5_K_M, llama-bench)

Для Gemma 4 уже отмечено что QAT даёт почти F16-качество на Q4_K_M. Для других моделей (особенно non-QAT, Qwen3-Coder) Q5_K_M может быть оправдан. Замерить на benchmark, если разница в pass-rate >5% -- переходить.

#### M-003: model offloading -- KV-cache на GPU, веса на CPU

**Статус**: idea (экспериментально)
**Impact**: высокий для моделей не помещающихся в "comfortable" зону
**Effort**: средний

Для модели 80GB (Coder Next в Q5/Q6) -- держать KV-cache на GPU (быстрый PP), веса на CPU memory. llama.cpp поддерживает `-ngl <N>` (число GPU-слоёв). Замерить trade-off между full-GPU и hybrid offload.

### Hardware / backend

#### H-001: ROCm/HIP backend для Qwen3-Coder Next

**Статус**: ожидание fix gfx1151 (см. [acceleration-outlook.md](acceleration-outlook.md))
**Impact**: возможно +20-30% tg при native HIP
**Effort**: после исправления KFD VRAM lock

Проверять каждый release ROCm. На текущем Vulkan стабильно, переход на HIP -- только когда HIP не падает с segfault на gfx1151.

#### H-002: NPU offload для small ops через Lemonade

**Статус**: long-term idea
**Impact**: малый для CHAT-моделей (overhead передачи данных)
**Effort**: высокий (Lemonade всё ещё ограниченная экосистема)

См. [lemonade.md](lemonade.md). Сейчас NPU полезен для CV/embedding моделей, не для chat-инференса.

#### H-003: `--no-mmap` всегда vs только для small models

**Статус**: idea
**Impact**: малый (mmap-overhead vs RAM pressure)
**Effort**: эмпирический

`--no-mmap` загружает модель сразу в RAM (без файл-кэша ОС). Полезно когда:
- Модель < 50 GB и хватает RAM
- Доступная RAM > 2× model size (чтобы избежать swap)

На Strix Halo с 120 GiB unified -- mmap почти не нужен. Можно стандартизировать `--no-mmap` во всех пресетах (сейчас только в gemma4 и нескольких других).

### Upstream tracking (что мониторить)

#### U-001: llama.cpp PR 13194 -- hybrid memory checkpointing

**Статус**: open в upstream
**Impact**: cache-reuse заработает для Coder Next, Qwen 3.6-27B
**URL**: https://github.com/ggml-org/llama.cpp/pull/13194

Самый важный pending change. Когда merge'ат:
1. Обновить llama.cpp build
2. Вернуть `--cache-reuse 256` в hybrid-пресеты
3. Перезамерить Aider Polyglot smoke -- ожидаем -30% времени

Проверять статус: раз в 2 недели или при release-новостях llama.cpp.

#### U-002: llama.cpp PR на Gated DeltaNet квантизацию

**Статус**: search
**Impact**: возможный (если recurrent state можно квантизовать)
**Действие**: следить за llama.cpp issues по теме `recurrent state quantization`

Текущий recurrent state в Coder Next -- F32 (288 MiB на slot). Если квантизуется в F16 -- вдвое меньше memory pressure.

#### U-003: ROCm gfx1151 KFD VRAM fix

**Статус**: long-term, отслеживается через [CLAUDE.md мониторинг](../../CLAUDE.md)
**Impact**: huge (PyTorch и HIP backend пока ограничены 15.5 GiB вместо 120 GiB)

Не относится к llama.cpp, но косвенно: пока KFD не fix'нут, нельзя сравнить ROCm vs Vulkan на крупных моделях.

#### U-004: Mesa RADV оптимизации для gfx1151

**Статус**: следить через news
**Impact**: 5-15% при крупных driver-обновлениях
**Действие**: при апгрейде Mesa измерить `llama-bench` baseline до/после

### Infrastructure

#### I-001: bench-aider-suite параллельно несколько prompt'ов в одном сервере

**Статус**: idea (нужна проверка совместимости)
**Impact**: 2-4× throughput при `--parallel 4` в llama-server
**Effort**: средний (правка benchmark.py для thread-safe-доступа)

Сейчас `--threads 1` в bench-aider.sh заставляет benchmark.py делать задачи последовательно. Если `llama-server --parallel 4` -- можно делать 4 задачи параллельно через `--threads 4`. Trade-off: каждый параллельный запрос делит compute и bandwidth, tg на slot снижается, но total throughput растёт.

#### I-002: pre-built docker image с aider, polyglot, моделями

**Статус**: idea
**Impact**: пропадает 5-30 сек/задача toolchain init
**Effort**: высокий (нужно собирать custom image)

Текущий Docker container запускается заново на каждый benchmark прогон. Альтернатива: keep-alive container, в который шлются задачи через `docker exec`. Усложняет error handling.

#### I-003: cache toolchain артефактов между задачами

**Статус**: idea
**Impact**: -10-20 сек/задача (Cargo cold start особенно)
**Effort**: средний

Cargo создаёт `target/` для каждой задачи. Если использовать shared `CARGO_HOME=/aider/.cargo-shared` между задачами -- индексы и cache сохраняются. Аналогично для npm `--cache /aider/.npm-shared`, Maven `~/.m2`.

Минус: возможна интерференция между задачами (одна задача может загрязнить cache для другой).

#### I-004: распределённый бенчмарк через несколько серверов

**Статус**: idea (экспериментально, для будущего)
**Impact**: 4× ускорение полного suite (если есть 4 сервера)
**Effort**: высокий

Когда появится второй сервер -- разделить 225 задач polyglot на 4 шарда по языку (Python+JS, Go+Rust, Java+Cpp), запустить параллельно. SUMMARY-сборщик объединяет результаты.

## Приоритизация

| ID | Идея | Impact | Effort | Когда |
|----|------|--------|--------|-------|
| **A-005** | watchdog timeout per task | критический | средний | СРОЧНО (после Coder Next зависания) |
| **A-001** | --tries 1 в smoke | высокий | тривиальный | следующая правка bench-aider |
| **A-003** | --num-tests 20 default | высокий | тривиальный | следующая правка bench-aider |
| **B-001** | убрать --cache-reuse из hybrid пресетов | косметика | тривиальный | следующая правка пресетов |
| **U-001** | следить за PR 13194 | huge | мониторинг | раз в 2 недели |
| **A-002** | --edit-format diff | средний | тривиальный | после A-001 |
| **B-002** | --ubatch-size 2048 | средний | эмпирический | при llama-bench сессии |
| **B-004** | speculative decoding | высокий | средний | требует draft-модели |
| **M-001** | Qwen3-Coder 30B-A3B как fallback | контекстный | малый | при сценарии cache-sensitive |
| **I-003** | shared toolchain cache | малый | средний | если smoke станет регулярным |

**Top-4 действия сейчас**:
1. **A-005**: watchdog timeout -- предотвратить повторение 3-часового retry-loop из прогона Coder Next
2. A-001 + A-003: правка `bench-aider.sh` -- snapshot smoke стал управляемым
3. B-001: чистка пресетов от non-functional `--cache-reuse`
4. U-001: подписка на PR 13194 в llama.cpp

## Workflow при новой идее

1. Записать в этот файл с уникальным ID (B-NNN / A-NNN / M-NNN / H-NNN / U-NNN / I-NNN)
2. Указать impact, effort, статус
3. Если idea-only -- оставить как backlog
4. Если planned -- добавить в next steps текущего runs/-отчёта
5. После применения -- статус "применено", дата применения, ссылка на коммит

## Связанные статьи

- [acceleration-outlook.md](acceleration-outlook.md) -- long-term прогнозы платформы
- [benchmarking.md](benchmarking.md) -- методика замеров
- [troubleshooting.md](troubleshooting.md) -- диагностика проблем
- [llama-cpp.md](llama-cpp.md) -- llama.cpp обзор
- [vulkan-llama-cpp.md](vulkan-llama-cpp.md) -- Vulkan backend параметры
- [../llm-guide/benchmarks/runs/](../llm-guide/benchmarks/runs/README.md) -- отчёты прогонов (источник наблюдений)
