#!/bin/bash
set -e

cat >> app/globals.css << 'FORCEWIDTHEOF'
/* 주기장요도 카드 폭을 상단 보고서 배너와 동일하게 꽉 채우기 */
.airport-info-card {
  width: 100%;
}
FORCEWIDTHEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."