# Модели для кодинга

Платформа: Radeon 8060S (120 GiB GPU-доступной памяти), llama-server + Vulkan.

## Рекомендуемый набор

| Модель | VRAM | tg tok/s | Назначение |
|--------|------|----------|-----------|
| **Qwen2.5-Coder-1.5B** | ~2 GiB (Q8) | 120.6 | FIM-автодополнение в IDE |
| **Qwen3-Coder-30B-A3B** (MoE) | ~18 GiB Q4 | 86.1 | Chat, рефакторинг, быстрая |
| **Qwen3-Coder-Next** (MoE) | ~45 GiB Q4 | 53.2 | Максимальное качество, SWE-bench |
| **Devstral Small 2 24B** | ~15 GiB Q4 | -- | Агентные задачи, 256K контекст |

### Доступны при 120 GiB (были недоступны/впритык при 96)

| Модель | VRAM | Назначение |
|--------|------|-----------|
| **Qwen2.5-Coder-32B Q8_0** | ~40 GiB | FIM + chat максимального качества |
| **Mixtral 8x22B Q4_K_M** | ~82 GiB | MoE 141B, универсальный кодинг + chat |

При 120 GiB можно держать Coder-Next (~45 GiB) + FIM 1.5B (~2 GiB) одновременно с запасом ~73 GiB.

## Рейтинг моделей

| Модель | Параметры | Active | HumanEval | SWE-bench | FIM | Контекст | Лицензия | GGUF Q4 |
|--------|-----------|--------|-----------|-----------|-----|----------|----------|---------|
| **Qwen3-Coder-Next** | 80B MoE | 3B | -- | Pro 44.3% | нет | 256K | Apache 2.0 | ~45 GiB |
| **Qwen3-Coder-30B-A3B** | 30B MoE | 3B | -- | -- | нет | 256K | Apache 2.0 | ~18 GiB |
| **Qwen2.5-Coder-32B** | 32B dense | 32B | 92.7% | -- | да | 128K | Apache 2.0 | ~20 GiB |
| **Devstral Small 2** | 24B dense | 24B | -- | 68.0% | да | 256K | Apache 2.0 | ~15 GiB |
| **Codestral 22B** | 22B dense | 22B | -- | -- | да | 32K | MNPL | ~13 GiB |
| **Qwen2.5-Coder-14B** | 14B dense | 14B | ~89% | -- | да | 128K | Apache 2.0 | ~9 GiB |
| **Qwen2.5-Coder-7B** | 7B dense | 7B | 88.4% | -- | да | 128K | Apache 2.0 | ~5 GiB |
| **StarCoder2-15B** | 15B dense | 15B | -- | -- | да | 16K | BigCode OL | ~9 GiB |
| **Qwen2.5-Coder-1.5B** | 1.5B dense | 1.5B | ~75% | -- | да | 128K | Apache 2.0 | ~1 GiB |

MoE-модели (Qwen3-Coder) активируют только 3B параметров на токен -- высокая скорость при большом объеме знаний.

## Бенчмарки на платформе (Vulkan, llama-bench pp512/tg128)

| Модель | Размер | pp tok/s | tg tok/s |
|--------|--------|----------|----------|
| Qwen2.5-Coder-1.5B Q8_0 | 1.5 GiB | 5245 | 120.6 |
| Qwen3-Coder-30B-A3B Q4_K_M | 17.3 GiB | 1036 | 86.1 |
| Qwen3-Coder-Next Q4_K_M | 45.1 GiB | 590 | 53.2 |

MoE-модели дают высокую скорость генерации: 30B-A3B -- 86 tok/s, Next 80B-A3B -- 53 tok/s. Dense 32B при том же VRAM дал бы ~12 tok/s.

## FIM-совместимость

Fill-in-Middle (FIM) -- режим вставки кода в середину (между prefix и suffix). Критично для автодополнения в IDE.

**Модели с FIM**: Qwen2.5-Coder (все размеры), Devstral Small 2, Codestral 22B, StarCoder2.

**Модели без FIM** (только chat): Qwen3-Coder-Next, Qwen3-Coder-30B-A3B.

Для автодополнения -- FIM-модель. Для chat/агентов -- любая.

---

## Qwen3-Coder (новейшее поколение)

**Назначение**: кодинг нового поколения. MoE-архитектура -- быстрый отклик при большом объеме знаний.

**Сильные стороны**:
- Qwen3-Coder-Next: SWE-bench Pro 44.3% -- лидер среди open-source для агентных задач
- MoE (3B active): 86 tok/s (30B-A3B), 53 tok/s (Next) -- замерено на платформе
- Контекст 256K -- навигация по большим проектам
- Apache 2.0

