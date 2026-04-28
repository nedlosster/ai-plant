#!/bin/bash
# Агрегация per-language результатов Aider Polyglot из tmp.benchmarks/<dir>/
#
# Использование:
#   ./aider-aggregate.sh <run-dir>
#
# Где <run-dir> -- абсолютный или относительный путь к директории с результатами,
# например: ~/projects/aider/tmp.benchmarks/2026-04-27-10-55-07--full-qwen-coder-next-20260427-135505
#
# Скрипт проходит по подкаталогам <lang>/exercises/practice/*/.aider.results.json,
# извлекает tests_outcomes (список boolean попыток), агрегирует pass_1 и pass_2
# по каждому языку и итого.
#
# Зачем: финальный YAML агрегат benchmark.py может быть обрезан при manual abort
# или потерян если run прерван. .aider.results.json пишутся per-task и сохраняются
# даже после kill контейнера. Это authoritative источник per-language статистики.

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Использование: $0 <run-dir>" >&2
    echo "Пример: $0 ~/projects/aider/tmp.benchmarks/2026-04-27-10-55-07--full-qwen-coder-next-20260427-135505" >&2
    exit 1
fi

RUN_DIR="$1"

if [[ ! -d "$RUN_DIR" ]]; then
    echo "ОШИБКА: директория не найдена: $RUN_DIR" >&2
    exit 1
fi

echo "=== Per-language агрегация: $RUN_DIR ==="
echo ""

python3 - "$RUN_DIR" <<'PYEOF'
import json
import sys
from pathlib import Path

run_dir = Path(sys.argv[1])
languages = ['cpp', 'go', 'java', 'javascript', 'python', 'rust']

print(f"{'Язык':<12} {'Прогнано':>10} {'Pass-1':>10} {'Rate-1':>10} {'Pass-2':>10} {'Rate-2':>10}")
print("-" * 70)

grand_total = grand_p1 = grand_p2 = 0

for lang in languages:
    lang_dir = run_dir / lang / 'exercises' / 'practice'
    if not lang_dir.is_dir():
        continue

    total = pass1 = pass2 = 0
    for results_file in lang_dir.glob('*/.aider.results.json'):
        try:
            with open(results_file) as f:
                d = json.load(f)
            outcomes = d.get('tests_outcomes', [])
        except (OSError, json.JSONDecodeError):
            continue
        total += 1
        if not outcomes:
            continue
        if outcomes[0]:
            pass1 += 1
            pass2 += 1
        elif any(outcomes):
            pass2 += 1

    if total == 0:
        continue
    rate1 = pass1 * 100 / total
    rate2 = pass2 * 100 / total
    print(f"{lang:<12} {total:>10} {pass1:>10} {rate1:>9.1f}% {pass2:>10} {rate2:>9.1f}%")

    grand_total += total
    grand_p1 += pass1
    grand_p2 += pass2

if grand_total > 0:
    print("-" * 70)
    grand_r1 = grand_p1 * 100 / grand_total
    grand_r2 = grand_p2 * 100 / grand_total
    print(f"{'ИТОГО':<12} {grand_total:>10} {grand_p1:>10} {grand_r1:>9.1f}% {grand_p2:>10} {grand_r2:>9.1f}%")
    print("")
    print(f"Retry effect: +{grand_r2 - grand_r1:.1f}pp")
PYEOF
