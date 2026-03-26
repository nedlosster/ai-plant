# ACE-Step 1.5: промпт-инжиниринг

## Два входа

ACE-Step принимает два текстовых поля:
1. **Caption** -- описание стиля, жанра, настроения, инструментов
2. **Lyrics** -- текст песни с разметкой структуры

## Caption (описание стиля)

Рекомендуемая структура: **жанр + настроение + темп + инструменты + продакшн + вокал**.

### Жанры

```
pop, rock, jazz, electronic, hip-hop, folk, classical, lo-fi, synthwave,
metal, R&B, country, ambient, EDM, trap, house, techno, drum and bass,
reggae, blues, soul, funk, disco, indie, punk, grunge, bossa nova,
shoegaze, post-rock, new wave, darkwave, chillwave, vaporwave
```

### Настроение

```
melancholic, uplifting, energetic, dreamy, dark, nostalgic, euphoric,
intimate, aggressive, peaceful, haunting, triumphant, bittersweet,
playful, somber, epic, mysterious, romantic, anxious, serene
```

### Инструменты

```
acoustic guitar, electric guitar, piano, synth pads, 808 drums, strings,
brass, slap bass, drum machine, Rhodes, organ, violin, cello, flute,
saxophone, trumpet, balalaika, accordion, harpsichord, mandolin,
distorted guitar, clean guitar, fingerpicked guitar, slide guitar,
analog synth, digital synth, arpeggiator, vocoder, choir
```

### Вокал

```
female vocal, male vocal, breathy, powerful, falsetto, raspy, clean,
rhythmic, whispered, choir, duet, operatic, soulful, nasal, warm
```

### Продакшн и тембр

```
lo-fi, high-fidelity, studio-polished, bedroom pop, vinyl texture,
wide stereo mix, dry mix, cinematic reverb, warm, bright, crisp, airy,
punchy, lush, gritty, distorted, compressed, spacious, intimate
```

### Темп (BPM)

```
60 bpm (баллада), 80 bpm (медленный), 100 bpm (средний),
120 bpm (поп/рок), 128 bpm (house), 140 bpm (drum and bass),
160 bpm (punk), 170 bpm (jungle)
```

## Примеры caption по жанрам

### Русский поп (женский вокал)
```
russian pop, female vocals, emotional, piano, strings, 110 bpm, ballad, warm mix
```

### Русский рок (мужской вокал)
```
russian rock, male vocals, energetic, electric guitar, drums, bass, 140 bpm, aggressive, punchy
```

### Русский фолк
```
russian folk, female vocals, acoustic, balalaika, accordion, traditional, 100 bpm, warm, intimate
```

### Электроника с русским вокалом
```
electronic, russian, female vocals, synthwave, retro, synth, drum machine, 128 bpm, wide stereo
```

### Русский рэп
```
russian hip-hop, male vocals, rap, trap, 808 bass, hi-hats, 90 bpm, dark, gritty
```

### Cinematic Ambient (без вокала)
```
cinematic ambient, 72 bpm, soft synth pads, distant piano, evolving drones, slow build, wide stereo mix, no vocals
```

### Lo-fi Hip Hop
```
lo-fi hip hop, 88 bpm, vinyl texture, mellow Rhodes, laid-back drums, warm mix, no vocals
```

### Synthwave
```
synthwave, 100 bpm, analog bass, arpeggiated leads, gated drums, bright chorus, retro mix, 80s style
```

### Jazz
```
jazz, 130 bpm, upright bass, brushed drums, piano trio, warm, intimate, swing feel, smoky club atmosphere
```

### Metal
```
progressive metal, 160 bpm, distorted guitars, double bass drums, male vocals, aggressive, complex time signatures
```

### Funk/Disco
```
funk, disco, 112 bpm, slap bass, drum machine, male vocals, clean, rhythmic, 80s style, punchy, dry mix
```

### Trailer Score (без вокала)
```
trailer score, 120 bpm, low brass hits, pulsing strings, build to climax, dramatic risers, cinematic reverb, no vocals
```

## Lyrics (текст песни)

### Структурные теги

| Тег | Назначение |
|-----|-----------|
| `[Intro]` | Вступление, установка настроения |
| `[Verse]` / `[Verse 1]` | Куплет, нарративное развитие |
| `[Pre-Chorus]` | Нарастание энергии перед припевом |
| `[Chorus]` | Припев, эмоциональный пик |
| `[Bridge]` | Переход, контраст |
| `[Outro]` | Завершение |
| `[Instrumental]` | Инструментальная секция |
| `[Build]` | Постепенное нарастание |
| `[Drop]` | Сброс (электронная музыка) |
| `[Breakdown]` | Уменьшение инструментовки |
| `[Guitar Solo]` | Гитарное соло |
| `[Piano Interlude]` | Фортепианная интерлюдия |
| `[Fade Out]` | Постепенное затухание |
| `[Silence]` | Пауза |

Теги с модификаторами:
```
[Chorus - anthemic]
[Bridge - whispered]
[Verse - spoken word]
```

### Пример: поп-баллада на русском

