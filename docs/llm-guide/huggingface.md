# HuggingFace: как найти и загрузить модель

## Что такое HuggingFace

HuggingFace ([huggingface.co](https://huggingface.co)) -- основная платформа для open-source AI. Содержит:

| Раздел | Назначение | URL |
|--------|-----------|-----|
| **Models** | Модели (LLM, diffusion, audio, vision) | [huggingface.co/models](https://huggingface.co/models) |
| **Datasets** | Датасеты для обучения и fine-tuning | [huggingface.co/datasets](https://huggingface.co/datasets) |
| **Spaces** | Демо-приложения (запуск моделей в браузере) | [huggingface.co/spaces](https://huggingface.co/spaces) |
| **Leaderboards** | Рейтинги моделей по бенчмаркам | [Open LLM Leaderboard](https://huggingface.co/spaces/open-llm-leaderboard) |

Для данной платформы HuggingFace -- основной источник GGUF-моделей для llama.cpp.

## Поиск моделей

### Фильтры

На странице [huggingface.co/models](https://huggingface.co/models):

1. **Tasks** -- тип задачи: Text Generation, Image-to-Text, Text-to-Image
2. **Libraries** -- формат: GGUF, Transformers, Diffusers
3. **Languages** -- язык: ru (русский), en (английский)
4. **Licenses** -- лицензия: apache-2.0, mit, llama3.1
5. **Sort** -- сортировка: Most Downloads, Most Likes, Trending

### Поиск GGUF для llama.cpp

Быстрый фильтр: `library:gguf` + нужная модель.

Пример: поиск Qwen2.5-32B в GGUF:
```
huggingface.co/models?search=Qwen2.5-32B+GGUF&library=gguf&sort=downloads
```

### Авторы GGUF-квантизаций

| Автор | Специализация | Качество |
|-------|--------------|----------|
| **bartowski** | LLM, широкий выбор (Q2--Q8, IQ) | отличное, стандарт de facto |
| **unsloth** | LLM, оптимизированные квантизации | отличное |
| **city96** | Diffusion (FLUX, SD3, HiDream) в GGUF | отличное |
| **Qwen** (official) | Qwen-серия | официальные |
| **IlyaGusev** | Saiga (русские fine-tune) | хорошее |
| **T-Bank** | T-lite, T-pro (русские) | хорошее |

Рекомендация: искать `bartowski/<model-name>-GGUF` -- наиболее полные квантизации.

## Model Card: как читать

Каждая модель имеет страницу (model card) с информацией:

### Что смотреть

1. **Model size** -- количество параметров (7B, 32B, 70B)
2. **License** -- лицензия (Apache 2.0, MIT, Llama CL)
3. **Files** -- вкладка Files: размеры файлов, доступные квантизации
4. **Downloads** -- количество загрузок (индикатор популярности)
5. **Likes** -- количество лайков (индикатор качества)
6. **Tags** -- теги: `gguf`, `text-generation`, `en`, `ru`

### Квантизации в GGUF

В Files вкладке -- список .gguf файлов. Типичная схема именования:

```
Model-Name-Q4_K_M.gguf    # 4-bit mixed (рекомендуемый)
Model-Name-Q5_K_M.gguf    # 5-bit mixed
Model-Name-Q6_K.gguf      # 6-bit
Model-Name-Q8_0.gguf      # 8-bit
Model-Name-IQ4_XS.gguf    # 4-bit importance quantization (меньше, чем Q4_K_M)
Model-Name-f16.gguf        # FP16 (без квантизации)
```

Для данной платформы (96 GiB): Q4_K_M -- стандартный выбор, Q8_0 -- если VRAM позволяет.

Подробнее о квантизации: [quantization.md](quantization.md).

## CLI: установка и использование

### Установка

```bash
# Ubuntu 24.04 (системный Python)
pip install --break-system-packages huggingface-hub

# Или в venv
python3 -m venv ~/.hf-env
source ~/.hf-env/bin/activate
pip install huggingface-hub
```

CLI устанавливается как `hf` (huggingface-hub >= 1.8). Старое имя `huggingface-cli` -- устаревшее.

Если `hf` не в PATH:
```bash
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Загрузка модели

```bash
# Загрузка конкретной квантизации
hf download bartowski/Qwen2.5-32B-Instruct-GGUF \
    --include "*Q4_K_M*" \
    --local-dir ~/models/

# Загрузка нескольких файлов
hf download bartowski/Qwen2.5-32B-Instruct-GGUF \
    --include "*Q4_K_M*" "*Q8_0*" \
    --local-dir ~/models/

# Загрузка всего репозитория
hf download bartowski/Qwen2.5-32B-Instruct-GGUF \
    --local-dir ~/models/qwen-32b/
```

Или через скрипт проекта:
```bash
./scripts/inference/download-model.sh bartowski/Qwen2.5-32B-Instruct-GGUF --include "*Q4_K_M*"
```

### Авторизация (для gated-моделей)

Некоторые модели (Llama, Gemma) требуют авторизации:

1. Создать аккаунт на [huggingface.co](https://huggingface.co)
2. Принять лицензию модели на её странице
3. Создать токен: [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)
4. Авторизоваться:

```bash
hf login
# Ввести токен

# Или через переменную окружения
export HF_TOKEN=hf_xxxxxxxxxxxxx
```

### Информация о модели

```bash
# Информация о репозитории
hf repo info bartowski/Qwen2.5-32B-Instruct-GGUF

# Список файлов
hf ls bartowski/Qwen2.5-32B-Instruct-GGUF
```

## Кэш

По умолчанию модели кэшируются в `~/.cache/huggingface/hub/`.

```bash
# Размер кэша
du -sh ~/.cache/huggingface/

# Список кэшированных моделей
ls ~/.cache/huggingface/hub/

# Очистка кэша (осторожно -- удалит все загруженные модели)
rm -rf ~/.cache/huggingface/hub/

# Изменить расположение кэша
export HF_HOME=/data/huggingface
```

При использовании `--local-dir` файлы копируются в указанную директорию и не зависят от кэша.

## Spaces: демо без установки

HuggingFace Spaces -- веб-приложения для тестирования моделей без установки.

Примеры:
- [ACE-Step v1.5](https://huggingface.co/spaces/ACE-Step/Ace-Step-v1.5) -- генерация музыки
- [Open LLM Leaderboard](https://huggingface.co/spaces/open-llm-leaderboard) -- рейтинг LLM
- [Stable Diffusion 3.5](https://huggingface.co/spaces/stabilityai/stable-diffusion-3.5-large) -- генерация картинок

Ограничения: очереди, лимиты по времени, невозможность кастомизации. Для серьезной работы -- локальный запуск.

## Open LLM Leaderboard

Рейтинг open-source LLM по стандартизированным бенчмаркам:
- [huggingface.co/spaces/open-llm-leaderboard](https://huggingface.co/spaces/open-llm-leaderboard)

Метрики:
- **MMLU** -- знания (57 предметов)
- **ARC** -- science reasoning
- **HellaSwag** -- здравый смысл
- **TruthfulQA** -- правдивость
- **Winogrande** -- coreference
- **GSM8K** -- математика

Фильтры: размер модели, тип (pretrained, fine-tuned, chat), лицензия.

Для выбора модели: отсортировать по Average, отфильтровать по размеру (помещается в 96 GiB), проверить лицензию.

## Datasets: данные для fine-tuning

[huggingface.co/datasets](https://huggingface.co/datasets) -- датасеты для обучения.

Полезные для fine-tuning на русском:
- `IlyaGusev/ru_turbo_saiga` -- русские instruction-данные
- `OpenAssistant/oasst2` -- мультиязычные диалоги
- `mlabonne/orpo-dpo-mix-40k` -- DPO-пары
- `sahil2801/CodeAlpaca-20k` -- код

Загрузка через Python:
```python
from datasets import load_dataset

dataset = load_dataset("IlyaGusev/ru_turbo_saiga")
print(dataset)
```

Подробнее: [datasets.md](../training/datasets.md).

## Практические команды для данной платформы

```bash
cd ~/projects/ai-plant

# LLM (русский, основная)
./scripts/inference/download-model.sh bartowski/Qwen2.5-32B-Instruct-GGUF --include "*Q4_K_M*"

# LLM (русский fine-tune)
./scripts/inference/download-model.sh IlyaGusev/saiga_qwen2.5_32b_gguf --include "*Q4_K_M*"

# Кодинг (FIM)
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-1.5B-Instruct-GGUF --include "*Q8_0*"

# Кодинг (chat)
./scripts/inference/download-model.sh bartowski/Qwen2.5-Coder-32B-Instruct-GGUF --include "*Q4_K_M*"

# Reasoning
./scripts/inference/download-model.sh bartowski/QwQ-32B-GGUF --include "*Q4_K_M*"

# Тесты
./scripts/inference/download-model.sh bartowski/Llama-3.1-8B-Instruct-GGUF --include "*Q4_K_M*"
```

## Связанные статьи

- [Выбор моделей](../inference/model-selection.md)
- [Справочник LLM](../models/llm.md)
- [Российские LLM](../models/russian-llm.md)
- [Квантизация](quantization.md)
- [Подготовка данных](../training/datasets.md)
