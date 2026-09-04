#!/bin/bash
set -e

python3 << 'PYEOF'
import os

files = [
    "app/resources/ResourceBoard.tsx",
    "app/tasks/TaskBoard.tsx",
    "app/contacts/page.tsx",
    "app/notices/page.tsx",
]

for path in files:
    if not os.path.exists(path):
        print("skip (not found):", path)
        continue

    with open(path, encoding="utf-8") as f:
        content = f.read()

    if "lib/isNew" in content:
        print("already has import:", path)
        continue

    lines = content.split("\n")
    insert_idx = 0

    first = lines[0].strip().strip('"').strip("'") if lines else ""
    if first == "use client":
        insert_idx = 1
        while insert_idx < len(lines) and lines[insert_idx].strip() == "":
            insert_idx += 1

    lines.insert(insert_idx, "import { isNew } from '@/lib/isNew'")
    content = "\n".join(lines)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("import added:", path)
PYEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."