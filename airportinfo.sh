#!/bin/bash
set -e

mkdir -p app app/tasks

cat > app/tasks/airportInfoActions.ts << 'AIRPORTINFOEOF'
'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function saveAirportInfo(formData: FormData) {
  const airport = formData.get('airport') as string
  const field = formData.get('field') as string
  const textValue = formData.get('value_text') as string | null
  const file = formData.get('value_file') as File | null

  let updateValue: string | null = textValue

  if (field === 'apron_diagram_url' && file && file.size > 0) {
    const filePath = `airport-info/${airport}_${Date.now()}_${file.name}`

    const { error: uploadError } = await supabase.storage
      .from('task-documents')
      .upload(filePath, file)

    if (uploadError) {
      console.error(uploadError)
      throw new Error('이미지 업로드에 실패했습니다.')
    }

    const { data } = supabase.storage.from('task-documents').getPublicUrl(filePath)
    updateValue = data.publicUrl
  }

  const { error } = await supabase
    .from('airport_info')
    .upsert(
      { airport, [field]: updateValue, updated_at: new Date().toISOString() },
      { onConflict: 'airport' }
    )

  if (error) {
    console.error(error)
    throw new Error('저장에 실패했습니다.')
  }

  revalidatePath('/tasks')
}
AIRPORTINFOEOF

cat > app/tasks/AirportInfoCard.tsx << 'AIRPORTINFOEOF'
'use client'

import { useState } from 'react'
import { saveAirportInfo } from './airportInfoActions'

type AirportInfo = {
  airport: string
  apron_diagram_url: string | null
  parking_stand: string | null
  active_runway: string | null
  deicing_pad: string | null
}

const FIELDS: {
  key: keyof Omit<AirportInfo, 'airport'>
  label: string
  type: 'image' | 'text'
}[] = [
  { key: 'apron_diagram_url', label: '주기장요도', type: 'image' },
  { key: 'parking_stand', label: '주기장', type: 'text' },
  { key: 'active_runway', label: '사용 활주로', type: 'text' },
  { key: 'deicing_pad', label: '제방빙장', type: 'text' },
]

