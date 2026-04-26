# AI-кодинг: ожидания и тренды

Прогнозы по open-source coding моделям и агентам на Q2-Q3 2026 и далее. Что ожидать, что следить, на что не рассчитывать. Платформа: Strix Halo (120 GiB unified VRAM, 256 GB/s bandwidth).

Обновляется реже чем [news.md](news.md) -- ориентир на тренды, не на отдельные релизы. Профиль раздела -- [README.md](README.md).

---

## Почему современные модели "маленькие"

Распространённое недоумение: на платформу помещаются модели до ~250B Q4, а актуальные релизы для coding -- 27-35B. Кажется что это "не использует ресурс".

Это не так. Размер выбран осознанно по архитектурным причинам.

### MoE vs dense: что определяет скорость

На memory-bound платформе (Strix Halo: 256 GB/s) **скорость определяется active params, а не total**.

| Модель | Total | Active | tg tok/s | Почему |
|--------|-------|--------|----------|--------|
| Qwen3.6-35B-A3B (MoE) | 35B | 3B | **58.7 (замер)** | 1.7 GiB Q4 active -> 256/1.7 ≈ 150 max, реально ~40% от theoretical |
| Qwen 3.6-27B (dense) | 27B | 27B | ~15 | 17 GiB Q4 active -> 256/17 ≈ 15 max |
| Qwen3-Coder Next (MoE) | 80B | 3B | 53 | 3B active, но larger router overhead |
| Qwen3-Coder 30B-A3B (MoE) | 30B | 3B | 86 | минимальный router |

То есть **dense 27B в 5x медленнее sparse 35B** при сопоставимом качестве coding. Архитектура решает.

### Total params -- широта, active -- глубина

Roughly:
- **Total params** -- сколько знаний помещается: синтаксис языков, библиотеки, паттерны, edge cases
- **Active params** -- глубина reasoning на каждый токен: насколько сложные цепочки рассуждений можно построить

Для coding обычно:
- Дискретные фрагменты (написать функцию, понять stack trace) -- зависит от total knowledge
- Сложный architecture/refactor -- зависит от active reasoning

3B active хватает для большинства agent-loop задач (tool calls, многоступенчатый план, простые рефакторы). 10B+ active нужен для unfamiliar codebases с глубоким reasoning.

### Парадокс Qwen3.6: dense 27B обгоняет 397B MoE

| Модель | Total | SWE-V | HumanEval | Архитектура |
|--------|-------|-------|-----------|-------------|
| Qwen3.6-27B (dense) | 27B | **77.2%** | -- | Hybrid Gated DeltaNet |
| Qwen3.5-397B-A17B (MoE) | 397B | ~70% | -- | Standard MoE |
| Qwen3-Coder-480B-A35B | 480B | ~68% | -- | Coder MoE |

Меньшая модель **обгоняет в 15-18× большую** на coding-бенчмарках. Причины:
- Coding-специализация (data mix, fine-tune под tool use, FIM)
- Архитектурные оптимизации (Gated DeltaNet, hybrid attention)
- Качество instruction-tuning и RLHF
- Чище данные обучения (меньше noise)

**Вывод**: размер ≠ качество. На современной архитектуре 27-35B специализированной модели достаточно для большинства coding-задач, кроме самых тяжёлых reasoning-сценариев.

---

## Что уже есть на платформе (апрель 2026)

