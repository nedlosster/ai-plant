# Анализ и обработка документов

Стратегии работы с PDF, Word, Excel, сканами и изображениями документов на платформе Strix Halo. Локальный AI-стек: Vision-LLM (Qwen3-VL, InternVL3.5, Gemma 4) + классические парсеры (pdfplumber, python-docx, openpyxl, marker, MinerU).

Полные описания моделей -- в [docs/models/families/](../../models/families/), запуск -- через пресеты в `scripts/inference/vulkan/preset/`.

## Что умеем

| Задача | Подход |
|--------|--------|
| PDF (текстовый) → Markdown | pdfplumber/marker без LLM, либо marker+VLM для сложных layout |
| PDF (сканы, фото документа) | Vision-LLM (Qwen3-VL) → Markdown / JSON |
| Word (.docx) → Markdown | python-docx + pandoc, без LLM |
| Excel (.xlsx) → Markdown / JSON | openpyxl + jinja, без LLM |
| Скан таблицы → Excel | Vision-LLM → JSON → openpyxl |
| Перевод документа с сохранением layout | Vision-LLM (235B через API) или 30B-A3B + ручная сборка |
| Извлечение структурированных данных (счёт → JSON) | Vision-LLM с structured output |
| Суммаризация / Q&A по документу | Текст + LLM (Qwen3.5 122B) или RAG |
| Редактирование Word/Excel программно | python-docx / openpyxl + LLM для генерации правок |
| Reasoning по диаграммам / графикам | [InternVL3.5-38B](../../models/families/internvl.md#3-5-38b) |

## Стек инструментов

### Парсеры (без AI, быстро и точно для текстовых документов)

| Формат | Библиотека | Установка | Когда брать |
|--------|------------|-----------|-------------|
| PDF (текст) | [pdfplumber](https://github.com/jsvine/pdfplumber) | `pip install pdfplumber` | Извлечение текста, таблиц из текстового PDF |
| PDF (layout) | [marker](https://github.com/VikParuchuri/marker) | `pip install marker-pdf` | PDF → Markdown с сохранением структуры, формулами LaTeX |
| PDF (сложный layout) | [MinerU](https://github.com/opendatalab/MinerU) | `pip install magic-pdf` | Лучший на сложных научных PDF, OCR fallback |
| PDF (universal) | [pymupdf4llm](https://github.com/pymupdf/PyMuPDF) | `pip install pymupdf4llm` | PDF → Markdown в одну строку, для LLM-pipeline |
| Word | [python-docx](https://python-docx.readthedocs.io/) | `pip install python-docx` | Чтение/изменение .docx с сохранением форматирования |
| Word ↔ Markdown | [pandoc](https://pandoc.org/) | `apt install pandoc` | Двусторонняя конвертация |
| Excel | [openpyxl](https://openpyxl.readthedocs.io/) | `pip install openpyxl` | Чтение/запись .xlsx, формулы, стили |
| Excel (быстро) | [polars](https://pola.rs/) или pandas | `pip install polars` | Анализ табличных данных |
| OCR | [tesseract](https://github.com/tesseract-ocr/tesseract) | `apt install tesseract-ocr tesseract-ocr-rus` | Сканированные документы без layout-понимания |
| OCR (продвинутый) | [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) | `pip install paddleocr` | Лучше tesseract, поддержка таблиц |

### Vision-LLM (для скан-документов и сложного layout)

| Модель | Сильное место | VRAM | Скорость |
|--------|---------------|------|----------|
| [Qwen3-VL 30B-A3B](../../models/families/qwen3-vl.md#30b-a3b) ⭐ | Лучший OCR open-source, structured JSON, 30+ языков | 20 GiB | ~80 tok/s |
| [Gemma 4 26B-A4B](../../models/families/gemma4.md) ⭐ | Function calling, 256K контекст | 23 GiB | ~70 tok/s |
| [InternVL3.5-38B](../../models/families/internvl.md#3-5-38b) | Reasoning по диаграммам, math, charts | 27 GiB | ~15 tok/s |
| [Qwen3-VL 235B-A22B](../../models/families/qwen3-vl.md#235b-a22b) | Frontier для критичных задач | через API | -- |

⭐ Скачаны на платформе.

## Стратегии по типу документа

### 1. Текстовый PDF (статья, отчёт, документация)

**Лучший подход**: marker или pymupdf4llm. AI не нужен.

```bash
# Установка
pip install marker-pdf

# Конвертация
marker_single document.pdf --output_dir ./out --output_format markdown
```

Получаем `.md` с сохранением заголовков, таблиц, формул, ссылок. Качество ~95% на типичных научных статьях.

**Когда нужен AI**: если документ содержит сложные диаграммы или таблицы со сложной структурой -- прогнать результат marker через [InternVL3.5-38B](../../models/families/internvl.md#3-5-38b) для верификации:

```python
import requests, base64

# Marker дал markdown, но таблица сложная -- проверяем VLM
with open("page-3-table.png", "rb") as f:
    img_b64 = base64.b64encode(f.read()).decode()

resp = requests.post("http://192.168.1.77:8081/v1/chat/completions", json={
    "model": "internvl3.5-38b",
    "messages": [{
        "role": "user",
        "content": [
            {"type": "text", "text": "Распознай эту таблицу в формате markdown с правильными границами. Не добавляй ничего лишнего."},
            {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img_b64}"}}
        ]
    }],
    "temperature": 0.1
})
print(resp.json()["choices"][0]["message"]["content"])
```

### 2. Сканированный PDF (старые документы, фото договора)

**Лучший подход**: Vision-LLM напрямую, минуя marker (он плохо работает с растровыми PDF).

Шаги:
1. PDF → набор PNG страниц через `pdftoppm`:
   ```bash
   pdftoppm -r 300 scan.pdf page -png
   # → page-1.png, page-2.png, ...
   ```
2. Каждую страницу → Qwen3-VL 30B-A3B с промптом на структурированный вывод:
   ```python
   import base64, requests, json
   from pathlib import Path

   pages = sorted(Path(".").glob("page-*.png"))
   result = []
   for p in pages:
       img_b64 = base64.b64encode(p.read_bytes()).decode()
       r = requests.post("http://192.168.1.77:8081/v1/chat/completions", json={
           "model": "qwen3-vl-30b-a3b",
           "messages": [{
               "role": "user",
               "content": [
                   {"type": "text", "text": "Распознай эту страницу документа. Сохрани структуру (заголовки, абзацы, списки, таблицы) в формате markdown. Если есть подписи к рисункам -- сохрани. Не добавляй своих комментариев."},
                   {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img_b64}"}}
               ]
           }],
           "temperature": 0.0,
           "max_tokens": 4000
       })
       result.append(r.json()["choices"][0]["message"]["content"])

   Path("output.md").write_text("\n\n---\n\n".join(result))
   ```

**Альтернатива для production**: [MinerU](https://github.com/opendatalab/MinerU) -- open-source pipeline, который сам делит PDF на страницы, делает OCR, восстанавливает layout и выдаёт markdown. Качество выше, чем pdfplumber на сканах, но без локального VLM.

### 3. Word (.docx) → Markdown / редактирование

**Чтение и конвертация** (без AI):

```bash
# pandoc -- быстро, надёжно, сохраняет структуру
pandoc input.docx -o output.md

# В обратную сторону
pandoc output.md -o updated.docx
```

**Программное редактирование** через python-docx:

```python
from docx import Document

doc = Document("contract.docx")

# Поиск и замена в параграфах
for para in doc.paragraphs:
    if "ООО Старое название" in para.text:
        for run in para.runs:
            run.text = run.text.replace("ООО Старое название", "ООО Новое название")

# Изменение таблиц
for table in doc.tables:
    for row in table.rows:
        for cell in row.cells:
            if cell.text.strip() == "TODO":
                cell.text = "Заполнено"

doc.save("contract-updated.docx")
```

**С участием LLM** -- для генерации содержимого:

```python
# 1. Извлекаем текст шаблона
text = "\n".join(p.text for p in doc.paragraphs)

# 2. Просим LLM заполнить
import requests
filled = requests.post("http://192.168.1.77:8081/v1/chat/completions", json={
    "model": "qwen3-coder-next",
    "messages": [{
        "role": "user",
        "content": f"Заполни placeholders {{...}} в этом шаблоне договора реальными данными:\n\n{text}\n\nДанные: ИНН 7707083893, дата 2026-04-09, сумма 150000 руб."
    }]
}).json()["choices"][0]["message"]["content"]

# 3. Возвращаем в docx через python-docx или pandoc
```

### 4. Excel (.xlsx) → Markdown / JSON / редактирование

**Чтение** через openpyxl или polars:

```python
import openpyxl

wb = openpyxl.load_workbook("report.xlsx", data_only=True)
ws = wb["Sheet1"]

# В JSON
data = []
headers = [c.value for c in ws[1]]
for row in ws.iter_rows(min_row=2, values_only=True):
    data.append(dict(zip(headers, row)))

import json
print(json.dumps(data, ensure_ascii=False, indent=2))
```

**В Markdown** (через polars / pandas):

```python
import polars as pl
df = pl.read_excel("report.xlsx")
print(df.to_pandas().to_markdown(index=False))
```

**Запись и формулы** через openpyxl:

```python
ws["E2"] = "=SUM(B2:D2)"
ws["E2"].number_format = "#,##0.00"
wb.save("report-updated.xlsx")
```

**С участием LLM** -- анализ и генерация формул:

```python
# Просим LLM проанализировать данные и предложить формулы
prompt = f"""Дана таблица:
{df.to_pandas().head(20).to_markdown()}

Предложи 5 полезных формул для столбца E (например выручка минус расходы, маржа в %, скользящее среднее).
Верни JSON: [{{"name": "...", "formula": "=...", "description": "..."}}]
"""
# → отправить в Qwen3-Coder Next, распарсить JSON, применить через openpyxl
```

### 5. Скан таблицы → Excel

Самый частый запрос: фото таблицы (например распечатка прайс-листа) → редактируемый xlsx.

Pipeline:
1. Скан → PNG (если нужно -- кропнуть только таблицу)
2. Qwen3-VL 30B-A3B с промптом structured output:
   ```
   Извлеки данные из таблицы в JSON-формате:
   {"headers": [...], "rows": [[...], [...], ...]}
   Не добавляй комментариев. Используй null для пустых ячеек.
   ```
3. JSON → openpyxl → xlsx:
   ```python
   import json, openpyxl
   data = json.loads(llm_response)
   wb = openpyxl.Workbook()
   ws = wb.active
   ws.append(data["headers"])
   for row in data["rows"]:
       ws.append(row)
   wb.save("extracted.xlsx")
   ```

Качество распознавания на наших тестах: ~95% на чёткой печати, ~80-85% на смазанных сканах. Для критичных задач -- дополнительный проход через [InternVL3.5-38B](../../models/families/internvl.md#3-5-38b) (лучше на cell boundaries).

### 6. Перевод документа с сохранением структуры

**Простой документ (текст без layout)**:

```python
# 1. Извлекаем текст по абзацам
import pymupdf4llm
md = pymupdf4llm.to_markdown("doc.pdf")

# 2. Переводим chunks через LLM
chunks = md.split("\n\n")
translated = []
for chunk in chunks:
    if not chunk.strip():
        translated.append(chunk)
        continue
    r = requests.post("http://192.168.1.77:8081/v1/chat/completions", json={
        "model": "qwen3-vl-30b-a3b",
        "messages": [{
            "role": "user",
            "content": f"Переведи на русский, сохрани markdown-разметку:\n\n{chunk}"
        }],
        "temperature": 0.2
    }).json()["choices"][0]["message"]["content"]
    translated.append(r)

Path("translated.md").write_text("\n\n".join(translated))
```

**Сложный layout (договор, инструкция, брошюра)**: использовать [Qwen3-VL 235B через API](../../models/families/qwen3-vl.md#235b-a22b) -- 30B-A3B справится, но 235B даёт более идиоматичный перевод юридических и технических текстов с сохранением форматирования.

### 7. Извлечение структурированных данных (счёт, накладная, удостоверение)

Production-pipeline для бухгалтерии или KYC:

```python
schema = """
{
  "supplier_name": "string",
  "supplier_inn": "string (12 digits)",
  "invoice_number": "string",
  "invoice_date": "YYYY-MM-DD",
  "items": [
    {"name": "string", "quantity": number, "price_per_unit": number, "total": number}
  ],
  "vat_amount": number,
  "total_amount": number
}
"""

prompt = f"""Извлеки данные из счёта в JSON по схеме:
{schema}

Если поле не видно -- используй null. Не добавляй комментариев, только валидный JSON."""

# Отправить в Qwen3-VL с image + prompt
# Распарсить как JSON, провалидировать через pydantic
```

Качество: ~90-95% на типичных российских счетах через [Qwen3-VL 30B-A3B](../../models/families/qwen3-vl.md#30b-a3b). Для критичных полей (ИНН, суммы) -- дополнительная валидация regex / контрольной суммы ИНН.

### 8. Суммаризация / Q&A по документу

**Короткий документ** (до 100K токенов): загружать целиком в [Qwen3.5 122B-A10B](../../models/families/qwen35.md#122b-a10b) или [Gemma 4](../../models/families/gemma4.md) (256K контекст):

```python
text = pymupdf4llm.to_markdown("report.pdf")
r = requests.post("http://192.168.1.77:8081/v1/chat/completions", json={
    "model": "gemma-4-26b-a4b",
    "messages": [{
        "role": "user",
        "content": f"Суммаризируй этот отчёт за квартал в 5 ключевых пунктов:\n\n{text}"
    }],
    "max_tokens": 2000
})
```

**Длинный документ** (>200K токенов): RAG-подход с эмбеддингами и retrieval. См. [llm-guide/rag/](../../llm-guide/rag/).

### 9. Reasoning по диаграммам и графикам

[InternVL3.5-38B](../../models/families/internvl.md#3-5-38b) -- лучший выбор. См. сложные кейсы в [families/internvl.md](../../models/families/internvl.md#сложные-сценарии).

Типичный сценарий: квартальный отчёт с графиками → автоматическая выжимка ключевых трендов с конкретными цифрами.

## Универсальный pipeline для production

```
вход
 │
 ▼
┌─────────────────────┐
│ Определить тип файла│  ── pdf / docx / xlsx / image
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
текстовый      сканированный
документ       или image-only
    │             │
    ▼             ▼
marker /     pdftoppm + Qwen3-VL
pandoc       (постранично)
    │             │
    └──────┬──────┘
           ▼
    Markdown / JSON
           │
           ▼
   ┌───────────────┐
   │ Нужно         │
   │ редактировать?│
   └───────┬───────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
LLM-генерация  python-docx /
правок        openpyxl применяет
     │           │
     └─────┬─────┘
           ▼
       выходной файл
```

## Сравнение подходов: AI vs классические парсеры

| Критерий | Парсеры (marker, pdfplumber) | Vision-LLM (Qwen3-VL, InternVL) |
|----------|------------------------------|----------------------------------|
| Скорость | секунды на документ | 30-60 сек на страницу |
| Точность на текстовых PDF | 95-99% | 95-98% |
| Точность на сканах | 60-80% (с tesseract) | 90-95% |
| Сложные таблицы | средне | хорошо |
| Формулы LaTeX | хорошо (marker) | средне |
| Стоимость | $0 | $0 (локально), CPU/GPU время |
| Кастомизация под формат | сложно | easy через prompt |
| Multi-language | средне | отлично (30+ языков) |
| Reasoning над содержимым | нет | да |

**Правило**: для текстовых PDF -- сначала marker / pymupdf4llm, для сканов и сложных layout -- сразу VLM. Гибридные pipeline (marker + VLM на проблемных страницах) дают лучший результат за разумное время.

## Ограничения локального стека

1. **Frontier-задачи** (multi-page reasoning, peer-review научных статей) -- лучше через [Kimi K2.5](../../models/families/kimi-k25.md) или Qwen3-VL 235B через API
2. **Real-time** обработка большого потока документов (>100/час) -- упрётся в скорость одной GPU. Для batch -- очередь через redis + worker
3. **Сложные форматы** (структурированные XML, защищённые PDF, файлы с цифровой подписью) -- требуют дополнительной обработки сторонними инструментами
4. **Юридическая значимость** перевода -- AI-перевод не имеет юридической силы, для нотариально заверенных документов нужен присяжный переводчик

## Ссылки и инструменты

**Open-source pipelines**:
- [marker](https://github.com/VikParuchuri/marker) -- PDF → Markdown
- [MinerU](https://github.com/opendatalab/MinerU) -- сложные научные PDF
- [unstructured.io](https://github.com/Unstructured-IO/unstructured) -- universal document parser
- [docling](https://github.com/DS4SD/docling) -- IBM-проект, PDF/DOCX/PPTX/HTML

**Python-библиотеки**:
- [pdfplumber](https://github.com/jsvine/pdfplumber)
- [pymupdf4llm](https://github.com/pymupdf/PyMuPDF)
- [python-docx](https://python-docx.readthedocs.io/)
- [openpyxl](https://openpyxl.readthedocs.io/)
- [polars](https://pola.rs/)
- [pandoc](https://pandoc.org/)

**OCR**:
- [tesseract](https://github.com/tesseract-ocr/tesseract)
- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR)
- [EasyOCR](https://github.com/JaidedAI/EasyOCR)

## Связано

- **Модели**: [docs/models/families/qwen3-vl.md](../../models/families/qwen3-vl.md), [gemma4.md](../../models/families/gemma4.md), [internvl.md](../../models/families/internvl.md)
- **Направление**: [docs/models/vision.md](../../models/vision.md)
- **Платформы и клиенты**: [families/qwen3-vl.md#платформы-и-клиенты-для-работы-с-моделью](../../models/families/qwen3-vl.md)
- **RAG для длинных документов**: [llm-guide/rag/](../../llm-guide/rag/)
- **Запуск vision-сервера**: `scripts/inference/vulkan/preset/qwen3-vl.sh`, `gemma4.sh`, `internvl.sh`
