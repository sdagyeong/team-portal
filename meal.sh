#!/bin/bash
set -e

mkdir -p app

cat > app/mealActions.ts << 'MEALEOF'
'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function saveMealImage(formData: FormData) {
  const side = formData.get('side') as string
  const file = formData.get('file') as File | null

  if (!file || file.size === 0) {
    throw new Error('이미지를 선택해주세요.')
  }

  const filePath = `meal/${side}_${Date.now()}_${file.name}`

  const { error: uploadError } = await supabase.storage
    .from('task-documents')
    .upload(filePath, file)

  if (uploadError) {
    console.error(uploadError)
    throw new Error('이미지 업로드에 실패했습니다.')
  }

  const { data } = supabase.storage.from('task-documents').getPublicUrl(filePath)
  const column = side === 'left' ? 'left_image_url' : 'right_image_url'

  const { error } = await supabase
    .from('meal_board')
    .upsert(
      { id: 1, [column]: data.publicUrl, updated_at: new Date().toISOString() },
      { onConflict: 'id' }
    )

  if (error) {
    console.error(error)
    throw new Error('저장에 실패했습니다.')
  }

  revalidatePath('/')
}

export async function clearMealImage(side: 'left' | 'right') {
  const column = side === 'left' ? 'left_image_url' : 'right_image_url'

  const { error } = await supabase
    .from('meal_board')
    .upsert(
      { id: 1, [column]: null, updated_at: new Date().toISOString() },
      { onConflict: 'id' }
    )

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/')
}
MEALEOF

cat > app/MealBoard.tsx << 'MEALEOF'
'use client'

import { useState } from 'react'
import { saveMealImage, clearMealImage } from './mealActions'
import { IconImage } from '@/components/icons'

type MealInfo = {
  left_image_url: string | null
  right_image_url: string | null
} | null

