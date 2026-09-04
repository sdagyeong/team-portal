#!/bin/bash
set -e

python3 << 'PYEOF'
import re
import os

path = "next.config.ts"

if not os.path.exists(path):
    path = "next.config.js"

if not os.path.exists(path):
    print("next.config.ts(js) 파일을 찾지 못했어요. 직접 확인이 필요해요.")
else:
    with open(path, encoding="utf-8") as f:
        content = f.read()

    if "serverActions" in content:
        print("이미 serverActions 설정이 있어요:", path)
    else:
        new_content, count = re.subn(
            r"(const\s+nextConfig[^=]*=\s*\{)",
            r"\1\n  experimental: {\n    serverActions: {\n      bodySizeLimit: \"10mb\",\n    },\n  },",
            content,
            count=1,
        )
        if count == 0:
            print("설정 위치를 자동으로 못 찾았어요. 파일 내용을 보여주시면 직접 고쳐드릴게요:", path)
        else:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new_content)
            print("설정 추가 완료:", path)
PYEOF

echo "적용 완료. npm run dev 재시작 후 다시 업로드해보세요."