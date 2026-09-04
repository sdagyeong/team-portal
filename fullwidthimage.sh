#!/bin/bash
set -e

cat >> app/globals.css << 'FULLWIDTHEOF'
/* 주기장요도 이미지 - 카드 폭 제한 없이 화면 최대로 확대 */
.airport-info-card {
  max-width: 100%;
}

.airport-info-image {
  width: 100%;
  max-width: 100%;
  height: auto;
  max-height: none;
}
FULLWIDTHEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."