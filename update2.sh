#!/bin/bash
# 프로젝트 루트에서 실행하세요: bash update2.sh
set -e

mkdir -p app app/tasks components

cat > components/Sidebar.tsx << 'UPDATE2EOF'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const menuItems = [
  { href: "/notices", label: "공지사항", icon: "📢" },
  { href: "/resources", label: "자료실", icon: "📁" },
  { href: "/tasks", label: "업무관리", icon: "✅" },
  { href: "/calendar", label: "일정관리", icon: "📅" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="sidebar">
      <Link href="/" className="brand-link">
        <div className="brand">
          <span className="brand-line1">JEJUAIR</span>
          <span className="brand-line2">RAMP CONTROL TEAM</span>
        </div>
      </Link>

      <nav>
        {menuItems.map((item) => (
          <Link key={item.href} href={item.href}>
            <div className={`menu ${pathname === item.href ? "active" : ""}`}>
              <span className="menu-icon">{item.icon}</span>
              {item.label}
            </div>
          </Link>
        ))}
      </nav>
    </aside>
  );
}
UPDATE2EOF

cat > app/tasks/actions.ts << 'UPDATE2EOF'
'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function addTask(formData: FormData) {
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const assignee = formData.get('assignee') as string
  const due_date = (formData.get('due_date') as string) || null
  const category = formData.get('category') as string

  const { error } = await supabase.from('tasks').insert({
    title,
    description,
    assignee,
    due_date,
    category,
    status: '진행중',
  })

  if (error) {
    console.error(error)
    throw new Error('업무 등록에 실패했습니다.')
  }

  revalidatePath('/tasks')
}

export async function toggleTaskStatus(id: number, currentStatus: string) {
  const nextStatus = currentStatus === '완료' ? '진행중' : '완료'

  const { error } = await supabase
    .from('tasks')
    .update({ status: nextStatus })
    .eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('상태 변경에 실패했습니다.')
  }

  revalidatePath('/tasks')
}

export async function deleteTask(id: number) {
  const { error } = await supabase.from('tasks').delete().eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/tasks')
}
UPDATE2EOF

cat > app/tasks/TaskForm.tsx << 'UPDATE2EOF'
'use client'

import { useRef, useState } from 'react'
import { addTask } from './actions'

const CATEGORIES = [
  '출장보고서-국내',
  '출장보고서-해외',
  '주기장요도-국내',
  '주기장요도-해외',
  '업무지시공유',
]

export default function TaskForm({ defaultCategory }: { defaultCategory?: string }) {
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
      <select name="category" defaultValue={defaultCategory ?? CATEGORIES[0]} required>
        {CATEGORIES.map((c) => (
          <option key={c} value={c}>
            {c}
          </option>
        ))}
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
UPDATE2EOF

cat > app/tasks/page.tsx << 'UPDATE2EOF'
import { supabase } from '@/lib/supabaseClient'
import { toggleTaskStatus, deleteTask } from './actions'
import TaskForm from './TaskForm'

export const dynamic = 'force-dynamic'

const CATEGORIES = [
  '출장보고서-국내',
  '출장보고서-해외',
  '주기장요도-국내',
  '주기장요도-해외',
  '업무지시공유',
]

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
      <p className="page-desc">카테고리별로 업무를 등록하고 진행 상태를 관리하세요</p>

      <TaskForm />

      {CATEGORIES.map((category) => {
        const categoryTasks = (tasks ?? []).filter((t) => t.category === category)

        return (
          <section key={category} className="task-category">
            <h2 className="task-category-title">
              {category}
              <span className="task-category-count">{categoryTasks.length}</span>
            </h2>

            <div className="card-list">
              {categoryTasks.length === 0 && (
                <p className="empty">등록된 업무가 없습니다.</p>
              )}

              {categoryTasks.map((task) => (
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
                        'use server'
                        await toggleTaskStatus(task.id, task.status)
                      }}
                    >
                      <button type="submit" className="btn-toggle">
                        {task.status === '완료' ? '진행중으로 변경' : '완료 처리'}
                      </button>
                    </form>

                    <form
                      action={async () => {
                        'use server'
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
          </section>
        )
      })}
    </div>
  )
}
UPDATE2EOF

cat > app/globals.css << 'UPDATE2EOF'
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
  font-size: 15px;
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
UPDATE2EOF

cat > app/portal-styles.css << 'UPDATE2EOF'
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
.task-form {
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
.task-form select {
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
.task-form button {
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
.task-form button:hover {
  background: var(--color-orange-dark);
}

.resource-form button:disabled,
.schedule-form button:disabled,
.task-form button:disabled {
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
UPDATE2EOF

echo "✅ 적용 완료. Supabase SQL Editor에서 sql/add-task-category.sql 도 실행해주세요."