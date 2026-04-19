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
| ROCm | 7.2.1 | KFD видит 120 GiB, HIP работает нативно gfx1151 |
| llama.cpp | b8708 (апрель 2026) | Vulkan backend, GGUF v3 |
| Ollama | 0.9.x | vendored llama.cpp |
| XDNA / amdxdna | ядро 6.19+ | /dev/accel0, 50 TOPS INT8 |
| PyTorch ROCm | 2.7.1+rocm6.2.4 | работает с wheels gfx1151 |

### Критические проблемы

**ROCm HIP на gfx1151**: С ROCm 7.2.1 HIP-инференс работает стабильно, GPU определяется нативно как gfx1151. Ограничение: HIP runtime не может выделить единый буфер >30-35 GiB (модели >30 GiB Q4 вызывают OOM при `hipMalloc`). VRAM лимит KFD решён через `ttm.pages_limit=31457280` (120 GiB). Открытые issues на GitHub ROCm: GPU hang ([#5151](https://github.com/ROCm/ROCm/issues/5151)), page fault ([#5991](https://github.com/ROCm/ROCm/issues/5991)).

**NPU (XDNA 2)**: драйвер amdxdna в mainline с 6.14+, устройство `/dev/accel0` видно, но inference-фреймворки (Lemonade, OGA) требуют доработки для production use.

---

## 2026-Q2

### Апрель 2026 -- ядро 6.19.8, llama.cpp b8708

- Обновление до ядра 6.19.8 (mainline)
- Резервное ядро: 6.18.18
- llama.cpp обновлён до b8708 (Vulkan backend)
- Стабильная работа Vulkan backend
- ROCm 7.2.1: HIP inference работает нативно, Vulkan остаётся быстрее
- HIP VRAM allocation limit: модели >30 GiB вызывают OOM при hipMalloc
- Открытые issues gfx1151: GPU hang ([#5151](https://github.com/ROCm/ROCm/issues/5151)), page fault ([#5991](https://github.com/ROCm/ROCm/issues/5991))
- Mesa 26.0 (ожидается): RADV transfer queue support на GFX9+

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
- Установка ROCm 6.4.0 (позже обновлён до 7.2.1)
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
