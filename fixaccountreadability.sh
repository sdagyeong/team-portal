#!/bin/bash
set -e

python3 << 'PYEOF'
path = "app/contacts/ContactsBoard.tsx"

with open(path, encoding="utf-8") as f:
    content = f.read()

old = "mergeColumns={['group_name', 'system_name', 'url']}"
new = "mergeColumns={['group_name', 'system_name', 'url', 'note']}"

if old in content:
    content = content.replace(old, new)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("patched:", path)
else:
    print("패턴을 못 찾았어요. 파일 내용을 다시 확인해야 해요:", path)
PYEOF

cat >> app/globals.css << 'CSSEOF'

/* 계정 표 - 비고 칸 최소 너비 확보 및 가독성 개선 */
.edit-table td:last-child {
  min-width: 260px;
}

.edit-table-cell-value {
  line-height: 1.6;
}
CSSEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."