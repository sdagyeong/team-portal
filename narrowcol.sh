#!/bin/bash
set -e

cat >> app/globals.css << 'NARROWCOLEOF'
/* 날씨 표 - 구분 칸 1/4 크기로 축소 고정, 글씨 한 단계 확대 */
.weather-airport-table {
  font-size: 13px;
}

.weather-airport-table th:first-child,
.weather-airport-table td:first-child {
  width: 14px;
  white-space: nowrap;
  overflow: visible;
}
NARROWCOLEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."