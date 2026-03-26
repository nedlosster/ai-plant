# Промпт-инжиниринг для генерации изображений

Правила составления промптов для diffusion-моделей. Различия между FLUX и Stable Diffusion, структура промпта, стили, примеры.

## FLUX vs Stable Diffusion: различия промптирования

| Аспект | FLUX | Stable Diffusion |
|--------|------|------------------|
| Формат | Естественный язык (предложения) | Теги через запятую |
| Negative prompt | Не используется (стандартно) | Обязательно для качества |
| Длина промпта | Длинные описательные промпты работают лучше | Короткие теги эффективнее |
| Язык | Английский, понимает контекст | Английский, ключевые слова |
| CFG | 1.0 (не используется стандартно) | 7.0-12.0 |

FLUX обучен на T5-XXL text encoder, который понимает грамматику и контекст. SD использует CLIP, который работает как набор тегов.

## Структура промпта

Универсальная формула:

```
[субъект] + [действие] + [окружение] + [освещение] + [стиль] + [камера]
```

Каждый элемент необязателен, но чем больше деталей -- тем предсказуемее результат.

### Субъект

Главный объект изображения. Чем конкретнее, тем лучше.

- Плохо: `a woman`
- Лучше: `a young woman with red curly hair, wearing a leather jacket`

### Действие

Что субъект делает.

- `standing on a rooftop, looking at the city skyline`
- `reading a book in a cozy armchair`

### Окружение

Место, фон, атмосфера.

- `in a dense foggy forest`
- `inside an abandoned space station`

### Освещение

Критично для реализма и настроения.

- `golden hour sunlight` -- мягкий теплый свет
- `dramatic rim lighting` -- контурный свет
- `neon lights reflecting on wet pavement` -- неоновый свет
- `soft diffused studio lighting` -- студийное освещение
- `moonlit` -- лунный свет

### Стиль

Художественное направление или техника рендеринга.

- `photorealistic`, `hyperrealistic` -- фото
- `oil painting`, `watercolor` -- живопись
- `digital art`, `concept art` -- цифровое искусство
- `anime style`, `manga` -- аниме
- `cinematic` -- кинематографичный

### Камера

Ракурс и параметры камеры.

- `close-up portrait` -- крупный план
- `wide angle shot` -- широкий угол
- `aerial view` -- вид сверху
- `shot on Canon EOS R5, 85mm f/1.4` -- эмуляция конкретного объектива
- `shallow depth of field, bokeh` -- размытие фона

## Синтаксис взвешивания

ComfyUI поддерживает синтаксис усиления и ослабления элементов промпта:

```
(word:1.3)    -- усиление в 1.3 раза
(word:0.7)    -- ослабление до 0.7
(word)        -- эквивалент (word:1.1)
((word))      -- эквивалент (word:1.21)
```

Примеры:

```
a woman with (bright red hair:1.3), wearing a (leather jacket:0.8)
```

Красные волосы будут более выраженными, куртка -- менее заметной.

Диапазон 0.5-1.5 -- рабочий. Значения выше 1.5 часто приводят к артефактам.

## Стили с примерами промптов

### Фотореализм

```
a 35-year-old man sitting in a cafe, morning sunlight through the window,
shot on Sony A7III, 50mm f/1.8, shallow depth of field, natural colors,
photorealistic
```

### Кинематограф

```
a lone astronaut walking through a vast desert landscape, dramatic clouds,
golden hour, cinematic composition, anamorphic lens flare,
film grain, color graded in teal and orange
```

### Аниме

```
a girl with long silver hair and blue eyes, wearing a school uniform,
cherry blossom petals falling, anime style, clean lineart,
soft pastel colors, studio ghibli inspired
```

### Масляная живопись

```
a medieval castle on a cliff overlooking a stormy sea,
oil painting style, thick brushstrokes, dramatic lighting,
romantic era, inspired by Caspar David Friedrich
```

### Концепт-арт

```
a futuristic cyberpunk marketplace, neon signs in japanese,
crowded street with diverse alien species, rain, volumetric fog,
concept art, detailed environment design, wide angle
```

### Минимализм

```
a single red umbrella on a wet gray street, minimalist composition,
muted colors with one accent color, negative space, clean
```

### Фэнтези

```
an ancient dragon perched on a crystal mountain, aurora borealis in the sky,
ethereal glow, fantasy illustration, highly detailed scales,
epic composition, magical atmosphere
```

### Портрет

```
portrait of an elderly fisherman, weathered skin, deep wrinkles,
kind eyes, wearing a wool cap, natural outdoor lighting,
environmental portrait, shot on medium format camera
```

### Архитектура

```
a brutalist concrete building at sunset, dramatic shadows,
symmetrical composition, architectural photography,
shot on tilt-shift lens, warm golden light
```

### Натюрморт

```
a ceramic vase with dried flowers on a wooden table,
soft window light from the left, dark background,
dutch golden age still life painting, rich colors, moody
```

## Negative prompts (Stable Diffusion)

Для SD-моделей (SD 3.5, SDXL) negative prompt критически важен. Он описывает, чего не должно быть на изображении.

### Универсальный negative prompt

```
blurry, low quality, low resolution, deformed, bad anatomy,
bad hands, extra fingers, missing fingers, extra limbs,
disfigured, ugly, watermark, text, signature, cropped,
out of frame, worst quality, jpeg artifacts
```

### Для портретов (дополнительно)

```
cross-eyed, asymmetric face, unnatural skin, plastic skin,
double chin, bad teeth
```

### Для пейзажей (дополнительно)

```
oversaturated, flat composition, boring, empty
```

FLUX не использует negative prompts в стандартной конфигурации -- качество контролируется только положительным промптом.

## Практические советы

**Порядок слов имеет значение.** Элементы в начале промпта оказывают большее влияние. Субъект и стиль -- в начало.

**Длина промпта.** Для FLUX -- чем подробнее, тем лучше (до ~200 слов). Для SD -- 30-75 токенов оптимально, дальше влияние слабеет.

**Детализация.** Конкретные детали (`oak table`, `brass doorknob`) дают более четкие результаты, чем абстрактные описания (`nice table`, `good door`).

**Итерации.** Генерация изображений -- итеративный процесс. Менять seed, корректировать промпт, экспериментировать с весами.

**Seed.** Фиксированный seed + одинаковый промпт = воспроизводимый результат. При подборе промпта зафиксировать seed для сравнения.

**Разрешение.** Модели обучены на определенных разрешениях. FLUX: 1024x1024 (базовое). Нестандартные пропорции работают, но могут вызвать артефакты.

**Quality boosters (SD).** Добавление в промпт: `masterpiece, best quality, highly detailed, 8k` -- повышает общее качество для SD-моделей. Для FLUX это менее эффективно.

## Связанные документы

- [workflows.md](workflows.md) -- как собрать workflow для генерации
- [Справочник моделей](../../models/images.md) -- параметры моделей и квантизации
