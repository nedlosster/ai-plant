# Промпт-инжиниринг для видеогенерации

## Отличие от промптов для картинок

Промпты для видео описывают не только сцену, но и **движение**, **камеру** и **действие во времени**. Статичный промпт ("a cat on a table") даст статичное видео. Для динамики нужны глаголы движения, описание камеры, изменение во времени.

| Картинка | Видео |
|----------|-------|
| "a cat sitting on a table" | "a cat jumping off a table and walking away, camera tracking the cat" |
| "sunset over the ocean" | "ocean waves rolling onto the shore at sunset, camera slowly panning right, golden light" |
| "portrait of a woman" | "a woman turning her head slowly to the right, soft smile, wind blowing her hair" |

## Структура промпта

Рекомендуемая формула:

```
[субъект] + [действие/движение] + [камера] + [окружение] + [стиль/качество]
```

### Субъект

Что или кто в кадре. Конкретные описания работают лучше абстрактных.

```
a golden retriever             # конкретная порода лучше, чем "a dog"
a young woman in a red dress   # детали внешности
a steaming cup of coffee       # неодушевленные объекты тоже работают
a school of fish               # группы объектов
```

### Действие / движение

Ключевой элемент для видео. Описывает, что происходит во времени.

```
walking slowly along the path
running through a field of flowers
turning head to the left
pouring water into a glass
leaves falling from trees
clouds moving across the sky
waves crashing against rocks
smoke rising from a chimney
```

### Камера

Управление виртуальной камерой. Существенно влияет на восприятие видео.

| Тип движения камеры | Описание |
|---------------------|----------|
| `camera panning left/right` | Панорамирование (поворот камеры) |
| `camera tilting up/down` | Наклон камеры вверх/вниз |
| `zoom in / zoom out` | Приближение / удаление |
| `dolly shot forward` | Движение камеры вперед |
| `tracking shot` | Камера следует за объектом |
| `crane shot` | Движение камеры вверх (как на кране) |
| `orbit shot` | Камера вращается вокруг объекта |
| `handheld camera` | Имитация ручной камеры (легкая тряска) |
| `static camera / locked shot` | Камера неподвижна |
| `aerial shot / drone shot` | Вид сверху |
| `low angle shot` | Камера снизу |
| `close-up` | Крупный план |
| `wide shot / establishing shot` | Общий план |
| `first person view / POV` | От первого лица |

### Окружение

Где происходит действие, освещение, погода, время суток.

```
in a dense forest at dawn
on a busy city street at night, neon lights
underwater, coral reef, sunlight filtering through water
in a minimalist white studio
on a snowy mountain peak, clear sky
in a cozy cafe, warm lighting
```

### Стиль / качество

Визуальный стиль и технические характеристики.

```
cinematic, shallow depth of field
slow motion, 120fps look
timelapse, clouds moving fast
stop motion animation
anime style, vibrant colors
photorealistic, 4k quality
film grain, vintage look
black and white, high contrast
watercolor painting style
cyberpunk aesthetic, neon glow
```

## Примеры промптов

### Природа

```
A mountain stream flowing over smooth rocks, crystal clear water,
sunlight creating sparkles on the surface, camera slowly tilting
down to follow the water flow, lush green moss on rocks,
cinematic, shallow depth of field
```

```
A field of sunflowers gently swaying in the wind, golden hour
lighting, camera slowly panning right across the field,
soft bokeh in the background, warm color palette, 4k quality
```

```
Timelapse of clouds moving over a mountain range at sunset,
dramatic orange and purple sky, static wide shot,
cinematic color grading
```

### Городская среда

```
A busy intersection in Tokyo at night, people crossing the street,
neon signs reflecting on wet pavement, rain falling, camera positioned
at street level, slow motion, cinematic
```

```
An empty corridor in an old building, dust particles floating in
a beam of sunlight from a window, camera slowly dolly forward,
atmospheric, film grain
```

### Люди

```
A woman walking through a wheat field at golden hour, her hand
gently touching the wheat stalks, wind blowing her hair,
camera tracking from behind, cinematic, warm tones
```

```
Close-up of a man's face as he opens his eyes slowly, soft
morning light from a window, shallow depth of field,
intimate, cinematic
```

### Вода / жидкости