export default function MealBoard({ info }: { info: MealInfo }) {
  const [editing, setEditing] = useState<'left' | 'right' | null>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleUpload(side: 'left' | 'right', formData: FormData) {
    formData.set('side', side)
    setSubmitting(true)
    try {
      await saveMealImage(formData)
      setEditing(null)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  async function handleClear(side: 'left' | 'right') {
    if (!confirm('이미지를 삭제할까요?')) return
    setSubmitting(true)
    try {
      await clearMealImage(side)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  const slots: { key: 'left' | 'right'; url: string | null }[] = [
    { key: 'left', url: info?.left_image_url ?? null },
    { key: 'right', url: info?.right_image_url ?? null },
  ]

  return (
    <section className="dashboard-card meal-card">
      <div className="dashboard-card-header">
        <h3>
          <IconImage size={15} className="page-title-icon" /> 식단
        </h3>
      </div>

      <div className="meal-images">
        {slots.map((slot) => (
          <div key={slot.key} className="meal-slot">
            {editing !== slot.key && slot.url && (
              <img src={slot.url} alt="식단 이미지" className="meal-image" />
            )}
            {editing !== slot.key && !slot.url && (
              <div className="meal-empty">등록된 이미지가 없습니다.</div>
            )}

            {editing !== slot.key && (
              <div className="meal-slot-actions">
                <button
                  type="button"
                  className="airport-info-edit-btn"
                  onClick={() => setEditing(slot.key)}
                >
                  수정
                </button>
                {slot.url && (
                  <button
                    type="button"
                    className="airport-info-clear-btn"
                    onClick={() => handleClear(slot.key)}
                    disabled={submitting}
                  >
                    삭제
                  </button>
                )}
              </div>
            )}

            {editing === slot.key && (
              <form action={(fd) => handleUpload(slot.key, fd)} className="meal-edit-form">
                <input type="file" name="file" accept="image/*" />
                <div className="airport-info-edit-actions">
                  <button type="submit" className="btn-primary" disabled={submitting}>
                    {submitting ? '저장 중...' : '저장'}
                  </button>
                  <button
                    type="button"
                    className="btn-secondary"
                    onClick={() => setEditing(null)}
                  >
                    취소
                  </button>
                </div>
              </form>
            )}
          </div>
        ))}
      </div>
    </section>
  )
}
MEALEOF

cat > app/page.tsx << 'MEALEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;

import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { supabase as supabaseData } from "@/lib/supabaseClient";
import { IconPlane, IconPin, IconFilePreview } from "@/components/icons";
import MealBoard from "./MealBoard";

export default async function DashboardPage() {
  const [{ data: notices }, { data: mealInfo }] = await Promise.all([
    supabase
      .from("notices")
      .select("*")
      .order("id", { ascending: false })
      .limit(3),
    supabaseData.from("meal_board").select("*").eq("id", 1).maybeSingle(),
  ]);

  return (
    <>
      <header className="top">
        <div>
          <h2>
            <IconPlane size={20} className="page-title-icon" /> Ramp Control Team 포털
          </h2>
          <p>오늘의 업무지시와 자료 현황을 한눈에 확인하세요</p>
        </div>

        <form action="/search" method="GET" className="header-search">
          <input type="text" name="q" placeholder="전체 검색..." />
          <button type="submit" aria-label="검색">
            <IconFilePreview size={16} />
          </button>
        </form>
      </header>

      <div className="dashboard-grid">
        {/* 최근 업무지시공유 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>
              <IconPin size={15} className="page-title-icon" /> 최근 업무지시공유
            </h3>
            <Link href="/notices" className="dashboard-more">
              전체보기
            </Link>
          </div>
          {(!notices || notices.length === 0) && (
            <p className="empty">등록된 글이 없습니다.</p>
          )}
          <ul className="dashboard-list">
            {notices?.map((notice) => (
              <li key={notice.id}>
                <Link href={`/notices/${notice.id}`} className="dashboard-list-title">
                  {notice.title}
                </Link>
                <span className="dashboard-list-meta">{notice.author}</span>
              </li>
            ))}
          </ul>
        </section>
      </div>

      <MealBoard info={mealInfo ?? null} />
    </>
  );
}
MEALEOF

cat > app/globals.css << 'MEALEOF'
@import url("https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.css");

:root {
  --color-navy: #0b1f3a;
  --color-navy-light: #16345d;
  --color-orange: #ea6a12;
  --color-orange-dark: #d15f0f;
  --color-orange-soft: #fdece0;
  --color-bg: #f5f6f8;
  --color-surface: #ffffff;
  --color-border: #e6e8ec;
  --color-text: #172033;
  --color-text-muted: #667085;
  --color-danger: #d92d20;
  --radius-md: 12px;
  --radius-lg: 16px;
  --shadow-card: 0 1px 2px rgba(16, 24, 40, 0.04), 0 1px 3px rgba(16, 24, 40, 0.06);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: var(--color-bg);
  font-family: "Pretendard", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
    sans-serif;
  color: var(--color-text);
}

.layout {
  display: flex;
  min-height: 100vh;
}

/* ================= 사이드바 ================= */
.sidebar {
  width: 260px;
  flex-shrink: 0;
  background: var(--color-navy);
  color: white;
  padding: 32px 20px;
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
}

.brand {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 0 6px 28px 6px;
  margin-bottom: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.12);
}

.brand-line1 {
  font-size: 20px;
  font-weight: 800;
  letter-spacing: 0.5px;
  color: var(--color-orange);
}

.brand-line2 {
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 1.2px;
  color: rgba(255, 255, 255, 0.75);
}

nav {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.menu {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 14px;
  border-radius: var(--radius-md);
  cursor: pointer;
  color: rgba(255, 255, 255, 0.82);
  font-size: 14px;
  font-weight: 500;
  border-left: 3px solid transparent;
  transition: background 0.15s ease, color 0.15s ease;
}

.menu-icon {
  display: inline-flex;
  align-items: center;
}

.menu:hover {
  background: rgba(255, 255, 255, 0.06);
  color: white;
}

.menu.active {
  background: rgba(234, 106, 18, 0.16);
  color: white;
  border-left-color: var(--color-orange);
  font-weight: 700;
}

.brand-link {
  text-decoration: none;
  cursor: pointer;
}

.sidebar nav a {
  text-decoration: none;
  color: inherit;
  font-size: inherit;
  font-weight: inherit;
  display: block;
}

.sidebar nav a:visited {
  color: inherit;
}

/* ================= 본문 ================= */
.content {
  flex: 1;
  padding: 40px 48px;
  min-width: 0;
}

.top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 28px;
}

.top h2 {
  font-size: 24px;
  font-weight: 800;
  margin: 0 0 6px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.page-title-icon {
  color: var(--color-orange);
}

.top p {
  color: var(--color-text-muted);
  margin: 0;
}

.top span {
  background: var(--color-orange-soft);
  color: var(--color-orange-dark);
  padding: 8px 15px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
}

/* 카드 / 작성 박스 */
.writeBox,
.card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 24px;
  margin-top: 20px;
  box-shadow: var(--shadow-card);
}

.card h3 {
  margin-top: 0;
  font-size: 16px;
  font-weight: 700;
}

.noticeList {
  display: grid;
  gap: 14px;
  margin-top: 16px;
}

.meta {
  margin-top: 14px;
  font-size: 13px;
  color: var(--color-text-muted);
  line-height: 1.6;
}

/* 폼 */
input,
textarea {
  width: 100%;
  padding: 12px 14px;
  margin-bottom: 12px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  font-family: inherit;
  font-size: 14px;
}

input:focus,
textarea:focus {
  outline: none;
  border-color: var(--color-orange);
  box-shadow: 0 0 0 3px var(--color-orange-soft);
}

textarea {
  height: 110px;
  resize: vertical;
}

/* 버튼 */
button {
  font-family: inherit;
  font-size: 14px;
  font-weight: 600;
  border: 0;
  border-radius: 10px;
  padding: 12px 22px;
  cursor: pointer;
  transition: background 0.15s ease, opacity 0.15s ease;
}

.btn-primary,
.top > button,
form > button[type="submit"] {
  background: var(--color-orange);
  color: white;
}

.btn-primary:hover {
  background: var(--color-orange-dark);
}

.btn-secondary {
  background: var(--color-bg);
  color: var(--color-text);
  border: 1px solid var(--color-border);
}

.form-actions {
  display: flex;
  gap: 8px;
}

.deleteButton {
  margin-top: 15px;
  background: transparent;
  color: var(--color-danger);
  border: 1px solid #fda29b;
  cursor: pointer;
}

.deleteButton:hover {
  background: #fef3f2;
}

.notice-card {
  position: relative;
  padding-right: 70px;
}

.notice-delete-form {
  position: absolute;
  top: 16px;
  right: 16px;
  margin: 0;
}

.notice-delete-form .deleteButton {
  margin-top: 0;
  padding: 6px 10px;
  border-radius: 8px;
}

/* 업무지시 - 리치텍스트 에디터 */
.rte-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}

.rte-toolbar select,
.rte-toolbar button,
.rte-image-btn {
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 6px 10px;
  font-size: 13px;
  background: #fff;
  cursor: pointer;
  color: var(--color-text);
}

.rte-toolbar input[type="color"] {
  width: 34px;
  height: 32px;
  padding: 2px;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  cursor: pointer;
}

.rte-image-btn {
  display: inline-flex;
  align-items: center;
}

.rte-divider {
  width: 1px;
  height: 20px;
  background: var(--color-border);
  margin: 0 2px;
}

.rte-hint {
  font-size: 12px;
  color: var(--color-text-muted);
  margin: -4px 0 8px 0;
}

.rte-table-menu {
  position: relative;
}

.rte-table-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  z-index: 20;
  display: flex;
  flex-direction: column;
  min-width: 120px;
  background: #fff;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  box-shadow: var(--shadow-card);
  padding: 6px;
  gap: 2px;
}

.rte-table-dropdown button {
  border: none;
  background: none;
  text-align: left;
  padding: 8px 10px;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
}

.rte-table-dropdown button:hover {
  background: var(--color-bg);
}

/* 공용 작성 팝업 (DocForm) */
.doc-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 24px;
}

.doc-modal {
  background: #fff;
  border-radius: var(--radius-lg);
  width: 100%;
  max-width: 760px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.25);
}

.doc-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid var(--color-border);
  position: sticky;
  top: 0;
  background: #fff;
  z-index: 1;
}

.doc-modal-header h3 {
  margin: 0;
  font-size: 17px;
}

.doc-modal-close {
  background: none;
  border: none;
  font-size: 16px;
  cursor: pointer;
  color: var(--color-text-muted);
  padding: 4px 8px;
}

.doc-modal-close:hover {
  color: var(--color-text);
}

.doc-modal-form {
  padding: 20px 24px 24px;
}

.doc-modal-title {
  width: 100%;
  font-size: 16px;
  font-weight: 700;
  border: none;
  border-bottom: 1px solid var(--color-border);
  padding: 8px 0;
  margin-bottom: 14px;
  border-radius: 0;
}

.doc-modal-title:focus {
  outline: none;
  border-bottom-color: var(--color-orange);
}

.doc-modal-editor {
  min-height: 320px;
}

.doc-modal-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 14px;
  flex-wrap: wrap;
}

