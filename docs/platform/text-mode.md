# Переключение между графическим и текстовым режимом

Отключение графической оболочки освобождает VRAM и системные ресурсы для inference. На сервере для AI-задач GUI не нужен -- текстовый режим оптимален.

## Режимы загрузки systemd

| Target | Описание | GUI | Использование |
|--------|----------|-----|---------------|
| `graphical.target` | Полный графический режим (Xorg/Wayland, display manager) | да | Рабочая станция |
| `multi-user.target` | Текстовый многопользовательский режим (сеть, SSH) | нет | Сервер, inference |

## Переключение на лету

```bash
# Текущий режим
systemctl get-default

# Переключение в текстовый (останавливает GUI, сохраняет SSH)
sudo systemctl isolate multi-user.target

# Переключение обратно в графический
sudo systemctl isolate graphical.target
```

При `isolate multi-user.target`:
- Останавливается display manager (gdm/lightdm/sddm)
- Завершаются X server / Wayland compositor
- Освобождается VRAM framebuffer (~256-512 MiB)
- Освобождается RAM под оконный менеджер, desktop (~500 MiB - 2 GiB)
- SSH-сессии сохраняются

## Режим по умолчанию при загрузке

```bash
# Установить текстовый режим по умолчанию (для сервера)
sudo systemctl set-default multi-user.target

# Вернуть графический режим
sudo systemctl set-default graphical.target

# Проверка
systemctl get-default
```

После `set-default` -- следующая перезагрузка будет в выбранном режиме.

## Мониторинг VRAM до и после

```bash
# До переключения (в графическом режиме)
cat /sys/class/drm/card1/device/mem_info_vram_used | awk '{printf "VRAM used: %.1f MiB\n", $1/1048576}'

# Переключение
sudo systemctl isolate multi-user.target

# После переключения
cat /sys/class/drm/card1/device/mem_info_vram_used | awk '{printf "VRAM used: %.1f MiB\n", $1/1048576}'
```

Типичный выигрыш на Strix Halo:

| Режим | VRAM занято | Примечание |
|-------|-----------|-----------|
| graphical.target (GNOME) | ~500-800 MiB | Framebuffer + compositor + desktop |
| graphical.target (XFCE) | ~300-500 MiB | Легче, чем GNOME |
| multi-user.target | ~100-250 MiB | Только amdgpu driver overhead |

## Проблема: экран гаснет в текстовом режиме (Strix Halo)

На Strix Halo (gfx1151, DCN 3.5.1) при загрузке в `multi-user.target` дисплей полностью отключается:

- Все DRM-коннекторы переходят в `disconnected`
- DPMS устанавливается в `Off`
- EDID не читается -- монитор не обнаруживается
- Framebuffer blank = 4 (`FB_BLANK_POWERDOWN`)
- Текстовая консоль (tty) недоступна, экран темный

**Причина**: без графического сервера (Xorg/Wayland) драйвер amdgpu не инициализирует display pipeline. В текстовом режиме display core остается неактивным -- ни один HUBP/OTG не конфигурируется (видно в `amdgpu_dm_dtn_log`).

Параметры ядра `consoleblank=0` и `amdgpu.runpm=0` проблему не решают -- дисплей не активируется на уровне display controller.

### Диагностика

```bash
# Проверка состояния коннекторов
for c in /sys/class/drm/card1-*/status; do echo "$c: $(cat $c)"; done

# Проверка DPMS
cat /sys/class/drm/card1-HDMI-A-1/dpms

# Проверка blanking
cat /sys/class/graphics/fb0/blank
# 0 = unblanked, 4 = FB_BLANK_POWERDOWN

# Display pipeline (debugfs)
sudo cat /sys/kernel/debug/dri/1/amdgpu_dm_dtn_log | head -20
# Пустые таблицы HUBP/OTG = display controller не активен
```

### Решение: graphical.target по умолчанию

Для Strix Halo единственный рабочий вариант -- `graphical.target` с GDM. Xorg при старте инициализирует display pipeline amdgpu, после чего монитор определяется и DPMS переходит в `On`.

```bash
sudo systemctl set-default graphical.target
```

При необходимости освободить ресурсы для inference -- переключение на лету:
```bash
sudo systemctl isolate multi-user.target
# Экран погаснет, но SSH останется
# Для возврата:
sudo systemctl isolate graphical.target
```

### Текущие параметры ядра

```
GRUB_CMDLINE_LINUX_DEFAULT="amdgpu.gttsize=131072 amdgpu.vm_update_mode=3 amdgpu.dc=1 consoleblank=0 amdgpu.runpm=0 ttm.pages_limit=31457280"
```

Полный разбор параметров: [gpu-kernel-setup.md](gpu-kernel-setup.md#разбор-параметров).

## Рекомендация для AI-сервера

На Strix Halo рекомендуется `graphical.target` по умолчанию (иначе экран недоступен). Подключение через SSH, веб-интерфейсы (Open WebUI, Gradio) доступны из браузера рабочей станции.

При тяжелом inference, когда нужна вся VRAM -- временное переключение в текстовый режим:
```bash
sudo systemctl isolate multi-user.target
# ... inference ...
sudo systemctl isolate graphical.target
```

## Автоматизация

Скрипт переключения (для удобства):

```bash
#!/bin/bash
# Переключение режима: ./toggle-mode.sh [text|gui]
case "${1:-text}" in
    text|server)
        sudo systemctl isolate multi-user.target
        echo "Текстовый режим. GUI остановлен."
        ;;
    gui|desktop)
        sudo systemctl isolate graphical.target
        echo "Графический режим запущен."
        ;;
    status)
        systemctl get-default
        ;;
esac
```

## Связанные статьи

- [Настройка VRAM](vram-allocation.md) -- выделение 120 GiB VRAM
- [Настройка ядра](gpu-kernel-setup.md) -- параметры amdgpu
- [BIOS](bios-setup.md) -- UMA Frame Buffer Size
