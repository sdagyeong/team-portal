#!/bin/bash
set -e

mkdir -p app app/contacts

cat > app/contacts/contactActions.ts << 'CONTACTSEOF'
'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

// ---------- 시스템 계정 ----------
export async function addSystemAccountRow() {
  const { error } = await supabase.from('system_accounts').insert({})
  if (error) {
    console.error(error)
    throw new Error('추가에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

export async function updateSystemAccountCell(id: number, field: string, value: string) {
  const { error } = await supabase
    .from('system_accounts')
    .update({ [field]: value, updated_at: new Date().toISOString() })
    .eq('id', id)
  if (error) {
    console.error(error)
    throw new Error('저장에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

export async function deleteSystemAccountRow(id: number) {
  const { error } = await supabase.from('system_accounts').delete().eq('id', id)
  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

// ---------- 유선 연락망 ----------
export async function addPhoneContactRow() {
  const { error } = await supabase.from('phone_contacts').insert({})
  if (error) {
    console.error(error)
    throw new Error('추가에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

export async function updatePhoneContactCell(id: number, field: string, value: string) {
  const { error } = await supabase
    .from('phone_contacts')
    .update({ [field]: value, updated_at: new Date().toISOString() })
    .eq('id', id)
  if (error) {
    console.error(error)
    throw new Error('저장에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

export async function deletePhoneContactRow(id: number) {
  const { error } = await supabase.from('phone_contacts').delete().eq('id', id)
  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }
  revalidatePath('/contacts')
}
CONTACTSEOF

cat > app/contacts/EditableTable.tsx << 'CONTACTSEOF'
'use client'

import { useState } from 'react'
import { IconTrash, IconPlus } from '@/components/icons'

export type Column = { key: string; label: string; width?: string }

export default function EditableTable({
  rows,
  columns,
  onUpdateCell,
  onDeleteRow,
  onAddRow,
}: {
  rows: Record<string, string | number | null>[]
  columns: Column[]
  onUpdateCell: (id: number, field: string, value: string) => Promise<void>
  onDeleteRow: (id: number) => Promise<void>
  onAddRow: () => Promise<void>
}) {
  const [editing, setEditing] = useState<{ id: number; field: string } | null>(null)
  const [busy, setBusy] = useState(false)

  async function save(id: number, field: string, value: string) {
    setBusy(true)
    try {
      await onUpdateCell(id, field, value)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
      setEditing(null)
    }
  }

  async function handleDelete(id: number) {
    if (!confirm('이 행을 삭제할까요?')) return
    setBusy(true)
    try {
      await onDeleteRow(id)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
    }
  }

  async function handleAdd() {
    setBusy(true)
    try {
      await onAddRow()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="edit-table-wrap">
      <table className="edit-table">
        <thead>
          <tr>
            {columns.map((c) => (
              <th key={c.key} style={{ width: c.width }}>
                {c.label}
              </th>
            ))}
            <th style={{ width: 40 }} />
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 && (
            <tr>
              <td colSpan={columns.length + 1} className="edit-table-empty-row">
                등록된 항목이 없습니다.
              </td>
            </tr>
          )}
          {rows.map((row) => {
            const id = row.id as number
            return (
              <tr key={id}>
                {columns.map((c) => {
                  const isEditing = editing?.id === id && editing.field === c.key
                  const value = row[c.key]
                  return (
                    <td
                      key={c.key}
                      onClick={() => !isEditing && setEditing({ id, field: c.key })}
                    >
                      {isEditing ? (
                        <textarea
                          autoFocus
                          defaultValue={(value as string) ?? ''}
                          disabled={busy}
                          onBlur={(e) => save(id, c.key, e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter' && !e.shiftKey) {
                              e.preventDefault()
                              ;(e.target as HTMLTextAreaElement).blur()
                            }
                            if (e.key === 'Escape') setEditing(null)
                          }}
                        />
                      ) : value ? (
                        <span className="edit-table-cell-value">{value}</span>
                      ) : (
                        <span className="edit-table-cell-empty">-</span>
                      )}
                    </td>
                  )
                })}
                <td>
                  <button
                    type="button"
                    className="doc-row-delete"
                    onClick={() => handleDelete(id)}
                    aria-label="삭제"
                  >
                    <IconTrash />
                  </button>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>

      <button type="button" className="edit-table-add" onClick={handleAdd} disabled={busy}>
        <IconPlus size={13} /> 행 추가
      </button>
    </div>
  )
}
CONTACTSEOF

cat > app/contacts/ContactsBoard.tsx << 'CONTACTSEOF'
'use client'

import { useState } from 'react'
import EditableTable, { type Column } from './EditableTable'
import {
  addSystemAccountRow,
  updateSystemAccountCell,
  deleteSystemAccountRow,
  addPhoneContactRow,
  updatePhoneContactCell,
  deletePhoneContactRow,
} from './contactActions'

const ACCOUNT_COLUMNS: Column[] = [
  { key: 'group_name', label: '그룹', width: '110px' },
  { key: 'system_name', label: '시스템명', width: '160px' },
  { key: 'url', label: 'URL', width: '180px' },
  { key: 'detail', label: '내용', width: '120px' },
  { key: 'account_id', label: 'ID', width: '110px' },
  { key: 'password', label: 'PW', width: '110px' },
  { key: 'note', label: '비고' },
]

const CONTACT_COLUMNS: Column[] = [
  { key: 'name', label: '이름', width: '100px' },
  { key: 'position', label: '소속/직책', width: '160px' },
  { key: 'office_phone', label: '사무실 전화', width: '140px' },
  { key: 'mobile', label: '휴대폰', width: '140px' },
  { key: 'note', label: '비고' },
]

type Row = Record<string, string | number | null>

export default function ContactsBoard({
  systemAccounts,
  phoneContacts,
}: {
  systemAccounts: Row[]
  phoneContacts: Row[]
}) {
  const [tab, setTab] = useState<'system' | 'phone'>('system')

  return (
    <div className="task-board">
      <div className="task-folder-tabs">
        <button
          type="button"
          className={`task-folder-tab ${tab === 'system' ? 'active' : ''}`}
          onClick={() => setTab('system')}
        >
          시스템 계정
        </button>
        <button
          type="button"
          className={`task-folder-tab ${tab === 'phone' ? 'active' : ''}`}
          onClick={() => setTab('phone')}
        >
          유선 연락망
        </button>
      </div>

      {tab === 'system' ? (
        <EditableTable
          rows={systemAccounts}
          columns={ACCOUNT_COLUMNS}
          onUpdateCell={updateSystemAccountCell}
          onDeleteRow={deleteSystemAccountRow}
          onAddRow={addSystemAccountRow}
        />
      ) : (
        <EditableTable
          rows={phoneContacts}
          columns={CONTACT_COLUMNS}
          onUpdateCell={updatePhoneContactCell}
          onDeleteRow={deletePhoneContactRow}
          onAddRow={addPhoneContactRow}
        />
      )}
    </div>
  )
}
CONTACTSEOF

cat > app/contacts/page.tsx << 'CONTACTSEOF'
import { supabase } from '@/lib/supabaseClient'
import ContactsBoard from './ContactsBoard'
import { IconContact } from '@/components/icons'

export const dynamic = 'force-dynamic'

export default async function ContactsPage() {
  const [{ data: systemAccounts, error: accError }, { data: phoneContacts, error: contactError }] =
    await Promise.all([
      supabase.from('system_accounts').select('*').order('id', { ascending: true }),
      supabase.from('phone_contacts').select('*').order('id', { ascending: true }),
    ])

  if (accError) console.error(accError)
  if (contactError) console.error(contactError)

  return (
    <div className="page">
      <h1>
        <IconContact size={20} className="page-title-icon" /> 계정/연락망
      </h1>

      <ContactsBoard
        systemAccounts={systemAccounts ?? []}
        phoneContacts={phoneContacts ?? []}
      />
    </div>
  )
}
CONTACTSEOF

cat > app/globals.css << 'CONTACTSEOF'
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

/* 메인 헤더 - 전체 검색 */
.header-search {
  display: flex;
  align-items: center;
  background: #fff;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  overflow: hidden;
  height: 38px;
  flex-shrink: 0;
}

.header-search-category {
  border: none;
  border-right: 1px solid var(--color-border);
  background: var(--color-bg);
  height: 100%;
  padding: 0 10px;
  font-size: 12px;
  font-weight: 600;
  color: var(--color-navy);
  max-width: 130px;
  cursor: pointer;
}

.header-search-category:focus {
  outline: none;
}

.header-search input {
  border: none;
  padding: 0 12px;
  font-size: 13px;
  width: 220px;
  height: 100%;
  margin: 0;
  border-radius: 0;
}

.header-search input:focus {
  outline: none;
  box-shadow: none;
}

.header-search button[type="submit"] {
  border: none;
  background: var(--color-navy);
  color: #fff;
  height: 100%;
  width: 44px;
  padding: 0;
  margin: 0;
  border-radius: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
}

.header-search button[type="submit"]:hover {
  background: var(--color-navy-light);
}

/* 헤더 오른쪽 영역(검색+작성버튼) 정렬 */
.top-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

/* 검색 드롭다운 */
.header-search-wrap {
  position: relative;
  flex-shrink: 0;
}

.search-dropdown {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  width: 340px;
  max-height: 360px;
  overflow-y: auto;
  background: #fff;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.12);
  z-index: 50;
  padding: 6px;
}

.search-dropdown-item {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  width: 100%;
  text-align: left;
  background: none;
  border: none;
  border-radius: 8px;
  padding: 8px 10px;
  cursor: pointer;
  gap: 2px;
}

.search-dropdown-item:hover {
  background: var(--color-bg);
}

.search-dropdown-type {
  font-size: 11px;
  font-weight: 700;
  color: var(--color-orange-dark);
}

.search-dropdown-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text);
}

.search-dropdown-author {
  font-size: 11px;
  color: var(--color-text-muted);
}

.search-dropdown-empty {
  padding: 14px 10px;
  font-size: 13px;
  color: var(--color-text-muted);
  text-align: center;
}

.search-dropdown-more {
  width: 100%;
  text-align: center;
  background: var(--color-bg);
  border: none;
  border-radius: 8px;
  padding: 9px;
  font-size: 12px;
  font-weight: 600;
  color: var(--color-navy);
  cursor: pointer;
  margin-top: 4px;
}

.search-dropdown-more:hover {
  color: var(--color-orange-dark);
}

/* 계정/연락망 - 편집 가능한 표 */
.edit-table-wrap {
  overflow-x: auto;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
  padding: 4px;
}

.edit-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.edit-table th {
  text-align: left;
  padding: 10px 12px;
  background: var(--color-bg);
  color: var(--color-navy);
  font-weight: 700;
  font-size: 12px;
  border-bottom: 2px solid var(--color-border);
  white-space: nowrap;
}

.edit-table td {
  padding: 0;
  border-bottom: 1px solid var(--color-border);
  vertical-align: top;
  cursor: pointer;
}

.edit-table-cell-value {
  display: block;
  padding: 9px 12px;
  white-space: pre-wrap;
  word-break: break-word;
  min-height: 18px;
}

.edit-table-cell-empty {
  display: block;
  padding: 9px 12px;
  color: #c7cbd3;
}

.edit-table td textarea {
  width: 100%;
  min-height: 36px;
  border: none;
  padding: 9px 12px;
  font-size: 13px;
  font-family: inherit;
  resize: vertical;
  background: var(--color-orange-soft);
}

.edit-table td textarea:focus {
  outline: none;
}

.edit-table-empty-row {
  text-align: center;
  color: var(--color-text-muted);
  padding: 24px !important;
  cursor: default !important;
}

.edit-table-add {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin: 10px 6px 6px;
  background: var(--color-orange);
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.edit-table-add:hover {
  background: var(--color-orange-dark);
}

.edit-table-add:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.edit-table tr:last-child td {
  border-bottom: none;
}
CONTACTSEOF

# 예전 글쓰기 방식 파일 정리(더 이상 사용 안 함)
rm -f app/contacts/DocumentForm.tsx app/contacts/documentActions.ts
rm -rf 'app/contacts/doc'

echo "적용 완료. npm run dev 재시작 후 확인하세요."