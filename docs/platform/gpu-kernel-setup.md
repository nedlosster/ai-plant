# Настройка ядра и графики для AMD Ryzen AI MAX+ 395 (Strix Halo)

Платформа: Meigao MS-S1 MAX, AMD Ryzen AI MAX+ 395, Radeon 8060S (RDNA 3.5, gfx1151), Ubuntu 24.04.4 LTS.

## Проблематика

Strix Halo (device 1586) -- новая платформа с unified memory и интегрированным GPU на RDNA 3.5 (DCN 3.5.1). Стоковое ядро Ubuntu 24.04 (6.8.x) не содержит поддержки этого чипа. Для работы GPU и NPU требуется ядро >= 6.18, а для стабильности -- ядро >= 6.19 с дополнительными параметрами.

## Требования к ядру

| Компонент | Минимальное ядро | Рекомендуемое |
|-----------|-----------------|---------------|
| amdgpu (gfx1151) | 6.18.x | 6.19.8+ |
| amdxdna (NPU) | 6.18.x | 6.19.8+ |
| DCN 3.5.1 (display) | 6.18.x | 6.19.8+ |

### Установка ядра mainline

```bash
# Загрузка пакетов mainline-ядра (пример для 6.19.8)
wget https://kernel.ubuntu.com/mainline/v6.19.8/amd64/linux-headers-6.19.8-061908_6.19.8-061908.202503131837_all.deb
wget https://kernel.ubuntu.com/mainline/v6.19.8/amd64/linux-headers-6.19.8-061908-generic_6.19.8-061908.202503131837_amd64.deb
wget https://kernel.ubuntu.com/mainline/v6.19.8/amd64/linux-image-unsigned-6.19.8-061908-generic_6.19.8-061908.202503131837_amd64.deb
wget https://kernel.ubuntu.com/mainline/v6.19.8/amd64/linux-modules-6.19.8-061908-generic_6.19.8-061908.202503131837_amd64.deb

sudo dpkg -i linux-*.deb
sudo update-grub
sudo reboot
```

### Обновление linux-firmware

Стоковый пакет `linux-firmware` из Ubuntu 24.04 не содержит firmware для gfx1151. Требуется обновление:

```bash
sudo add-apt-repository ppa:canonical-kernel-team/ppa
sudo apt update
sudo apt install linux-firmware
```

Или ручная установка из git:

```bash
git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
sudo cp -r linux-firmware/amdgpu/* /lib/firmware/amdgpu/
sudo update-initramfs -u
```

Без актуального firmware amdgpu не загрузит PSP, SMU и Display Core.

## Параметры ядра (GRUB)

Текущая рабочая конфигурация `/etc/default/grub`:

```
GRUB_CMDLINE_LINUX_DEFAULT="amdgpu.gttsize=131072 amdgpu.vm_update_mode=3 amdgpu.dc=1 consoleblank=0 amdgpu.runpm=0 ttm.pages_limit=31457280"
```

### Разбор параметров

| Параметр | Значение | Назначение |
|----------|----------|------------|
| `amdgpu.gttsize=131072` | 128 GiB | Размер GTT (Graphics Translation Table). Для unified memory с 96 GiB VRAM требуется большой GTT для маппинга системной памяти |
| `amdgpu.vm_update_mode=3` | CPU+SDMA | Режим обновления page tables GPU VM. Значение 3 -- обновление через CPU и SDMA, повышает стабильность на Strix Halo |
| `amdgpu.dc=1` | включен | Display Core -- подсистема дисплейного вывода. Без неё GPU работает только для compute (нет вывода на монитор) |
| `consoleblank=0` | отключен | Запрет гашения текстовой консоли по таймауту |
| `amdgpu.runpm=0` | отключен | Запрет runtime power management для GPU. Без этого параметра GPU может уйти в D3cold и потерять display state |
| `ttm.pages_limit=31457280` | 120 GiB | Лимит TTM-аллокаций в 4K-страницах. По умолчанию KFD ограничивает GPU heap до 15.5 GiB (carved-out из firmware). Этот параметр поднимает лимит до 120 GiB |

### Дополнительные параметры (при необходимости)

| Параметр | Назначение |
|----------|------------|
| `amdgpu.dcdebugmask=0x10` | Отключает PSR (Panel Self Refresh). Может потребоваться если DPMS ломает vblank counter |
| `amdgpu.dc=0` | Полное отключение Display Core. GPU работает только для compute, дисплейный вывод через simpledrm |
| `video=HDMI-A-1:1920x1080@60` | Принудительное ограничение разрешения на уровне ядра (не работает с Xorg -- используется xorg.conf) |

### Известные проблемы DCN 3.5.1

**Черный экран при загрузке** -- основная проблема на ядрах 6.18--6.19 с Strix Halo:

1. amdgpu загружает Display Core, инициализирует framebuffer
2. GDM запускает Wayland/X11 сессию, переключает режим дисплея
3. DPMS пытается управлять энергосбережением, вызывает `drmmode_do_crtc_dpms`
4. vblank counter не возвращается -- экран гаснет

Проблема воспроизводится на мониторах с разрешением выше 1080p через HDMI. На 1080p-мониторах (Samsung) работает без ограничений.

**Workaround для мониторов 2K+ через HDMI:**
- Принудительное 1080p через xorg.conf (см. ниже) -- рабочее решение
- Альтернатива: подключение через DisplayPort (не через HDMI)
- `amdgpu.dcdebugmask=0x10` -- отключает PSR, помогает на Samsung 1080p, недостаточно для Sunwind 2K

## Настройка X11

Wayland не работает стабильно на DCN 3.5.1. GDM переключен на X11.

`/etc/gdm3/custom.conf`:

```ini
[daemon]
WaylandEnable=false
```

### Ограничение разрешения для HDMI

`/etc/X11/xorg.conf.d/10-monitor.conf`:

```
Section "Monitor"
    Identifier "HDMI-A-0"
    Option "PreferredMode" "1920x1080"
EndSection

Section "Screen"
    Identifier "Default Screen"
    Monitor "HDMI-A-0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection
```

Без этого файла Xorg выбирает нативное разрешение монитора (2560x1440 для Sunwind SAC 2700), что вызывает ошибку vblank.

## Диагностика

```bash
# Параметры ядра текущей загрузки
cat /proc/cmdline

# Статус amdgpu
journalctl -b 0 -k | grep amdgpu

# Ошибки Display Core / DPMS
journalctl -b 0 | grep -iE 'crtc_dpms|segfault|Unrecoverable'

# EDID и подключенные мониторы
journalctl -b 0 | grep -iE 'gdm-x-session' | grep -iE 'connected|EDID|Monitor name'

# Информация о GPU
cat /sys/class/drm/card1/device/mem_info_vram_total    # VRAM в байтах
lspci -s bc:00.0 -v                                      # PCI-детали
```

## Установленные ядра

| Ядро | Статус |
|------|--------|
| 6.19.8-061908-generic | текущее, рабочее |
| 6.18.18-061818-generic | резервное |

## Связанные статьи

- [Драйвер amdgpu](amdgpu-driver.md)
- [Настройка BIOS](bios-setup.md)
- [Установка ROCm](../inference/rocm-setup.md)
- [Диагностика](../inference/troubleshooting.md)
