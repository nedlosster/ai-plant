# ACE-Step (ACE-Step team, 2025)

> Diffusion-модель для генерации песен с вокалом по текстовому описанию, лучший выбор для AMD ROCm.

**Тип**: diffusion (audio)
**Лицензия**: Apache 2.0
**Статус на сервере**: скачана (1.5 turbo + LM 4B)
**Направления**: [music](../music.md), [russian-vocals](../russian-vocals.md)

## Обзор

ACE-Step -- diffusion-модель для генерации полных песен с вокалом по текстовому описанию. Главная особенность для нашей платформы -- **явная поддержка AMD ROCm**, что делает её лучшим выбором среди music-генераторов на gfx1151.

Принимает на вход:
- **Tags** -- описание стиля, инструментов, темпа (например `upbeat electronic dance, female vocals, 128bpm`)
- **Lyrics** -- текст песни (поддержка русского)

Выдаёт WAV-файл готовой песни длиной до 2-4 минут.

На платформе работает через PyTorch ROCm (HSA_OVERRIDE_GFX_VERSION=11.5.1) с собственным venv. Запуск -- через `scripts/music/ace-step/start.sh`.

## Варианты

| Вариант | Параметры | VRAM | Скорость | Статус | Hub |
|---------|-----------|------|----------|--------|-----|
| 1.5-turbo (DiT) | <4 GiB | <4 GiB | 2 мин трек за 66 сек | скачана | автозагрузка через `acestep.model_downloader` |
| LM 4B | 4B | ~8 GiB | -- | скачана | `acestep-5Hz-lm-4B` |

### 1.5-turbo (DiT) {#dit-turbo}

Дистиллированная "быстрая" версия с 8 шагами sampling вместо стандартных 50.

- Generation: 2-минутный трек за ~66 секунд на GPU
- VRAM <4 GiB -- помещается даже в HIP-лимит платформы
- Качество достаточно для большинства задач

### LM 4B {#lm-4b}

Language model для генерации lyrics-aware тренда. Подключается через `--init_llm true --lm_model_path acestep-5Hz-lm-4B` в команде запуска.

- ~8 GiB VRAM
- Делает вокал более согласованным с текстом
- На платформе настроен в `scripts/music/ace-step/config.sh`:
  ```bash
  export ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-4B
  export ACESTEP_LM_BACKEND=pt
  export ACESTEP_INIT_LLM=true
  ```

## Архитектура и особенности

- **Diffusion в latent audio space** -- быстрее autoregressive подходов
- **Двухкомпонентная**: DiT (генерация музыки/вокала) + LM (понимание lyrics)
- **Native AMD ROCm support** -- редкость среди music-моделей
- **Tags + lyrics формат** -- структурированный ввод для контроля
- **Apache 2.0** -- коммерческое использование

## Сильные кейсы

- **Полные песни с вокалом** -- одна команда от описания до WAV
- **AMD ROCm "из коробки"** -- единственная music-модель с явной поддержкой gfx1151
- **Малый VRAM** -- помещается в любой запас
- **Скорость** -- 2 минуты трека за минуту генерации
- **Русский вокал** -- работает с lyrics на русском (см. [русский вокал](../russian-vocals.md))

## Слабые стороны / ограничения

- **Качество вокала уступает коммерческим** (Suno, Udio) -- это open-source 2025 года
- **На сложных промптах** может выдавать нелогичные переходы
- **Lyrics на длинные песни** иногда теряет согласованность
- **Не для инструментальной музыки** -- для неё лучше [musicgen](musicgen.md)

## Идеальные сценарии применения

- **Демо-треки** -- быстрая генерация для прототипа песни
- **Background music** для видео/презентаций
- **Русский вокал** -- единственная open-source с поддержкой русского из коробки
- **Бэкграунд для подкастов / стримов** -- быстро, без копирайт-проблем
- **A/B-тестирование mood'ов** -- генерация нескольких вариантов одного описания

## Установка

```bash
# Через готовый скрипт (включает PyTorch ROCm + загрузку моделей)
./scripts/music/ace-step/install.sh
```

Что делает:
1. Клонирует ACE-Step в `~/projects/ACE-Step-1.5`
2. `uv sync` для зависимостей
3. Заменяет PyTorch на ROCm-вариант (`whl/rocm6.2.4`)
4. Загружает основные модели (~10 GiB)
5. Загружает LM 4B (~8 GiB)

## Запуск

```bash
# Foreground (Gradio UI)
./scripts/music/ace-step/start.sh

# Daemon (фоновый)
./scripts/music/ace-step/start.sh -d

# Web UI: http://localhost:7860
```

Скрипт автоматически:
- Устанавливает `HSA_OVERRIDE_GFX_VERSION=11.5.1`
- Запускает через `.venv/bin/python` (НЕ через `uv run` -- иначе сбрасывается ROCm torch)
- Подключает LM 4B через `--init_llm true --lm_model_path`
- Поднимает Gradio UI на порту 7860

## Формат промпта

```
Tags: upbeat electronic dance, female vocals, 128bpm, synth, energetic
Lyrics:
[Verse 1]
Dancing in the moonlight
Stars are shining bright
...
[Chorus]
We are the dreamers
...
```

Подробнее с примерами для разных жанров и русским языком -- в [русский вокал](../russian-vocals.md).

## Связано

- Направления: [music](../music.md), [russian-vocals](../russian-vocals.md)
- Родственные семейства: [musicgen](musicgen.md) (инструментальная), [yue](yue.md) (lyrics-to-song альтернатива)
- Скрипты: `scripts/music/ace-step/{install,start,stop,status}.sh`
- Use cases: [`docs/use-cases/music/quickstart.md`](../../use-cases/music/quickstart.md)
