# Open WebUI: простые сценарии

Базовые сценарии использования Open WebUI на Strix Halo. Предполагается что установка выполнена через [`scripts/webui/open-webui/install.sh`](../../../scripts/webui/open-webui/install.sh) и сервер запущен.

## Предусловия

1. **Inference backend запущен**: llama-server слушает на `localhost:8081` (или другом порту согласно [`scripts/inference/start-server.sh`](../../../scripts/inference/start-server.sh))
2. **Open WebUI контейнер запущен**: [`scripts/webui/open-webui/start.sh`](../../../scripts/webui/open-webui/start.sh)
3. **Веб-UI доступен**: `http://<SERVER_IP>:3210`
4. **Аккаунт создан**: при первом запуске регистрация admin-пользователя (local account)

## 1. Первый чат с локальной моделью

**Задача**: задать вопрос модели и получить ответ.

### Шаги

1. Открыть `http://<SERVER_IP>:3210`
2. Войти (email + password, admin-аккаунт создан при первом запуске)
3. В sidebar слева кликнуть "**New Chat**"
4. Вверху выбрать модель в dropdown (например "qwen3-coder-next")
5. В поле ввода написать промпт: "Объясни что такое mutex в Python"
6. Enter или кнопка отправки

Ответ приходит streaming'ом, текст появляется символ за символом. После завершения чат сохраняется в sidebar слева.

### Что происходит под капотом

1. Frontend отправляет POST `/api/chat` в backend с JWT
2. Backend валидирует, проверяет RBAC
3. Backend отправляет запрос в llama-server по OpenAI-compat API (`POST /v1/chat/completions`)
4. llama-server генерирует ответ токен за токеном, возвращает как SSE stream
5. Backend Open WebUI проксирует stream в frontend через WebSocket
6. Frontend дорисовывает текст в UI
7. После завершения, пара `user→assistant` сохраняется в SQLite

## 2. Переключение между моделями

**Задача**: в одном сеансе использовать разные модели для разных задач.

### Шаги

1. В текущем чате кликнуть на dropdown модели вверху
2. Выбрать другую модель из списка
3. Следующие сообщения идут через новую модель

### Важные детали

- **История чата сохраняется** -- новая модель видит весь предыдущий контекст
- **Модели должны быть запущены**: у llama-server обычно одна модель на один экземпляр. Для переключения между моделями нужно либо запустить несколько llama-server'ов на разных портах, либо использовать Ollama (автоматически выгружает/загружает)

### Рекомендованная настройка на Strix Halo

Запустить несколько `llama-server` через `start-server.sh`, каждый на своём порту, и зарегистрировать их в Open WebUI как отдельные connections:

```bash
# Chat модель
./scripts/inference/start-server.sh qwen3.5-122b-a10b.gguf --port 8081 --daemon

# Coding модель
./scripts/inference/start-server.sh qwen3-coder-next.gguf --port 8082 --daemon

# Vision модель
./scripts/inference/start-server.sh gemma4.gguf --port 8083 --daemon
```

В Open WebUI → Admin Panel → Settings → Connections → добавить каждый как "OpenAI API" connection с соответствующим `Base URL`.

## 3. Редактирование и regenerate

**Задача**: получить лучший ответ, изменив свой вопрос или перезапустив генерацию.

### Редактирование user-сообщения

1. Навести на собственное сообщение → появляется иконка "редактировать" (карандаш)
2. Изменить текст
3. Нажать "Save & Submit" → новый ответ генерируется с обновлённым промптом

Это создаёт **branch** в чате -- оригинальное сообщение не теряется, оно доступно через переключение версий.

### Regenerate ответа

1. Навести на assistant-сообщение → иконка "regenerate" (круговая стрелка)
2. Ответ генерируется заново с тем же промптом (но другим seed -- получается другой результат)

Полезно для:
- Получения альтернативных формулировок
- Когда модель "забуксовала" и даёт низкокачественный ответ
- Для creative writing -- посмотреть разные варианты

### Навигация между версиями

Если в чате есть branches (из-за редактирования / regenerate), под сообщением появляются стрелки "1/3" -- можно листать между версиями.

## 4. Сохранённые промпты (Prompts)

**Задача**: переиспользовать часто используемые промпты без копипаста.

### Создание

1. Settings → Prompts → "+"
2. Title: "Code review"
3. Command: `/review`
4. Content:
   ```
   You are a senior code reviewer. Review the following code for:
   1. Correctness
   2. Security vulnerabilities
   3. Performance issues
   4. Style
   Provide specific line-by-line feedback.
   ```
