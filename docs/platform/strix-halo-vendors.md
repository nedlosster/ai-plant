# Сравнение mini-PC на AMD Strix Halo: вендоры и сборки (апрель 2026)

Все mini-PC и workstations на AMD Ryzen AI Max+ 395 (Strix Halo) используют один и тот же SoC, но отличаются корпусом, охлаждением, портами, BIOS-зрелостью, качеством сборки и ценой. Здесь -- разбор реальных проблем и преимуществ каждого вендора по форумам и обзорам, чтобы выбрать корпус под свой use case.

Эта статья -- продолжение [hardware-alternatives.md](hardware-alternatives.md) (Strix Halo как класс vs RTX/Mac/DGX). Если уже выбрали Strix Halo -- здесь сравнение конкретных сборок.

## Контекст: единая SoC-платформа, разные корпуса

Базовый SoC одинаков у всех вендоров:

- AMD Ryzen AI Max+ 395 (16C/32T Zen 5, 5.18 GHz boost, до 120W cTDP)
- Radeon 8060S iGPU (RDNA 3.5, 40 CU, gfx1151)
- XDNA 2 NPU (50 TOPS INT8)
- LPDDR5X-8000 unified memory (128 GiB max, 256-bit bus = 256 GB/s)

Различия между вендорами:

- **Сетевая оснащённость**: 2.5GbE / 5GbE / dual 10GbE
- **USB**: USB4 / Thunderbolt 4 / USB-C 3.2
- **Охлаждение**: вентиляторы / vapor chamber / liquid cooling, шум под нагрузкой
- **BIOS**: UEFI feature set (UMA Frame Buffer slider, cTDP контроль, fan curves)
- **OEM-плата**: большинство китайских mini-PC построены на **Sixunited AXB35** (унифицированный board), HP делает свой board с ECC, у Beelink собственная плата (v1 → v2.2 ревизия)
- **Цена / гарантия / доступность по регионам**

