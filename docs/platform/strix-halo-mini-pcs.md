# Какой Strix Halo mini PC купить в 2026: сравнение и рекомендации

Все mini PC на AMD Strix Halo с 128 GiB RAM используют один и тот же SoC -- AMD Ryzen AI Max+ 395 + Radeon 8060S iGPU + XDNA 2 NPU + LPDDR5X-8000 unified (256 GB/s). Различия -- в корпусе, охлаждении, портах, BIOS, качестве сборки и цене. Здесь -- сравнение всех актуальных вариантов и финальная рекомендация.

Эта статья сфокусирована **только на mini-PC формфакторе с 128 GiB**. Ноутбук HP ZBook Ultra G1a и прототип Sapphire Linked Dual (256 GiB) разобраны отдельно в [strix-halo-vendors.md](strix-halo-vendors.md). Сравнение Strix Halo как класса с RTX 5090 / Mac M4/M3 / DGX Spark -- в [hardware-alternatives.md](hardware-alternatives.md).

## Главная таблица: все mini-PC на Strix Halo 128 GiB

| Модель | Цена 2026 (128GB) | Сеть | Охлаждение | Сборка | Гарантия |
|--------|-------------------|------|------------|--------|----------|
| **Meigao MS-S1 MAX** ⭐ | **~$2000** | 2× 10GbE | 6 heat pipes + dual turbine | премиум | 1 год |
| **Minisforum MS-S1 MAX** | $2700 | 2× 10GbE | то же + 2U rack-вариант | премиум | 1-2 года |
| **Beelink GTR9 Pro** v2.2 | ~$3000 | 2× 10GbE Realtek | vapor chamber + dual fans (тихо) | хорошее | 1-3 года |
| **Framework Desktop** | $2500+ | 2× 5GbE | модульное (есть fanless mods) | хорошее | community-friendly |
| **GMKtec EVO-X2** | $3000 | 2.5GbE + Wi-Fi 7 | стандартное Sixunited | среднее | 1 год |
| **Bosgame M5** | $2599 | 2.5GbE Realtek | стандартное + задний вентилятор | среднее (заводские дефекты) | 1 год |
| **Corsair AI Workstation 300** | **$3399** ⚠️ | 2.5GbE | **liquid cooling** | premium QC | стандартная |
| **HP Z2 Mini G1a** | $2500-3500 | RJ45 + WiFi | до 160W overclock, шумнее | enterprise | **3-5 лет** |
| FEVM FA-EX9 / GEEKOM A9 Mega / NIMO | $1700-2500 | varies | стандартное Sixunited | лотерея | 1 год |

**Главные дельты по конфигурациям**:

- **Цена**: разброс **$1700-3399** -- почти в 2× при идентичном SoC
- **Сеть**: dual 10GbE (top vendors) vs 2.5GbE (бюджетные) -- критично для AI-cluster
- **Охлаждение**: liquid (Corsair) > vapor chamber (Beelink) > 6 heat pipes (Minisforum) > стандартное Sixunited (бюджетные)
- **Гарантия**: 3-5 лет (HP) vs 1 год (китайские бренды)

## Краткие профили по каждому вендору

### Meigao MS-S1 MAX (наш сервер)

OEM-партнёр Minisforum: **идентичная плата SHWSA v1.0**, разные BIOS. Авторская платформа -- около 3 месяцев эксплуатации, см. [server-spec.md](server-spec.md).

- **Плюсы**: 6 heat pipes + dual turbine fans, 2× 10GbE, USB4 v2, PCIe x16 для расширения. Лучшее охлаждение в сегменте по обзорам (наряду с Minisforum)
- **Минусы**: EC fan control недоступен в Linux, fan curves субоптимальны (шумит на idle, лечится снижением cTDP в BIOS)
- **Цена/доступность**: ~$2000 (преимущественно Asia)

### Minisforum MS-S1 MAX

То же что Meigao, но более раскрученный бренд + 2U rack-вариант для AI-cluster. Доступнее в EU/US.

