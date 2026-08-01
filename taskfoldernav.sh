#!/bin/bash
set -e

mkdir -p app app/tasks

cat > app/tasks/DocumentForm.tsx << 'NAVEOF'
'use client'

import { useRef, useState } from 'react'
import { addDocument } from './documentActions'

export default function DocumentForm({
  docType,
  region,
}: {
  docType: '보고서' | '주기장요도'
  region: '국내' | '해외'
}) {
  const formRef = useRef<HTMLFormElement>(null)
  const [open, setOpen] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(formData: FormData) {
    setSubmitting(true)
    try {
      await addDocument(formData)
      formRef.current?.reset()
      setOpen(false)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  if (!open) {
    return (
      <button type="button" className="btn-primary" onClick={() => setOpen(true)}>
        + {docType} 작성
      </button>
    )
  }

  return (
    <form ref={formRef} action={handleSubmit} className="document-form">
      <input type="hidden" name="doc_type" value={docType} />
      <input type="hidden" name="region" value={region} />
      <input name="title" placeholder="제목" required />
      <textarea name="description" placeholder="내용" rows={3} />
      <input name="author" placeholder="작성자" required />
      <input type="file" name="file" accept=".pdf,.jpg,.jpeg,.png,.xlsx,.xls" />
      <div className="form-actions">
        <button type="submit" disabled={submitting}>
          {submitting ? '업로드 중...' : '등록'}
        </button>
        <button type="button" className="btn-secondary" onClick={() => setOpen(false)}>
          닫기
        </button>
      </div>
    </form>
  )
}
NAVEOF

cat > app/tasks/TaskBoard.tsx << 'NAVEOF'
'use client'

import { useState } from 'react'
import { toggleTaskStatus, deleteTask } from './actions'
import { deleteDocument } from './documentActions'
import DocumentForm from './DocumentForm'
import TaskForm from './TaskForm'

type Task = {
  id: number
  title: string
  description: string | null
  assignee: string
  due_date: string | null
  status: string
  category: string
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

type DocFolder = '보고서' | '주기장요도'

type Step =
  | { level: 'root' }
  | { level: 'region'; folder: DocFolder }
  | { level: 'content'; folder: DocFolder; region: '국내' | '해외' }
  | { level: 'content'; folder: '업무지시공유' }

function DocList({ docs }: { docs: Doc[] }) {
  return (
    <div className="card-list">
      {docs.length === 0 && <p className="empty">등록된 자료가 없습니다.</p>}
      {docs.map((doc) => (
        <div key={doc.id} className="card">
          <h3>{doc.title}</h3>
          {doc.description && <p>{doc.description}</p>}
          <p className="meta">작성자 : {doc.author}</p>
          <p className="meta">
            작성일 : {new Date(doc.created_at).toLocaleDateString('ko-KR')}
          </p>
          {doc.file_url && (
            <a className="file-link" href={doc.file_url} target="_blank" rel="noreferrer">
              📎 {doc.file_name} 다운로드
            </a>
          )}
          <form
            action={async () => {
              await deleteDocument(doc.id)
            }}
          >
            <button type="submit" className="btn-delete">
              🗑 삭제
            </button>
          </form>
        </div>
      ))}
    </div>
  )
}

export default function TaskBoard({
  tasks,
  documents,
}: {
  tasks: Task[]
  documents: Doc[]
}) {
  const [step, setStep] = useState<Step>({ level: 'root' })

  // 1단계: 보고서 / 주기장요도 / 업무지시공유
  if (step.level === 'root') {
    return (
      <div className="task-board">
        <div className="folder-menu">
          <div className="folder-group">
            <button
              type="button"
              className="folder-item"
              onClick={() => setStep({ level: 'region', folder: '보고서' })}
            >
              📋 보고서
            </button>
            <button
              type="button"
              className="folder-item"
              onClick={() => setStep({ level: 'region', folder: '주기장요도' })}
            >
              🗺️ 주기장요도
            </button>
          </div>

          <div className="folder-group folder-group-separate">
            <button
              type="button"
              className="folder-item"
              onClick={() => setStep({ level: 'content', folder: '업무지시공유' })}
            >
              📌 업무지시공유
            </button>
          </div>
        </div>
      </div>
    )
  }

  // 2단계: 보고서/주기장요도 선택 후 국내/해외
  if (step.level === 'region') {
    return (
      <div className="task-board">
        <button type="button" className="breadcrumb-back" onClick={() => setStep({ level: 'root' })}>
          ← 뒤로
        </button>
        <h2 className="folder-title">
          {step.folder === '보고서' ? '📋' : '🗺️'} {step.folder}
        </h2>
        <div className="folder-menu">
          <div className="folder-group">
            <button
              type="button"
              className="folder-item"
              onClick={() => setStep({ level: 'content', folder: step.folder, region: '국내' })}
            >
              국내
            </button>
            <button
              type="button"
              className="folder-item"
              onClick={() => setStep({ level: 'content', folder: step.folder, region: '해외' })}
            >
              해외
            </button>
          </div>
        </div>
      </div>
    )
  }

  // 3단계 - 업무지시공유
  if (step.folder === '업무지시공유') {
    const filtered = tasks.filter((t) => t.category === '업무지시공유')

    return (
      <div className="task-board">
        <button type="button" className="breadcrumb-back" onClick={() => setStep({ level: 'root' })}>
          ← 뒤로
        </button>
        <h2 className="folder-title">📌 업무지시공유</h2>

        <TaskForm />

        <div className="card-list">
          {filtered.length === 0 && <p className="empty">등록된 업무가 없습니다.</p>}
          {filtered.map((task) => (
            <div key={task.id} className="card">
              <div className="task-header">
                <h3>{task.title}</h3>
                <span className={`badge ${task.status === '완료' ? 'done' : 'progress'}`}>
                  {task.status}
                </span>
              </div>
              {task.description && <p>{task.description}</p>}
              <p className="meta">담당자 : {task.assignee}</p>
              {task.due_date && <p className="meta">마감일 : {task.due_date}</p>}
              <div className="task-actions">
                <form
                  action={async () => {
                    await toggleTaskStatus(task.id, task.status)
                  }}
                >
                  <button type="submit" className="btn-toggle">
                    {task.status === '완료' ? '진행중으로 변경' : '완료 처리'}
                  </button>
                </form>
                <form
                  action={async () => {
                    await deleteTask(task.id)
                  }}
                >
                  <button type="submit" className="btn-delete">
                    🗑 삭제
                  </button>
                </form>
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  // 3단계 - 보고서/주기장요도 (국내 또는 해외 선택 후)
  const filteredDocs = documents.filter(
    (d) => d.doc_type === step.folder && d.region === step.region
  )

  return (
    <div className="task-board">
      <button
        type="button"
        className="breadcrumb-back"
        onClick={() => setStep({ level: 'region', folder: step.folder })}
      >
        ← 뒤로
      </button>
      <h2 className="folder-title">
        {step.folder} - {step.region}
      </h2>

      <DocumentForm docType={step.folder} region={step.region} />
      <DocList docs={filteredDocs} />
    </div>
  )
}
NAVEOF

cat > app/portal-styles.css << 'NAVEOF'
/* 자료실 / 일정관리 / 업무관리 공통 스타일
   globals.css 의 :root 변수(--color-orange 등)를 그대로 사용합니다 */

.page {
  padding: 0;
}

.page h1 {
  font-size: 24px;
  font-weight: 800;
  margin-bottom: 6px;
}

.page-desc {
  color: var(--color-text-muted);
  margin-bottom: 28px;
}

/* 등록 폼 */
.resource-form,
.schedule-form,
.task-form,
.document-form {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-width: 480px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 20px;
  margin-bottom: 28px;
  box-shadow: var(--shadow-card);
}

.resource-form input,
.resource-form textarea,
.schedule-form input,
.schedule-form textarea,
.task-form input,
.task-form textarea,
.task-form select,
.document-form input,
.document-form textarea,
.document-form select {
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 10px 12px;
  font-size: 14px;
  font-family: inherit;
  background: #fff;
}

.date-row {
  display: flex;
  gap: 12px;
}

.date-row label {
  display: flex;
  flex-direction: column;
  font-size: 12px;
  color: var(--color-text-muted);
  gap: 4px;
  flex: 1;
}

.resource-form button,
.schedule-form button,
.task-form button,
.document-form button {
  background: var(--color-orange);
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 10px 16px;
  font-weight: 600;
  cursor: pointer;
  align-self: flex-start;
}

.resource-form button:hover,
.schedule-form button:hover,
.task-form button:hover,
.document-form button:hover {
  background: var(--color-orange-dark);
}

.resource-form button:disabled,
.schedule-form button:disabled,
.task-form button:disabled,
.document-form button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* 카드 목록 */
.card-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.card .meta {
  font-size: 13px;
  color: var(--color-text-muted);
}

.file-link {
  display: inline-block;
  margin-top: 8px;
  color: var(--color-navy);
  font-weight: 600;
  text-decoration: underline;
}

.file-link:hover {
  color: var(--color-orange);
}

.empty {
  color: #9ca3af;
  padding: 20px 0;
}

.btn-delete {
  margin-top: 12px;
  background: transparent;
  color: var(--color-danger);
  border: 1px solid #fda29b;
  border-radius: 8px;
  padding: 8px 16px;
  font-weight: 600;
  cursor: pointer;
}

.btn-delete:hover {
  background: #fef3f2;
}

/* 캘린더 그리드 */
.calendar {
  max-width: 640px;
}

.calendar-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 12px;
}

.calendar-header h3 {
  font-size: 16px;
  font-weight: 700;
}

.calendar-header button {
  background: none;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  width: 32px;
  height: 32px;
  cursor: pointer;
  padding: 0;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
  margin-bottom: 24px;
}

.calendar-weekday {
  text-align: center;
  font-size: 12px;
  color: #9ca3af;
  padding: 6px 0;
}

.calendar-cell {
  position: relative;
  aspect-ratio: 1;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
}

.calendar-cell.empty {
  border: none;
  cursor: default;
}

.calendar-cell.today {
  border-color: var(--color-orange);
  font-weight: 700;
}

.calendar-cell.selected {
  background: var(--color-navy);
  color: #fff;
  border-color: var(--color-navy);
}

.calendar-cell .dot {
  position: absolute;
  bottom: 4px;
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--color-orange);
}

.calendar-cell.selected .dot {
  background: #fff;
}

.schedule-list h4 {
  margin-bottom: 12px;
  font-size: 15px;
}

/* 업무관리 */
.task-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.badge {
  font-size: 12px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 999px;
  white-space: nowrap;
}

.badge.progress {
  background: #fef3c7;
  color: #92400e;
}

.badge.done {
  background: #dcfce7;
  color: #166534;
}

.task-actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

.btn-toggle {
  background: var(--color-navy);
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-weight: 600;
  cursor: pointer;
}

.btn-toggle:hover {
  background: var(--color-navy-light);
}

.task-category {
  margin-top: 32px;
}

.task-category-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  font-weight: 700;
  color: var(--color-navy);
  padding-bottom: 8px;
  margin-bottom: 14px;
  border-bottom: 1px solid var(--color-border);
}

.task-category-count {
  background: var(--color-orange-soft);
  color: var(--color-orange-dark);
  font-size: 12px;
  font-weight: 700;
  padding: 2px 9px;
  border-radius: 999px;
}

/* 메인 대시보드 */
.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 16px;
  margin-top: 8px;
}

.dashboard-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 22px;
  box-shadow: var(--shadow-card);
}

.dashboard-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.dashboard-card-header h3 {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
}

.dashboard-more {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-orange-dark);
  text-decoration: none;
}

.dashboard-more:hover {
  text-decoration: underline;
}

.dashboard-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.dashboard-list li {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 13px;
  padding-bottom: 10px;
  border-bottom: 1px solid var(--color-border);
}

.dashboard-list li:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.dashboard-list-title {
  font-weight: 600;
  color: var(--color-text);
}

.dashboard-list-meta {
  color: var(--color-text-muted);
  white-space: nowrap;
}

.dashboard-stats {
  display: flex;
  gap: 24px;
}

.dashboard-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.dashboard-stat-num {
  font-size: 28px;
  font-weight: 800;
  color: var(--color-navy);
}

.dashboard-stat-label {
  font-size: 12px;
  color: var(--color-text-muted);
}

/* 업무관리 - 폴더 탭 구조 */
.task-board {
  margin-top: 8px;
}

.task-folder-tabs {
  display: inline-flex;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 999px;
  padding: 4px;
  gap: 2px;
  margin-bottom: 20px;
}

.task-folder-tab {
  background: none;
  border: none;
  padding: 9px 22px;
  font-size: 14px;
  font-weight: 600;
  color: var(--color-text-muted);
  border-radius: 999px;
  cursor: pointer;
}

.task-folder-tab:hover {
  color: var(--color-navy);
}

.task-folder-tab.active {
  background: var(--color-navy);
  color: #fff;
}

/* 업무관리 - 폴더 네비게이션 */
.folder-menu {
  display: flex;
  flex-direction: column;
  max-width: 340px;
}

.folder-group {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.folder-group-separate {
  margin-top: 28px;
  padding-top: 20px;
  border-top: 1px solid var(--color-border);
}

.folder-item {
  display: flex;
  align-items: center;
  gap: 10px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 16px 20px;
  font-size: 15px;
  font-weight: 700;
  color: var(--color-text);
  cursor: pointer;
  text-align: left;
  box-shadow: var(--shadow-card);
}

.folder-item:hover {
  border-color: var(--color-orange);
  color: var(--color-orange-dark);
}

.breadcrumb-back {
  background: none;
  border: none;
  color: var(--color-text-muted);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  padding: 0;
  margin-bottom: 14px;
}

.breadcrumb-back:hover {
  color: var(--color-navy);
}

.folder-title {
  font-size: 18px;
  font-weight: 800;
  margin-bottom: 18px;
}
NAVEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."