export default function AirportInfoCard({
  airport,
  info,
}: {
  airport: string
  info: AirportInfo | null
}) {
  const [editing, setEditing] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSave(field: string, formData: FormData) {
    formData.set('airport', airport)
    formData.set('field', field)
    setSubmitting(true)
    try {
      await saveAirportInfo(formData)
      setEditing(null)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="airport-info-card">
      {FIELDS.map((f) => {
        const value = info?.[f.key] ?? null
        const isEditing = editing === f.key

        return (
          <div key={f.key} className="airport-info-row">
            <span className="airport-info-label">{f.label}</span>

            {!isEditing && (
              <>
                <div className="airport-info-value">
                  {f.type === 'image' ? (
                    value ? (
                      <img src={value} alt={f.label} className="airport-info-image" />
                    ) : (
                      <span className="empty">등록된 이미지가 없습니다.</span>
                    )
                  ) : value ? (
                    value
                  ) : (
                    <span className="empty">등록된 내용이 없습니다.</span>
                  )}
                </div>
                <button
                  type="button"
                  className="airport-info-edit-btn"
                  onClick={() => setEditing(f.key)}
                >
                  수정
                </button>
              </>
            )}

            {isEditing && (
              <form
                action={(fd) => handleSave(f.key, fd)}
                className="airport-info-edit-form"
              >
                {f.type === 'image' ? (
                  <input type="file" name="value_file" accept="image/*" />
                ) : (
                  <input
                    type="text"
                    name="value_text"
                    defaultValue={value ?? ''}
                    placeholder={f.label}
                  />
                )}
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
        )
      })}
    </div>
  )
}
AIRPORTINFOEOF

cat > app/tasks/TaskBoard.tsx << 'AIRPORTINFOEOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { deleteDocument } from './documentActions'
import DocumentForm from './DocumentForm'
import AirportInfoCard from './AirportInfoCard'
import { IconFileText, IconTrash, IconChevronLeft } from '@/components/icons'

type AirportInfo = {
  airport: string
  apron_diagram_url: string | null
  parking_stand: string | null
  active_runway: string | null
  deicing_pad: string | null
}

type Doc = {
  id: number
  doc_type: string
  region: string
  title: string
  description: string | null
  author: string
  file_url: string | null
  file_name: string | null
  created_at: string
}

const DOMESTIC = ['ICN', 'GMP', 'CJU', 'PUS', 'TAE', 'CJJ', 'KWJ']
const INTERNATIONAL = [
  'Japan',
  'Northeast Asia',
  'Vietnam',
  'Philippines',
  'Indonesia',
  'Singapore',
  'Thailand / Laos',
  'Malaysia',
  'Saipan',
  'Mongolia',
]

type Step =
  | { level: 'list' }
  | { level: 'sub'; airport: string }
  | { level: 'content'; airport: string }

function DocList({ docs }: { docs: Doc[] }) {
  return (
    <div className="doc-list">
      {docs.length === 0 && <p className="empty">등록된 자료가 없습니다.</p>}
      {docs.map((doc) => (
        <div key={doc.id} className="doc-row">
          <Link href={`/tasks/doc/${doc.id}`} className="doc-row-title">
            {doc.file_url && '📎 '}
            {doc.title}
          </Link>
          <span className="doc-row-author">{doc.author}</span>
          <span className="doc-row-date">
            {new Date(doc.created_at).toLocaleDateString('ko-KR')}
          </span>
          <form
            action={async () => {
              await deleteDocument(doc.id)
            }}
          >
            <button type="submit" className="doc-row-delete" aria-label="삭제">
              <IconTrash />
            </button>
          </form>
        </div>
      ))}
    </div>
  )
}

export default function TaskBoard({
  documents,
  airportInfoList,
}: {
  documents: Doc[]
  airportInfoList: AirportInfo[]
}) {
  const [step, setStep] = useState<Step>({ level: 'list' })

  function go(next: Step) {
    setStep(next)
  }

  // 국내 / 해외 2분할 목록
  if (step.level === 'list') {
    return (
      <div className="task-board">
        <div className="airport-columns">
          <div className="airport-column">
            <h3 className="airport-column-title">국내</h3>
            <div className="folder-menu">
              {DOMESTIC.map((code) => (
                <button
                  key={code}
                  type="button"
                  className="folder-item"
                  onClick={() => go({ level: 'sub', airport: code })}
                >
                  {code}
                </button>
              ))}
            </div>
          </div>

          <div className="airport-column">
            <h3 className="airport-column-title">해외</h3>
            <div className="folder-menu">
              {INTERNATIONAL.map((name) => (
                <button
                  key={name}
                  type="button"
                  className="folder-item"
                  onClick={() => go({ level: 'sub', airport: name })}
                >
                  {name}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    )
  }

  // 공항별 하위 폴더 (보고서)
  if (step.level === 'sub') {
    return (
      <div className="task-board">
        <button type="button" className="breadcrumb-back" onClick={() => go({ level: 'list' })}>
          <IconChevronLeft size={13} /> 뒤로
        </button>
        <h2 className="folder-title">{step.airport}</h2>

        <AirportInfoCard
          airport={step.airport}
          info={airportInfoList.find((i) => i.airport === step.airport) ?? null}
        />

        <div className="folder-menu">
          <button
            type="button"
            className="folder-item"
            onClick={() => go({ level: 'content', airport: step.airport })}
          >
            <IconFileText size={16} /> 보고서
          </button>
        </div>
      </div>
    )
  }

  // 컨텐츠 (작성/목록)
  const filteredDocs = documents.filter(
    (d) => d.doc_type === '보고서' && d.region === step.airport
  )

  return (
    <div className="task-board">
      <button
        type="button"
        className="breadcrumb-back"
        onClick={() => go({ level: 'sub', airport: step.airport })}
      >
        <IconChevronLeft size={13} /> 뒤로
      </button>

      <h2 className="folder-title">{step.airport} - 보고서</h2>

      <DocumentForm docType="보고서" region={step.airport} />

      <DocList docs={filteredDocs} />
    </div>
  )
}
AIRPORTINFOEOF

cat > app/tasks/page.tsx << 'AIRPORTINFOEOF'
import { supabase } from '@/lib/supabaseClient'
import TaskBoard from './TaskBoard'
import { IconPlane } from '@/components/icons'

export const dynamic = 'force-dynamic'

export default async function TasksPage() {
  const [{ data: documents, error: docError }, { data: airportInfo, error: infoError }] =
    await Promise.all([
      supabase.from('task_documents').select('*').order('created_at', { ascending: false }),
      supabase.from('airport_info').select('*'),
    ])

  if (docError) {
    console.error(docError)
  }
  if (infoError) {
    console.error(infoError)
  }

  return (
    <div className="page">
      <h1>
        <IconPlane size={20} className="page-title-icon" /> AIRPORT
      </h1>

      <TaskBoard documents={documents ?? []} airportInfoList={airportInfo ?? []} />
    </div>
  )
}
AIRPORTINFOEOF

cat > app/globals.css << 'AIRPORTINFOEOF'
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
  padding: 0;
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

/* AIRPORT - 공항 정보 카드 */
.airport-info-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
  margin-bottom: 20px;
  overflow: hidden;
  max-width: 640px;
}

.airport-info-row {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 20px;
  border-bottom: 1px solid var(--color-border);
}

.airport-info-row:last-child {
  border-bottom: none;
}

.airport-info-label {
  width: 90px;
  flex-shrink: 0;
  font-weight: 700;
  font-size: 13px;
  color: var(--color-navy);
}

.airport-info-value {
  flex: 1;
  font-size: 13px;
  color: var(--color-text);
}

.airport-info-image {
  max-height: 120px;
  border-radius: 6px;
  border: 1px solid var(--color-border);
}

.airport-info-edit-btn {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 5px 12px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  color: var(--color-navy);
  flex-shrink: 0;
}

.airport-info-edit-btn:hover {
  border-color: var(--color-orange);
  color: var(--color-orange-dark);
}

.airport-info-edit-form {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 8px;
}

.airport-info-edit-form input[type="text"] {
  flex: 1;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 6px 10px;
  font-size: 13px;
}

.airport-info-edit-actions {
  display: flex;
  gap: 6px;
  flex-shrink: 0;
}

.airport-info-edit-actions button {
  font-size: 12px;
  padding: 6px 10px;
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
AIRPORTINFOEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."