```
[Intro]

[Verse 1]
Снова ночь, и город спит в тиши,
Только ветер шепчет мне слова.
Я иду по улицам пустым,
Вспоминая все, что было у нас.

[Pre-Chorus]
И каждый шаг звучит как эхо,
В пустоте ночной тишины.

[Chorus]
Не уходи, останься рядом,
Мне без тебя так холодно одной.
Не уходи, мне больше ничего не надо,
Только быть с тобой.

[Verse 2]
Капли дождя стучат в окно,
И каждая -- как слезы по щеке.
Я знаю, что ушел ты далеко,
Но сердце все еще стучит к тебе.

[Chorus]
Не уходи, останься рядом,
Мне без тебя так холодно одной.
Не уходи, мне больше ничего не надо,
Только быть с тобой.

[Bridge]
И пусть весь мир замрет на миг,
Пусть тишина нас обнимет.
Я верю -- ты услышишь крик
Моей души, что помнит имя.

[Outro]
Не уходи...
```

### Пример: русский рок

```
[Intro]

[Verse 1]
Город в огнях, асфальт горит,
Мотор ревет, душа летит.
Ни тормозов, ни поворотов,
Вперед, где небо и свобода.

[Chorus]
Мы -- дети ночи, мы -- ветер,
Нас не поймать, не удержать.
Мы верим только в этот вечер,
И нам не надо отступать.

[Verse 2]
Огни мелькают за стеклом,
Мы растворяемся в потоке.
Не важно, что будет потом,
Пока горят дороги.

[Chorus]
Мы -- дети ночи, мы -- ветер,
Нас не поймать, не удержать.
Мы верим только в этот вечер,
И нам не надо отступать.

[Guitar Solo]

[Bridge]
Один момент -- и все изменится,
Один момент -- и мир другой.

[Chorus]
Мы -- дети ночи, мы -- ветер,
Нас не поймать, не удержать.

[Outro]
```

### Пример: электроника на английском

```
[Intro]

[Build]
Feel the pulse, feel the beat
Rising through the concrete streets

[Drop]
Move your body, lose control
Let the bass consume your soul

[Verse]
Neon lights and midnight dreams
Nothing ever what it seems
Digital hearts and analog minds
Leaving all the world behind

[Chorus]
We are electric, we are alive
Dancing on the edge of time
We are electric, burning bright
Chasing shadows through the night

[Breakdown]

[Build]
Can you feel it coming

[Drop]
We are electric, we are alive

[Fade Out]
```

### Инструментальная генерация

Три способа:
1. Добавить `no vocals` в caption
2. Отметить чекбокс "Instrumental" в Simple Mode
3. Использовать только тег `[Instrumental]` в lyrics

## Параметры генерации

| Параметр | По умолчанию | Диапазон | Описание |
|----------|-------------|----------|----------|
| Duration | auto | 10-600 сек | Длительность песни |
| Inference Steps | 8 (turbo) | 1-200 | Больше = качественнее, медленнее |
| Guidance Scale | 7.0 | -- | Только для base/sft моделей |
| Seed | -1 (random) | -- | Фиксация для воспроизводимости |
| Shift | 3.0 | 1.0-5.0 | 3.0 рекомендуется для turbo |
| LM Temperature | 0.85 | 0.0-2.0 | Креативность LM-планировщика |
| LM CFG Scale | 2.0 | 1.0-3.0 | Соответствие caption |
| LM Top-P | 0.9 | 0.0-1.0 | Ядерный сэмплинг |
| Batch Size | 2 | 1-8 | Число вариантов за раз |
| Audio Format | mp3 | mp3/flac | Формат выхода |

### Метаданные (опционально)

| Параметр | Примеры |
|----------|---------|
| BPM | 80, 120, 140 |
| Key Scale | C Major, Am, F# minor |
| Time Signature | 4 (4/4), 3 (3/4), 6 (6/8) |

## Best practices

1. **Конкретность** -- "acoustic guitar, fingerpicked, warm" лучше, чем "guitar"
2. **3-4 измерения** -- жанр + инструменты + настроение + продакшн
3. **Референсы на эпоху** -- "80s synthwave", "90s grunge" эффективны
4. **Без конфликтов** -- "aggressive calm" не работает; вместо этого -- распределить по секциям
5. **Итерации** -- менять по одному параметру за раз
6. **Batch** -- генерировать 2-4 варианта, выбирать лучший
7. **Repaint** -- для исправления отдельных секций вместо полной перегенерации
8. **Ритмичный текст** -- короткие строки, рифмы, одинаковая длина строк
9. **Повторяющийся припев** -- стабильнее по качеству
10. **Think mode** -- включить для LM-планирования (улучшает структуру)

### Типичные ошибки

| Ошибка | Решение |
|--------|---------|
| Невнятное произношение | Упростить текст, избегать скоплений согласных |
| Неправильные ударения | Переформулировать строку |
| Вокал заглушен инструментами | Увеличить LM CFG Scale |
| Текст не совпадает с мелодией | Укоротить строки, добавить `[Instrumental]` паузы |
| Однообразная мелодия | Добавить контрастные секции (verse vs chorus vs bridge) |
| Песня обрывается | Добавить `[Outro]` или `[Fade Out]` |

## Связанные статьи

- [Быстрый старт](quickstart.md)
- [Продвинутое использование](advanced.md)
- [Русский вокал](../../models/russian-vocals.md)
