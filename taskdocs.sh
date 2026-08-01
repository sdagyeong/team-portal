#!/bin/bash
set -e

mkdir -p app app/tasks

cat > app/tasks/documentActions.ts << 'DOCSEOF'
'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function addDocument(formData: FormData) {
  const doc_type = formData.get('doc_type') as string
  const region = formData.get('region') as string
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const author = formData.get('author') as string
  const file = formData.get('file') as File | null

  let file_url: string | null = null
  let file_name: string | null = null

  if (file && file.size > 0) {
    const filePath = `${Date.now()}_${file.name}`

    const { error: uploadError } = await supabase.storage
      .from('task-documents')
      .upload(filePath, file)

    if (uploadError) {
      console.error(uploadError)
      throw new Error('파일 업로드에 실패했습니다.')
    }

    const { data: publicUrlData } = supabase.storage
      .from('task-documents')
      .getPublicUrl(filePath)

    file_url = publicUrlData.publicUrl
    file_name = file.name
  }

  const { error } = await supabase.from('task_documents').insert({
    doc_type,
    region,
    title,
    description,
    author,
    file_url,
    file_name,
  })

  if (error) {
    console.error(error)
    throw new Error('등록에 실패했습니다.')
  }

  revalidatePath('/tasks')
}

export async function deleteDocument(id: number) {
  const { error } = await supabase.from('task_documents').delete().eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/tasks')
}
DOCSEOF

cat > app/tasks/DocumentForm.tsx << 'DOCSEOF'
'use client'

import { useRef, useState } from 'react'
import { addDocument } from './documentActions'

export default function DocumentForm({ docType }: { docType: '보고서' | '주기장요도' }) {
  const formRef = useRef<HTMLFormElement>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(formData: FormData) {
    setSubmitting(true)
    try {
      await addDocument(formData)
      formRef.current?.reset()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form ref={formRef} action={handleSubmit} className="document-form">
      <input type="hidden" name="doc_type" value={docType} />
      <select name="region" defaultValue="국내" required>
        <option value="국내">국내</option>
        <option value="해외">해외</option>
      </select>
      <input name="title" placeholder="제목" required />
      <textarea name="description" placeholder="내용" rows={3} />
      <input name="author" placeholder="작성자" required />
      <input type="file" name="file" accept=".pdf,.jpg,.jpeg,.png,.xlsx,.xls" />
      <button type="submit" disabled={submitting}>
        {submitting ? '업로드 중...' : `+ ${docType} 작성`}
      </button>
    </form>
  )
}
DOCSEOF

cat > app/tasks/TaskForm.tsx << 'DOCSEOF'
'use client'

import { useRef, useState } from 'react'
import { addTask } from './actions'

export default function TaskForm() {
  const formRef = useRef<HTMLFormElement>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(formData: FormData) {
    setSubmitting(true)
    try {
      await addTask(formData)
      formRef.current?.reset()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form ref={formRef} action={handleSubmit} className="task-form">
      <input type="hidden" name="category" value="업무지시공유" />
      <input name="title" placeholder="업무 제목" required />
      <textarea name="description" placeholder="내용" rows={2} />
      <div className="date-row">
        <label>
          담당자
          <input name="assignee" placeholder="담당자" required />
        </label>
        <label>
          마감일
          <input type="date" name="due_date" />
        </label>
      </div>
      <button type="submit" disabled={submitting}>
        {submitting ? '등록 중...' : '+ 업무 등록'}
      </button>
    </form>
  )
}
DOCSEOF

cat > app/tasks/TaskBoard.tsx << 'DOCSEOF'
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

const FOLDERS = ['보고서', '주기장요도', '업무지시공유'] as const
type FolderKey = (typeof FOLDERS)[number]

export default function TaskBoard({
  tasks,
  documents,
}: {
  tasks: Task[]
  documents: Doc[]
}) {
  const [folder, setFolder] = useState<FolderKey>('보고서')

  return (
    <div className="task-board">
      <div className="task-folder-tabs">
        {FOLDERS.map((f) => (
          <button
            key={f}
            type="button"
            className={`task-folder-tab ${folder === f ? 'active' : ''}`}
            onClick={() => setFolder(f)}
          >
            {f}
          </button>
        ))}
      </div>

      {folder === '업무지시공유' ? (
        <>
          <TaskForm />
          <div className="card-list">
            {tasks.filter((t) => t.category === '업무지시공유').length === 0 && (
              <p className="empty">등록된 업무가 없습니다.</p>
            )}
            {tasks
              .filter((t) => t.category === '업무지시공유')
              .map((task) => (
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
        </>
      ) : (
        <>
          <DocumentForm docType={folder} />
          <div className="card-list">
            {documents.filter((d) => d.doc_type === folder).length === 0 && (
              <p className="empty">등록된 {folder}가 없습니다.</p>
            )}
            {documents
              .filter((d) => d.doc_type === folder)
              .map((doc) => (
                <div key={doc.id} className="card">
                  <div className="task-header">
                    <h3>{doc.title}</h3>
                    <span className="badge progress">{doc.region}</span>
                  </div>

                  {doc.description && <p>{doc.description}</p>}

                  <p className="meta">작성자 : {doc.author}</p>
                  <p className="meta">
                    작성일 : {new Date(doc.created_at).toLocaleDateString('ko-KR')}
                  </p>

                  {doc.file_url && (
                    <a
                      className="file-link"
                      href={doc.file_url}
                      target="_blank"
                      rel="noreferrer"
                    >
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
        </>
      )}
    </div>
  )
}
DOCSEOF

cat > app/tasks/page.tsx << 'DOCSEOF'
import { supabase } from '@/lib/supabaseClient'
import TaskBoard from './TaskBoard'

export const dynamic = 'force-dynamic'

export default async function TasksPage() {
  const [{ data: tasks, error: taskError }, { data: documents, error: docError }] =
    await Promise.all([
      supabase.from('tasks').select('*').order('created_at', { ascending: false }),
      supabase.from('task_documents').select('*').order('created_at', { ascending: false }),
    ])

  if (taskError) console.error(taskError)
  if (docError) console.error(docError)

  return (
    <div className="page">
      <h1>✅ 업무관리</h1>
      <p className="page-desc">보고서 / 주기장요도 / 업무지시공유를 관리하세요</p>

      <TaskBoard tasks={tasks ?? []} documents={documents ?? []} />
    </div>
  )
}
DOCSEOF

cat > app/portal-styles.css << 'DOCSEOF'
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
DOCSEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."