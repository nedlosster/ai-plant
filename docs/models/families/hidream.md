# HiDream-I1 Full (HiDream-AI, 2025)

> 17B Apache 2.0 diffusion-модель -- альтернатива FLUX.1-dev для коммерции.

**Тип**: diffusion (17B)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [images](../images.md)

## Обзор

HiDream-I1 Full -- 17B diffusion-модель от HiDream-AI. Apache 2.0 -- полная коммерческая свобода. Отличное качество, конкурентное с [flux 1-dev](flux.md#dev), но без ограничений лицензии.

## Варианты

| Вариант | Параметры | GGUF Q8 | GGUF Q4 | Hub |
|---------|-----------|---------|---------|-----|
| HiDream-I1 Full | 17B | 18 GiB | 11.5 GiB | [city96/HiDream-I1-Full-gguf](https://huggingface.co/city96/HiDream-I1-Full-gguf) |

## Сильные кейсы

- **Apache 2.0** -- единственная топовая diffusion с такой лицензией
- **17B параметров** -- больше чем FLUX (12B)
- **Качество photo-realistic** -- сравнимо с FLUX dev
- **GGUF от city96** -- адаптация под VRAM
- **Коммерция** -- идеальная замена FLUX dev

## Слабые стороны

- Большая модель -- 18 GiB Q8
- Меньше community-LoRA чем у SD/FLUX
- Свежий релиз -- меньше fine-tune'ов

## Идеальные сценарии

- **Коммерческие SaaS** -- замена FLUX dev (CC) на полностью свободную
- **Photo-realistic** в production
- **Высокое качество** при готовности дать VRAM

## Загрузка

```bash
huggingface-cli download city96/HiDream-I1-Full-gguf --include "*Q8_0*" --local-dir ComfyUI/models/diffusion_models/
```

## Ссылки

**Официально**:
- [HuggingFace: HiDream-ai/HiDream-I1-Full](https://huggingface.co/HiDream-ai/HiDream-I1-Full)
- [HuggingFace: HiDream-ai](https://huggingface.co/HiDream-ai) -- организация
- [HuggingFace: city96/HiDream-I1-Full-gguf](https://huggingface.co/city96/HiDream-I1-Full-gguf) -- GGUF

## Связано

- Направления: [images](../images.md)
- Альтернативы: [flux](flux.md) (Schnell -- тоже Apache 2.0), [sd35](sd35.md)
