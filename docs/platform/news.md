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
| Mesa / RADV | 25.2.8 | Vulkan 1.4.318, основной backend (Mesa 26.0+ доступна для апгрейда -- +4-5% gen speed на gfx1151) |
| ROCm | 7.2.1 | KFD видит 120 GiB, HIP работает нативно gfx1151 |
| llama.cpp | b8717 (апрель 2026) | Vulkan backend, GGUF v3, commit `d9a12c82f` |
| Ollama | 0.9.x | vendored llama.cpp |
| XDNA / amdxdna | ядро 6.19+ | /dev/accel0, 50 TOPS INT8 |
| PyTorch ROCm | 2.7.1+rocm6.2.4 | работает с wheels gfx1151 |

### Критические проблемы

**ROCm HIP на gfx1151**: С ROCm 7.2.1 HIP-инференс работает стабильно, GPU определяется нативно как gfx1151. Ограничение: HIP runtime не может выделить единый буфер >30-35 GiB (модели >30 GiB Q4 вызывают OOM при `hipMalloc`). VRAM лимит KFD решён через `ttm.pages_limit=31457280` (120 GiB). Открытые issues на GitHub ROCm: GPU hang ([#5151](https://github.com/ROCm/ROCm/issues/5151)), page fault ([#5991](https://github.com/ROCm/ROCm/issues/5991)), hang при tensor finalization ([#6027](https://github.com/ROCm/ROCm/issues/6027), Qwen 3.5).

**ROCm 7+ performance regression на gfx1151**: После обновления до ROCm 7+ наблюдается регресс производительности. Community-workaround -- дополнительный флаг компиляции `-mllvm --amdgpu-unroll-threshold-local=600`, даёт ~20% uplift на 122B после корректировки defaults под gfx1151. Issue в llama.cpp по inefficient defaults -- [#21284](https://github.com/ggml-org/llama.cpp/issues/21284).

**linux-firmware-20251125 несовместим**: Пакет `linux-firmware` версии 20251125 ломает ROCm support на Strix Halo. Не апгрейдить, оставаться на версии марта 2026 или откатываться.

**Ядра <6.18.4**: Содержат bug, ломающий стабильность на gfx1151. Рекомендация -- не использовать ядра старше 6.18.4, на сервере установлено 6.19.8.

**NPU (XDNA 2)**: драйвер amdxdna в mainline с 6.14+, устройство `/dev/accel0` видно, но inference-фреймворки (Lemonade, OGA) требуют доработки для production use.

---

## 2026-Q2

### Апрель 2026 -- статус критических llama.cpp PR'ов (29 апреля)

Проверка через `gh pr view` трёх PR'ов влияющих на скорость inference на нашей платформе:

- [PR #20819](https://github.com/ggml-org/llama.cpp/pull/20819) "server: persist context checkpoints across slot save/restore" -- **OPEN**, last activity 2026-03-29. Реализует router-mode swap между моделями через `/slots` save/restore. **Не путать с встроенным checkpoint механизмом llama-server** -- тот active без этого PR (видно в логах `created/restored context checkpoint`)
- [PR #19670](https://github.com/ggml-org/llama.cpp/pull/19670) "Allow partial success of seq_rm for hybrid memory" -- **OPEN**, last activity 2026-03-12. Главный приоритет для нашей платформы -- решит inter-task cache reuse на hybrid Gated DeltaNet (Coder Next, Qwen3.6)
- [PR #20376](https://github.com/ggml-org/llama.cpp/pull/20376) "vulkan: f16 mixed-precision state for GATED_DELTA_NET" -- **DRAFT** на 2026-04-29 после feedback о numerical stability. Автор переключается на sharded approach через PR #20391, #20361

Прогноз: 3-6 месяцев до merge ключевого PR #19670 для inter-task cache reuse. Текущий 35B-text full прогон (running 2026-04-28..29) достигает 168/195 задач за ~22h из-за no-cache на hybrid -- benchmark будет переснят после merge для замера эффекта.

### Апрель 2026 -- llama.cpp b8717 (29 апреля)

- На сервере собрана версия b8717 (commit `d9a12c82f`) -- актуальная версия использовалась для full прогонов 2026-04-26..29 (Coder Next 178/195, 35B-text running)
- Ранее в news было b8708 -- устаревшая запись, актуально b8717

### Апрель 2026 -- Mesa 26.0 доступна (запланировано к апгрейду)

[Mesa 26.0](https://docs.mesa3d.org/relnotes/26.0.0.html) релиз -- 11 февраля 2026, последняя [Mesa 26.0.5](https://www.linuxcompatible.org/story/mesa-2605-released) ещё актуальнее. Ключевое для нашей платформы:

- **+4-5% generation speed на Strix Halo gfx1151** при сочетании Mesa 26.0.1+ и tuned accelerator-performance profile (по [strix-halo-guide community](https://github.com/hogeheer499-commits/strix-halo-guide))
- Unified memory reporting на APUs работает корректно -- system utilities видят правильный VRAM
- RADV ray tracing performance gains (не релевантно для inference)

На сервере сейчас Mesa **25.2.8** (Ubuntu 24.04 stable). Апгрейд до 26.0+ не из стандартных PPA -- требует mesa-from-source или Kisak PPA. Запланировать после стабилизации текущих full прогонов.

### Апрель 2026 -- SSH-верификация стека (25 апреля)

- Ядро: 6.19.8-061908-generic
- ROCm: 7.2.53211.70201-81 (rocm-core 7.2.1)
- Mesa Vulkan: 25.2.8-0ubuntu0.24.04.1
- llama.cpp: коммит `d9a12c82f` (сборка b8708)
- linux-firmware: 20250901.git993ff19b-0ubuntu1 (сентябрь 2025, безопасная версия -- не сломанный 20251125)
- Все компоненты совпадают с задокументированным состоянием таблицы

### Апрель 2026 -- SSH-верификация стека (22 апреля)

- Ядро: 6.19.8-061908-generic
- ROCm: 7.2.53211.70201-81 (hip 7.2.1)
- llama.cpp: коммит `d9a12c82f` (сборка b8708)
- Все компоненты совпадают с задокументированным состоянием таблицы

### Апрель 2026 -- best practices сборки llama.cpp под gfx1151

Рекомендуемые флаги CMake для HIP-сборки под Strix Halo:

- `GPU_TARGETS=gfx1151` -- точная цель компиляции
- `GGML_HIP_ROCWMMA_FATTN=ON` -- flash attention через rocWMMA, заметный прирост на больших контекстах
- `GGML_HIP_NO_VMM=ON` -- обход проблем HIP Virtual Memory Manager, повышает стабильность

Без `ROCWMMA_FATTN` flash attention падает на fallback-ядра, без `NO_VMM` возможны зависания при аллокациях крупных буферов.

### Апрель 2026 -- known issues платформы

- `linux-firmware-20251125` ломает ROCm support на Strix Halo -- не апгрейдить пакет `linux-firmware`, держать версию марта 2026
- Ядра <6.18.4 содержат bug стабильности gfx1151 -- не использовать, минимум 6.18.4
- ROCm 7+ даёт regression производительности, community-workaround: сборка с `-mllvm --amdgpu-unroll-threshold-local=600`, уплифт ~20% на моделях уровня 122B
- Исправление дефолтов llama.cpp под gfx1151 отслеживается в issue [#21284](https://github.com/ggml-org/llama.cpp/issues/21284)
- Hang при tensor finalization на Qwen 3.5 -- ROCm issue [#6027](https://github.com/ROCm/ROCm/issues/6027)

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