```
A drop of ink falling into clear water in slow motion,
swirling patterns of blue and red ink spreading,
macro shot, black background, dramatic lighting
```

```
Ocean waves crashing against a lighthouse during a storm,
dramatic sky, sea spray, camera locked at medium distance,
cinematic, desaturated colors
```

### Абстракция

```
Abstract flowing shapes morphing between organic forms,
iridescent colors shifting from blue to purple to gold,
smooth motion, dark background, elegant, loop-friendly
```

```
Particles of light converging into a sphere and then
exploding outward, dark void background, vibrant neon colors,
slow motion, macro perspective
```

### Животные

```
A fox walking cautiously through a misty forest at dawn,
camera tracking the fox from the side, soft diffused light,
shallow depth of field, cinematic, nature documentary style
```

```
A hummingbird hovering near a red flower, wings moving in
slow motion, shallow depth of field, macro shot, garden
background blurred, natural lighting
```

### Еда / предметы

```
Hot coffee being poured into a white ceramic mug,
steam rising, close-up shot, warm studio lighting,
slow motion, shallow depth of field, cozy atmosphere
```

### Sci-fi / фантастика

```
A massive spaceship slowly emerging from clouds above a city,
people on the street looking up, dramatic low angle shot,
cinematic lighting, lens flare, sci-fi, photorealistic
```

### Атмосферное

```
A single candle flame flickering in a dark room, wax dripping
slowly, warm orange glow illuminating the surroundings,
close-up, static camera, intimate, meditative
```

## Параметры генерации

| Параметр | Описание | Рекомендация |
|----------|----------|-------------|
| Разрешение | Ширина x высота | 832x480 (быстро), 1280x720 (качество) |
| Число кадров | Длительность видео | 81 (~5 сек), 129 (~8 сек) при 16 fps |
| FPS | Кадров в секунду | 16 (стандарт Wan2.1), 24 (кинематографичнее) |
| Steps | Шаги денойзинга | 20-30 (баланс), 50 (максимальное качество) |
| CFG Scale | Соответствие промпту | 5.0-7.0 (стандарт), 3.0-5.0 (свобода модели) |

### Соотношение сторон

| Формат | Разрешение | Применение |
|--------|-----------|------------|
| 16:9 | 832x480, 1280x720 | Стандартное видео |
| 9:16 | 480x832, 720x1280 | Вертикальное (мобильное) |
| 1:1 | 480x480, 720x720 | Квадратное |
| 21:9 | 960x480 | Кинематографичное |

## Советы для качества

1. **Конкретность** -- "a golden retriever puppy running on a beach" лучше, чем "a dog on a beach"
2. **Описание движения обязательно** -- без глаголов движения модель генерирует почти статичное видео
3. **Одна камера** -- не указывать несколько движений камеры одновременно ("pan left and zoom in and tilt up")
4. **Один субъект** -- начинать с одного объекта, несколько персонажей сложнее для модели
5. **Стиль в конце** -- технические характеристики ("cinematic, 4k, slow motion") располагать в конце промпта
6. **Negative prompt** -- если модель поддерживает: "blurry, distorted, low quality, watermark, text overlay, static, no motion"
7. **Итерации** -- менять по одному элементу (камера, движение, стиль) между попытками
8. **Batch** -- генерировать 2-4 варианта с разными seed, выбирать лучший
9. **Длина промпта** -- 2-4 предложения оптимально. Слишком длинный промпт снижает когерентность
10. **Английский язык** -- модели обучены преимущественно на английских описаниях

## Типичные ошибки

| Ошибка | Решение |
|--------|---------|
| Статичное видео | Добавить движение: "walking", "flowing", "camera panning" |
| Мерцание кадров | Уменьшить CFG Scale, увеличить Steps |
| Искаженные лица | Не использовать крупный план лиц; уменьшить CFG |
| Несвязные движения | Упростить промпт, один субъект, одно действие |
| Промпт игнорируется | Увеличить CFG Scale; переформулировать промпт |
| Текст в видео нечитаемый | Видеомодели плохо генерируют текст -- избегать |

## Связанные статьи

- [Быстрый старт](quickstart.md)
- [Продвинутое использование](advanced.md)
- [Ресурсы](resources.md)
