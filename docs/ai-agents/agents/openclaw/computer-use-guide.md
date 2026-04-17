# Computer Use: управление экраном, мышью, клавиатурой

Контекст: OpenClaw поддерживает полноценный desktop control -- не только browser automation (как Cline), а управление любым приложением через GUI. Профиль продукта -- [README.md](README.md).

---

## Что такое Computer Use

**Определение**: программный контроль графического интерфейса через цепочку screen capture, vision model, action planning, input injection. Агент "видит" экран через скриншот, анализирует его через VLM, планирует действие и выполняет его через injection ввода.

**Отличие от browser-only подхода (Cline browser use)**: OpenClaw контролирует весь desktop -- терминал, IDE, почтовый клиент, файловый менеджер, legacy-приложения. Cline ограничен browser-контекстом через Playwright/Puppeteer.

**Отличие от Anthropic Computer Use (API-based)**: OpenClaw реализует аналогичный подход -- screen capture + vision + action -- но open-source, self-hosted, model-agnostic. Anthropic Computer Use привязан к Claude API и работает только через облачную инфраструктуру Anthropic.

---

## Архитектура Computer Use

### Pipeline

Основной цикл работы Computer Use:

```
Screen capture (scrot)
    |
    v
Screenshot (PNG)
    |
    v
Vision model (любая VLM: Qwen3-VL, InternVL, Gemma 4, cloud API)
    |
    v
Action plan (structured action primitive)
    |
    v
Input injection (xdotool / wmctrl / xclip)
    |
    v
[следующая итерация цикла]
```

Цикл повторяется до достижения цели или превышения лимита итераций. Каждая итерация -- один screenshot + один или несколько action primitives.

### Structured action primitives

OpenClaw использует structured action primitives -- типизированные команды с параметрами. Это не произвольный текст, а конкретные действия с валидацией.

Категории:

- `click` -- клик мышью (left, right, middle)
- `type` -- ввод текстовой строки
- `scroll` -- прокрутка
- `navigate` -- переход (URL, файл, приложение)
- `extract` -- извлечение данных со скриншота

### Action types (полный перечень)

**Mouse**:

| Action | Параметры | Описание |
|--------|-----------|----------|
| click | x, y, button (left/right/middle) | Клик по координатам |
| double-click | x, y | Двойной клик |
| drag | from_x, from_y, to_x, to_y | Drag and drop |
| scroll | direction (up/down/left/right), amount | Прокрутка |
| hover | x, y | Перемещение курсора без клика |
| move | x, y, mode (absolute/relative) | Перемещение курсора |

**Keyboard**:

| Action | Параметры | Описание |
|--------|-----------|----------|
| type | text | Ввод строки текста |
| key | keyname | Нажатие одной клавиши (Return, Escape, Tab) |
| hotkey | keys[] | Комбинация клавиш (Ctrl+C, Alt+Tab, Ctrl+Shift+S) |
| shortcut_sequence | sequence[] | Последовательность hotkey с задержками |

**Screen**:

| Action | Параметры | Описание |
|--------|-----------|----------|
| screenshot | region (optional) | Полный скриншот или указанная область |
| element_detect | description | Поиск UI-элемента по описанию через VLM |
| ocr | region (optional) | Извлечение текста из области экрана |
| window_list | -- | Перечисление открытых окон (wmctrl) |

**Clipboard**:

| Action | Параметры | Описание |
|--------|-----------|----------|
| copy | -- | Ctrl+C |
| paste | -- | Ctrl+V |
| read_clipboard | -- | Чтение содержимого clipboard (xclip) |

### Инструменты

