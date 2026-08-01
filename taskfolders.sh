#!/bin/bash
mkdir -p app app/tasks

cat > app/tasks/TaskBoard.tsx << 'TASKFOLDEREOF'
'use client'

import { useState } from 'react'
import { toggleTaskStatus, deleteTask } from './actions'

type Task = {
  id: number
  title: string
  description: string | null
  assignee: string
  due_date: string | null
  status: string
  category: string
}

const FOLDERS = [
  { key: '보고서', icon: '📋', hasRegion: true },
  { key: '주기장요도', icon: '🗺️', hasRegion: true },
  { key: '업무지시공유', icon: '📌', hasRegion: false },
] as const

type FolderKey = (typeof FOLDERS)[number]['key']

function getCategory(folder: FolderKey, region: '국내' | '해외') {
  if (folder === '보고서') return region === '국내' ? '출장보고서-국내' : '출장보고서-해외'
  if (folder === '주기장요도') return region === '국내' ? '주기장요도-국내' : '주기장요도-해외'
  return '업무지시공유'
}

export default function TaskBoard({ tasks }: { tasks: Task[] }) {
  const [folder, setFolder] = useState<FolderKey>('보고서')
  const [region, setRegion] = useState<'국내' | '해외'>('국내')

  const activeFolder = FOLDERS.find((f) => f.key === folder)!
  const activeCategory = getCategory(folder, region)

  const filtered = tasks.filter((t) => t.category === activeCategory)

  return (
    <div className="task-board">
      <div className="task-folder-tabs">
        {FOLDERS.map((f) => (
          <button
            key={f.key}
            className={`task-folder-tab ${folder === f.key ? 'active' : ''}`}
            onClick={() => {
              setFolder(f.key)
              setRegion('국내')
            }}
            type="button"
          >
            <span>{f.icon}</span> {f.key}
          </button>
        ))}
      </div>

      {activeFolder.hasRegion && (
        <div className="task-region-tabs">
          {(['국내', '해외'] as const).map((r) => (
            <button
              key={r}
              className={`task-region-tab ${region === r ? 'active' : ''}`}
              onClick={() => setRegion(r)}
              type="button"
            >
              {r}
            </button>
          ))}
        </div>
      )}

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
TASKFOLDEREOF

cat > app/tasks/TaskForm.tsx << 'TASKFOLDEREOF'
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
      <select name="category" defaultValue="출장보고서-국내" required>
        <optgroup label="📋 보고서">
          <option value="출장보고서-국내">출장보고서 - 국내</option>
          <option value="출장보고서-해외">출장보고서 - 해외</option>
        </optgroup>
        <optgroup label="🗺️ 주기장요도">
          <option value="주기장요도-국내">주기장요도 - 국내</option>
          <option value="주기장요도-해외">주기장요도 - 해외</option>
        </optgroup>
        <optgroup label="📌 업무지시공유">
          <option value="업무지시공유">업무지시공유</option>
        </optgroup>
      </select>
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
TASKFOLDEREOF

cat > app/tasks/page.tsx << 'TASKFOLDEREOF'
import { supabase } from '@/lib/supabaseClient'
import TaskForm from './TaskForm'
import TaskBoard from './TaskBoard'

export const dynamic = 'force-dynamic'

export default async function TasksPage() {
  const { data: tasks, error } = await supabase
    .from('tasks')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    console.error(error)
  }

  return (
    <div className="page">
      <h1>✅ 업무관리</h1>
      <p className="page-desc">폴더별로 업무를 등록하고 진행 상태를 관리하세요</p>

      <TaskForm />
      <TaskBoard tasks={tasks ?? []} />
    </div>
  )
}
TASKFOLDEREOF

echo "✅ 업무관리 폴더 구조 적용 완료. npm run dev 재시작 후 확인하세요."