# Qwen3-VL (Alibaba, 2026)

> Vision-флагман от Qwen, лучший OCR/document understanding в open-source.

**Тип**: MoE (3B-22B active)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [vision](../vision.md)

## Обзор

Qwen3-VL -- специализированная vision-серия от Alibaba 2026. 30B-A3B вариант -- быстрая MoE с 3B активных параметров, как у [qwen3-coder Next](qwen3-coder.md), но с vision. 235B-A22B -- флагман уровня Gemini-2.5-Pro / GPT-5 на multimodal-бенчмарках.

## Варианты

| Вариант | Параметры | Active | VRAM Q4 | mmproj | Статус | Hub |
|---------|-----------|--------|---------|--------|--------|-----|
| 30B-A3B Instruct | 30B MoE | 3B | 18.6 GiB | 1.08 GB F16 | не скачана | [Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF) |
| 30B-A3B Thinking | 30B MoE | 3B | 18.6 GiB | 1.08 GB F16 | не скачана | [Qwen/Qwen3-VL-30B-A3B-Thinking-GGUF](https://huggingface.co/Qwen/Qwen3-VL-30B-A3B-Thinking-GGUF) |
| 235B-A22B Instruct | 235B MoE | 22B | ~135 GiB | ~3 GB | не скачана | [Qwen/Qwen3-VL-235B-A22B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen3-VL-235B-A22B-Instruct-GGUF) |

### 30B-A3B Instruct {#30b-a3b}

Рекомендуемая модель для платформы. MoE с 3B active -- скорость как у Qwen3-Coder.

### 235B-A22B {#235b-a22b}

На пределе VRAM (135 GB Q4 + ~3 GB mmproj + контекст). Уровень Gemini-2.5-Pro / GPT-5.

## Сильные кейсы

- **OCR на 30+ языках** -- лучшая в open-source. Русский, китайский, японский, арабский в одном потоке
- **Document understanding** -- структурированный JSON-вывод из PDF/счетов/договоров
- **Video understanding** -- ввод нескольких кадров, action recognition
- **Structured output** -- строго валидный JSON по schema
- **Agentic GUI** -- кликабельные координаты на скриншотах
- **Чтение комиксов/манги** -- понимает порядок панелей, текст в баблах
- **UI-to-code** -- скриншот макета → HTML/React

## Слабые стороны

- Reasoning -- через Thinking-вариант (выше latency)
- 235B на пределе VRAM, мало места под контекст

## Идеальные сценарии

- Парсинг чеков/счетов → JSON для бухгалтерии
- Извлечение данных из научных публикаций
- Browser automation: скриншот → следующий клик
- Многоязычный OCR
- Замена платных Document AI сервисов

## Загрузка

```bash
# 30B-A3B (рекомендуется для платформы)
./scripts/inference/download-model.sh Qwen/Qwen3-VL-30B-A3B-Instruct-GGUF \
    --include '*Q4_K_M*' --include '*mmproj*F16*'
```

## Связано

- Направления: [vision](../vision.md)
- Альтернативы: [gemma4](gemma4.md) (function calling), [qwen25-omni](qwen25-omni.md) (vision+audio)
