#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path
import re

failures = []
pattern = re.compile(r'\[[^]]*\]\(([^)]+)\)')
for document in Path('.').rglob('*.md'):
    if any(part in {'.git', 'build', 'results'} for part in document.parts):
        continue
    text = document.read_text(encoding='utf-8')
    for raw in pattern.findall(text):
        target = raw.split('#', 1)[0].strip()
        if not target or '://' in target or target.startswith(('mailto:', '#')):
            continue
        resolved = (document.parent / target).resolve()
        if not resolved.exists():
            failures.append(f'{document}: missing {raw}')

if failures:
    raise SystemExit('\n'.join(failures))
print('Markdown links: PASS')
PY
