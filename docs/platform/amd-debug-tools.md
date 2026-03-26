# amd-debug-tools: диагностика AMD-платформ

Набор утилит от AMD для диагностики и настройки Linux-платформ на базе AMD. Включает управление TTM pages_limit (GPU-память), парсинг логов BIOS/ядра, диагностику P-states и suspend.

Репозиторий: https://github.com/superm1/amd-debug-tools

## Установка

```bash
pip3 install --break-system-packages amd-debug-tools
```

Утилиты устанавливаются в `~/.local/bin/`. Для доступа без полного пути:

```bash
export PATH="$HOME/.local/bin:$PATH"
# Добавить в ~/.bashrc для постоянного эффекта
```

Проверка:
```bash
amd-ttm --version
# 0.2.16
```

Текущая версия на сервере: **0.2.16**.

## Утилиты

### amd-ttm -- управление TTM pages_limit

Просмотр и установка лимита TTM-аллокаций GPU. На Strix Halo с unified memory TTM pages_limit определяет, сколько памяти доступно GPU через KFD/ROCm.

#### Просмотр текущего значения

```bash
amd-ttm
```

Вывод на сервере:
```
Current TTM pages limit: 31457280 pages (120.00 GB)
Total system memory: 30.98 GB
```

#### Установка значения

```bash
# Установить 120 GiB
sudo amd-ttm --set 120

# Сохраняется в /etc/modprobe.d/ttm.conf
# Требует перезагрузки для применения
```

Команда создает файл `/etc/modprobe.d/ttm.conf` с параметром `options ttm pages_limit=N`.

Альтернативный способ -- параметр ядра в GRUB (используется на сервере):
```
ttm.pages_limit=31457280
```

Расчет: `pages = GiB * 1024^3 / 4096`. Для 120 GiB = 31457280 страниц.

#### Сброс значения

```bash
sudo amd-ttm --clear
# Удаляет /etc/modprobe.d/ttm.conf
# Требует перезагрузки
```

#### Отладка

```bash
amd-ttm --tool-debug
```

### amd-bios -- парсинг логов ядра и BIOS

Анализирует dmesg/journalctl, выделяет BIOS-сообщения, предупреждения и ошибки. Полезен для диагностики проблем загрузки, инициализации GPU, ошибок firmware.

#### Парсинг текущего лога

```bash
amd-bios parse
```

Вывод цветовой разметкой:
- Обычные сообщения ядра
- Предупреждения (выделены)
- Ошибки и segfault (выделены красным)

Пример вывода (фрагмент):
```
Linux version 6.19.8-061908-generic ...
Command line: BOOT_IMAGE=/boot/vmlinuz-6.19.8-061908-generic root=UUID=... amdgpu.gttsize=131072 ...
BIOS-e820: [mem 0x0000000000000000-0x000000000009ffff] usable
...
amdgpu 0000:bc:00.0: [drm] fb0: amdgpudrmfb frame buffer device
...
llama-bench[4845]: segfault at 18 ip ... in libamdhip64.so.6.4.60400
```

Утилита автоматически находит segfault, ошибки GPU, проблемы firmware -- удобнее, чем ручной grep по dmesg.

#### Парсинг файла

```bash
amd-bios parse --input /path/to/dmesg.log
```

#### Требования

Без sudo читает `/dev/kmsg` (если доступен) или journalctl. С sudo -- доступ ко всему dmesg.

### amd-pstate -- диагностика CPU P-states

Сбор информации о настройке amd-pstate (CPU frequency scaling).

```bash
amd-pstate triage
```

Показывает: текущий драйвер (amd-pstate-epp / acpi-cpufreq), governors, EPP-профили, частоты.

Текущий статус на сервере: утилита требует доработки (ModuleNotFoundError при вызове через `sudo`). Работает при вызове от пользователя с `--break-system-packages` или из venv.

### amd-s2idle -- диагностика suspend (s2idle)

Диагностика проблем suspend-to-idle на AMD-платформах.

#### Тест

```bash
sudo amd-s2idle test
```

Выполняет цикл suspend/resume и анализирует результат. Интерактивная команда -- запрашивает параметры.

#### Отчет

```bash
amd-s2idle report
```

Генерирует отчет по предыдущим запускам.

На inference-сервере suspend не используется (сервер работает постоянно), утилита полезна при диагностике проблем энергосбережения.

## Известные проблемы

### ModuleNotFoundError при sudo

При установке через `pip3 --break-system-packages` пакет ставится в `~/.local/lib/python3.12/`. При вызове через `sudo` Python ищет модули в системных путях и не находит `amd_debug`.

Решение:
```bash
# Вариант 1: вызов с сохранением PYTHONPATH
sudo PYTHONPATH=$HOME/.local/lib/python3.12/site-packages $HOME/.local/bin/amd-ttm --set 120

# Вариант 2: системная установка
sudo pip3 install --break-system-packages amd-debug-tools
```

`amd-ttm` работает без sudo (чтение). Для записи (`--set`, `--clear`) требуется sudo.

## Связанные статьи

- [Настройка VRAM](vram-allocation.md) -- TTM pages_limit для 120 GiB
- [Настройка ядра](gpu-kernel-setup.md) -- параметры GRUB
- [Драйвер amdgpu](amdgpu-driver.md) -- sysfs-мониторинг
