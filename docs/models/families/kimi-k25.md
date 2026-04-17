# Kimi K2.5 (Moonshot AI, 2026)

> Open-weight 1T MoE с native vision, agentic coding и Agent Swarm -- лидер open-source agentic-сегмента 2026.

**Тип**: MoE (32B active / 1T total, 384 экспертов, 8 active + 1 shared)
**Лицензия**: Modified MIT (open weights)
**Статус на сервере**: не помещается (минимум 240 GiB даже в 1.8-bit dynamic)
**Направления**: [llm](../llm.md), [coding](../coding.md), [vision](../vision.md)

## Обзор

Kimi K2.5 -- релиз Moonshot AI в январе 2026, продолжение Kimi K2 (июль 2025). Главное отличие от K2: **native multimodal с нуля** -- continual pretraining на 15T токенах смешанных visual+text данных поверх Kimi-K2-Base. Vision-энкодер MoonViT (400M параметров) интегрирован архитектурно, не приклеен сверху.

Архитектура -- 1T параметров total / 32B active, 61 слой (1 dense + 60 MoE), 384 эксперта, выбор 8 + 1 shared per token. Тренировка на оптимизаторе Muon, специально разработанном Moonshot для trillion-scale MoE. Контекст 256K токенов.

Главная фишка K2.5 -- **Agent Swarm**: координация до 100 специализированных под-агентов параллельно. На Humanity's Last Exam достигает 50.2% при стоимости на 76% ниже Claude Opus 4.5, время выполнения сокращается в 4.5x. Это превратило K2.5 в основной open-source бэкенд для агентных инструментов после блокировки Anthropic Claude Pro/Max в third-party tools (см. [news.md](../../ai-agents/news.md#apr-2026----война-подписок-anthropic-vs-openclaw)).

## Варианты

