# Deployment: Docker, security, production

Контекст: [README.md](README.md). OpenClaw -- self-hosted агент. Полный контроль
над данными и инфраструктурой, но ответственность за безопасность и обслуживание
лежит на операторе.

---

## Быстрый старт (Docker Compose)

### Требования

| Компонент | Минимум | Рекомендация |
|-----------|---------|-------------|
| Docker Engine | 20+ | 27+ |
| Docker Compose | v2 | v2.30+ |
| ОС | Linux, macOS, Windows (WSL2) | Linux (Ubuntu 22.04+) |
| RAM | 2 GiB | 4 GiB (без локальных моделей) |
| Диск | 50 GiB | 100 GiB+ для heavy use |
| Сеть | Стабильное подключение к API провайдера | -- |

### Минимальный docker-compose.yml

```yaml
version: '3.8'
services:
  openclaw:
    image: ghcr.io/openclaw/openclaw:latest
    ports:
      - "18789:18789"
    volumes:
      - openclaw-data:/data
      - ./config:/config
    environment:
      - OPENCLAW_CONFIG=/config/config.yaml
    restart: unless-stopped

volumes:
  openclaw-data:
```

### Первый запуск

```bash
# Клонирование репозитория (содержит примеры конфигурации)
git clone https://github.com/openclaw/openclaw
cd openclaw

# Запуск с pre-built image
export OPENCLAW_IMAGE="ghcr.io/openclaw/openclaw:latest"
docker compose up -d
```

### Проверка

```bash
# Health check
curl http://localhost:18789/health

# WebChat UI
# Открыть в браузере: http://localhost:18789
```

При первом запуске WebChat предложит настроить провайдер модели
(см. [models-providers.md](models-providers.md)).

---

## Архитектура deployment

### Компоненты

| Компонент | Назначение | Порт |
|-----------|-----------|------|
| Gateway | Control plane, WebChat UI, API | 18789 |
| Agent Sessions | Изолированные сессии для каждого разговора | Internal |
| Channel Adapters | Мосты к мессенджерам (WhatsApp bridge, Slack bot) | Internal |
| Tool Workers | Выполнение MCP tools и Computer Use actions | Internal |

Все компоненты запускаются в одном контейнере. Gateway -- единственный
публичный endpoint.

### Volumes

| Mount point | Содержимое | Persistence |
|------------|-----------|-------------|
| `/data` | Sessions, history, memory, state | Обязательно |
| `/config` | Конфигурация: providers, channels, skills | Обязательно |
| `/logs` | Runtime логи | Опционально |

### Порты

По умолчанию используется один порт -- 18789. Через него доступны:
- WebChat UI (HTTP)
- WebSocket connections для real-time
- REST API для программного доступа
- Health endpoint (`/health`)

---

## Security

### CVE-2026-25253 и уроки

В марте 2026 обнаружена уязвимость CVE-2026-25253:
- WebSocket origin header bypass -- позволяет RCE через crafted page
- CVSS 8.8 (High)
- Затронутые версии: до 0.9.3

**Выводы:**

1. Обновлять image при каждом релизе.
2. Не выставлять порт 18789 в публичный интернет без reverse proxy.
3. Sandboxing -- не опция, а требование.

### Network isolation

Ограничение доступа только localhost:

```yaml
services:
  openclaw:
    networks:
      - internal
    ports:
      - "127.0.0.1:18789:18789"  # только localhost
networks:
  internal:
    driver: bridge
```

Доступ извне -- только через reverse proxy с аутентификацией.

### Container hardening

```yaml
services:
  openclaw:
    user: "1000:1000"        # не root
    cap_drop: [ALL]
    read_only: true
    tmpfs: ["/tmp:size=500M"]
    volumes:
      - openclaw-data:/data
      - ./config:/config:ro  # config read-only
```

### Computer Use: изоляция

При использовании Computer Use -- запускать Xvfb (virtual framebuffer)
или отдельную VM. Не монтировать host X11 (`/tmp/.X11-unix`).
Подробнее: [computer-use-guide.md](computer-use-guide.md).

### API keys

Хранить через environment variables (`.env` с `chmod 600`, не в git).
Для Swarm/K8s -- Docker secrets. Для каждой интеграции -- минимальные scopes

---

## Persistence

### Стратегия volumes

| Volume | Содержимое | Backup | Размер |
|--------|-----------|--------|--------|
| `/data` | Sessions, memory, history | Ежедневно | 1-50 GiB |
| `/config` | Config files | В git | < 1 MiB |
| `/logs` | Runtime логи | Ротация | 100 MiB-1 GiB |

### Backup и восстановление

```bash
# Backup (с остановкой для консистентности)
docker compose stop
tar czf openclaw-backup-$(date +%Y%m%d).tar.gz ./data ./config
docker compose start

# Восстановление
docker compose down && rm -rf ./data
tar xzf openclaw-backup-YYYYMMDD.tar.gz && docker compose up -d
```

Для zero-downtime -- volume snapshots (ZFS, LVM, btrfs)

---

## Production deployment

### Reverse proxy

Рекомендуется Caddy (auto-TLS, WebSocket upgrade из коробки):
```
openclaw.local {
    reverse_proxy localhost:18789
    tls internal
}
```

Для nginx -- обязательно настроить WebSocket upgrade:
```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_read_timeout 86400;
```

