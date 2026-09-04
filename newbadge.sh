#!/bin/bash
set -e

mkdir -p lib

# 1) NEW 배지 판정 유틸 (새 파일)
cat > lib/isNew.ts << 'KMAEOF'
// 작성된 지 24시간 이내면 true (NEW 배지 표시 여부 판단)
export function isNew(createdAt: string | null | undefined, hours: number = 24): boolean {
  if (!createdAt) return false
  const created = new Date(createdAt).getTime()
  if (Number.isNaN(created)) return false
  return Date.now() - created < hours * 60 * 60 * 1000
}
KMAEOF

# 2) NEW 배지 스타일 (기존 CSS 유지, 끝에 추가)
cat >> app/globals.css << 'CSSEOF'

.new-badge {
  display: inline-block;
  background: var(--color-orange);
  color: #fff;
  font-size: 9px;
  font-weight: 800;
  padding: 1px 6px;
  border-radius: 999px;
  margin-left: 6px;
  vertical-align: middle;
  letter-spacing: 0.3px;
}
CSSEOF

# 3) 각 게시판 목록 파일에 NEW 배지 코드를 안전하게 끼워넣기
python3 << 'PYEOF'
import re

def patch_doc_row_file(path):
    with open(path, encoding="utf-8") as f:
        content = f.read()

    if "lib/isNew" not in content:
        content = re.sub(r"(^import[^\n]*\n)", r"\1import { isNew } from '@/lib/isNew'\n", content, count=1)

    if "isNew(doc.created_at)" not in content:
        content = re.sub(
            r"(\{doc\.title\})",
            r"\1\n            {isNew(doc.created_at) && <span className=\"new-badge\">NEW</span>}",
            content,
            count=1,
        )

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("patched:", path)

def patch_notice_file(path):
    with open(path, encoding="utf-8") as f:
        content = f.read()

    if "lib/isNew" not in content:
        content = re.sub(r'(^import[^\n]*\n)', r'\1import { isNew } from "@/lib/isNew"\n', content, count=1)

    if "isNew(notice.created_at)" not in content:
        content = re.sub(
            r"<h3>\{notice\.title\}<\/h3>",
            '<h3>{notice.title} {isNew(notice.created_at) && <span className="new-badge">NEW</span>}</h3>',
            content,
            count=1,
        )

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("patched:", path)

import os

if os.path.exists("app/resources/ResourceBoard.tsx"):
    patch_doc_row_file("app/resources/ResourceBoard.tsx")

if os.path.exists("app/tasks/TaskBoard.tsx"):
    patch_doc_row_file("app/tasks/TaskBoard.tsx")

if os.path.exists("app/contacts/page.tsx"):
    patch_doc_row_file("app/contacts/page.tsx")

if os.path.exists("app/notices/page.tsx"):
    patch_notice_file("app/notices/page.tsx")
PYEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."