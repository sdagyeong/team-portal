#!/bin/bash
set -e

cat >> app/globals.css << 'MOBILEEOF'
/* ===== 모바일 화면 대응 ===== */
@media (max-width: 768px) {
  .layout {
    flex-direction: column;
  }

  .sidebar {
    width: 100%;
    height: auto;
    position: relative;
    top: auto;
    padding: 16px;
  }

  .brand {
    padding-bottom: 12px;
    margin-bottom: 12px;
  }

  nav {
    flex-direction: row;
    flex-wrap: wrap;
    gap: 6px;
  }

  .menu {
    padding: 8px 12px;
    font-size: 13px;
  }

  .content {
    padding: 20px 16px;
  }

  .top {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .header-search {
    width: 100%;
  }

  .header-search input {
    width: 100%;
    flex: 1;
  }

  .top-actions {
    width: 100%;
    flex-wrap: wrap;
  }

  .dashboard-grid {
    grid-template-columns: 1fr;
  }

  .metar-row {
    grid-template-columns: 40px 1fr 1fr;
    row-gap: 4px;
    font-size: 11px;
  }

  .taf-row {
    grid-template-columns: 40px 1fr;
    row-gap: 4px;
    font-size: 11px;
  }

  .weather-airport-table {
    font-size: 11px;
  }

  .weather-airport-table th,
  .weather-airport-table td {
    padding: 6px 8px;
  }

  .doc-row {
    grid-template-columns: 1fr;
    row-gap: 4px;
  }

  .edit-table {
    font-size: 11px;
  }

  .phone-panels-column {
    min-width: 100%;
  }

  .airport-columns {
    grid-template-columns: 1fr;
    gap: 20px;
  }

  .folder-menu {
    max-width: 100%;
  }

  .doc-modal {
    max-width: 100%;
    margin: 0 8px;
  }
}
MOBILEEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."