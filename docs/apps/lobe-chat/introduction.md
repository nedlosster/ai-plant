# LobeChat: введение

## Что это

**LobeChat** -- AI-приложение с фокусом на дизайн и экосистему расширений. Построено на Next.js, предлагает markdown-first chat с Plugin Market (тысячи готовых плагинов) и Agents Market (готовые промпт-агенты). От команды LobeHub (изначально Lobe Technology), open-source, Apache 2.0.

Если [Open WebUI](../open-webui/README.md) -- это "self-hosted платформа с enterprise-фичами и Python extensibility", то LobeChat -- "красивый chat с отполированным UX и гигантским marketplace'ом готовых assistant'ов и плагинов". Обе хороши, но философии разные.

## Краткая история

- **Начало 2023** -- [Arvin Xu](https://github.com/arvinxx) запускает LobeChat как UI-проект, первоначально для себя. Фокус: pixel-perfect design, smooth animations, beautiful markdown
- **Середина 2023** -- community adoption, первые плагины, первый релиз 1.0
- **Конец 2023** -- LobeHub как зонтичная организация. LobeChat -- флагман, но появляются LobeUI (design system), LobeIcons, LobeFlow
- **2024** -- запуск **Plugin Market** и **Agents Market**. Сообщество активно публикует готовые агенты и плагины. Тысячи в каталоге через год
- **2024** -- поддержка **multi-provider**: OpenAI, Anthropic, Google, Ollama, Azure, AWS Bedrock, Groq, HuggingFace, Together, Fireworks и т.д.
- **2025** -- **LobeHub мета-repository**: `lobehub/lobehub` -- следующее поколение, где LobeChat становится частью большего agent collaboration framework. Идея: "не один чат, а команда агентов"
- **2026** -- **background tasks** (агенты могут выполнять долгие операции не блокируя conversation), **multi-agent collaboration**, assistants как unit of work interaction

## Философия

### 1. Design-first

LobeChat создавался дизайнером-first, программистом-second. Это видно во всём:
- **Smooth animations**: transitions между сообщениями, hover states, loading indicators -- всё плавное, с продуманным easing
- **Markdown рендеринг**: использует `@lobehub/ui` с fine-tuned typography, красивые code blocks, table rendering, math через KaTeX
- **Dark/light themes**: не просто цвета, а продуманные цветовые схемы с контрастом и гармонией
- **Icons**: собственная библиотека `lobe-icons` с консистентным стилем для AI-related концептов
- **Responsive**: работает отлично и на desktop, и на mobile

Это противоположность утилитарного подхода Open WebUI, где приоритет -- функциональность.

### 2. Marketplace ecosystem

**Plugin Market** и **Agents Market** -- основная уникальная черта:

- **Plugins**: функциональные модули, расширяющие способности LLM. Web search, image generation, academic search, document OCR, Bilibili API, Spotify, Steam, custom APIs -- тысячи готовых плагинов
- **Agents**: готовые промпт-конфигурации с системным промптом, описанием, примерами. "Писатель SF", "Code reviewer", "Данская учительница", "Юрист-консультант" и т.д. -- десятки тысяч агентов

Эти рынки -- **curated, open**: плагины/агенты от community проходят модерацию, публикуются в официальный `@lobehub/market-sdk`. Self-hosted инсталяции могут подключать к официальному marketplace или поднимать свой.

### 3. Multi-provider unified

LobeChat абстрагирует провайдеров. В настройках:
- OpenAI (cloud)
- Anthropic (cloud)
- Google (Gemini)
- **Ollama / llama-server (self-hosted)**
- Azure OpenAI
- AWS Bedrock
- Groq, Together, Fireworks, DeepSeek, Moonshot, Zhipu, Baichuan...

Для всех провайдеров -- единый интерфейс. Пользователь может в одном чате переключаться между Claude и локальным Qwen не меняя UX.

### 4. Three deployment paradigms

LobeChat работает в **трёх режимах deployment'а**:

1. **Cloud**: [chat.lobehub.com](https://chat.lobehub.com) -- managed версия для регистрации с bring-your-own-key
2. **Self-hosted**: Docker-контейнер на своём сервере (наш use-case на Strix Halo)
3. **Desktop**: Electron-приложение для Windows/Mac/Linux, локальные модели, standalone

Одна codebase покрывает все три. Это редкость в open-source chat-тулах.

## Позиционирование против Open WebUI

Это главный вопрос: зачем LobeChat, если есть Open WebUI?

| Критерий | LobeChat | Open WebUI |
|----------|----------|------------|
| **Философия** | Design + marketplace | Platform + extensibility |
| **Frontend** | Next.js (SSR hybrid) | SvelteKit SPA |
| **UX polish** | ★★★★★ | ★★★☆ |
| **Extensibility** | Plugin Market (готовые) | Functions + Pipelines (писать самому) |
| **RAG** | через плагины | встроенный, нативный |
| **Enterprise (RBAC/SSO)** | ограниченно | богато |
| **Multi-user** | есть, но проще | развито |
| **Deployment options** | Cloud / Self-hosted / Desktop | Self-hosted основной |
| **Python extensibility** | нет (TS/JS) | да |
| **Agent marketplace** | тысячи готовых | нет |
| **Core audience** | UX-conscious users, plugin consumers | Power users, teams, privacy-focused |

### Когда выбрать LobeChat

- Ценишь **красивый UI и smooth UX**
- Хочется **готовых agents и plugins из маркета**, а не писать свои
- Нужен **multi-deployment** (cloud + self-host + desktop)
- Активно используешь **разных providers** (несколько cloud LLM одновременно)
- Desktop-use case важнее browser-use case

### Когда выбрать Open WebUI

- Нужен **встроенный RAG** по документам
- Планируется **multi-user deployment** с enterprise-фичами (RBAC, SSO, audit)
- Готов **писать Python** для custom логики (Functions, Pipelines)
- **Privacy-first**, минимум внешних зависимостей
- Нужны **MCP servers** (native support в Open WebUI)

На нашей платформе (Strix Halo) обе работают хорошо. Типичный выбор:
- **Power user / админ / разработчик** -- Open WebUI (Functions, Pipelines, RAG)
- **Команда пользователей хочет красивый UI** -- LobeChat
- **Серверная машина + команда** -- Open WebUI (лучшая multi-user история)
- **Личное использование + качество UX** -- LobeChat

## Что даёт на Strix Halo

- **Chat-интерфейс поверх llama-server** через OpenAI-compat API
- **Multi-model в одном UI**: можно в одном сеансе переключаться между Qwen3-Coder Next, Qwen3.5-27B, Gemma 4, Claude cloud -- все в одном списке
- **Plugin Market**: десятки готовых плагинов (web search, math, image gen) работают с локальными моделями, поддерживающими function calling
- **Agents**: можно взять готового "code reviewer" или "English tutor" из маркета без написания промптов
- **Desktop app**: можно поставить LobeHub desktop и подключиться к Strix Halo как к "cloud" сервису через LAN

## Экосистема

| Компонент | Что это |
|-----------|---------|
| **[lobehub/lobe-chat](https://github.com/lobehub/lobe-chat)** | Основной chat-проект |
| **[lobehub/lobehub](https://github.com/lobehub/lobehub)** | Мета-repo следующего поколения, multi-agent framework |
| **[Plugin Market](https://lobehub.com/plugins)** | Curated marketplace плагинов |
| **[Agents Market](https://lobehub.com/agents)** | Curated marketplace готовых агентов |
| **[@lobehub/ui](https://github.com/lobehub/lobe-ui)** | Design system, используется в chat и других продуктах |
| **[@lobehub/icons](https://github.com/lobehub/lobe-icons)** | Icon library для AI-концептов |
| **[@lobehub/market-sdk](https://www.npmjs.com/package/@lobehub/market-sdk)** | SDK для self-hosted market server |
| **[LobeChat Docs](https://lobehub.com/docs)** | Официальная документация |

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [architecture.md](architecture.md) -- внутреннее устройство
- [simple-use-cases.md](simple-use-cases.md) -- базовые сценарии
- [advanced-use-cases.md](advanced-use-cases.md) -- Plugin Market, custom assistants, voice, image gen
- [../open-webui/introduction.md](../open-webui/introduction.md) -- альтернатива
- [../../inference/llama-cpp.md](../../inference/llama-cpp.md) -- backend на платформе
