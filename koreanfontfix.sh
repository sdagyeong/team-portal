#!/bin/bash
set -e

cat >> app/globals.css << 'FONTFIXEOF'
/* 모노스페이스 폰트에 한글 전용 폰트가 없어서 생기던 한글 크기 불일치 수정 */
.metar-row,
.taf-row,
.warning-row,
.weather-airport-table th,
.weather-airport-table td {
  font-family: ui-monospace, "SFMono-Regular", Menlo, Consolas, "Liberation Mono",
    "Pretendard", monospace;
}
FONTFIXEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."