HTTPS обязателен для production (wss://, API tokens в headers).

### Health checks и resource limits

```yaml
services:
  openclaw:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "3"
```

---

## Обновление

### Процедура обновления

```bash
docker compose pull && docker compose up -d
```

Перед обновлением: прочитать release notes, backup data volume.
OpenClaw автоматически мигрирует `/data`. При ошибке -- восстановить backup,
откатить image на предыдущую версию

---

## Deployment на ai-plant сервере (Strix Halo)

### Специфика платформы

| Параметр | Значение |
|----------|---------|
| CPU | AMD Ryzen AI Max+ 395 (Strix Halo) |
| RAM / VRAM | 96 GiB unified (shared CPU/GPU) |
| GPU backend | Vulkan (ROCm ограничен, см. [rocm-setup.md](../../../inference/rocm-setup.md)) |
| Inference | llama-server + Vulkan |
| Адрес | 192.168.1.77 |
| Inference порт | 8081 |

### Связка OpenClaw + локальный llama-server

OpenClaw как frontend агент, llama-server как backend на том же хосте:

```yaml
services:
  openclaw:
    image: ghcr.io/openclaw/openclaw:latest
    ports:
      - "18789:18789"
    environment:
      - DEFAULT_PROVIDER=openai-compatible
      - OPENAI_COMPATIBLE_BASE_URL=http://host.docker.internal:8081/v1
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - openclaw-data:/data
      - ./config:/config
    restart: unless-stopped
volumes:
  openclaw-data:
```

Альтернатива: `network_mode: host` (проще, но менее изолировано).

### Конфигурация моделей для Strix Halo

| Задача | Модель | Размер (Q4_K_M) | Карточка |
|--------|--------|----------------|----------|
| Coding, tool use | Qwen3-Coder Next | ~45 GiB | [qwen3-coder.md](../../../models/families/qwen3-coder.md) |
| Coding (альт.) | Devstral 2 | ~40 GiB | [devstral2.md](../../../models/families/devstral.md) |
| Vision (Computer Use) | InternVL3-38B | ~22 GiB | [internvl.md](../../../models/families/internvl.md) |
| Vision (альт.) | Gemma 4 | ~20 GiB | [gemma4.md](../../../models/families/gemma4.md) |

Пресеты запуска: [`scripts/inference/vulkan/preset/`](../../../../scripts/inference/vulkan/preset/)

### Одновременный запуск нескольких моделей

96 GiB VRAM позволяет запускать одновременно coding-модель и vision-модель:

- Qwen3-Coder Next Q4_K_M (~45 GiB) + InternVL3-38B Q4_K_M (~22 GiB) = ~67 GiB
- Остаётся ~29 GiB для KV cache и системных нужд

Для этого llama-server запускается на разных портах:
```bash
# Coding модель на порту 8081
# Vision модель на порту 8082
```

Конфигурация OpenClaw для двух endpoint:
```yaml
providers:
  coding:
    type: openai-compatible
    base_url: "http://localhost:8081/v1"
    default_model: "qwen3-coder-next"
  vision:
    type: openai-compatible
    base_url: "http://localhost:8082/v1"
    default_model: "internvl3-38b"
```

### Полный production docker-compose.yml

Пример с hardening, health checks, resource limits:

```yaml
version: '3.8'
services:
  openclaw:
    image: ghcr.io/openclaw/openclaw:latest
    user: "1000:1000"
    read_only: true
    cap_drop: [ALL]
    tmpfs: ["/tmp:size=500M"]
    ports:
      - "127.0.0.1:18789:18789"
    volumes:
      - openclaw-data:/data
      - ./config:/config:ro
    env_file: .env
    environment:
      - OPENCLAW_CONFIG=/config/config.yaml
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "3"
    restart: unless-stopped
    networks:
      - internal

networks:
  internal:
    driver: bridge

volumes:
  openclaw-data:
```

---

## Troubleshooting

### Контейнер не запускается

```bash
ss -tlnp | grep 18789           # порт занят?
docker compose logs openclaw     # ошибки в логах
ls -la ./data ./config           # права на volumes
```

### Нет подключения к API провайдера

```bash
docker exec openclaw nslookup api.moonshot.cn
docker exec openclaw curl -s https://api.moonshot.cn/v1/models \
  -H "Authorization: Bearer ${KIMI_API_KEY}"
```

Частые причины: firewall, невалидный API key, DNS failure в контейнере.

### Нет подключения к локальному llama-server

```bash
curl http://192.168.1.77:8081/health
docker exec openclaw curl http://host.docker.internal:8081/health
```

Частые причины: llama-server не запущен, неправильный `extra_hosts`, firewall.

### Channel не подключается

Проверить логи: `docker compose logs openclaw | grep -i "slack\|telegram"`.
Частые причины: невалидный token, webhook URL недоступен извне, scopes.

### High memory

```bash
docker stats openclaw --no-stream
```

Решения: установить `deploy.resources.limits.memory`, уменьшить concurrent sessions.

### WebSocket disconnects

Проверить reverse proxy: WebSocket upgrade headers, timeout (min 86400 для nginx).

---

## Связанные статьи

- [README.md](README.md) -- профиль OpenClaw
- [computer-use-guide.md](computer-use-guide.md) -- Computer Use и X11 setup
- [models-providers.md](models-providers.md) -- настройка провайдеров моделей
- [integrations-guide.md](integrations-guide.md) -- настройка каналов и MCP
- [Inference стек](../../../inference/README.md) -- llama-server и backend
- [Платформа](../../../platform/README.md) -- спецификация Strix Halo
