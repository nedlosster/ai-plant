# InternVL3 (OpenGVLab, 2025)

> Vision-серия с большим vision encoder (6B), сильна на математике, диаграммах, reasoning.

**Тип**: dense (2B / 14B / 78B)
**Лицензия**: Open
**Статус на сервере**: не скачана
**Направления**: [vision](../vision.md)

## Обзор

InternVL3 от OpenGVLab -- серия с фокусом на reasoning и сложные задачи. Использует **InternViT-6B-448px-V2_5** -- большой vision encoder (6B параметров, в 6 раз больше типового). Отсюда сила на сложных визуальных задачах: математика, диаграммы, графики.

## Варианты

| Вариант | Параметры | VRAM Q4 | mmproj | MMMU | Статус | Hub |
|---------|-----------|---------|--------|------|--------|-----|
| InternVL3-2B | 2B dense | ~2 GiB | ~3 GiB | -- | не скачана | [bartowski/InternVL3-2B-GGUF](https://huggingface.co/bartowski/InternVL3-2B-GGUF) |
| InternVL3-14B | 14B dense | ~8 GiB | ~3 GiB | -- | не скачана | [bartowski/InternVL3-14B-GGUF](https://huggingface.co/bartowski/InternVL3-14B-GGUF) |
| InternVL3-78B | 78B dense | ~50 GiB | ~3 GiB | **72.2** | не скачана | [bartowski/InternVL3-78B-GGUF](https://huggingface.co/bartowski/InternVL3-78B-GGUF) |

## Сильные кейсы

- **Математика по картинке** -- решение задач из учебников, уравнения с переменными, геометрия
- **Научные диаграммы** -- графики из статей, диаграммы рассеяния, контурные карты
- **Chart QA** -- одна из лучших на ChartQA benchmark
- **Reasoning по схемам** -- блок-схемы алгоритмов, UML, ER-диаграммы
- **Tables** -- извлечение таблиц из научных статей
- **Лидер на MMMU** -- 78B = 72.2 (комплексный multimodal reasoning)

## Слабые стороны

- mmproj большой (3 GB) -- занимает заметно VRAM
- OCR на текстах не лучше [qwen3-vl](qwen3-vl.md)
- Function calling слабее
- Не поддерживает видео нативно

## Идеальные сценарии

- **Исследовательская работа** -- обработка научных PDF с диаграммами
- **Образовательные приложения** -- решение задач по фото из учебника
- **Финансовая аналитика** -- понимание квартальных отчётов с графиками
- **STEM-education tools**

## Загрузка

```bash
./scripts/inference/download-model.sh bartowski/InternVL3-14B-GGUF \
    --include '*Q4_K_M*' --include 'mmproj*'
```

## Связано

- Направления: [vision](../vision.md)
- Альтернативы: [qwen3-vl](qwen3-vl.md) (OCR/документы), [gemma4](gemma4.md) (function calling)