.doc-modal-file-label {
  font-size: 13px;
  color: var(--color-text-muted);
  display: flex;
  align-items: center;
  gap: 6px;
}

.doc-modal-file {
  border: none;
  padding: 0;
  font-size: 13px;
}

.doc-modal-author {
  max-width: 200px;
  margin-bottom: 0 !important;
}

.rte-editor {
  min-height: 160px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  padding: 12px 14px;
  margin-bottom: 12px;
  font-size: 14px;
  line-height: 1.6;
  white-space: pre-wrap;
  overflow-wrap: break-word;
}

.rte-editor:focus {
  outline: none;
  border-color: var(--color-orange);
  box-shadow: 0 0 0 3px var(--color-orange-soft);
}

.rte-editor img {
  max-width: 100%;
  border-radius: 6px;
  margin: 6px 0;
}

.rte-editor table,
.notice-content-preview table,
.notice-detail-content table {
  border-collapse: collapse;
  margin: 8px 0;
}

.rte-editor td,
.notice-content-preview td,
.notice-detail-content td {
  border: 1px solid #d1d5db;
  padding: 8px;
}

.notice-content-preview td,
.notice-detail-content td {
  resize: none !important;
  overflow: visible !important;
}

/* 업무지시 목록/상세 */
.notice-title-link {
  text-decoration: none;
  color: inherit;
}