| Модель | Размер Q4 | SWE-V | Роль |
|--------|-----------|-------|------|
| [Qwen3-Coder Next](../models/families/qwen3-coder.md#next-80b-a3b) | 45 GiB | 70.6% | Long-context agent (256K) |
| [Qwen3-Coder 30B-A3B](../models/families/qwen3-coder.md#30b-a3b) | 18 GiB | ~62% | Quick chat |
| [Qwen3.6-35B-A3B](../models/families/qwen36.md#35b-a3b) | 20 GiB + mmproj | 73.4% | Default daily agent (vision) |
| [Devstral 2 24B](../models/families/devstral.md) | 14 GiB | 72.2% | FIM+agent dense |
| [Qwen3.5-122B-A10B](../models/families/qwen35.md) | 71 GiB | -- | Heavy reasoning |
| [Qwen2.5-Coder 1.5B](../models/families/qwen25-coder.md#1-5b) | 2 GiB | -- | FIM autocomplete |

Стек закрывает: FIM, quick chat, daily agent, long-context, heavy reasoning, vision. Качество локальных моделей вплотную к Claude Sonnet 4.5 / Opus 4.5 на типичных задачах.

---

## Что не помещается (frontier, API-only)

Платформа держит до ~250B Q4. Выше -- только cloud API:

| Модель | Размер Q4 | SWE-V | Lic | Доступ |
|--------|-----------|-------|-----|--------|
| Qwen3-Coder-480B | ~270 GB | -- | Apache 2.0 | API + offload-возможен |
| MiMo V2.5-Pro (Xiaomi) | ~600 GB | -- (Pro 57.2%) | "open soon" | -- |
| Kimi K2.6 (Moonshot) | ~250 GB | 80.2% | Modified MIT | API |
| GLM-5.1 (Z.AI) | ~440 GB | -- (Pro 58.4%) | MIT | API |
| DeepSeek V4-Pro | ~880 GB | 80.6% | MIT | API |
| Claude Opus 4.7 | -- | 87.6% | Closed | API |
| GPT-5.3 Codex | -- | 85.0% | Closed | API |

Frontier closed-source даёт ~10-15 п.п. SWE-V преимущества над лучшим local. Платится в pay-as-you-go API-токенах.

---

## Что ждать (Q2-Q3 2026)

### Прямо ожидаемые релизы

**Qwen 4 family** (предположительно Q3 2026)
- По циклу: Qwen3.5 в феврале, Qwen3.6 в апреле, Qwen 4 ожидается летом
- Скорее всего будут варианты 30-100B, sparse MoE
- Direct fit для платформы

**DeepSeek V4-Flash доработка**
- 284B / 13B active, MIT
- Уже релизнут (24 апреля), но 13B active требует offload-решений
- Ожидается Ollama-интеграция, ROCm-fixes
- Если SWE-V подтвердится 79%, станет лучшим open для платформы по SWE через offload

**Llama 4 family expansion** (слухи)
- Meta анонсировал Maverick (1T+), но средний вариант не выпустил
- Ожидается релиз 70-100B coder-варианта для self-hosted (Q2-Q3 2026)
- Не подтверждено

**Devstral 3** (Mistral, не подтверждено)
- Devstral 2 (24B) -- сильный dense coder. Если будет 3 -- скорее всего тот же диапазон
- Mistral может перейти на MoE по тренду рынка

### Тренд: sparse MoE 50-100B становится новой нормой

Frontier масштабируется в 1T+ для cloud, но для self-hosted (Strix Halo, Mac M4 Ultra, DGX Spark) производители целятся именно в 50-100B sparse:
- 50-100B total -- помещается на 120 GiB
- 5-15B active -- разумная скорость на 256 GB/s
- MoE -- широта знаний без compute-cost dense
- Vision -- de facto стандарт

Это **прямая категория для платформы Strix Halo**.

### Что НЕ стоит ждать

- **Большой dense >100B** для local -- не делают, dense дорогие в обучении и медленные в inference
- **Coder-only foundation** в малых размерах -- general-purpose с coding-специализацией оказались эффективнее
- **Frontier модели в open** -- DeepSeek V4 единственное исключение, остальные (Mythos, GPT-5.3, Opus 4.7) останутся closed
- **Strix Halo native ROCm 100% stable** -- ROCm 7+ имеет regression issues, fixes идут медленно. Vulkan остаётся primary

---

## Coding agents: куда идёт индустрия

### Консолидация

- **SpaceX-Cursor** ($60B option, апрель 2026) -- сигнал: VC-фаза кончается, начинаются strategic acquisitions
- **Anthropic-Amazon** (+$5B) -- compute как валюта
- **Anysphere → corporate**, **Devin → enterprise** -- B2B становится главным

Прогноз: 1-2 крупных слияния среди commercial agents до конца 2026. Open-source (opencode, Cline, Aider) останется бесплатной альтернативой.

### Multi-agent / Agent Teams

Тренд набирает обороты:
- Claude Code Agent Teams (experimental)
- Kimi K2.6 Agent Swarm (до 300 агентов)
- Cursor 3 parallel Agent Tabs
- OpenClaw Hermes Agent

Реальная польза:
- **Refactor monorepo** (10+ services)
- **Multi-language migration**
- **Security audit / scan**

Антипаттерны:
- Простые задачи (overhead координации)
- Когда нет естественного разбиения

Подробнее: [agent-teams.md](../ai-agents/agents/claude-code/agent-teams.md).

### Computer Use / Vision-driven coding

С vision encoder в 35B-A3B и MiMo V2.5-Pro:
- Скриншот ошибки -> фикс
- Wireframe -> код компонента
- UI design -> functional frontend
- Stack trace screenshot -> debugging

Это становится daily, не demo. Ожидаемо распространение в IDE-расширениях.

### Бенчмарки: Pro замещает Verified

SWE-bench Verified загрязнён (>80% подозрительно по аудиту OpenAI, февраль 2026). SWE-bench Pro становится primary metric:
- Cleaned dataset, без contamination
- Frontier closed: 57-65% Pro (vs 80-93% Verified)
- Open лидеры: Kimi K2.6 58.6%, GLM-5.1 58.4%, MiMo V2.5-Pro 57.2%

Если в обзоре указан только Verified -- скорее всего модель загрязнена. Смотреть Pro.

---

## Рекомендации по миграции стека

### Если есть бюджет на эксперименты

- Скачать DeepSeek V4-Flash при появлении ROCm-fixes (potential 79% SWE-V)
- Тестировать Kimi K2.6 через API (Anthropic-blocking иронично толкает к open)
- Следить за Qwen 4 release (ожидается Q3 2026)

### Если нужна стабильность

- Qwen 3.6-35B-A3B как default (текущий рекомендуемый)
- Qwen3-Coder Next для long-context fallback
- Qwen3.5-122B-A10B для тяжёлого reasoning
- Devstral 2 24B как dense alternative

### Когда переходить на cloud

Local не заменит frontier на:
- Heavy debugging unfamiliar codebase
- Architecture review больших систем
- Когда нужно >256K контекста
- Multi-modal pipelines (вспоминание + поиск + reasoning)

Cloud baseline: Claude Sonnet 4.5 ($3/$15 per M) или GPT-5.3 Codex ($10/$30) для сложных задач. Подробнее: [closed-source-coding.md](../models/closed-source-coding.md).

---

## Связанные статьи

- [README.md](README.md) -- профиль раздела
- [news.md](news.md) -- хроника событий
- [workflows.md](workflows.md) -- практические workflow'ы
- [resources.md](resources.md) -- блоги, рассылки, leaderboard-сайты
- [Модели для кодинга](../models/coding.md) -- каталог open coding LLM
- [Closed-source coding](../models/closed-source-coding.md) -- frontier модели
- [SWE-bench](../llm-guide/benchmarks/swe-bench.md) -- методология бенчмарка, contamination
- [Тренды AI-агентов](../ai-agents/trends.md) -- общие парадигмы индустрии