**Слабые стороны**:
- Нет FIM (только chat) -- не для автодополнения в IDE
- Next: ~45 GiB Q4 -- но при 120 GiB помещается с запасом

**Применение**:
- AI-агенты: Aider, SWE-agent, Cline
- Рефакторинг больших проектов (256K контекст)
- Code review, генерация тестов
- Сложные архитектурные задачи (Next)

---

## Qwen2.5-Coder (FIM, автодополнение)

**Назначение**: FIM-модели для автодополнения в IDE. Линейка от 1.5B до 32B.

**Сильные стороны**:
- FIM из коробки -- автодополнение в Continue.dev, llama.vscode
- HumanEval 92.7% (32B) -- лучший среди open-source
- Линейка размеров: 1.5B для FIM, 32B для chat
- Apache 2.0

**При 120 GiB**: Qwen2.5-Coder-32B в Q8_0 (~40 GiB) -- максимальное качество FIM. При 96 GiB Q8 занимал слишком много места для параллельной работы с другими моделями.

**Применение**:
- **1.5B (Q8, ~2 GiB)**: FIM-сервер (порт 8081), автодополнение -- 120 tok/s
- **7B (Q4, ~5 GiB)**: FIM повышенного качества
- **32B (Q4, ~20 GiB / Q8, ~40 GiB)**: Chat, рефакторинг, генерация кода

---

## Devstral Small 2 (Mistral)

**Назначение**: агентный кодинг с длинным контекстом 256K. Оптимизация под SWE-agent.

**Сильные стороны**:
- SWE-bench Verified 68.0%
- Контекст 256K -- весь проект в контексте
- FIM-поддержка
- Apache 2.0

**Слабые стороны**:
- 24B dense -- медленнее MoE Qwen3-Coder при том же качестве
- Русский средний

---

## Codestral 22B (Mistral)

**Назначение**: code completion, 80+ языков программирования.

**Сильные стороны**:
- Оптимизирована для code completion и infill
- 32K контекст
- Хороший FIM

**Слабые стороны**:
- MNPL-лицензия (ограничения на коммерческое использование)
- 22B dense -- ~13 GiB Q4

---

## Загрузка

```bash
cd ~/projects/ai-plant

# FIM (автодополнение, 1.5B Q8) -- ~2 GiB
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF --include "*Q8_0*"

# Chat/агенты (MoE, 30B-A3B) -- ~18 GiB
./scripts/inference/download-model.sh unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF --include "*Q4_K_M*"

# Максимальное качество (MoE, Next) -- ~45 GiB
./scripts/inference/download-model.sh Qwen/Qwen3-Coder-Next-GGUF --include "*Q4_K_M*"

# Агентный (Devstral, 256K контекст) -- ~15 GiB
./scripts/inference/download-model.sh unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF --include "*Q4_K_M*"

# FIM высокого качества (7B) -- ~5 GiB
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-7B-Instruct-GGUF --include "*Q4_K_M*"

# Codestral (FIM, 80+ языков) -- ~13 GiB
./scripts/inference/download-model.sh bartowski/Codestral-22B-v0.1-GGUF --include "*Q4_K_M*"
```

## Два сервера одновременно

FIM (1.5B Q8, ~2 GiB) + Chat (30B-A3B Q4, ~18 GiB) = ~20 GiB. Остается ~100 GiB.

```bash
# Терминал 1: FIM (порт 8081)
./scripts/inference/start-fim.sh Qwen2.5-Coder-1.5B-Instruct-Q8_0.gguf --daemon

# Терминал 2: Chat (порт 8080)
./scripts/inference/start-server.sh Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf --daemon
```

## Инструменты

Подробнее: [use-cases/coding/](../use-cases/coding/README.md)

| Инструмент | Модель | Порт |
|-----------|--------|------|
| Continue.dev (autocomplete) | Coder 1.5B FIM | 8081 (/infill) |
| Continue.dev (chat) | Coder 30B-A3B | 8080 (/v1/chat) |
| Aider | Coder-Next или 30B-A3B | 8080 |
| Cline / Roo Code | Coder-Next или 30B-A3B | 8080 |
| SWE-agent | Coder-Next | 8080 |

## Связанные статьи

- [Справочник LLM](llm.md)
- [IDE-интеграция](../use-cases/coding/ide-integration.md)
- [AI-агенты](../use-cases/coding/agents.md)
- [Настройка сервера](../use-cases/coding/server-setup.md)
- [Бенчмарки](../inference/benchmarking.md)