.notice-title-link h3 {
  margin: 0 0 8px 0;
}

.notice-title-link:hover h3 {
  color: var(--color-orange-dark);
}

.notice-content-preview {
  font-size: 14px;
  line-height: 1.6;
  max-height: 120px;
  overflow: hidden;
  color: var(--color-text);
}

.notice-content-preview img {
  max-width: 100%;
  border-radius: 6px;
}

.notice-detail-content {
  margin-top: 20px;
  font-size: 15px;
  line-height: 1.7;
}

.notice-detail-content img {
  max-width: 100%;
  border-radius: 8px;
  margin: 10px 0;
}

.attached-image {
  max-width: 100%;
  border-radius: 8px;
  margin-top: 16px;
  border: 1px solid var(--color-border);
}

.attachment-block {
  margin-top: 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.attachment-frame {
  width: 100%;
  height: 600px;
  border: 1px solid var(--color-border);
  border-radius: 8px;
}

.attachment-inline {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 16px;
}

.attachment-name {
  font-size: 14px;
  color: var(--color-text);
}

.attachment-preview-btn {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-navy);
  cursor: pointer;
}

.attachment-preview-btn:hover {
  border-color: var(--color-orange);
  color: var(--color-orange-dark);
}

.attachment-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  font-size: 13px;
  cursor: pointer;
  text-decoration: none;
  color: var(--color-navy);
}

.attachment-icon-btn:hover {
  border-color: var(--color-orange);
  background: var(--color-orange-soft);
}

.attachment-modal {
  max-width: 900px;
}

.attachment-modal-body {
  padding: 20px 24px 24px;
}

.dashboard-list-title {
  text-decoration: none;
  color: var(--color-text);
}

.dashboard-list-title:hover {
  color: var(--color-orange-dark);
  text-decoration: underline;
}

/* AIRPORT - 국내/해외 2분할 */
.airport-columns {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 40px;
  max-width: 720px;
}

.airport-column-title {
  font-size: 15px;
  font-weight: 800;
  color: var(--color-navy);
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 2px solid var(--color-orange);
}

/* 메인 - 식단 게시판 */
.meal-card {
  margin-top: 16px;
  max-width: 640px;
}

.meal-images {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.meal-slot {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.meal-image {
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
  border-radius: 10px;
  border: 1px solid var(--color-border);
}

.meal-empty {
  width: 100%;
  aspect-ratio: 4 / 3;
  border: 1px dashed var(--color-border);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 12px;
  font-size: 12px;
  color: var(--color-text-muted);
  background: var(--color-bg);
}

.meal-slot-actions {
  display: flex;
  gap: 6px;
}

.meal-edit-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  padding: 12px;
}

.meal-edit-form input[type="file"] {
  font-size: 12px;
}
MEALEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."