| Вариант | Параметры | Active | Контекст | VRAM 1.8-bit | Статус | Hub |
|---------|-----------|--------|----------|--------------|--------|-----|
| Kimi-K2.5 (Instruct) | 1T MoE | 32B | 256K | 240 GiB+ | не помещается | [unsloth/Kimi-K2.5-GGUF](https://huggingface.co/unsloth/Kimi-K2.5-GGUF) |
| Kimi-K2-Thinking | 1T MoE | 32B | 256K | 240 GiB+ | не помещается | [unsloth/Kimi-K2-Thinking-GGUF](https://huggingface.co/unsloth/Kimi-K2-Thinking-GGUF) |
| Kimi-K2 (предыдущий) | 1T MoE | 32B | 128K | 240 GiB+ | не помещается | [unsloth/Kimi-K2-Instruct-GGUF](https://huggingface.co/unsloth/Kimi-K2-Instruct-GGUF) |

## Архитектура и особенности

- **MoE 384 экспертов**, 8 active + 1 shared per token (более sparse, чем DeepSeek V3 256/8)
- **Native multimodal**: MoonViT 400M интегрирован в претрейн (не post-hoc adapter)
- **Muon optimizer** -- разработан Moonshot для триллионных MoE
- **Agent Swarm** -- встроенная координация до 100 параллельных под-агентов
- **INT4 native** -- модель оригинально выпущена в INT4, поэтому 4-bit/5-bit GGUF близки к full precision
- **Tool calling, vision, function calling** -- из коробки
- **Vision merged в llama.cpp master** (PR закрыт), запуск без патчей

## Сильные кейсы

- **Agentic coding** -- SWE-Bench Verified 76.8% (vs K2: 65.8%), лидер open-source
- **Multimodal reasoning** -- MMMU Pro 78.5% (обходит GPT-5.2)
- **Math reasoning** -- AIME 2025 96.1% (vs ~88% у GPT-5.2)
- **BrowseComp 74.9%** -- лучший среди open-моделей на агентных browsing-задачах
- **Дешёвый API** -- $0.45 / 1M input tokens, frontier-class по цене бюджетных моделей
- **Замена Claude Opus** в open-source стеке: после блокировки Anthropic Pro/Max в OpenClaw/Cline апреля 2026

## Слабые стороны / ограничения

- **Не помещается на нашу платформу** (120 GiB unified) -- даже Dynamic 1.8-bit требует 240 GiB
- **Огромный disk footprint**: 600 GiB в оригинале, 240 GiB в самом маленьком кванте
- **Скорость локально низкая**: 16 GiB VRAM + 256 GiB RAM даёт 5+ tok/s -- неудобно для интерактива
- **Лучше через API**, чем локально -- $0.45/1M input делает self-hosting экономически бессмысленным
- **Vision encoder MoonViT не отделяется** -- нельзя запустить text-only вариант для экономии

## Идеальные сценарии применения

- **API-режим через [opencode](../../ai-agents/agents/opencode.md), [Cline](../../ai-agents/agents/cline.md), [OpenClaw](../../ai-agents/agents/openclaw/README.md)** -- основной use case в 2026
- **Long-context multi-file refactoring** -- 256K + agentic loop для крупных monorepo
- **Visual debugging** -- скриншоты ошибок + код в одном промпте
- **Замена Claude Sonnet/Opus** при бюджетных ограничениях на frontier-tier
- **Agent Swarm для распределённых задач** -- параллельные под-агенты на одну задачу

## Загрузка (если будут возможности)

```bash
# Полный 1T (600 GiB) -- не для нашей платформы
./scripts/inference/download-model.sh unsloth/Kimi-K2.5-GGUF \
    --include "*UD-IQ1_S*"  # самый маленький Dynamic 1.8-bit (~240 GiB)
```

## Запуск

Локально на платформе невозможен. Использовать через API или удалённый сервер с 240+ GiB unified memory.

Подключение через OpenAI-compatible endpoint:

```bash
export OPENAI_BASE_URL=https://api.moonshot.ai/v1
export OPENAI_API_KEY=<key>
opencode --model kimi-k2.5
```

## Бенчмарки

| Бенч | Значение | Сравнение |
|------|----------|-----------|
| SWE-bench Verified | **76.8%** | K2: 65.8%, Qwen3-Coder Next: 70.6% |
| MMMU Pro (vision) | 78.5% | обходит GPT-5.2 |
| AIME 2025 (math) | 96.1% | GPT-5.2: ~88% |
| BrowseComp (agentic) | 74.9% | лидер open-source |
| Humanity's Last Exam | 50.2% (с Agent Swarm) | -76% стоимости vs Opus 4.5 |

## Ссылки

**Официально**:
- [moonshotai/Kimi-K2.5](https://huggingface.co/moonshotai/Kimi-K2.5) -- основной репозиторий
- [GitHub: MoonshotAI/Kimi-K2.5](https://github.com/MoonshotAI/Kimi-K2.5)
- [Карточка организации Moonshot](https://huggingface.co/moonshotai)

**GGUF-квантизации**:
- [unsloth/Kimi-K2.5-GGUF](https://huggingface.co/unsloth/Kimi-K2.5-GGUF) -- Dynamic 1.8-bit / 2-bit / 4-bit / 5-bit
- [unsloth/Kimi-K2-Thinking-GGUF](https://huggingface.co/unsloth/Kimi-K2-Thinking-GGUF) -- thinking-вариант
- [ubergarm/Kimi-K2.5-GGUF](https://huggingface.co/ubergarm/Kimi-K2.5-GGUF) -- альтернативные кванты
- [AesSedai/Kimi-K2.5-GGUF](https://huggingface.co/AesSedai/Kimi-K2.5-GGUF)

**Документация / анонсы**:
- [Unsloth: Run Kimi K2.5 Locally](https://unsloth.ai/docs/models/kimi-k2.5)
- [NVIDIA NIM: kimi-k2.5](https://build.nvidia.com/moonshotai/kimi-k2.5/modelcard)
- [Wikipedia: Moonshot AI](https://en.wikipedia.org/wiki/Moonshot_AI)

## Связано

- Направления: [llm.md](../llm.md), [coding.md](../coding.md), [vision.md](../vision.md)
- Конкуренты по нише: [qwen36](qwen36.md) (API-only frontier), [qwen3-coder](qwen3-coder.md) (open, помещается), [deepseek-distill](deepseek-distill.md)
- Использующие агенты: [opencode](../../ai-agents/agents/opencode.md), [Cline](../../ai-agents/agents/cline.md), [OpenClaw](../../ai-agents/agents/openclaw/README.md)
- Контекст релиза: [../../ai-agents/news.md](../../ai-agents/news.md)
