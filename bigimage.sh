#!/bin/bash
set -e

cat >> app/globals.css << 'IMGSIZEEOF'
/* 주기장요도 이미지 크게 표시 */
.airport-info-image {
  max-height: none;
  max-width: 100%;
  width: auto;
  height: auto;
}
IMGSIZEEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."