Большинство сравнений ниже ссылается на [Strix Halo Wiki Buyer's Guide](https://strixhalo.wiki/Guides/Buyer's_Guide), [ServeTheHome](https://www.servethehome.com/) и [Strix Halo Wiki](https://strixhalo.wiki/Hardware/PCs).

## 1. Meigao MS-S1 MAX (наш сервер) и Minisforum MS-S1 MAX

Meigao и Minisforum -- два бренда одного и того же устройства. У них **идентичная плата SHWSA v1.0** (по факту это OEM-партнёрство, не Sixunited), разная только Bios-вилка и upselling. Наш сервер -- **Meigao MS-S1 MAX**, см. [server-spec.md](server-spec.md).

| Параметр | Значение |
|----------|----------|
| Корпус | Алюминиевый, mini-PC форм-фактор + 2U rack-вариант (Minisforum) |
| Охлаждение | 6 heat pipes + dual turbine fans + phase change material (Minisforum); EC-управление вентиляторами (нет sysfs `pwm*`) |
| TDP режимы | 130W (Performance) / 95W (Balanced) / 60W (Quiet) |
| Сеть | 2× 10GbE (Intel или Aquantia в зависимости от ревизии) |
| USB | USB4 v2 + USB 3.2 + SD reader |
| BIOS | AMI 1.06 (наш Meigao, 04.01.2026); UMA Frame Buffer slider есть |
| PCIe слот | x16 (для расширения) |
| Цена 2026 | ~$2000 (Meigao) / $2400-2700 (Minisforum) |

**Плюсы**:

- Лидер по AI-mini-PC согласно [ServeTheHome review](https://www.servethehome.com/minisforum-ms-s1-max-review-the-best-ryzen-ai-max-mini-pc-yet/) -- "best Ryzen AI Max mini-PC yet"
- 6 heat pipes + dual turbine fans -- лучшее охлаждение в сегменте
- Dual 10GbE + USB4 v2 -- premium networking
- PCIe x16 расширение (редкая фича для mini-PC)
- 2U rack mount -- сборка в кластер для 235B+ моделей

**Минусы и косяки**:

- **Linux 10GbE NIC unstable на старых ядрах** -- требуется kernel 6.17.11+ или 6.18+ (наше 6.19.8 OK), [подтверждено в Strix Halo Wiki](https://strixhalo.wiki/Hardware/PCs/Minisforum_MS-S1_MAX) и Reddit
- **Sub-optimal fan curves** -- при idle устройство шумнее чем требуется; обходится UEFI manual tuning или снижением cTDP
- **Fan control только в BIOS** -- нет sysfs `pwm*` / `fan*_input`, EC controller не expose'ится в Linux. Решение: понизить cTDP в BIOS, не пытаться менять fan curves софтом. См. [bios-setup.md](bios-setup.md)
- **Цена** -- $2400-2700 у Minisforum (с 128 GiB), $2000 у Meigao -- premium по сравнению с GMKtec/Bosgame

**Авторский опыт (Meigao MS-S1 MAX, ~3 месяца эксплуатации)**:

- Стабильная работа на Ubuntu 24.04 + kernel 6.19.8 (mainline), Vulkan/Mesa RADV 25.2.8
- llama.cpp Vulkan backend работает идеально, 86 tok/s на Qwen3-Coder 30B-A3B
- ROCm 6.4.0-47 установлен, но HIP-ядра падают с segfault на gfx1151 при инференсе -- известная проблема всей платформы Strix Halo, не специфична для MS-S1 MAX. См. [rocm-setup.md](../inference/rocm-setup.md#статус-gfx1151-strix-halo)
- Шум на cTDP 95W -- приемлемый ("ровный шум турбинок"), при cTDP 130W -- громко
- 10GbE Intel NIC работает стабильно на нашем 6.19.8

**Вердикт**: лучший выбор для AI-cluster и production-inference при наличии 10GbE-инфраструктуры. Minisforum-вариант обходится дороже Meigao за рамкой сборки (один и тот же board).

**Источники**:

- [ServeTheHome review](https://www.servethehome.com/minisforum-ms-s1-max-review-the-best-ryzen-ai-max-mini-pc-yet/)
- [Notebookcheck review](https://www.notebookcheck.net/One-of-the-most-powerful-mini-PCs-of-2025-Minisforum-MS-S1-Max-review-AMD-Strix-Halo-Power-128-GB-RAM-Radeon-8060S-for-professionals-AI.1124332.0.html)
- [Strix Halo Wiki: MS-S1 MAX](https://strixhalo.wiki/Hardware/PCs/Minisforum_MS-S1_MAX)
- [AkitaOnRails review (96GB VRAM)](https://akitaonrails.com/en/2026/03/31/minisforum-ms-s1-max-amd-ai-max-395-review/)

## 2. Beelink GTR9 Pro

Внешне как Mac Studio (вертикальный mini-PC), интегрированный БП. Релиз -- сентябрь 2025.

| Параметр | Значение |
|----------|----------|
| Корпус | Алюминий, Mac Studio-style |
| Охлаждение | Vapor chamber + dual fans (тихий под нагрузкой по Notebookcheck) |
| Сеть | 2× 10GbE Intel E610 (v1) / Realtek (v2.2) |
| USB | USB4 + множество USB 3.1 + SD reader |
| TDP | до 120W |
| Цена 2026 | $2000-3000 (128 GiB) |

**Плюсы**:

- Vapor chamber + dual fans -- работает тихо под нагрузкой (по [Notebookcheck teardown](https://www.notebookcheck.net/Strix-Halo-Beelink-GTR9-Pro-teardown-reveals-a-vapor-chamber-dual-fan-design-filling-most-of-the-chassis-delivering-silent-120B-LLM-performance-at-120-W.1137263.0.html))
- Интегрированный БП -- меньше кабелей
- Wi-Fi 6E (MT7925)
- Линейка price points

**Минусы и косяки (КРИТИЧНО)**:

- **Версия 1 платы имеет серьёзные проблемы стабильности** -- [Strix Halo Wiki предупреждает](https://strixhalo.wiki/Guides/Buyer's_Guide): "Avoid unless you can confirm the motherboard is version 2.2 or later"
- **Intel E610 dual 10GbE NICs crashed под нагрузкой** -- на Windows и Arch Linux. Beelink выпустил firmware fix + replacement program для v1 плат
- **v2.2 заменила Intel NICs на Realtek** -- что снизило производительность networking, но повысило стабильность
- Soldered RAM (как у всех Strix Halo)

**Вердикт**: после ремонта v1→v2.2 -- хороший выбор за свою цену. Перед покупкой обязательно проверить ревизию платы. Если 10GbE Intel критичен -- лучше Minisforum/Meigao.

**Источники**:

- [ServeTheHome review](https://www.servethehome.com/beelink-gtr9-pro-review-amd-ryzen-ai-max-395-system-with-128gb-and-dual-10gbe/)
- [GTR9 PRO troubles -- Beelink Forum](https://bbs.bee-link.com/d/8935-gtr9-pro-troubles-and-how-sort-of-solved-it)
- [Strix Halo Wiki: Beelink GTR9 Pro](https://strixhalo.wiki/Hardware/PCs/Beelink_GTR9_Pro)

## 3. Framework Desktop

Модульный, ориентирован на ремонтопригодность и Linux-friendly экосистему. Выпуск -- начало 2026.

| Параметр | Значение |
|----------|----------|
| Корпус | Modular, swappable expansion cards |
| Охлаждение | Custom fan setup (есть fanless варианты от энтузиастов) |
| Сеть | Dual 5GbE (vs 10GbE у топов) |
| USB | USB4 + DisplayPort + expansion ports |
| Цена 2026 | $2000 (base) до $2500+ (128 GiB) |

**Плюсы**:

- Crown jewel платформы согласно Strix Halo Wiki -- лучшая сообщество и поддержка
- **Linux-first design** -- Framework активно работает с Mesa, ядром 6.18+
- Январь 2026 update задокументировал stable ROCm+Linux configurations
- Exchangeable I/O modules (хотя не настолько как Framework Laptop)
- Phoronix [хвалит](https://www.phoronix.com/review/framework-desktop-linux) как "Linux-Friendly Performance"

**Минусы и косяки**:

- **USB4 + mDP super flaky** -- [community report](https://community.frame.work/): "unusably flaky under every Linux distribution tried" при попытке драйвить 2 монитора (один HDMI + другой mDP)
- **AMD TPM unavailable после sleep/wake** -- "annoying device" по форуму
- **Occasional PSU fan noise issues** (Strix Halo Wiki Buyer's Guide)
- **Длительные сроки доставки** на старте Q1 2026
- **Soldered RAM** -- "antithetical to Framework's ethos" по review Tom's Hardware (но необходимость для Strix Halo bandwidth)
- 5GbE вместо 10GbE -- хуже networking чем MS-S1 MAX/GTR9 Pro

**Вердикт**: лучший выбор если приоритет Linux-совместимость и community. Хуже networking чем 10GbE-кандидаты. Нужно подождать stable build (поздняя 2026).

**Источники**:

- [Tom's Hardware review](https://www.tomshardware.com/desktops/gaming-pcs/framework-desktop-review)
- [ServeTheHome review](https://www.servethehome.com/framework-desktop-review-a-solid-amd-strix-halo/)
- [Phoronix Linux review](https://www.phoronix.com/review/framework-desktop-linux)
- [Linux + ROCm: January 2026 Stable Configurations](https://community.frame.work/t/linux-rocm-january-2026-stable-configurations-update/79876)
- [Strix Halo Wiki: Framework Desktop](https://strixhalo.wiki/Hardware/PCs/Framework_Desktop)

## 4. GMKtec EVO-X2

Самый популярный китайский Strix Halo. Построен на унифицированной плате **Sixunited AXB35**.

| Параметр | Значение |
|----------|----------|
| Корпус | Алюминий снизу + пластик сверху, 96GB или 128GB конфигурации |
| Охлаждение | Стандартное Sixunited cooling |
| Сеть | 2.5GbE + Wi-Fi 7 + USB4 |
| TDP | Performance / Balanced / Quiet режимы |
| Цена 2026 | $1700-3000 |

**Плюсы**:

- **Самая бюджетная цена** в сегменте -- $1700 за 96 GiB конфигурацию
- Wi-Fi 7 + USB4 + Quad Screen 8K Display
- Performance Mode (P-Mode) разгоняет CPU/GPU/NPU агрессивно
- BIOS включает UMA slider и Performance/Balanced/Quiet профили

**Минусы и косяки (по форумам)**:

- **BIOS extremely limited** -- по Strix Halo Wiki Buyer's Guide: "BIOS on these systems is extremely limited and getting updates is an adventure"
- **Тепло в Balanced mode 87-94°C** при играх (community report)
- **Fan noise louder than expected** -- слышно через всю комнату при CPU benchmark
- **Cooling system in Performance mode leaves much to be desired**
- Outdated BIOS на ship -- требует update вручную

**Вердикт**: лучший price/performance, но BIOS-зрелость и охлаждение сделаны на минимуме. Подходит как entry-point для экспериментов с Strix Halo.

**Источники**:

- [Tom's Hardware review](https://www.tomshardware.com/desktops/mini-pcs/gmktec-evo-x2-ai-mini-pc-review)
- [PCWorld review](https://www.pcworld.com/article/3011421/gmktec-evo-x2-review.html)
- [Notebookcheck review](https://www.notebookcheck.net/AMD-Strix-Halo-in-the-GMKtec-EVO-X2-Powerful-mini-PC-with-AMD-Ryzen-AI-Max-395-and-Radeon-8060S-reviewed.1102641.0.html)
- [CraftRigs LLM review](https://craftrigs.com/reviews/gmktec-evo-x2-ryzen-ai-max-local-llm-review/)

## 5. Bosgame M5

Второй по популярности китайский Strix Halo, тоже на Sixunited платформе. Поставки с июля 2025.

| Параметр | Значение |
|----------|----------|
| Корпус | All-metal, 220.8 × 199.5 × 57.1 мм, premium feel, vertical stand |
| Охлаждение | Стандартное Sixunited + задний вентилятор (есть жалобы на clicking noise) |
| Сеть | **только 2.5GbE** Realtek RTL8125 (RJ45) |
| USB | 2× USB4/Thunderbolt + USB 3.1 xHCI + SD reader |
| Wi-Fi | Wi-Fi 7 + Bluetooth 5.4 (MT7925) |
| TDP | Performance switch (загадочный, упомянут в [tech.yahoo.com](https://tech.yahoo.com/computing/articles/bosgame-m5-mini-pc-ryzen-183200183.html)) |
| Цена 2026 | $1699 (96GB pre-order) / $2599 (128GB) |

**Плюсы**:

- All-metal premium feel (по Notebookcheck/Guru3D)
- Vertical stand (PS5-like)
- Самая низкая цена за 96 GiB ($1699 pre-order)
- Wi-Fi 7

**Минусы и косяки (Strix Halo Wiki + форумы)**:

- **Только 2.5GbE** -- значительный downgrade vs 10GbE у MS-S1 MAX/GTR9 Pro
- **Stuck power buttons** -- известный заводской дефект ("неправильно установленная кнопка питания")
- **Loose screws inside chassis** -- свободные винты внутри корпуса
- **Rear fan clicking noise** -- задний вентилятор шумит, сложно заменяется
- Soldered RAM (как у всех)
- "Mysterious performance switch" -- неясно как именно работает в [tech.yahoo](https://tech.yahoo.com/computing/articles/bosgame-m5-mini-pc-ryzen-183200183.html)

**Вердикт**: дёшево и сердито, но качество сборки -- лотерея. Подходит если networking ниже 10GbE приемлем и готов жить с возможным заводским дефектом.

**Источники**:

- [TechRadar review](https://www.techradar.com/computing/bosgame-m5-ai-mini-pc-review)
- [Guru3D review](https://www.guru3d.com/review/review-bosgame-m5-ai-mini-desktop-ryzen-ai-395/)
- [Notebookcheck review](https://www.notebookcheck.net/Mini-PC-with-AMD-Strix-Halo-and-128-GB-RAM-AMD-Ryzen-AI-Max-395-and-AMD-Radeon-8060S-impress-in-Bosgame-M5.1088558.0.html)
- [Strix Halo Wiki: Bosgame M5](https://strixhalo.wiki/Hardware/PCs/Bosgame_M5)
- [Starry Hope review](https://www.starryhope.com/minipcs/models/bosgame-m5/)

## 6. Corsair AI Workstation 300

Standard Sixunited плата, но с премиум-сборкой и liquid cooling. Запуск -- начало 2026.

| Параметр | Значение |
|----------|----------|
| Корпус | Премиум, classy compact |
| Охлаждение | **Liquid cooling** (единственный с water cooling в сегменте) |
| Сеть | Стандартное 2.5GbE + USB4 |
| Цена 2026 | $2299 → **$3399** (apr 2026, RAMpocalypse) |

**Плюсы**:

- Liquid cooling -- лучшее охлаждение в сегменте под длинной нагрузкой
- Premium quality control (Corsair бренд)
- Самый "classy" внешне -- дизайн под workstation

**Минусы**:

- **Резкий рост цены**: с $2299 до **$3399** в апреле 2026 из-за RAM shortage и геополитики
- 1TB вариант ушёл с $1999 до $2699 (+$700)
- Несмотря на liquid -- **под лёгкой нагрузкой шумнее чем DGX Spark** (по Tom's Hardware)
- Software stability issues упомянуты в Tom's Hardware review

**Вердикт**: красивый, но overpriced на текущем рынке. При $2300 был бы хорошим выбором, но за $3399 проще взять Mac M4 Max или DGX Spark.

**Источники**:

- [Tom's Hardware review](https://www.tomshardware.com/pc-components/gpus/corsair-ai-workstation-300-review)
- [Tom's Hardware: $3,399 price hike](https://www.tomshardware.com/desktops/mini-pcs/corsairs-strix-halo-ai-workstation-300-gets-even-more-expensive-amid-the-rampocalypse-ryzen-ai-max-395-flagship-now-sits-at-usd3-399)
- [PC Gamer review](https://www.pcgamer.com/hardware/gaming-pcs/corsairs-strix-halo-mini-pc-will-set-you-back-usd2-300-for-the-top-model-but-boring-old-ai-productivity-is-the-name-of-the-game/)

## 7. HP Z2 Mini G1a и HP ZBook Ultra G1a

Единственный крупный западный вендор. **Z2 Mini G1a** -- desktop mini-PC, **ZBook Ultra G1a 14"** -- mobile workstation laptop.

| Параметр | Z2 Mini G1a | ZBook Ultra G1a 14" |
|----------|-------------|---------------------|
| Форм-фактор | Mini-PC | 14" laptop, 3.46 lbs |
| TDP boost | до **160W** (overclocking) | 55-80W mobile envelope |
| ECC память | **да** (опция) | нет |
| Сеть | RJ45 + WiFi | WiFi 7 |
| ОС | Windows 11 Pro / Linux | Windows 11 Pro / Ubuntu certified |
| Цена 2026 | $2500-3500 | $4049 (128 GiB + 2TB) |

**Плюсы (общие)**:

- **Workstation-grade гарантия** + поддержка (Western vendor)
- **ECC память** опционально (Z2 Mini G1a) -- единственный в сегменте
- **Ubuntu certified** для Ryzen AI Max+ Pro 395 и Max 385 (ZBook)
- HP Z2 Mini G1a с 160W overclock -- самый агрессивный TDP в сегменте
- **Phoronix хвалит ZBook Ultra G1a** как "Incredible, Powerful Mobile Workstation" с Linux performance

**Минусы**:

- **HP Z2 Mini G1a -- noisier than Sixunited's cooling** (Strix Halo Wiki)
- **ZBook Ultra G1a -- дорого**: $4049 за 128GB конфигурацию
- **Непредсказуемое ценообразование** у HP (Strix Halo Wiki Buyer's Guide)
- ZBook -- mobile thermal envelope, gpt-oss-120B даёт всего **12.21 tok/s** ([StorageReview](https://www.storagereview.com/review/hp-zbook-ultra-g1a-14-review-all-the-ai-hype-not-enough-payoff))

**Вердикт**: рекомендуется при цене ниже $2500 (Z2 Mini G1a) благодаря гарантии и ECC. ZBook Ultra G1a -- если нужен ноутбук-workstation для AI-разработки (не основной inference-сервер).

**Источники**:

- [Phoronix review (ZBook Ultra G1a)](https://www.phoronix.com/review/hp-zbook-ultra-g1a)
- [StorageReview ZBook Ultra G1a](https://www.storagereview.com/review/hp-zbook-ultra-g1a-14-review-all-the-ai-hype-not-enough-payoff)
- [StorageReview HP Z2 Mini G1a](https://www.storagereview.com/review/hp-z2-mini-g1a-review-running-gpt-oss-120b-without-a-discrete-gpu)
- [Level1Techs forum: ZBook Ultra G1a](https://forum.level1techs.com/t/my-first-impression-on-hp-zbook-ultra-g1a-ryzen-ai-max-395-strix-halo-128-gb/232958)

## 8. Sapphire Edge AI Max+ 395 (Linked Dual)

Прототип -- двухсокетная конфигурация для 235B+ моделей. Embedded World 2026 / Computex 2026 launch.

| Параметр | Значение |
|----------|----------|
| Конфигурация | 2× Strix Halo node, **256 GiB total** |
| Соединение | USB-C (прототип) → dual LAN (целевая) |
| TDP | 140W (Sapphire showed at Embedded World 2026) |
| Цена | TBD (~$5000+ оценка) |

**Плюсы**:

- Единственная open-weight платформа для **235B-параметрических моделей** локально
- 256 GiB unified memory pool через linked nodes
- Подходит для RAG с длинным контекстом + большой моделью одновременно

**Минусы**:

- Прототип -- launch только Computex 2026 (Q2 2026)
- Inter-node link через USB-C -- bandwidth bottleneck (целевой dual LAN не реализован)
- ПО stack для linked configurations -- незрелый (нет llama.cpp поддержки multi-node out-of-box)
- Цена выше Mac M3 Ultra 192GB (который тоже умеет 235B, но один node)

**Вердикт**: пока не reality. После Computex 2026 + созревания software stack может быть единственный путь к 235B локально на Linux. Для production inference сейчас не подходит.

**Источники**:

- [Starry Hope: Sapphire Linked](https://www.starryhope.com/minipcs/sapphire-linked-strix-halo-mini-pc-cluster-llm-inference/)
- [VideoCardz](https://videocardz.com/newz/sapphire-shows-ryzen-ai-max-395-mini-pc-that-can-link-with-other-strix-halo-systems)
- [Lunar Computer review](https://lunar.computer/sapphire-shows-off-edge-ai-max-395-mini-pc-with-20260311)

## 9. Прочие игроки (FEVM FA-EX9, GEEKOM A9 Mega, NIMO AI MiniPC)

[Strix Halo Wiki](https://strixhalo.wiki/Hardware/PCs) перечисляет ещё несколько китайских mini-PC, все построены на той же **Sixunited AXB35** платформе. Без значимых отличий от GMKtec/Bosgame в hardware, мало review в западной прессе. Покупка -- лотерея аналогичная Bosgame, но без накопленной community базы знаний об их косяках.

## Сводная таблица: качество исполнения

| Vendor | Корпус | Охлаждение | Шум | Сборка |
|--------|--------|------------|-----|--------|
| **Meigao MS-S1 MAX** ⭐ | Алюминий | 6 heat pipes + dual turbine | средний (приглушённый) | премиум |
| Minisforum MS-S1 MAX | Алюминий + 2U rack | то же + sub-optimal fan curves | громкий idle, можно tune в UEFI | премиум |
| Beelink GTR9 Pro | Алюминий, Mac Studio-style | Vapor chamber + dual fans | **тихий** под нагрузкой | хорошее (после v2.2) |
| Framework Desktop | Модульный | Custom (есть fanless mods) | occasional PSU fan noise | хорошее |
| GMKtec EVO-X2 | Алюминий + пластик | Стандартное | громкий в Performance | среднее |
| Bosgame M5 | All-metal premium feel | Стандартное + задний вентилятор | clicking noise rear fan | среднее (заводские дефекты) |
| Corsair AI Workstation 300 | Premium classy | **Liquid cooling** | громче DGX Spark при low load | premium QC |
| HP Z2 Mini G1a | Workstation | Noisier than Sixunited | громкий | enterprise grade |

## Сводная таблица: Networking & I/O

| Vendor | Ethernet | USB | Wi-Fi | DisplayPort/HDMI |
|--------|----------|-----|-------|------------------|
| **Meigao/Minisforum MS-S1 MAX** | **2× 10GbE** | USB4 v2 + 3.2 + SD | -- | DP + HDMI |
| Beelink GTR9 Pro | **2× 10GbE** Intel(v1)/Realtek(v2.2) | USB4 + USB 3.1 + SD | Wi-Fi 6E | DP + HDMI |
| Framework Desktop | **2× 5GbE** | USB4 + expansion modules | Wi-Fi 6E | DP + HDMI + mDP (flaky) |
| GMKtec EVO-X2 | 2.5GbE | USB4 + SD | **Wi-Fi 7** | Quad 8K Display |
| Bosgame M5 | **только 2.5GbE** RTL8125 | 2× USB4 + 3.1 + SD | Wi-Fi 7 + BT 5.4 | HDMI 2.1 + DP 1.4 |
| Corsair AI Workstation 300 | 2.5GbE | USB4 | Wi-Fi 6E/7 | DP + HDMI |
| HP Z2 Mini G1a | RJ45 + опции | USB4 + USB-A | Wi-Fi | DP + HDMI |

**Networking-вывод**: для AI-cluster нужен **MS-S1 MAX или Beelink GTR9 Pro** (10GbE). Для одиночного inference-сервера 2.5GbE достаточно (модели не передаются по сети).

## Сводная таблица: BIOS-зрелость и Linux-совместимость

| Vendor | UMA slider | cTDP | Linux out-of-box | Известные Linux issues |
|--------|------------|------|-------------------|--------------------------|
| **Meigao MS-S1 MAX** ⭐ | да (AMI 1.06) | да (через cTDP) | да (kernel 6.18+) | 10GbE NIC unstable до 6.17.11 |
| Minisforum MS-S1 MAX | да | да | да | то же |
| Beelink GTR9 Pro | да | -- | да | v1: Intel E610 NIC crash под нагрузкой |
| Framework Desktop | -- | -- | **да** (Linux-first) | USB4+mDP flaky, AMD TPM sleep/wake |
| GMKtec EVO-X2 | да (Performance/Balanced/Quiet) | да | условно | **BIOS extremely limited**, updates "an adventure" |
| Bosgame M5 | да | "mysterious switch" | условно | заводские дефекты сборки |
| Corsair AI Workstation 300 | да | да | условно | software stability issues |
| HP Z2 Mini G1a / ZBook G1a | да | да | **Ubuntu certified** | -- |

## Сводная таблица: цена / гарантия

| Vendor | Базовая цена | Топ конфиг | Гарантия | Доступность |
|--------|--------------|------------|----------|--------------|
| Meigao MS-S1 MAX | -- | ~$2000 | 1 год (Китай) | Asia primarily |
| Minisforum MS-S1 MAX | $2400 (96GB) | $2700 (128GB) | 1-2 года | EU/US/Asia |
| Beelink GTR9 Pro | $2000 (96GB) | $3000 (128GB) | 1-3 года | EU/US/Asia |
| Framework Desktop | **$2000** | $2500+ | community-friendly RMA | NA/EU |
| GMKtec EVO-X2 | **$1700** (96GB) | $3000 (128GB) | 1 год (Китай) | global |
| Bosgame M5 | **$1699** pre-order (96GB) | $2599 (128GB) | 1 год | global |
| Corsair AI Workstation 300 | $2299 → **$3399** | до $4000 | стандартная Corsair | global |
| HP Z2 Mini G1a | $2500-3500 | -- | enterprise (3-5 лет) | global |
| HP ZBook Ultra G1a | -- | **$4049** (128GB+2TB) | enterprise (3-5 лет) | global |

## Известные косяки и их решение

Сводка проблем по форумам (r/LocalLLaMA, r/MiniPCs, ServeTheHome forums, Strix Halo Wiki):

| Косяк | Затронуты | Решение |
|-------|-----------|---------|
| EC fan control недоступен в Linux | Все Sixunited платы (GMKtec, Bosgame, Corsair и др.) + Meigao/Minisforum | Управлять только через BIOS, понизить cTDP. См. [bios-setup.md](bios-setup.md) |
| 10GbE NIC unstable на старых ядрах | Minisforum/Meigao MS-S1 MAX | Kernel 6.17.11+ или 6.18+ (наш 6.19.8 OK) |
| Intel E610 NIC crash под нагрузкой | Beelink GTR9 Pro v1 | Replacement program (v1 → v2.2 с Realtek) |
| USB4 + mDP flaky | Framework Desktop | Не использовать оба одновременно, only HDMI или only DP |
| AMD TPM unavailable после sleep/wake | Framework Desktop | Reboot, ждать kernel/firmware fix |
| BIOS extremely limited, updates "adventure" | GMKtec EVO-X2 | Vendor может молчать о новых BIOS, проверять форум |
| Stuck power button, loose screws, fan clicking | Bosgame M5 | RMA в первые дни эксплуатации |
| Outdated BIOS на ship | GMKtec и другие Sixunited | Update вручную сразу после распаковки |
| ROCm/HIP segfault при инференсе | Все Strix Halo (gfx1151) | Использовать **Vulkan backend** llama.cpp вместо ROCm. См. [rocm-setup.md](../inference/rocm-setup.md#статус-gfx1151-strix-halo) |
| KFD VRAM 15.5 GiB лимит | Все Strix Halo | `amdgpu.gttsize=131072 ttm.pages_limit=31457280` в kernel cmdline. См. [vram-allocation.md](vram-allocation.md) |
| Fan noise под полной нагрузкой | Все mini-PC формата | Понизить cTDP до 95W (`Balanced`), дать +5°C под throttle threshold |

## Как выбрать: decision tree

| Если приоритет... | Брать |
|--------------------|-------|
| **Лучший mix цена/качество** для AI inference | **Meigao MS-S1 MAX** (наш) или Minisforum MS-S1 MAX |
| **Dual 10GbE** для AI-cluster | Meigao/Minisforum MS-S1 MAX **или** Beelink GTR9 Pro v2.2 |
| **Minimum цена** | Bosgame M5 (96GB) или GMKtec EVO-X2 |
| **Linux first** + community + ремонтопригодность | Framework Desktop |
| **Тихая работа** под длинной нагрузкой | Beelink GTR9 Pro (vapor chamber) или Corsair (liquid) |
| **ECC память** + workstation-grade гарантия | HP Z2 Mini G1a |
| **Mobile workstation** для AI-разработки | HP ZBook Ultra G1a 14" |
| **235B+ модели локально** | Sapphire Linked Dual (после Computex 2026) |
| **Уверенность от западного бренда** | HP Z2 Mini G1a, Framework Desktop, Corsair AI Workstation 300 |
| **Premium QC от известного бренда** | Corsair AI Workstation 300 (если согласен на $3399) |

## Что отслеживать в 2026

- **Sapphire Linked Dual** -- launch на Computex 2026, потенциально 235B локально
- **HP Z2 Mini G1a price drops** -- если опустится ниже $2500, лучшая опция с гарантией
- **Beelink v3 платы** -- ожидаются с улучшенным охлаждением и 10GbE Intel return
- **Framework Desktop community-fanless mods** -- интересно для silent inference (см. [PC Gamer](https://www.pcgamer.com/hardware/this-striking-two-toned-mini-pc-features-a-fully-customised-fanless-cooling-system-for-framework-and-amds-new-halo-strix-motherboards/))
- **RAMpocalypse** -- цены LPDDR5X растут весной 2026, может стоит купить сейчас если планируется
- **Strix Point следующее поколение** (RDNA 4 APU, ~300 GB/s) -- 2027

## Связано

- [strix-halo-mini-pcs.md](strix-halo-mini-pcs.md) -- фокусированное сравнение mini-PC 128 GiB с финальной рекомендацией "какой купить"
- [hardware-alternatives.md](hardware-alternatives.md) -- Strix Halo как класс vs RTX 5090 / Mac M4/M3 / DGX Spark
- [server-spec.md](server-spec.md) -- наша конкретная конфигурация (Meigao MS-S1 MAX)
- [bios-setup.md](bios-setup.md) -- настройка BIOS под inference (Meigao-specific, частично применимо к Minisforum)
- [gpu-kernel-setup.md](gpu-kernel-setup.md) -- kernel parameters для всех Strix Halo mini-PC
- [vram-allocation.md](vram-allocation.md) -- KFD VRAM фикс (общий для всей платформы)
- [../inference/rocm-setup.md](../inference/rocm-setup.md#статус-gfx1151-strix-halo) -- статус ROCm на gfx1151
