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

**Статус**: **применено 2026-04-26**
**Impact**: косметика (логи), нулевой на performance
**Effort**: тривиальный (правка 3 пресетов)

llama.cpp молча игнорирует `--cache-reuse N` для моделей с recurrent memory (Gated DeltaNet) или sliding window attention. Параметр в пресете создаёт ложное впечатление, что фича работает.

Затрагивает: [`vulkan/preset/qwen-coder-next.sh`](../../scripts/inference/vulkan/preset/qwen-coder-next.sh), [`gemma4.sh`](../../scripts/inference/vulkan/preset/gemma4.sh), будущий `qwen36.sh`.

**Применение 2026-04-26**: убрана строка `--cache-reuse 256` из трёх пресетов: `qwen-coder-next.sh` (hybrid Gated DeltaNet), `gemma4.sh` (SWA + multimodal), `qwen3.6-35b.sh` (hybrid Gated DeltaNet + multimodal). В header-комментариях зафиксированы причины и ссылка на [U-001](#u-001-cache-reuse-для-hybrid--multimodal-моделей) (отслеживание upstream).

**Дополнительный фактор для multimodal**: llama.cpp не только игнорирует `--cache-reuse` для hybrid/SWA, но и **явно отключает его при загрузке multimodal-модели**: `srv load_model: cache_reuse is not supported by multimodal, it will be disabled`. То есть Qwen3.6-35B-A3B и Gemma 4 имеют две независимые причины (hybrid И multimodal). Один из факторов фиксится PR 13194, второй -- открытая проблема в multimodal-стеке llama.cpp.

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

**Статус**: **применено 2026-04-26**
**Impact**: -50% времени для retry-задач (~30-40% от всех)
**Effort**: тривиальный (правка [`scripts/inference/bench-aider.sh`](../../scripts/inference/bench-aider.sh))

В smoke-режиме `--tries 1` даёт чистую single-shot оценку, экономит ~25-30% времени suite. Full eval оставить с `--tries 2` для сравнения с публичным leaderboard.

**Применение 2026-04-26**: режимы --quick и --smoke теперь явно используют --tries 1, --full -- --tries 2. Параметр `--tries N` оставлен как override.

#### A-002: `--edit-format diff` для меньших prompt'ов

**Статус**: idea
**Impact**: средний (-30-60% prompt size на retry)
**Effort**: тривиальный

`--edit-format whole` отправляет полный файл при каждом edit. `diff` -- только изменения. Для retry-задачи разница prompt size с 5K → 1.5K токенов.

Минус: некоторые модели хуже работают с diff format (генерируют невалидный patch). Проверять `percent_cases_well_formed` после смены.

#### A-003: `--num-tests` cap по умолчанию

**Статус**: **применено 2026-04-26**
**Impact**: предсказуемое время smoke
**Effort**: тривиальный

Текущий smoke = 50 задач, реально 4-5 ч/модель. Снизить до 20 для quick smoke (~1.5 ч), оставить 50 опционально через `--full-smoke`.

**Применение 2026-04-26**: введены 3 режима в bench-aider.sh -- `--quick` (10), `--smoke` (20), `--full` (225). `--num-tests N` оставлен как override.

#### A-005: hard timeout per task в bench-aider.sh

**Статус**: **применено 2026-04-26**
**Impact**: критический -- предотвращает потерю часов на retry-loop
**Effort**: средний (правка benchmark.py wrapper, либо `timeout` обёртка)

В прогоне Coder Next aider завис на 31-й задаче в `litellm.Timeout` retry-loop с exponential backoff (~30 сек cap). За **3 часа** не было ни прогресса ни ошибки -- aider бесконечно перезапрашивал. Suite пришлось убивать вручную.

Корень: benchmark.py не имеет `--max-task-timeout`. litellm экспоненциально откатывается, но не помечает задачу как failed.

Действие: добавить watchdog в [`scripts/inference/bench-aider.sh`](../../scripts/inference/bench-aider.sh) -- если test_cases счётчик не растёт >10 минут, kill docker container и переходить к следующей.

Особенно критично для hybrid моделей (Coder Next, Qwen 3.6-27B), где cache-reuse не работает и retry потенциально ещё медленнее.

**Применение 2026-04-26**: реализован bash-watchdog в bench-aider.sh -- запуск `docker run --name aider-bench-$$` в фоне + параллельный watchdog-loop, который проверяет рост счётчика `test_cases:` каждые 30 сек. Если не было прогресса >900 сек (default 15 мин) или общее время >21600 сек (6 ч) -- `docker kill`. Параметризируется флагами `--task-timeout N` / `--total-timeout N`.

#### A-006: litellm retry-loop detector + LITELLM_REQUEST_TIMEOUT

**Статус**: **применено 2026-04-29**
**Impact**: критический -- закрывает дырку в watchdog A-005 (litellm не ловится progress-counter)
**Effort**: малый (~30 строк bash + 1 env var)

В прогоне Qwen3.5-122B-A10B (2026-04-29) обнаружился новый кейс: aider завис в **`litellm.Timeout` retry-loop** на JS задаче `affine-cipher`. Watchdog A-005 не сработал, потому что:

1. `test_cases:` counter не растёт (задача не закрыта)
2. **Лог обновляется** -- aider пишет "Retrying in 0.2 seconds..." каждые ~30 сек
3. log mtime обновляется → watchdog по `--task-timeout` думает что прогресс есть

Корень: litellm default timeout (60-100 сек) недостаточен для длинных responses на 122B-A10B (могут занимать >100 сек). Aider таймаутит → exponential backoff → бесконечный retry.

**Действие** (применено в [bench-aider.sh](../../scripts/inference/bench-aider.sh)):

1. **Proactive fix**: `LITELLM_REQUEST_TIMEOUT=600` env var в docker run -- 10 минут на отдельный API request, prevent timeout вообще
2. **Reactive safety net**: дополнительный watchdog detector -- если test_cases не рос >300 сек И в tail-200 лога >5 событий "Retrying in" → kill container

Это покрывает оба сценария: кейс быстрых responses (proactive timeout достаточен) и slow responses (reactive detector ловит).

#### A-004: `--languages python,javascript` для quick валидации

**Статус**: **применено 2026-04-26**
**Impact**: -67% времени (2 языка вместо 6)
**Effort**: средний (нужна правка `bench-aider.sh` для проброса флага)

Полезно для quick-sanity check после правок параметров (preset, llama.cpp build, modelfile). Полная multi-language оценка -- только в full-режиме.

**Применение 2026-04-26**: добавлен флаг `--languages cpp,go,java,javascript,python,rust` в bench-aider.sh (проброс в benchmark.py через -l). bench-aider-suite.sh пробрасывает флаг во все модели очереди.

### Архитектурный выбор моделей

#### M-001: Qwen3-Coder 30B-A3B как baseline для cache-sensitive workloads

**Статус**: **planned (следующий тест после Qwen3.6-35B smoke)**
**Impact**: cache-reuse работает (чистая attention MoE), даёт **прямой A/B замер влияния hybrid memory ограничения на производительность**
**Effort**: смена preset

Qwen3-Coder 30B-A3B (без "Next") -- чистая attention MoE без Gated DeltaNet и без mmproj. **Единственная active-coder модель платформы где cache-reuse РАБОТАЕТ полностью**:

| Модель | Hybrid memory | Multimodal | Cache reuse |
|--------|---------------|------------|-------------|
| Qwen3-Coder Next 80B | да (Gated DeltaNet) | нет | ❌ |
| Qwen3.6-35B-A3B | да (Gated DeltaNet) | да (mmproj) | ❌ |
| Gemma 4 26B-A4B | да (SWA) | да (mmproj) | ❌ |
| **Qwen3-Coder 30B-A3B** | **нет (full attention MoE)** | **нет** | ✅ |

Минус: 30B vs 35B/80B по качеству ниже на ~5-10pp (по предварительным leaderboard данным). Плюс: ~86 tok/s vs ~58 у Qwen3.6 -- **в 1.5× быстрее tg**.

**Use case**: high-frequency tool calls в одной сессии, FIM-completion с шарингом prefix, opencode/aider/Continue.dev multi-turn agentic coding.

**Тест-план (после завершения текущего Qwen3.6-35B smoke)**:

```bash
# Pre-flight: остановить текущий сервер на 8085
ssh -A -p 2277 nedlosster@79.164.89.150 \
  'cd ~/projects/ai-plant && ./scripts/inference/stop-servers.sh'

# Запустить qwen3-coder-30b на порту 8081
ssh -A -p 2277 nedlosster@79.164.89.150 \
  'cd ~/projects/ai-plant && ./scripts/inference/vulkan/preset/qwen3-coder-30b.sh -d'

# Healthcheck (ожидаем ~10 сек)
ssh -A -p 2277 nedlosster@79.164.89.150 \
  'curl -fs http://localhost:8081/v1/models'

# Smoke (тот же scope -- 20 задач, 5 языков без Rust, для прямого сравнения)
ssh -A -p 2277 nedlosster@79.164.89.150 -t \
  'cd ~/projects/ai-plant && \
   tmux new-session -d -s aider-test \
     "./scripts/inference/bench-aider.sh --smoke \
        --languages cpp,go,java,javascript,python \
        --model qwen3-coder-30b --port 8081 \
        --output /tmp/aider-test-30b-$(date +%Y%m%d-%H%M)"'
```

**Ожидаемые показатели** (на основе теории):
- seconds_per_case: ~150-180 сек (cache-reuse работает + tg выше → -30% по сравнению с Qwen3.6 ~275)
- pass_rate_1: ~30-40% (немного ниже Qwen3.6 single-shot)
- pass_rate_2: N/A (smoke = --tries 1)
- В логе llama-server: **НЕ должно быть** строки "forcing full prompt re-processing" (cache reuse работает)

**После теста сравнить с Qwen3.6-35B и Coder Next**:
- Если seconds_per_case разница ≥30% -- **подтверждена гипотеза о существенном overhead hybrid memory**
- Если разница меньше 10% -- cache reuse не главный фактор замедления, искать другие
- В обоих случаях -- pass_rate baseline для full-attention модели на платформе

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

#### U-001: cache-reuse для hybrid + multimodal моделей

**Статус**: распределён по нескольким open PR, общего решения нет
**Impact**: cache-reuse заработает для Coder Next / Qwen3.6-35B / Gemma 4 / Qwen3.6-27B
**Действие**: мониторить PR ниже, перезамерить smoke когда хотя бы один смержат

**Ремарка про PR 13194**: ссылка из лога llama-server (`forcing full prompt re-processing... see PR 13194`) ведёт не на open PR с фиксом, а на **уже смерженный** [PR #13194 от 20 мая 2025](https://github.com/ggml-org/llama.cpp/pull/13194) (`kv-cache: add SWA support`, +1414/-638). Это **исходное добавление SWA** в архитектуру KV-cache. Комментарий [#2868343055](https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055) от ggerganov объясняет архитектурное ограничение: SWA-cache теряет информацию о токенах при сдвиге окна, поэтому cache reuse / context shifting / token removal невозможны без fallback на "full" cache (большой и медленный).

**Реально открытые PR на 2026-04-26** (проверены через `gh pr view`):

| PR | Что делает | Статус | Польза для нашего случая |
|----|------------|--------|---------------------------|
| [#20819](https://github.com/ggml-org/llama.cpp/pull/20819) | Persist context checkpoints через `/slots` save/restore (router mode) | **OPEN** (на 2026-04-29, last activity 2026-03-29) | **Частично**. Решает router-mode (swap между моделями), не multi-turn в одной сессии. После merge -- replay 26K-токенов: 23s → 75ms при swap'е модели. |
| [#19670](https://github.com/ggml-org/llama.cpp/pull/19670) | partial seq_rm для hybrid memory (snapshot/rollback) | **OPEN** (на 2026-04-29, last activity 2026-03-12) | **Главный приоритет** -- inter-task cache reuse для hybrid Gated DeltaNet. После merge ожидаем -20% sec/case на Coder Next и 35B-text. |
| [#20376](https://github.com/ggml-org/llama.cpp/pull/20376) | Vulkan f16 mixed-precision state для **GATED_DELTA_NET** | **DRAFT** (на 2026-04-29, после feedback о numerical stability) | **Не решает cache reuse**, но ускорит prompt processing на ~10-20% для Coder Next и Qwen3.6. Автор переключается на "sharded approach" (PR #20391, #20361). |
| [#20697](https://github.com/ggml-org/llama.cpp/issues/20697) | feature request `--cache-disk` (persistent checkpoints) | OPEN issue | Будущая фича для cold-start cache. |
| [#16391](https://github.com/ggml-org/llama.cpp/issues/16391) | host-memory prompt caching | OPEN | Перспективная архитектурная задача. |
| [#21811](https://github.com/ggml-org/llama.cpp/issues/21811) | **Регрессия** в b8271 на Vulkan multimodal Qwen3.5-27B | OPEN issue | Может задеть наш b8717. Suspected commit `a7b3dee` (PR #20288 "make 2 checkpoints near the end"). |

**Вывод о перспективах** (проверено 2026-04-29 через `gh pr view`):
- **Все 3 целевых PR -- OPEN/DRAFT, не merged**. PR #20376 переведён в draft после feedback о numerical stability. PR #19670 ждёт review с марта. PR #20819 ждёт review с конца марта.
- **Intra-task checkpoint работает встроенным механизмом llama-server** (не из PR #20819). В логах видно `created context checkpoint N of 32` / `restored context checkpoint` -- это base feature checkpoint storage в slot, не из этого PR. Помогает на retry внутри одной задачи. Inter-task всё равно требует full re-processing на hybrid моделях.
- **3-6 мес**: PR #19670 -- решающий для inter-task cache reuse в hybrid моделях. После merge -20% sec/case на полном aider workflow
- **3-6 мес**: PR #20376 (или его replacement через sharded approach) -- ускорит pp на 10-20% всех hybrid моделей через f16 mixed-precision GATED_DELTA_NET
- **6-12+ мес**: cross-turn cache reuse в обычной (не save/restore) работе сервера для hybrid -- нет dedicated PR, требует архитектурного refactoring
- **Multimodal cache** -- открытого PR нет, multimodal-стек намеренно отключает cache reuse (`cache_reuse is not supported by multimodal, it will be disabled`). Архитектурная задача без даты.

**Стратегия на сегодня**: для cache-sensitive workloads использовать **Qwen3-Coder 30B-A3B** (full attention MoE, no multimodal -- cache-reuse работает 100%). Hybrid-моделей (Coder Next, Qwen3.6) -- принять overhead full prompt re-processing на каждом запросе.

### Сводная таблица: cache reuse по моделям (на 2026-04-29)

В llama-server существует **два уровня cache reuse**:

- **Intra-task** -- между retry внутри одной задачи / multi-turn в одной сессии. Работает через встроенный slot context checkpoint механизм (base feature, активна без специальных PR'ов). В логах: `created/restored context checkpoint N of 32`.
- **Inter-task** -- между разными запросами с разным prompt префиксом. Архитектурно зависит от типа attention.

| Модель | Архитектура | Intra-task | **Inter-task** |
|--------|-------------|------------|------------------|
| **[Qwen3-Coder 30B-A3B](../models/families/qwen3-coder.md#30b-a3b)** | Standard MoE attention | ✅ | **✅ работает 100%** |
| **[Devstral 2 24B (dense)](../models/families/devstral.md)** | Standard dense attention | ✅ | **✅ работает 100%** |
| [Qwen3.5-122B-A10B](../models/families/qwen35.md#122b-a10b) | Hybrid Gated DeltaNet (12 attn / 37 SSM из 49 layers) | ✅ | ❌ blocked |
| [Qwen3-Coder Next 80B-A3B](../models/families/qwen3-coder.md#next-80b-a3b) | Hybrid Gated DeltaNet | ✅ | ❌ blocked |
| [Qwen3.6-35B-A3B (text/multimodal)](../models/families/qwen36.md#35b-a3b) | Hybrid Gated DeltaNet | ✅ | ❌ blocked |
| [Qwen3.6-27B (dense)](../models/families/qwen36.md#27b) | Hybrid Gated DeltaNet | ✅ | ❌ blocked |
| [Gemma 4 26B-A4B](../models/families/gemma4.md) | SWA + multimodal | ✅ | ❌ blocked (двойная блокировка) |
| [Qwen3.5-35B-A3B (multimodal)](../models/families/qwen35.md#35b-a3b) | + multimodal lock | ✅ | ❌ blocked |

**Источник**: реальные logs llama-server (b8717), наблюдения 2026-04-29. Каждая модель проверена через `general.architecture` metadata + count attention layers vs total layers + `forcing full prompt re-processing` events.

**Что значит "работает 100%"**: `--cache-reuse 256` в preset реально переиспользует prefix между tasks. На больших prompt (5K+ токенов общего контекста) это даёт **2-5× ускорение** vs full re-processing на каждом запросе.

**Что значит "blocked"**: llama.cpp видит recurrent SSM state (Gated DeltaNet) или sliding window и не может корректно invalidate частичный prefix без полного пересчёта. Эффективная скорость на multi-task workloads -- как если бы cache не было вовсе.

**Когда снимется блок**: после merge llama.cpp [PR #19670](https://github.com/ggml-org/llama.cpp/pull/19670) -- partial seq_rm для hybrid memory. Status OPEN на 2026-04-29, ETA 3-6 мес. После merge ожидаем **-20-50% sec/case** на hybrid моделях для multi-task workloads (aider polyglot, opencode session).

**Production-вывод**: для cache-sensitive workloads сейчас доступны только **30B-A3B** (быстрая, но качество слабое: 26.3% pass_2) и **Devstral 2** (тестировался -- 15.0% pass_2, не подходит для agent). До merge PR #19670 hybrid модели (Coder Next, 35B-text, 122B-A10B) платят полную стоимость re-processing на каждой новой задаче.

#### U-002: PR #20376 -- Vulkan f16 GATED_DELTA_NET (наша платформа)

**Статус**: OPEN в upstream, ждёт review
**Impact**: -10-20% времени prompt processing для Coder Next и Qwen3.6-35B на Vulkan backend
**URL**: https://github.com/ggml-org/llama.cpp/pull/20376

Хранит 128-element state array в `float16_t` (вместо f32), все вычисления остаются в f32. Меньше register pressure → быстрее prompt processing. Тесты автора: 13/13 backend-ops passing, без потери точности.

Особенно ценен для нашей платформы (Vulkan -- основной backend). Когда смержится:
1. Обновить llama.cpp build (`/llama-cpp update`)
2. Перезамерить smoke на Coder Next и Qwen3.6 -- ожидаем -10-20% времени.

Проверять: раз в 2 недели через `gh pr view 20376 --repo ggml-org/llama.cpp`.

#### U-003: PR #20819 -- persist checkpoints через /slots save/restore

**Статус**: OPEN в upstream, REVIEW_REQUIRED
**Impact**: cache reuse в **router mode** (swap между моделями)
**URL**: https://github.com/ggml-org/llama.cpp/pull/20819

Решает узкий случай: когда сервер в router mode (`--models-max 1`) свопит модели, текущая реализация теряет checkpoints в памяти. Этот PR добавляет companion-файл `<slot>.checkpoints` чтобы save/restore сохранял checkpoints. Замеры автора (Qwen3.5-27B, 26K conversation): 23s → 75ms на restore.

**НЕ решает наш повседневный случай** (single model, multi-turn agentic в одной сессии). Но если в будущем будет добавлен router mode для платформы (свопы Coder Next ↔ Qwen3.6 ↔ Coder 30B) -- этот PR станет критичным.

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
| **U-001** | следить за PR 20376/20819/19670 (cache reuse hybrid) | huge | мониторинг | раз в 2 недели |
| **U-002** | следить за PR 20376 (Vulkan f16 GATED_DELTA_NET) | средний (-10-20% PP) | мониторинг | раз в 2 недели |
| **U-003** | следить за PR 20819 (router-mode checkpoints) | контекстный | мониторинг | если внедряем router mode |
| **A-002** | --edit-format diff | средний | тривиальный | после A-001 |
| **B-002** | --ubatch-size 2048 | средний | эмпирический | при llama-bench сессии |
| **B-004** | speculative decoding | высокий | средний | требует draft-модели |
| **M-001** | Qwen3-Coder 30B-A3B как fallback | контекстный | малый | при сценарии cache-sensitive |
| **I-003** | shared toolchain cache | малый | средний | если smoke станет регулярным |

**Top-4 действия сейчас**:
1. **A-005**: watchdog timeout -- предотвратить повторение 3-часового retry-loop из прогона Coder Next ✓ применено 2026-04-26
2. A-001 + A-003: правка `bench-aider.sh` -- snapshot smoke стал управляемым ✓ применено 2026-04-26
3. B-001: чистка пресетов от non-functional `--cache-reuse` ✓ применено 2026-04-26
4. U-001 / U-002: мониторить PR #20376 (Vulkan f16 Gated DeltaNet, наибольший impact для нашего стека) и #20819 (cache в router mode) -- проверять раз в 2 недели

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
- [../coding/benchmarks/runs/](../coding/benchmarks/runs/README.md) -- отчёты прогонов (источник наблюдений)
