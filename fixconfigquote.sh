#!/bin/bash
set -e

python3 << 'PYEOF'
import os

path = "next.config.ts"
if not os.path.exists(path):
    path = "next.config.js"

with open(path, encoding="utf-8") as f:
    content = f.read()

fixed = content.replace('bodySizeLimit: \\"10mb\\",', "bodySizeLimit: '10mb',")
fixed = fixed.replace('\\"10mb\\"', "'10mb'")

if fixed != content:
    with open(path, "w", encoding="utf-8") as f:
        f.write(fixed)
    print("fixed:", path)
else:
    print("no broken quotes found, printing current content for review:")
    print(content)
PYEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."