| Инструмент | Назначение | Пакет |
|------------|------------|-------|
| [xdotool](https://github.com/jordansissel/xdotool) | Ввод мыши/клавиатуры, управление окнами (focus, move, resize) | `xdotool` |
| [scrot](https://github.com/resurrecting-open-source-projects/scrot) | Создание скриншотов (full screen, region, window) | `scrot` |
| [wmctrl](https://www.freedesktop.org/wiki/Software/wmctrl/) | Управление окнами: move, resize, focus, minimize, list | `wmctrl` |
| [dogtail](https://gitlab.com/dogtail/dogtail) | Accessibility API для UI-элементов (GTK/Qt) через AT-SPI | `python3-dogtail` |
| [xclip](https://github.com/astrand/xclip) | Clipboard: read/write selections (primary, secondary, clipboard) | `xclip` |

### Skills для Computer Use

OpenClaw реализует Computer Use через систему Skills:

- **Desktop Control 1.0.0** -- полноценный Linux desktop control. Включает xdotool + wmctrl + dogtail + scrot + xclip. Поддерживает все action types. Работает в цикле screenshot-action.

- **Claw Mouse** -- облегчённый вариант, только mouse control. Без keyboard input, без clipboard, без window management. Подходит для задач где нужен только визуальный контроль и клики.

---

## Настройка Computer Use

### Системные требования

- Linux с X11 display server (Xorg)
- Wayland: частичная поддержка через XWayland (ограничения описаны в [Troubleshooting](#wayland-xdotool-не-работает))
- Установленные пакеты: xdotool, scrot, wmctrl, xclip
- Vision-capable модель: локальная VLM (Qwen3-VL, InternVL, Gemma 4) или cloud vision API
- Docker с X11 forwarding (при containerized deployment)
- Разрешение экрана: рекомендуется 1920x1080 (стандартное разрешение для стабильного coordinate mapping)

### Установка зависимостей

```bash
# Debian/Ubuntu
apt install -y xdotool scrot wmctrl xclip python3-dogtail

# Fedora
dnf install -y xdotool scrot wmctrl xclip python3-dogtail

# Arch
pacman -S xdotool scrot wmctrl xclip
# dogtail -- через AUR
```

### Docker setup

Базовый запуск с X11 forwarding:

```bash
docker run -d \
  --name openclaw-desktop \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $HOME/.Xauthority:/root/.Xauthority \
  --network host \
  ghcr.io/openclaw/openclaw:latest
```

Разрешение доступа к X server для контейнера:

```bash
xhost +local:docker
```

**Важно**: комбинация `--network host` + X11 socket mount + Xauthority = полный доступ к display хоста. Security implications описаны в разделе [Safety](#safety-критическая-секция).

Изолированный вариант с виртуальным display (Xvfb):

```bash
docker run -d \
  --name openclaw-sandbox \
  -e DISPLAY=:99 \
  ghcr.io/openclaw/openclaw:latest \
  bash -c "Xvfb :99 -screen 0 1920x1080x24 & openclaw start"
```

Этот вариант не даёт агенту доступ к реальному display хоста.

### Permissions

| Инструмент | Требуемый доступ |
|------------|-----------------|
| xdotool | X server (через DISPLAY + Xauthority) |
| wmctrl | X server (через DISPLAY + Xauthority) |
| scrot | Read-only доступ к framebuffer через X server |
| dogtail | AT-SPI accessibility interface (D-Bus session bus) |
| xclip | X server selections |

Для работы dogtail необходимо включить AT-SPI:

```bash
# Проверка
dbus-send --session --dest=org.a11y.Bus \
  --type=method_call --print-reply \
  /org/a11y/bus org.a11y.Bus.GetAddress

# Включение (если отключено)
gsettings set org.gnome.desktop.interface toolkit-accessibility true
```

### Включение Computer Use

В конфигурации OpenClaw:

```yaml
# openclaw.yaml
skills:
  - name: "Desktop Control"
    version: "1.0.0"
    enabled: true

vision:
  # Локальная VLM (рекомендуется для privacy)
  model: "qwen3-vl-72b"
  endpoint: "http://localhost:8080/v1"

  # Или cloud API
  # model: "gpt-4o"
  # endpoint: "https://api.openai.com/v1"
  # api_key: "${OPENAI_API_KEY}"

screen:
  width: 1920
  height: 1080
  capture_interval_ms: 500
  max_iterations: 100
```

---

## Практические сценарии

### UI тестирование

Агент проходит user flow в браузере или desktop-приложении: открыть URL, заполнить форму, нажать кнопку, проверить результат, сделать скриншот.

Пример workflow:

1. Открыть Firefox: `xdotool key super`, `xdotool type firefox`, `xdotool key Return`
2. Перейти на URL: click по address bar, type URL, Enter
3. Заполнить форму: click по полю, type текст, Tab к следующему полю
4. Нажать Submit: click по кнопке
5. Screenshot результата -- vision model анализирует содержимое страницы
6. Генерация отчёта: pass/fail + скриншот + описание расхождений

Преимущество перед Playwright/Puppeteer: работает с любым браузером (включая Electron-приложения), не требует инструментации.

### Legacy system automation

Работа с приложениями без API -- ERP-системы, legacy desktop apps, проприетарные клиенты баз данных.

Типичный сценарий: агент открывает legacy-приложение, навигирует по menu, заполняет формы, экспортирует отчёт. Всё через screen capture + input injection, без модификации целевого приложения.

### Data extraction

Screenshot -> OCR -> structured data. Применение:

- Dashboard'ы, которые не экспортируют данные (Grafana screenshots, проприетарные BI)
- Документы в image-формате (сканы, PDF без text layer)
- Данные из UI-элементов без доступного API

### Multi-app workflow

Связка нескольких приложений через screen control:

Пример: получить ошибку в терминале -> открыть файл в IDE -> исправить -> перезапустить сервис -> проверить в браузере -> отписать результат в Slack.

Каждый переход между приложениями -- через Alt+Tab или wmctrl, каждое действие -- через xdotool. Агент ориентируется по скриншотам.

### Screen monitoring

Continuous monitoring: агент периодически делает скриншоты, анализирует через vision model, реагирует на изменения.

Примеры реакций:

- Alert в чат при появлении ошибки на dashboard
- Запуск recovery-скрипта при обнаружении crash-диалога
- Логирование состояния UI с timestamp'ами

Конфигурация:

```yaml
monitoring:
  interval_seconds: 30
  conditions:
    - pattern: "error|critical|failed"
      action: "notify_slack"
    - pattern: "disk.*full"
      action: "run_script cleanup.sh"
```

---

## Safety (критическая секция)

### Риски Computer Use

| Риск | Описание | Вероятность |
|------|----------|-------------|
| Непреднамеренный клик | Агент "промахивается" мышью по coordinate из-за ошибки VLM | Высокая |
| Деструктивные действия | Удаление файлов, отправка сообщений, закрытие unsaved работы | Средняя |
| Credential exposure | Скриншот содержит пароли/ключи, передаётся в cloud model | Высокая |
| RCE-уязвимости | CVE-2026-25253: WebSocket origin bypass, CVSS 8.8 | Критическая |
| Lateral movement | Agent с доступом к X11 может контролировать всё на display | Высокая |
| Resource exhaustion | Runaway agent: бесконечный цикл screenshot-action, 100% CPU | Средняя |
| Data exfiltration | Agent отправляет screenshot с sensitive data на внешний endpoint | Средняя |

### CVE-2026-25253: Remote Code Execution

- **Тип**: WebSocket origin header validation bypass
- **CVSS**: 8.8 (High)
- **Вектор**: удалённый атакующий обходит проверку origin header в WebSocket-соединении к OpenClaw server
- **Импакт**: исполнение произвольного кода на машине с запущенным OpenClaw
- **Условие**: OpenClaw WebSocket endpoint доступен из сети (не localhost-only)
- **Статус**: исправлено в последующих версиях
- **Действие**: обновить до последней версии OpenClaw. Проверить, что WebSocket endpoint не exposed в публичную сеть.

Урок: self-hosted agent с computer use -- привлекательная мишень для атак. WebSocket endpoint, управляющий мышью и клавиатурой -- это фактически remote desktop без аутентификации при отсутствии proper origin validation.

### Sandboxing

OpenClaw позиционирует sandboxing как first-class feature -- agent execution в isolated environments.

Варианты изоляции:

| Метод | Уровень изоляции | Overhead |
|-------|-----------------|----------|
| Docker container | Процесс | Низкий |
| Docker + Xvfb | Процесс + display | Низкий |
| VM (QEMU/KVM) | Полная | Средний |
| Nested VM | Максимальная | Высокий |

Рекомендация: минимум -- Docker container с виртуальным display (Xvfb). Для работы с sensitive данными -- VM.

### Mitigation стратегии

1. **Sandbox environment**: запускать OpenClaw в VM или container с минимальными permissions. Не давать доступ к реальному display хоста.

2. **Screen region restrictions**: ограничить область экрана, доступную агенту. Агент может взаимодействовать только с указанным окном или регионом.

3. **Action whitelist**: разрешить только определённые типы действий. Запретить: удаление файлов, отправку сообщений, выполнение sudo-команд. Реализуется через policy в конфигурации.

4. **Confirmation prompts**: требовать подтверждение пользователя для деструктивных действий (delete, send, close unsaved). Агент ставит действие на паузу и ждёт approve.

5. **Vision model privacy**: использовать локальную VLM (Qwen3-VL, InternVL) вместо cloud API. Скриншоты остаются на локальной машине и не передаются третьим сторонам.

6. **Network isolation**: контейнер без доступа в интернет, кроме API endpoint'а модели. Предотвращает data exfiltration.

7. **Audit log**: логирование всех action'ов с timestamp'ами, координатами, скриншотами до и после. Полная трассировка для post-mortem анализа.

### Best practices

1. Не запускать Computer Use на production-машине с real credentials. Использовать dedicated sandbox environment.

2. Создать отдельный user account без sudo-прав. Агент работает от непривилегированного пользователя.

3. Закрыть все sensitive приложения перед запуском агента. Password manager, email с конфиденциальной перепиской, banking -- всё должно быть закрыто.

4. При использовании cloud vision model -- убедиться, что скриншоты не содержат credentials, API keys, personal data. Всё, что видит агент, передаётся в model endpoint.

5. Ограничить session duration. Рекомендуемый максимум -- 30 минут. Таймер предотвращает runaway agent.

6. Регулярно обновлять OpenClaw. CVE-2026-25253 -- пример критической уязвимости, обнаруженной в production.

7. Мониторить resource usage (CPU, memory, network). Аномальное потребление -- признак runaway agent или компрометации.

---

## Computer Use: OpenClaw vs Anthropic Computer Use vs Cline Browser

| Критерий | OpenClaw | Anthropic Computer Use | Cline Browser |
|----------|----------|----------------------|---------------|
| Scope | Full desktop (X11) | Full desktop (API) | Browser only |
| Open source | да | нет | да |
| Self-hosted | да | нет (cloud API) | да (VS Code extension) |
| Vision model | любая VLM | Claude only | любая |
| Sandbox | Docker/VM/Xvfb | Anthropic sandbox | Browser sandbox |
| Input method | xdotool, wmctrl, dogtail | API actions | Playwright/Puppeteer |
| OS support | Linux (X11) | Linux, macOS, Windows | Cross-platform (browser) |
| Security model | Self-maintained, CVE history | Anthropic-maintained | Browser-level sandbox |
| Latency | Зависит от VLM (local: низкая) | Cloud API latency | Низкая (DOM, не vision) |
| Accuracy | Зависит от VLM и разрешения | Высокая (Claude vision) | Высокая (DOM selectors) |

Ключевое отличие: Cline Browser работает через DOM (programmatic access к элементам страницы), OpenClaw и Anthropic Computer Use -- через vision (screenshot analysis). Vision-подход универсальнее (работает с любым GUI), но менее точен и медленнее.

---

## Troubleshooting

### Screenshot чёрный / пустой

Причины:

- Переменная `DISPLAY` не установлена или указывает на несуществующий display
- X11 socket не смонтирован в контейнер
- Xauthority cookie не совпадает

Решение:

```bash
# Проверить DISPLAY
echo $DISPLAY
# Ожидается: :0 или :1

# Проверить доступ к X server
xdpyinfo | head -5

# Для Docker: разрешить доступ
xhost +local:docker

# Проверить Xauthority
xauth list
```

### Клик попадает не туда

Причины:

- Resolution mismatch: screenshot сделан в одном разрешении, а координаты рассчитаны для другого
- HiDPI scaling не учтён (например, scale factor 2x -- координаты нужно умножить на 2)
- Окно переместилось между screenshot и click

Решение:

```bash
# Указать разрешение явно в конфигурации
screen:
  width: 1920
  height: 1080

# Проверить текущее разрешение
xdpyinfo | grep dimensions

# Проверить scale factor
xrdb -query | grep dpi
```

### Медленный response

Причины:

- Vision model latency (cloud API: 2-5 секунд на запрос)
- Большой размер screenshot (4K разрешение = большой PNG)

Решение:

- Использовать локальную VLM (InternVL, Qwen3-VL) -- latency 0.5-1 сек
- Уменьшить разрешение screenshot до 1920x1080
- Увеличить capture_interval_ms для снижения нагрузки

### xdotool: command not found

```bash
# Установить все необходимые пакеты
apt install -y xdotool scrot wmctrl xclip

# Проверить установку
which xdotool scrot wmctrl xclip
```

### Wayland: xdotool не работает

xdotool использует X11 protocol (XTest extension) и не работает в native Wayland.

Варианты решения:

- Запускать целевое приложение в XWayland-совместимом режиме (большинство GTK/Qt приложений поддерживают `GDK_BACKEND=x11`)
- Использовать [ydotool](https://github.com/ReimuNotMoe/ydotool) -- аналог xdotool для Wayland (работает через /dev/uinput)
- Запускать OpenClaw в Xvfb-контейнере (полностью X11-среда)

```bash
# Принудительный запуск приложения в X11 mode
GDK_BACKEND=x11 firefox

# ydotool (Wayland-native)
apt install ydotool
ydotool click 0xC0 --repeat 1
```

### dogtail: AT-SPI не доступен

```bash
# Включить accessibility
gsettings set org.gnome.desktop.interface toolkit-accessibility true

# Перезапустить D-Bus session
dbus-update-activation-environment --all

# Проверить AT-SPI bus
python3 -c "import dogtail; dogtail.utils.enableA11y()"
```

---

## Связанные статьи

- [README.md](README.md) -- профиль OpenClaw, архитектура, экосистема
- [deployment-guide.md](deployment-guide.md) -- Docker setup с X11 forwarding, production deployment
- [news.md](news.md) -- CVE-2026-25253, релизы, события
- [Anthropic Computer Use](../claude-code/README.md) -- конкурент (cloud-based desktop control)
- [Vision-модели](../../../models/vision.md) -- VLM для screenshot analysis
