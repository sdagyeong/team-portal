#!/bin/bash
set -e

cat >> app/globals.css << 'DASHFIXEOF'
/* 대시보드 카드 폭 통일 (큰 모니터에서도 일관되게) */
.dashboard-grid {
  max-width: 900px;
}

.meal-card {
  max-width: 900px;
}

/* 날씨 표 - 구분 칸이 화면 넓어져도 늘어나지 않도록 고정 */
.weather-airport-table {
  table-layout: fixed;
}

.weather-airport-table th:first-child,
.weather-airport-table td:first-child {
  width: 70px;
}
DASHFIXEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."