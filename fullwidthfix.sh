#!/bin/bash
set -e

cat >> app/globals.css << 'FULLWIDTHFIXEOF'
/* 대시보드 카드 - 항상 화면 폭(검색창까지)에 꽉 차게, 고정폭 취소 */
.dashboard-grid,
.meal-card,
.weather-card {
  width: 100%;
  max-width: 100%;
}

/* 날씨 표 - 구분 칸 좁게, 글씨체/굵기 통일 */
.weather-airport-table th:first-child,
.weather-airport-table td:first-child {
  width: 56px;
}

.weather-airport-table th,
.weather-airport-table td {
  font-family: ui-monospace, "SFMono-Regular", Menlo, Consolas, "Liberation Mono", monospace;
  font-weight: 700;
}
FULLWIDTHFIXEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."