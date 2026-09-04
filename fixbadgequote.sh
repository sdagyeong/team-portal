#!/bin/bash
set -e

python3 << 'PYEOF'
import os

files = [
    "app/resources/ResourceBoard.tsx",
    "app/tasks/TaskBoard.tsx",
    "app/contacts/page.tsx",
]

for path in files:
    if not os.path.exists(path):
        print("skip (not found):", path)
        continue
    with open(path, encoding="utf-8") as f:
        content = f.read()
    fixed = content.replace('className=\\"new-badge\\"', 'className="new-badge"')
    if fixed != content:
        with open(path, "w", encoding="utf-8") as f:
            f.write(fixed)
        print("fixed:", path)
    else:
        print("no broken quotes found:", path)
PYEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."