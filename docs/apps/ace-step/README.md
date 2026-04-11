# ACE-Step

Music generation studio -- целостный софтверный стек для генерации песен с вокалом из текстового промпта. Включает модель (diffusion DiT + Language Model для conditioning), inference-движок на PyTorch, Gradio UI и LoRA-тренер в одном пакете. От команды StepFun и ACE Studio, release 1.5 -- конец 2025, open-source MIT.

**Тип**: Python-приложение (PyTorch + Gradio) с собственной моделью
**Лицензия**: MIT (код), Apache 2.0 (веса)
**Статус на платформе**: CPU-режим, DiT-only (LM не инициализируется на CPU). ROCm заблокирован из-за KFD VRAM limit
**Порт по умолчанию**: 7860 (Gradio UI)

## Когда использовать

- Генерация песни по текстовому описанию (жанр, настроение, темп, инструменты, вокалист)
- Вокал на 50+ языках, включая русский
- Cover-режим (перепеть песню другим голосом / стилем)
- Remix-режим (изменить часть существующего аудио)
- LoRA fine-tuning под свой стиль или конкретного исполнителя

**Не для**: instrumental-only музыки без вокала (лучше MusicGen или Stable Audio), TTS с клонированием голоса (см. [tts.md](../../models/tts.md)), chat или coding (см. другие разделы).

## Файлы раздела

| Файл | О чём |
|------|-------|
| [introduction.md](introduction.md) | Что это как платформа (не просто модель), история, релизы, авторы |
| [architecture.md](architecture.md) | Dual-component: DiT diffusion + LM 4B conditioning + audio VAE + sampling loop + Gradio UI. Почему LM не стартует на CPU |
| [simple-use-cases.md](simple-use-cases.md) | Генерация первой песни через Gradio, выбор параметров, стили |
| [advanced-use-cases.md](advanced-use-cases.md) | LoRA-тренировка, cover/remix режимы, русский вокал с примерами, batch generation |

## Статус на Strix Halo

Текущее состояние -- **ограниченное**. Детали:

| Параметр | Значение |
|----------|----------|
| Backend | CPU (PyTorch) |
| DiT (diffusion) | acestep-v15-turbo (8 шагов), работает |
| LM (conditioning) | **не инициализируется** -- ACE-Step автоконфиг tier1 (CPU) отключает LM 4B |
| GPU (ROCm) | **заблокирован** -- KFD VRAM 15.5/96 GiB на gfx1151 не даёт загрузить LM 4B |
| Модели | `~/projects/ACE-Step-1.5/checkpoints/` (~18 GiB) |
| Скорость | минуты на песню вместо секунд (CPU) |
| Ожидание | fix KFD VRAM для gfx1151 в ROCm >= 7.3 или обновление ACE-Step с CPU-LM |

Это не недостаток ACE-Step -- это ограничение платформы Strix Halo (см. [../../platform/vram-allocation.md](../../platform/vram-allocation.md) и [../../inference/rocm-setup.md](../../inference/rocm-setup.md)). На других GPU (RTX 4090, Mac M4) ACE-Step работает полноценно с LM 4B.

## Быстрый старт

```bash
cd ~/projects/ai-plant
./scripts/music/ace-step/install.sh
./scripts/music/ace-step/start.sh --daemon
# Открыть http://<SERVER_IP>:7860

# Статус
./scripts/music/ace-step/status.sh
```

Детали операционных скриптов -- в [`scripts/music/ace-step/README.md`](../../../scripts/music/ace-step/README.md). Гайд по использованию Gradio UI -- в [use-cases/music/quickstart.md](../../use-cases/music/quickstart.md).

## Отличие от карточки модели

У ACE-Step есть два угла зрения в документации:
- [`docs/models/families/ace-step.md`](../../models/families/ace-step.md) -- **карточка модели**: параметры нейросети, архитектура diffusion, лицензия весов
- **Этот раздел** (`docs/apps/ace-step/`) -- **софтверный профиль**: Python-пакет, Gradio UI, CLI, LoRA trainer, CPU/ROCm пути, ограничения платформы

Оба дополняют друг друга. Карточка -- про веса, профиль -- про стек.

## Ссылки

- Официальный GitHub: [ace-step/ACE-Step](https://github.com/ace-step/ACE-Step)
- HuggingFace модели: [ACE-Step/ACE-Step-v1-3.5B](https://huggingface.co/ACE-Step/ACE-Step-v1-3.5B)
- Demo: [huggingface.co/spaces/ACE-Step/ACE-Step](https://huggingface.co/spaces/ACE-Step/ACE-Step)

## Связанные статьи

- [../../models/families/ace-step.md](../../models/families/ace-step.md) -- карточка модели (веса, архитектура нейросети)
- [../../use-cases/music/README.md](../../use-cases/music/README.md) -- обзор направления "музыка и вокал"
- [../../use-cases/music/quickstart.md](../../use-cases/music/quickstart.md) -- операционный гайд "первый запуск"
- [../../use-cases/music/prompting.md](../../use-cases/music/prompting.md) -- промпт-инжиниринг
- [../../use-cases/music/russian-classics.md](../../use-cases/music/russian-classics.md) -- примеры русского вокала
- [../../../scripts/music/ace-step/README.md](../../../scripts/music/ace-step/README.md) -- операционные скрипты и статус
