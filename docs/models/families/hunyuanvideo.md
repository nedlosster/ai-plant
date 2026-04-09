# HunyuanVideo (Tencent, 2024-2025)

> Foundation-модель для T2V/I2V с точным text-video alignment, понимание физики и кинематографии.

**Тип**: dense (8.3B в 1.5)
**Лицензия**: Tencent HunyuanVideo License
**Статус на сервере**: не скачана
**Направления**: [video](../video.md)

## Обзор

HunyuanVideo 1.5 (ноябрь 2025) -- 8.3B параметров (было 13B в 1.0). Унифицированная transformer-based архитектура для image и video. Dual-stream design (visual + text streams взаимодействуют). Foundation для дальнейших fine-tune.

## Варианты

| Вариант | Параметры | fp16 | VRAM offload | Hub |
|---------|-----------|------|--------------|-----|
| 1.5 | 8.3B | ~16 GB | 14 GB | [tencent/HunyuanVideo](https://huggingface.co/tencent/HunyuanVideo) |
| 1.0 | 13B | ~26 GB | -- | (устарела) |

GitHub: [Tencent-Hunyuan/HunyuanVideo](https://github.com/Tencent-Hunyuan/HunyuanVideo)

## Сильные кейсы

- **Foundation для fine-tune** -- база для своих доменных моделей
- **Text-video alignment** -- очень точно следует промпту
- **Физика объектов** -- лучше других open-source (падение, столкновения)
- **Понимание камеры** -- pan, zoom, dolly, tracking shots
- **Эффективность 1.5** -- в 1.5 раза меньше параметров без потери качества

## Слабые стороны

- Без native audio
- **Tencent-лицензия** -- не Apache
- Длительность короче чем [wan](wan.md) (до 5 сек vs 15)

## Идеальные сценарии

- Когда нужна точность следования сложному промпту
- Кинематографичные сцены с конкретными ракурсами камеры
- Fine-tuning под доменные данные (медицина, инженерия)
- Продакшн-pipeline где важна предсказуемость

## Загрузка

```bash
hf download tencent/HunyuanVideo --local-dir ~/models/hunyuan-video-1.5
```

## Связано

- Направления: [video](../video.md)
- Альтернативы: [wan](wan.md), [ltx-video](ltx-video.md)
