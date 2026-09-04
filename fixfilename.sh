#!/bin/bash
set -e

python3 << 'PYEOF'
import os

files = [
    "app/resources/documentActions.ts",
    "app/tasks/documentActions.ts",
    "app/contacts/documentActions.ts",
    "app/notices/actions.ts",
    "app/tasks/airportInfoActions.ts",
    "app/mealActions.ts",
]

for path in files:
    if not os.path.exists(path):
        print("skip (not found):", path)
        continue

    with open(path, encoding="utf-8") as f:
        content = f.read()

    if "safeName" in content:
        print("already patched:", path)
        continue

    lines = content.split("\n")
    new_lines = []
    changed = False

    for line in lines:
        if "filePath" in line and "file.name" in line and "=" in line:
            indent = line[: len(line) - len(line.lstrip())]
            safe_line = indent + "const safeName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_')"
            new_lines.append(safe_line)
            line = line.replace("${file.name}", "${safeName}")
            changed = True
        new_lines.append(line)

    if changed:
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(new_lines))
        print("patched:", path)
    else:
        print("pattern not found (check manually):", path)
PYEOF

echo "적용 완료. npm run dev 재시작 후 다시 업로드해보세요."