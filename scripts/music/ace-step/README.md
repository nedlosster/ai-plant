# scripts/music/ace-step/ -- ACE-Step 1.5

Генератор песен (вокал + инструменты) из текстового описания. Open-source, MIT, 50+ языков.

## Текущий статус платформы

| Параметр | Значение |
|----------|---------|
| Backend | CPU (PyTorch) |
| DiT | acestep-v15-turbo (8 шагов) |
| LM | tier1 (DiT-only, LM не инициализируется на CPU) |
| Модели | ~/projects/ACE-Step-1.5/checkpoints/ (~18 GiB) |
| Порт | 7860 (Gradio UI) |
| GPU (ROCm) | не используется (KFD VRAM 15.5/96 GiB, автоконфиг блокирует LM 4B) |

Ограничения:
- CPU-режим -- генерация медленнее (минуты вместо секунд)
- LM не инициализируется автоматически на tier1 (CPU) -- DiT-only
- ROCm GPU (15.5 GiB) -- tier5, но автоконфиг блокирует LM 4B по лимиту VRAM
- Ожидаем: исправление KFD VRAM для gfx1151 или обновление ACE-Step

## Скрипты

| Скрипт | Назначение |
|--------|-----------|
| `install.sh` | Клонирование, uv sync, PyTorch ROCm, загрузка моделей |
| `start.sh` | Запуск Gradio UI (foreground или --daemon) |
| `stop.sh` | Остановка |
| `status.sh` | Статус процесса и Gradio |
| `config.sh` | Переменные (порт, модели, пути) |

## Быстрый старт

```bash
# Установка (~18 GiB моделей)
./scripts/music/ace-step/install.sh

# Запуск
./scripts/music/ace-step/start.sh --daemon

# Открыть http://<SERVER_IP>:7860

# Статус
./scripts/music/ace-step/status.sh

# Остановка
./scripts/music/ace-step/stop.sh
```

## Документация

- [ACE-Step обзор](../../../docs/use-cases/music/README.md)
- [Быстрый старт](../../../docs/use-cases/music/quickstart.md)
- [Промпт-инжиниринг](../../../docs/use-cases/music/prompting.md)
- [Русские классики -- примеры промптов](../../../docs/use-cases/music/russian-classics.md)
