#!/bin/bash
set -e

python3 << 'PYEOF'
path = "lib/kmaWeather.ts"

with open(path, encoding="utf-8") as f:
    content = f.read()

old_max = "const maxTemps = [...xml.matchAll(/<iwxxm:maximumAirTemperature[^>]*>([^<]+)</g)].map((m) =>"
new_max = "const maxTemps = [...xml.matchAll(/<iwxxm:maximumAirTemperature(?!Time)[^>]*>([^<]+)</g)].map((m) =>"

old_min = "const minTemps = [...xml.matchAll(/<iwxxm:minimumAirTemperature[^>]*>([^<]+)</g)].map((m) =>"
new_min = "const minTemps = [...xml.matchAll(/<iwxxm:minimumAirTemperature(?!Time)[^>]*>([^<]+)</g)].map((m) =>"

changed = False
if old_max in content:
    content = content.replace(old_max, new_max)
    changed = True
if old_min in content:
    content = content.replace(old_min, new_min)
    changed = True

if changed:
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("patched:", path)
else:
    print("패턴을 못 찾았어요. 파일 내용을 다시 확인해야 해요:", path)
PYEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."