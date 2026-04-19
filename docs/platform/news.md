# Платформа Strix Halo: хроника обновлений

Хроника обновлений софтверного стека inference-сервера: ядро Linux, драйверы amdgpu, ROCm, Mesa/RADV, llama.cpp, firmware. Платформа: AMD Ryzen AI MAX+ 395 (gfx1151, RDNA 3.5, 40 CU, 120 GiB unified VRAM).

Спецификация сервера -- [README.md](README.md). Inference-стек -- [inference/](../inference/README.md).

Актуализация: `/refresh-news platform`.

---

## Текущее состояние (апрель 2026)

| Компонент | Версия | Статус |
|-----------|--------|--------|
| Ядро | 6.19.8-061908-generic | mainline, gfx1151 поддержка с 6.18+ |
| Firmware | linux-firmware (март 2026) | gfx1151 blobs включены |
| amdgpu driver | in-tree (ядро 6.19.8) | DCN 3.5.1, VCN, GFX, SDMA -- рабочие |
| Mesa / RADV | 25.2.8 | Vulkan 1.4.318, основной backend |
| ROCm | 6.4.0-47 | KFD видит 120 GiB, HIP segfault на gfx1151 |
| llama.cpp | b5520 (апрель 2026) | Vulkan backend, GGUF v3 |
| Ollama | 0.9.x | vendored llama.cpp |
| XDNA / amdxdna | ядро 6.19+ | /dev/accel0, 50 TOPS INT8 |
| PyTorch ROCm | 2.7.1+rocm6.2.4 | segfault на gfx1151 |

### Критические проблемы

**ROCm HIP segfault на gfx1151**: HIP-ядра llama.cpp падают с segfault при `HSA_OVERRIDE_GFX_VERSION=11.5.0`. KFD firmware table ограничивает carved-out VRAM до 15.5 GiB (обходится через `ttm.pages_limit=31457280`). Ожидается fix в будущих версиях ROCm.

**NPU (XDNA 2)**: драйвер amdxdna в mainline с 6.14+, устройство `/dev/accel0` видно, но inference-фреймворки (Lemonade, OGA) требуют доработки для production use.

---

## 2026-Q2

### Апрель 2026 -- ядро 6.19.8

- Обновление до ядра 6.19.8 (mainline)
- Резервное ядро: 6.18.18
- Стабильная работа Vulkan backend
- ROCm 6.4.0: KFD видит 120 GiB, но HIP segfault сохраняется

---

## 2026-Q1

### Март 2026 -- ROCm 7.2.1, бенчмарки

- ROCm 7.2.1 (из repo.radeon.com): gfx1151 нативная поддержка в target list
- HIP segfault по-прежнему воспроизводится (HSA_OVERRIDE не помогает)
- Бенчмарки Vulkan vs HIP на 3 моделях (1.5B, 27B, 30B MoE)
- TTM pages_limit fix: KFD видит 120 GiB вместо 15.5 GiB
- Пресеты inference: Devstral 2, InternVL3-38B, Qwen3.5-35B

### Январь-февраль 2026 -- начальная настройка

- Установка Ubuntu 24.04.4 LTS
- Сборка mainline ядра 6.18.x с поддержкой gfx1151
- Настройка GRUB параметров (amdgpu.gttsize, ttm.pages_limit)
- Первая сборка llama.cpp с Vulkan backend
- Установка ROCm 6.4.0
- BIOS: UMA 96 GiB, C-states отключены, Resizable BAR

---

## Что отслеживать

| Источник | Что проверять | Периодичность |
|----------|---------------|---------------|
| [kernel.org](https://kernel.org) | Новые stable/mainline ядра, amdgpu патчи | Раз в 2 недели |
| [repo.radeon.com](https://repo.radeon.com/amdgpu-install/) | Новые версии ROCm, amdgpu-install | Раз в месяц |
| [Mesa releases](https://docs.mesa3d.org/relnotes.html) | RADV performance, gfx1151 fixes | Раз в месяц |
| [llama.cpp releases](https://github.com/ggml-org/llama.cpp/releases) | Vulkan backend, новые архитектуры, GGUF | Раз в 2 недели |
| [ROCm/ROCK-Kernel-Driver](https://github.com/ROCm/ROCK-Kernel-Driver/issues) | KFD/HIP issues для gfx1151 | Раз в месяц |
| [amdxdna](https://github.com/amd/xdna-driver) | NPU driver, Lemonade support | Раз в месяц |

---

## Связанные статьи

- [README.md](README.md) -- спецификация сервера
- [gpu-kernel-setup.md](gpu-kernel-setup.md) -- настройка ядра
- [amdgpu-driver.md](amdgpu-driver.md) -- драйвер amdgpu
- [ROCm setup](../inference/rocm-setup.md) -- установка ROCm
- [Vulkan + llama.cpp](../inference/vulkan-llama-cpp.md) -- основной backend
- [Acceleration outlook](../inference/acceleration-outlook.md) -- перспективы GPU/CPU/NPU
- [Hardware alternatives](hardware-alternatives.md) -- сравнение с другими платформами
