#!/bin/bash
set -e

cat >> app/globals.css << 'FORCEIMPORTANTEOF'
/* 주기장요도 카드 폭 강제 적용 (다른 규칙보다 우선) */
.task-board .airport-info-card {
  width: 100% !important;
  max-width: 100% !important;
}

.task-board .airport-info-image {
  width: 100% !important;
  max-width: 100% !important;
  height: auto !important;
  max-height: none !important;
}
FORCEIMPORTANTEOF

echo "적용 완료. rm -rf .next 후 npm run dev 재시작하고 강력새로고침 해주세요."