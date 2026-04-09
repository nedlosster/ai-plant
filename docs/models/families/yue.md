# YuE (multimodal-art-projection, 2025)

> Lyrics-to-song мультиязычная модель, Apache 2.0.

**Тип**: 7B (генерация) + 1B (вокал)
**Лицензия**: Apache 2.0
**Статус на сервере**: не скачана
**Направления**: [music](../music.md)

## Обзор

YuE -- генерация полных песен с вокалом из текста и описания стиля. Двухкомпонентная: 7B генератор + 1B вокал. Apache 2.0 -- альтернатива [ace-step](ace-step.md) для коммерции.

## Варианты

| Вариант | Параметры | VRAM | Hub |
|---------|-----------|------|-----|
| YuE | 7B + 1B | 8-24 GiB | [m-a-p/YuE](https://huggingface.co/m-a-p) |

GitHub: [multimodal-art-projection/YuE](https://github.com/multimodal-art-projection/YuE)

## Сильные кейсы

- **Lyrics-to-song** -- полная песня из текста + описания жанра
- **Apache 2.0** -- коммерция
- **Многоязычность**

## Слабые стороны

- 8-24 GiB VRAM -- больше [ace-step](ace-step.md)
- На AMD ROCm не тестировалась явно

## Идеальные сценарии

- Альтернатива ACE-Step для коммерческих проектов
- Когда нужно lyrics-aware генерация

## Загрузка

```bash
git clone https://github.com/multimodal-art-projection/YuE.git ~/projects/YuE
cd ~/projects/YuE && pip install -r requirements.txt
```

## Ссылки

**Официально**:
- [GitHub: multimodal-art-projection/YuE](https://github.com/multimodal-art-projection/YuE)
- [HuggingFace: m-a-p](https://huggingface.co/m-a-p) -- организация

## Связано

- Направления: [music](../music.md)
- Альтернативы: [ace-step](ace-step.md) (нативный AMD), [musicgen](musicgen.md) (инструментальная)