5. Save

### Использование

В чате набрать `/review` → слот автоматически заполняется сохранённым текстом. Осталось добавить код для ревью.

Prompts -- это фактически **snippets** для часто используемых инструкций.

## 5. Загрузка документов и RAG (простой случай)

**Задача**: спросить вопрос по содержимому PDF/DOCX, не скармливая его в промпт вручную.

### Шаги

1. В чате кликнуть иконку скрепки "Attach file"
2. Выбрать `my_manual.pdf` (5 MB, 50 страниц)
3. Подождать пока файл обработается (чанкинг + embedding) -- обычно 10-30 секунд
4. Задать вопрос: "На какой странице написано про конфигурацию SSL?"

### Что происходит под капотом

1. PDF парсится через PyPDF (text extraction)
2. Текст разбивается на chunks (~500 токенов с 50 токенов overlap)
3. Каждый chunk векторизуется через embedding model (default `sentence-transformers/all-MiniLM-L6-v2`)
4. Chunks с embeddings сохраняются в Chroma vector store
5. При вопросе: embeddings вопроса → vector search → top-5 chunks → добавляются в system prompt
6. LLM отвечает опираясь на найденные chunks

### Типичные промпты после RAG

- "Summarize this document in 5 bullet points"
- "What are the main topics covered?"
- "Find all mentions of SSL configuration"
- "Is there any section about authentication?"

Для качественных ответов нужна модель поддерживающая **больший контекст** -- RAG chunks могут занимать 1-3K токенов.

## 6. Image upload в vision-модель

**Задача**: показать картинку vision-модели и попросить её описать.

### Предусловия

Запущена vision-модель (например [Qwen3-VL](../../models/families/qwen3-vl.md) или [Gemma 4 26B-A4B](../../models/families/gemma4.md)) через llama-server с правильным mmproj:

```bash
./scripts/inference/vulkan/preset/qwen3-vl.sh --daemon
# Запускается на порту 8083 с mmproj-файлом
```

Зарегистрирована в Open WebUI как connection.

### Шаги

1. New Chat → выбрать vision-модель
2. Кликнуть иконку "Image" (или перетащить файл в окно)
3. Загрузить фотографию
4. Промпт: "Что на этой картинке? Опиши детально"
5. Enter

Модель отвечает на основе и текста, и изображения.

### Что отличает от обычного чата

- Запрос в OpenAI-compat API идёт с `content` как массивом: `[{"type": "text", "text": "..."}, {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,..."}}]`
- llama-server через mmproj преобразует картинку в embeddings и инжектит в контекст модели
- Ответ идёт как обычный text stream

## 7. Темы, markdown, code blocks

Open WebUI имеет **приличный markdown renderer**:

- **Заголовки**, списки, таблицы отображаются корректно
- **Code blocks** с syntax highlighting (автоматически определяется язык)
- **Inline code** форматируется
- **Math**: LaTeX inline `$x = y$` и block `$$...$$` через KaTeX
- **Mermaid diagrams**: блоки с ```mermaid``` рендерятся как SVG

### Переключение темы

Settings → General → Theme: Light / Dark / System

### Copy code button

В code blocks автоматически появляется кнопка "Copy" в правом верхнем углу -- удобно для copying кода из ответов LLM.

## 8. Отметка favourite / pinning

**Задача**: сохранить важный чат чтобы он был всегда наверху.

### Шаги

1. Right-click на чат в sidebar → "Pin Chat" (или значок кнопки)
2. Чат перемещается в секцию "Pinned" вверху

Pinned чаты полезны для:
- Активных проектов ("работа над багом #42")
- System prompts, которые переиспользуются
- Reference-чатов ("как писать SQL запросы")

## Связанные статьи

- [README.md](README.md) -- обзор профиля
- [introduction.md](introduction.md) -- что это, история, философия
- [architecture.md](architecture.md) -- внутреннее устройство (чтобы понимать что происходит)
- [advanced-use-cases.md](advanced-use-cases.md) -- Functions, Pipelines, RAG pipelines, multi-user
- [../../../scripts/webui/README.md](../../../scripts/webui/README.md) -- операционные скрипты
- [../../inference/llama-cpp.md](../../inference/llama-cpp.md) -- backend
- [../../models/families/qwen3-vl.md](../../models/families/qwen3-vl.md) -- vision модели для image upload
