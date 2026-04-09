# DeepSeek-R1-Distill (DeepSeek, 2025)

> Дистилляции из DeepSeek-R1 (671B) -- reasoning в компактных моделях, MIT.

**Тип**: dense (14B / 32B)
**Лицензия**: MIT
**Статус на сервере**: не скачана
**Направления**: [llm](../llm.md)

## Обзор

R1-Distill -- дистилляции рассуждений из DeepSeek-R1 (671B, MoE) в компактные модели Qwen и Llama. MIT-лицензия. На платформе помещаются 14B и 32B варианты. R1-Distill-32B (Qwen base) -- MATH-500 94.3 при ~19 GiB.

## Варианты

| Вариант | База | Параметры | VRAM Q4 | MATH-500 | Статус | Hub |
|---------|------|-----------|---------|----------|--------|-----|
| R1-Distill-32B (Qwen) | Qwen2.5-32B | 32B dense | ~19 GiB | 94.3 | не скачана | [bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF](https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF) |
| R1-Distill-14B (Qwen) | Qwen2.5-14B | 14B dense | ~8.5 GiB | 93.9 | не скачана | [bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF](https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF) |

## Сильные кейсы

- **MATH-500 94.3 (32B)** -- топ reasoning при ~19 GiB
- **MIT-лицензия** -- полная свобода
- **Дистиллированные знания флагмана 671B** в компактных моделях
- **Базы Qwen и Llama** -- знакомая архитектура

## Слабые стороны

- **Длинные chain-of-thought**
- **Русский нестабильный** -- иногда переключается на английский в reasoning
- Уступает специализированным моделям на не-reasoning задачах

## Идеальные сценарии

- Math/logic-задачи с MIT-лицензией
- Замена платных reasoning-API
- Дистиллированный аналог DeepSeek-R1 для локального запуска

## Загрузка

```bash
# 32B (~19 GiB)
./scripts/inference/download-model.sh bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF --include "*Q4_K_M*"

# 14B (~8.5 GiB)
./scripts/inference/download-model.sh bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF --include "*Q4_K_M*"
```

## Связано

- Направления: [llm](../llm.md)
- Альтернативы: [qwq](qwq.md) (reasoning Apache), [phi](phi.md) (reasoning при малом VRAM)