- **Плюсы**: те же что Meigao + 2U rack form factor + 130W/95W/60W TDP-режимы
- **Минусы**: тот же price premium ($2400-2700), 10GbE NICs unstable на Linux ядрах <6.17.11 (наше 6.19.8 OK), sub-optimal fan curves
- Согласно [Strix Halo Wiki](https://strixhalo.wiki/Hardware/PCs/Minisforum_MS-S1_MAX): "problems with the network interfaces on Linux and sub-optimal fan curves"
- [ServeTheHome review](https://www.servethehome.com/minisforum-ms-s1-max-review-the-best-ryzen-ai-max-mini-pc-yet/) -- "best Ryzen AI Max mini-PC yet"

### Beelink GTR9 Pro

Mac Studio-style вертикальный mini-PC с интегрированным БП. Релиз -- сентябрь 2025.

- **Плюсы**: vapor chamber + dual fans -- **самый тихий** под нагрузкой. Wi-Fi 6E, USB4, integrated PSU
- **Минусы**: **версия v1 платы имела серьёзные проблемы стабильности** -- Intel E610 NIC crashed под нагрузкой. v2.2 заменила Intel на Realtek (стабильнее, но медленнее)
- Согласно [Strix Halo Wiki Buyer's Guide](https://strixhalo.wiki/Guides/Buyer's_Guide): "Avoid unless you can confirm the motherboard is version 2.2 or later"
- Подтверждение [GTR9 PRO troubles thread на Beelink Forum](https://bbs.bee-link.com/d/8935-gtr9-pro-troubles-and-how-sort-of-solved-it)

### Framework Desktop

Linux-first ориентация, сильное community и поддержка ремонтопригодности.

- **Плюсы**: лучший Linux out-of-box, January 2026 update задокументировал stable ROCm+Linux configs ([Framework Community](https://community.frame.work/t/linux-rocm-january-2026-stable-configurations-update/79876)). [Phoronix](https://www.phoronix.com/review/framework-desktop-linux) хвалит как "Linux-Friendly Performance". Crown jewel платформы по Strix Halo Wiki Buyer's Guide
- **Минусы**: USB4+mDP "super flaky" под Linux при двух мониторах ([Framework Community report](https://community.frame.work/)). AMD TPM unavailable после sleep/wake. Только 5GbE (vs 10GbE у топов). Длительные сроки доставки
- Soldered RAM "antithetical to Framework's ethos" по [Tom's Hardware review](https://www.tomshardware.com/desktops/gaming-pcs/framework-desktop-review), но необходимо для bandwidth Strix Halo

### GMKtec EVO-X2

Самый популярный китайский Strix Halo на унифицированной плате Sixunited AXB35.

- **Плюсы**: Wi-Fi 7, USB4, Quad 8K Display, Performance/Balanced/Quiet режимы в BIOS. P-Mode разгоняет CPU/GPU/NPU
- **Минусы**: "BIOS extremely limited and getting updates is an adventure" (Strix Halo Wiki). Тепло в Balanced 87-94°C при играх. Fan noise слышно через всю комнату при CPU benchmark. Outdated BIOS на ship -- update вручную
- [Tom's Hardware review](https://www.tomshardware.com/desktops/mini-pcs/gmktec-evo-x2-ai-mini-pc-review) -- thermals stable до 61°C average при stress test, но fans loud

### Bosgame M5

Второй по популярности китайский Strix Halo, тоже Sixunited платформа. Поставки с июля 2025.

- **Плюсы**: all-metal premium feel, vertical PS5-like stand, Wi-Fi 7 + Bluetooth 5.4, два USB4 + USB 3.1 + SD reader. Самая низкая цена за 96GB конфигурацию
- **Минусы**: **только 2.5GbE Realtek** (значительный downgrade vs 10GbE), "stuck power buttons", "loose screws inside chassis", "rear fan clicking noise" (Strix Halo Wiki). "Mysterious performance switch" неясно как работает
- Цена -- $1699 pre-order для 96GB / $2599 для 128GB
- [Strix Halo Wiki](https://strixhalo.wiki/Hardware/PCs/Bosgame_M5): "some Bosgame units had minor issues like stuck power buttons"

### Corsair AI Workstation 300

Standard Sixunited плата, но с премиум-сборкой и **liquid cooling**.

- **Плюсы**: liquid cooling -- лучшее охлаждение под длинной нагрузкой. Premium QC от Corsair бренда. Самый "classy" внешне
- **Минусы (КРИТИЧНО)**: **резкий рост цены с $2299 → $3399** в апреле 2026 из-за RAM shortage и геополитики ([Tom's Hardware](https://www.tomshardware.com/desktops/mini-pcs/corsairs-strix-halo-ai-workstation-300-gets-even-more-expensive-amid-the-rampocalypse-ryzen-ai-max-395-flagship-now-sits-at-usd3-399)). Software stability issues упомянуты в review. Под лёгкой нагрузкой шумнее DGX Spark
- При $2300 был бы хорошим выбором, но за $3399 проще взять Mac M4 Max или DGX Spark

### HP Z2 Mini G1a

Единственный mini-PC от крупного западного вендора. **Z2 Mini** -- desktop форм-фактор (отличается от ноутбука ZBook Ultra G1a).

- **Плюсы**: workstation-grade гарантия 3-5 лет, **ECC память опционально** (единственный в сегменте), **до 160W TDP overclock** (самый агрессивный), Ubuntu certified для AMD Ryzen AI Max+ Pro 395, поддержка enterprise
- **Минусы**: noisier than Sixunited cooling (Strix Halo Wiki), непредсказуемое ценообразование у HP. Цена $2500-3500 -- premium. [StorageReview](https://www.storagereview.com/review/hp-z2-mini-g1a-review-running-gpt-oss-120b-without-a-discrete-gpu): gpt-oss-120B работает на Z2 Mini G1a без discrete GPU
- [Strix Halo Wiki Buyer's Guide](https://strixhalo.wiki/Guides/Buyer's_Guide) рекомендует "при цене ниже $2500 благодаря гарантийной поддержке"

### FEVM FA-EX9 / GEEKOM A9 Mega / NIMO AI MiniPC

Прочие китайские варианты на той же Sixunited платформе. Без значимых отличий от GMKtec/Bosgame в hardware. Мало review в западной прессе.

- **Плюсы**: иногда самые низкие цены ($1700-2200 за 128GB)
- **Минусы**: лотерея сборки аналогичная Bosgame, но **без накопленной community базы знаний** об их косяках. Нет vendor forum активного. Гарантийный возврат сложнее
- Подходит только при отсутствии бюджета на проверенные варианты

## Анализ форумов: что говорят реальные пользователи

Сводка по обсуждениям на r/LocalLLaMA, r/MiniPCs, ServeTheHome, Strix Halo Wiki, Level1Techs, форумам вендоров:

### Топ жалобы (по частоте упоминаний)

1. **Шум вентиляторов** -- упоминается **у всех** mini-PC. Особенно критично у GMKtec EVO-X2 ("слышно через всю комнату при CPU benchmark") и при **idle у Minisforum MS-S1 MAX** ("сильно шумит при простое, лечится UEFI tuning"). Самые тихие: **Beelink GTR9 Pro** (vapor chamber) и **Corsair AI Workstation 300** (liquid). Общий обходной путь: понизить cTDP до 95W (Balanced)
2. **Soldered RAM** -- raised в каждой review-статье. Не специфично для вендора, ограничение Strix Halo для bandwidth
3. **BIOS-зрелость и updates** -- особенно слабо у GMKtec ("getting updates is an adventure"), Bosgame ("mysterious performance switch")
4. **Linux compatibility** -- ROCm/HIP segfault на gfx1151 у всех; решение -- Vulkan backend. См. [rocm-setup.md](../inference/rocm-setup.md#статус-gfx1151-strix-halo)
5. **EC fan control** -- ни один вендор не expose'ит fan curves в Linux sysfs. Управление только через BIOS
6. **Networking issues** -- 10GbE NICs unstable на старых Linux ядрах (Minisforum), Intel E610 crashes на Beelink v1
7. **Заводские дефекты сборки** -- особенно у Bosgame M5 (stuck power buttons, loose screws, fan clicking)
8. **Цена RAM растёт** -- "RAMpocalypse" 2026 поднял цены всех вариантов на 15-50%

### Топ похвалы (по частоте)

1. **Производительность LLM на 128 GiB** -- единодушно "лучшее за деньги" для моделей 30-122B
2. **Тихая работа Beelink GTR9 Pro** -- vapor chamber design делает GTR9 Pro эталоном по тишине под нагрузкой ([Notebookcheck teardown](https://www.notebookcheck.net/Strix-Halo-Beelink-GTR9-Pro-teardown-reveals-a-vapor-chamber-dual-fan-design-filling-most-of-the-chassis-delivering-silent-120B-LLM-performance-at-120-W.1137263.0.html))
3. **Linux-first Framework Desktop** -- активная community, January 2026 stable ROCm configs, Phoronix-friendly
4. **10GbE на Minisforum/Meigao** -- никто из конкурентов не предлагает dual 10GbE в этом ценовом сегменте
5. **HP Z2 Mini G1a с ECC** -- единственный enterprise-grade вариант с ECC памятью

### Цитаты с форумов

- [Strix Halo Wiki Buyer's Guide](https://strixhalo.wiki/Guides/Buyer's_Guide) о Beelink GTR9 Pro: *"suffered from significant stability issues unresolved for several months"*
- [GTR9 PRO troubles thread](https://bbs.bee-link.com/d/8935-gtr9-pro-troubles-and-how-sort-of-solved-it): *"my unit was crashing at random intervals, replaced motherboard helped"*
- О Framework Desktop ([Framework Community](https://community.frame.work/)): *"USB4 + mDP combo is unusably flaky under every Linux distribution tried"*
- О GMKtec EVO-X2 (Strix Halo Wiki): *"BIOS on these systems is extremely limited and getting updates is an adventure"*
- О Bosgame M5 ([Notebookcheck](https://www.notebookcheck.net/Mini-PC-with-AMD-Strix-Halo-and-128-GB-RAM-AMD-Ryzen-AI-Max-395-and-AMD-Radeon-8060S-impress-in-Bosgame-M5.1088558.0.html)): *"build quality is mostly good but quality control varies"*
- О Corsair AI Workstation 300 ([Tom's Hardware](https://www.tomshardware.com/pc-components/gpus/corsair-ai-workstation-300-review)): *"recent price hikes, software stability issues, and fresh competition all make it tough to recommend for AI work specifically"*

## Какой купить? Рекомендации по сценариям

### Для AI inference сервера (основной use case)

**Meigao MS-S1 MAX** (~$2000) -- лучший mix цена/качество. Если доступен в регионе. Авторский опыт -- стабильная работа Ubuntu 24.04 + kernel 6.19.8 + Vulkan, 86 tok/s на 30B-A3B MoE.

Альтернатива: **Minisforum MS-S1 MAX** ($2400-2700) -- та же плата SHWSA v1.0, но более доступен в EU/US, плюс 2U rack-вариант для будущего AI-cluster.

### Для тех, кто хочет тишину

**Beelink GTR9 Pro v2.2** (~$3000) -- vapor chamber + dual fans делают самым тихим под нагрузкой. **Обязательно проверить ревизию платы перед покупкой** -- v1 имеет stability issues. Только v2.2 или новее.

Альтернатива: **Corsair AI Workstation 300** -- liquid cooling, но цена $3399 переоценена для inference, лучше DGX Spark или Mac M4 Max за похожие деньги.

### Для Linux developer / community

**Framework Desktop** (~$2500) -- лучший Linux out-of-box, January 2026 stable ROCm configurations, Phoronix-friendly, активное community. Минус: 5GbE вместо 10GbE.

### Минимальный бюджет

**Bosgame M5** (96GB pre-order $1699) -- самый дешёвый. Готов жить с возможным заводским дефектом и только 2.5GbE.

Альтернатива: **GMKtec EVO-X2** ($1700-2200) -- bigger name, но плохой BIOS support.

Для **максимальной экономии** -- FEVM/GEEKOM/NIMO китайские варианты по $1700, но без community поддержки и лотерея QC.

### Для enterprise (с гарантией 3-5 лет)

**HP Z2 Mini G1a** ($2500-3500) -- единственный western vendor mini-PC. ECC память опционально, до 160W overclock, Ubuntu certified, enterprise warranty. Минус: шумнее Sixunited-аналогов.

### Для AI-cluster (нужен 10GbE backbone)

**Meigao/Minisforum MS-S1 MAX** или **Beelink GTR9 Pro v2.2** -- единственные с dual 10GbE. Plus: Minisforum 2U rack-mount для server-room установки.

### Чего лучше избегать в апреле 2026

- **Beelink GTR9 Pro v1** -- известные stability issues; покупать только v2.2 или новее
- **Corsair AI Workstation 300 за $3399** -- не оправдан price hike, лучше Mac M4 Max или DGX Spark
- **Менее известные китайские варианты** (FEVM, GEEKOM, NIMO) если бюджет позволяет проверенные альтернативы

## Финальный вывод

Если коротко: **Meigao MS-S1 MAX** или **Minisforum MS-S1 MAX** -- best balanced choice для большинства сценариев в $2000-2700 range. Дают премиум охлаждение, dual 10GbE, надёжный BIOS и проверенный community track record.

Если бюджет ниже $2000 -- **Bosgame M5** с готовностью к лотерее QC. Если важна гарантия 3+ года -- **HP Z2 Mini G1a**. Если важна тишина -- **Beelink GTR9 Pro v2.2**.

Все варианты на одном SoC и дают +-эквивалентную LLM-производительность (86 tok/s на Qwen3-Coder 30B-A3B Q4 в Vulkan). Выбор -- в основном по корпусу, networking, гарантии и тому "сколько готов потратить на качество исполнения".

## Связано

- [strix-halo-vendors.md](strix-halo-vendors.md) -- полное сравнение Strix Halo вендоров (включая HP ZBook ноутбук и Sapphire Linked Dual)
- [hardware-alternatives.md](hardware-alternatives.md) -- Strix Halo как класс vs RTX 5090 / Mac M4/M3 / DGX Spark
- [server-spec.md](server-spec.md) -- наша конкретная конфигурация (Meigao MS-S1 MAX)
- [bios-setup.md](bios-setup.md) -- настройка BIOS под inference (Meigao-specific, частично применимо к Minisforum)
- [gpu-kernel-setup.md](gpu-kernel-setup.md) -- kernel parameters, общие для всех Strix Halo mini-PC
- [vram-allocation.md](vram-allocation.md) -- KFD VRAM фикс (общий для всей платформы)
- [../inference/rocm-setup.md](../inference/rocm-setup.md#статус-gfx1151-strix-halo) -- статус ROCm на gfx1151
