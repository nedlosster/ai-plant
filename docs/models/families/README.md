# Каталог семейств моделей

Один файл = одна серия модели. **Единственный источник правды** для описания: архитектура, варианты, сильные кейсы, команды загрузки, ссылки.

Статьи направлений (`../coding.md`, `../llm.md`, `../vision.md` и т.д.) содержат только сравнительные таблицы и "выбор под задачу" со ссылками сюда.

Управление каталогом: skill `/models-catalog`.

## Индекс по категориям

### LLM общего назначения
- [qwen36](qwen36.md) -- Qwen3.6-Plus (API-only, ожидаются open weights)
- [kimi-k25](kimi-k25.md) -- Kimi K2.5 1T MoE (open weights, не помещается локально, API)
- [qwen35](qwen35.md) -- Qwen3.5 27B/35B-A3B/122B-A10B (скачаны 27B + 122B-A10B)
- [llama](llama.md) -- Llama 3.1/3.3/4 Scout
- [mixtral](mixtral.md) -- Mixtral 8x22B 141B MoE
- [command-a](command-a.md) -- Command A 111B (RAG/tool use)
- [phi](phi.md) -- Phi-4 14B (reasoning при малом VRAM)
- [qwq](qwq.md) -- QwQ-32B reasoning
- [deepseek-distill](deepseek-distill.md) -- DeepSeek-R1-Distill 14B/32B

### Кодинг
- [qwen36](qwen36.md) -- Qwen3.6-Plus (agentic coding, ожидается)
- [kimi-k25](kimi-k25.md) -- Kimi K2.5 (SWE-Bench 76.8%, лидер open-source agentic, через API)
- [qwen3-coder](qwen3-coder.md) -- Qwen3-Coder Next 80B-A3B + 30B-A3B (скачаны)
- [qwen25-coder](qwen25-coder.md) -- Qwen2.5-Coder 1.5B/7B/32B FIM (скачана 1.5B)
- [devstral](devstral.md) -- Devstral 2 24B
- [codestral](codestral.md) -- Codestral 25.08

### Vision (multimodal)
- [gemma4](gemma4.md) -- Gemma 4 26B-A4B + mmproj (скачана)
- [qwen3-vl](qwen3-vl.md) -- Qwen3-VL 30B-A3B / 235B-A22B
- [qwen25-omni](qwen25-omni.md) -- Qwen2.5-Omni 7B (vision+audio+text)
- [pixtral](pixtral.md) -- Pixtral 12B (Mistral, Apache 2.0)
- [mistral-small-31](mistral-small-31.md) -- Mistral Small 3.1 24B
- [internvl](internvl.md) -- InternVL3 2B/14B/78B
- [minicpm-o](minicpm-o.md) -- MiniCPM-o 2.6 8B (omni)
- [smolvlm2](smolvlm2.md) -- SmolVLM2 256M/500M/2.2B (edge)

### TTS / Voice cloning
- [qwen3-tts](qwen3-tts.md) -- Qwen3-TTS (нативный русский)
- [f5-tts](f5-tts.md) -- F5-TTS (MIT, RU-форки)
- [fish-speech](fish-speech.md) -- Fish Speech 1.5 (Apache 2.0)
- [indextts2](indextts2.md) -- IndexTTS-2 (контроль эмоций)
- [xtts](xtts.md) -- XTTS v2 (16 языков)

### Музыка и аудио
- [ace-step](ace-step.md) -- ACE-Step 1.5 (скачана, AMD ROCm)
- [musicgen](musicgen.md) -- MusicGen (инструментальная)
- [yue](yue.md) -- YuE (lyrics-to-song)
- [songgeneration](songgeneration.md) -- SongGeneration v2 (research)
- [stable-audio](stable-audio.md) -- Stable Audio Open (sfx)
- [bark](bark.md) -- Bark (multi-modal экспериментальная)

### Картинки (diffusion)
- [flux](flux.md) -- FLUX.1 schnell + dev + T5-XXL (скачаны)
- [sd35](sd35.md) -- Stable Diffusion 3.5 Large/Medium
- [hidream](hidream.md) -- HiDream-I1 Full 17B (Apache 2.0)

### Видео
- [wan](wan.md) -- Wan 2.6/2.7 (cinematic, MoE)
- [hunyuanvideo](hunyuanvideo.md) -- HunyuanVideo 1.5
- [ltx-video](ltx-video.md) -- LTX-Video 2.3 (4K 50fps)
- [cogvideox](cogvideox.md) -- CogVideoX 1.5-5B (ComfyUI-классика)
- [open-sora](open-sora.md) -- Open-Sora 2.0 (длинные видео)
- [svd](svd.md) -- Stable Video Diffusion (I2V классика)

### Российские LLM (finetune)
- [saiga](saiga.md) -- Saiga (Qwen/Llama base)
- [t-bank](t-bank.md) -- T-pro/T-lite от Т-Банка
- [vikhr](vikhr.md) -- Vikhr 7B (Mistral base)

## Шаблон

При создании нового файла семейства использовать структуру из skill `models-catalog` (см. `.claude/skills/models-catalog/SKILL.md`). Минимум: тип, лицензия, статус на сервере, направления, варианты-таблица, сильные/слабые кейсы, идеальные сценарии, команды загрузки/запуска.

## Правила

1. Один файл = одна серия (Qwen3-Coder = Next + 30B-A3B; FLUX = schnell + dev + T5)
2. Варианты внутри файла -- через якоря (`#next-80b-a3b`, `#30b-a3b`)
3. Полное описание модели не должно дублироваться в файлах направлений
4. Из направления -- ссылка на семейство (опционально с якорем варианта)
5. Не создавать файлы для моделей, которые **не помещаются** на платформе (GLM-5, MiniMax M2.5, DeepSeek V3.2 и т.п.)

## Статистика

- **41 файл семейств**
- **6 моделей скачано на сервере**: qwen3-coder (Next + 30B-A3B), qwen25-coder (1.5B), qwen35 (27B + 122B-A10B), gemma4 (26B-A4B + mmproj), flux (schnell + dev + T5-XXL), ace-step
- **~30 моделей в "watch"** -- приоритетные для скачивания
