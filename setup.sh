#!/bin/bash
# 이 스크립트를 프로젝트 루트(package.json이 있는 폴더)에서 실행하세요
# 사용법: bash setup.sh
set -e

mkdir -p app app/calendar app/resources app/tasks lib sql

cat > lib/supabaseClient.ts << 'PORTALEOF'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
PORTALEOF

cat > app/resources/actions.ts << 'PORTALEOF'
'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function addResource(formData: FormData) {
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const author = formData.get('author') as string
  const file = formData.get('file') as File | null

  let file_url: string | null = null
  let file_name: string | null = null

  // 파일이 첨부된 경우에만 Supabase Storage에 업로드
  if (file && file.size > 0) {
    const filePath = `${Date.now()}_${file.name}`

    const { error: uploadError } = await supabase.storage
      .from('resources')
      .upload(filePath, file)

    if (uploadError) {
      console.error(uploadError)
      throw new Error('파일 업로드에 실패했습니다.')
    }

    const { data: publicUrlData } = supabase.storage
      .from('resources')
      .getPublicUrl(filePath)

    file_url = publicUrlData.publicUrl
    file_name = file.name
  }

  const { error } = await supabase.from('resources').insert({
    title,
    description,
    author,
    file_url,
    file_name,
  })

  if (error) {
    console.error(error)
    throw new Error('자료 등록에 실패했습니다.')
  }

  revalidatePath('/resources')
}

export async function deleteResource(id: number) {
  const { error } = await supabase.from('resources').delete().eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/resources')
}
PORTALEOF

cat > app/resources/ResourceForm.tsx << 'PORTALEOF'
'use client'

import { useRef, useState } from 'react'
import { addResource } from './actions'

export default function ResourceForm() {
  const formRef = useRef<HTMLFormElement>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(formData: FormData) {
    setSubmitting(true)
    try {
      await addResource(formData)
      formRef.current?.reset()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form ref={formRef} action={handleSubmit} className="resource-form">
      <input name="title" placeholder="제목" required />
      <textarea name="description" placeholder="설명" rows={3} />
      <input name="author" placeholder="작성자" required />
      <input type="file" name="file" />
      <button type="submit" disabled={submitting}>
        {submitting ? '업로드 중...' : '+ 자료 등록'}
      </button>
    </form>
  )
}
PORTALEOF

cat > app/resources/page.tsx << 'PORTALEOF'
import { supabase } from '@/lib/supabaseClient'
import { deleteResource } from './actions'
import ResourceForm from './ResourceForm'

export const dynamic = 'force-dynamic'

export default async function ResourcesPage() {
  const { data: resources, error } = await supabase
    .from('resources')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    console.error(error)
  }

  return (
    <div className="page">
      <h1>📁 자료실</h1>
      <p className="page-desc">팀에서 필요한 자료를 올리고 다운로드하세요</p>

      <ResourceForm />

      <div className="card-list">
        {(!resources || resources.length === 0) && (
          <p className="empty">등록된 자료가 없습니다.</p>
        )}

        {resources?.map((resource) => (
          <div key={resource.id} className="card">
            <h3>{resource.title}</h3>
            {resource.description && <p>{resource.description}</p>}

            <p className="meta">작성자 : {resource.author}</p>
            <p className="meta">
              작성일 :{' '}
              {new Date(resource.created_at).toLocaleDateString('ko-KR')}
            </p>

            {resource.file_url && (
              <a
                className="file-link"
                href={resource.file_url}
                target="_blank"
                rel="noreferrer"
              >
                📎 {resource.file_name} 다운로드
              </a>
            )}

            <form
              action={async () => {
                'use server'
                await deleteResource(resource.id)
              }}
            >
              <button type="submit" className="btn-delete">
                🗑 삭제
              </button>
            </form>
          </div>
        ))}
      </div>
    </div>
  )
}
PORTALEOF

cat > app/calendar/actions.ts << 'PORTALEOF'
'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function addSchedule(formData: FormData) {
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const author = formData.get('author') as string
  const start_date = formData.get('start_date') as string
  const end_date = (formData.get('end_date') as string) || start_date

  const { error } = await supabase.from('schedules').insert({
    title,
    description,
    author,
    start_date,
    end_date,
  })

  if (error) {
    console.error(error)
    throw new Error('일정 등록에 실패했습니다.')
  }

  revalidatePath('/calendar')
}

export async function deleteSchedule(id: number) {
  const { error } = await supabase.from('schedules').delete().eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/calendar')
}
PORTALEOF

cat > app/calendar/ScheduleForm.tsx << 'PORTALEOF'
'use client'

import { useRef, useState } from 'react'
import { addSchedule } from './actions'

export default function ScheduleForm() {
  const formRef = useRef<HTMLFormElement>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(formData: FormData) {
    setSubmitting(true)
    try {
      await addSchedule(formData)
      formRef.current?.reset()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form ref={formRef} action={handleSubmit} className="schedule-form">
      <input name="title" placeholder="일정 제목" required />
      <textarea name="description" placeholder="내용" rows={2} />
      <input name="author" placeholder="담당자" required />
      <div className="date-row">
        <label>
          시작일
          <input type="date" name="start_date" required />
        </label>
        <label>
          종료일
          <input type="date" name="end_date" />
        </label>
      </div>
      <button type="submit" disabled={submitting}>
        {submitting ? '등록 중...' : '+ 일정 등록'}
      </button>
    </form>
  )
}
PORTALEOF

cat > app/calendar/CalendarGrid.tsx << 'PORTALEOF'
'use client'

import { useState } from 'react'
import { deleteSchedule } from './actions'

type Schedule = {
  id: number
  title: string
  description: string | null
  author: string
  start_date: string // YYYY-MM-DD
  end_date: string // YYYY-MM-DD
}

function toDateKey(date: Date) {
  return date.toISOString().slice(0, 10)
}

function isWithin(dateKey: string, s: Schedule) {
  return dateKey >= s.start_date && dateKey <= s.end_date
}

export default function CalendarGrid({ schedules }: { schedules: Schedule[] }) {
  const today = new Date()
  const [viewYear, setViewYear] = useState(today.getFullYear())
  const [viewMonth, setViewMonth] = useState(today.getMonth()) // 0-indexed
  const [selected, setSelected] = useState<string>(toDateKey(today))

  const firstDay = new Date(viewYear, viewMonth, 1)
  const startWeekday = firstDay.getDay() // 0 = Sun
  const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()

  const cells: (Date | null)[] = []
  for (let i = 0; i < startWeekday; i++) cells.push(null)
  for (let d = 1; d <= daysInMonth; d++) cells.push(new Date(viewYear, viewMonth, d))

  function prevMonth() {
    const m = viewMonth === 0 ? 11 : viewMonth - 1
    const y = viewMonth === 0 ? viewYear - 1 : viewYear
    setViewMonth(m)
    setViewYear(y)
  }

  function nextMonth() {
    const m = viewMonth === 11 ? 0 : viewMonth + 1
    const y = viewMonth === 11 ? viewYear + 1 : viewYear
    setViewMonth(m)
    setViewYear(y)
  }

  const selectedSchedules = schedules.filter((s) => isWithin(selected, s))

  return (
    <div className="calendar">
      <div className="calendar-header">
        <button onClick={prevMonth}>◀</button>
        <h3>
          {viewYear}년 {viewMonth + 1}월
        </h3>
        <button onClick={nextMonth}>▶</button>
      </div>

      <div className="calendar-grid">
        {['일', '월', '화', '수', '목', '금', '토'].map((d) => (
          <div key={d} className="calendar-weekday">
            {d}
          </div>
        ))}

        {cells.map((date, i) => {
          if (!date) return <div key={i} className="calendar-cell empty" />
          const key = toDateKey(date)
          const hasEvent = schedules.some((s) => isWithin(key, s))
          const isSelected = key === selected
          const isToday = key === toDateKey(today)

          return (
            <button
              key={i}
              onClick={() => setSelected(key)}
              className={`calendar-cell ${isSelected ? 'selected' : ''} ${
                isToday ? 'today' : ''
              }`}
            >
              <span>{date.getDate()}</span>
              {hasEvent && <span className="dot" />}
            </button>
          )
        })}
      </div>

      <div className="schedule-list">
        <h4>{selected} 일정</h4>
        {selectedSchedules.length === 0 && <p className="empty">일정이 없습니다.</p>}
        {selectedSchedules.map((s) => (
          <div key={s.id} className="card">
            <h3>{s.title}</h3>
            {s.description && <p>{s.description}</p>}
            <p className="meta">담당자 : {s.author}</p>
            <p className="meta">
              기간 : {s.start_date} ~ {s.end_date}
            </p>
            <form
              action={async () => {
                await deleteSchedule(s.id)
              }}
            >
              <button type="submit" className="btn-delete">
                🗑 삭제
              </button>
            </form>
          </div>
        ))}
      </div>
    </div>
  )
}
PORTALEOF

cat > app/calendar/page.tsx << 'PORTALEOF'
import { supabase } from '@/lib/supabaseClient'
import ScheduleForm from './ScheduleForm'
import CalendarGrid from './CalendarGrid'

export const dynamic = 'force-dynamic'

export default async function CalendarPage() {
  const { data: schedules, error } = await supabase
    .from('schedules')
    .select('*')
    .order('start_date', { ascending: true })

  if (error) {
    console.error(error)
  }

  return (
    <div className="page">
      <h1>📅 일정관리</h1>
      <p className="page-desc">팀 일정을 등록하고 확인하세요</p>

      <ScheduleForm />
      <CalendarGrid schedules={schedules ?? []} />
    </div>
  )
}
PORTALEOF

cat > app/tasks/actions.ts << 'PORTALEOF'
'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function addTask(formData: FormData) {
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const assignee = formData.get('assignee') as string
  const due_date = (formData.get('due_date') as string) || null

  const { error } = await supabase.from('tasks').insert({
    title,
    description,
    assignee,
    due_date,
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
PORTALEOF

cat > app/tasks/TaskForm.tsx << 'PORTALEOF'
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
PORTALEOF

cat > app/tasks/page.tsx << 'PORTALEOF'
import { supabase } from '@/lib/supabaseClient'
import { toggleTaskStatus, deleteTask } from './actions'
import TaskForm from './TaskForm'

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
      <p className="page-desc">팀 업무를 등록하고 진행 상태를 관리하세요</p>

      <TaskForm />

      <div className="card-list">
        {(!tasks || tasks.length === 0) && (
          <p className="empty">등록된 업무가 없습니다.</p>
        )}

        {tasks?.map((task) => (
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
    </div>
  )
}
PORTALEOF

cat > app/portal-styles.css << 'PORTALEOF'
/* 기존 TEAM PORTAL 테마(네이비 사이드바)에 맞춘 자료실/일정관리 스타일
   globals.css 에 이 내용을 붙여넣거나 import 해서 사용하세요 */

.page {
  padding: 40px 48px;
}

.page h1 {
  font-size: 28px;
  font-weight: 800;
  margin-bottom: 8px;
}

.page-desc {
  color: #6b7280;
  margin-bottom: 28px;
}

/* 등록 폼 */
.resource-form,
.schedule-form {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-width: 480px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 32px;
}

.resource-form input,
.resource-form textarea,
.schedule-form input,
.schedule-form textarea {
  border: 1px solid #d1d5db;
  border-radius: 8px;
  padding: 10px 12px;
  font-size: 14px;
}

.date-row {
  display: flex;
  gap: 12px;
}

.date-row label {
  display: flex;
  flex-direction: column;
  font-size: 12px;
  color: #6b7280;
  gap: 4px;
  flex: 1;
}

.resource-form button,
.schedule-form button {
  background: #0d1b3a;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 10px 16px;
  font-weight: 600;
  cursor: pointer;
  align-self: flex-start;
}

.resource-form button:disabled,
.schedule-form button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* 카드 목록 */
.card-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  padding: 24px;
}

.card h3 {
  font-size: 18px;
  font-weight: 700;
  margin-bottom: 8px;
}

.card .meta {
  font-size: 13px;
  color: #6b7280;
}

.file-link {
  display: inline-block;
  margin-top: 8px;
  color: #7c3aed;
  font-weight: 600;
  text-decoration: underline;
}

.empty {
  color: #9ca3af;
  padding: 20px 0;
}

.btn-delete {
  margin-top: 12px;
  background: #e63946;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-weight: 600;
  cursor: pointer;
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

.calendar-header button {
  background: none;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  width: 32px;
  height: 32px;
  cursor: pointer;
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
  border: 1px solid #e5e7eb;
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
  border-color: #0d1b3a;
  font-weight: 700;
}

.calendar-cell.selected {
  background: #0d1b3a;
  color: #fff;
}

.calendar-cell .dot {
  position: absolute;
  bottom: 4px;
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: #e63946;
}

.calendar-cell.selected .dot {
  background: #fff;
}

.schedule-list h4 {
  margin-bottom: 12px;
  font-size: 15px;
}

/* 업무관리 */
.task-form {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-width: 480px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 32px;
}

.task-form input,
.task-form textarea {
  border: 1px solid #d1d5db;
  border-radius: 8px;
  padding: 10px 12px;
  font-size: 14px;
}

.task-form button {
  background: #0d1b3a;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 10px 16px;
  font-weight: 600;
  cursor: pointer;
  align-self: flex-start;
}

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
  background: #0d1b3a;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-weight: 600;
  cursor: pointer;
}
PORTALEOF

cat > sql/schema.sql << 'PORTALEOF'
-- ========================================
-- 1. resources (자료실) 테이블
-- ========================================
create table if not exists resources (
  id bigint generated always as identity primary key,
  title text not null,
  description text,
  author text not null,
  file_url text,
  file_name text,
  created_at timestamptz default now()
);

alter table resources enable row level security;

create policy "allow anon select resources"
  on resources for select
  to anon
  using (true);

create policy "allow anon insert resources"
  on resources for insert
  to anon
  with check (true);

create policy "allow anon delete resources"
  on resources for delete
  to anon
  using (true);

-- ========================================
-- 2. schedules (일정관리) 테이블
-- ========================================
create table if not exists schedules (
  id bigint generated always as identity primary key,
  title text not null,
  description text,
  author text not null,
  start_date date not null,
  end_date date not null,
  created_at timestamptz default now()
);

alter table schedules enable row level security;

create policy "allow anon select schedules"
  on schedules for select
  to anon
  using (true);

create policy "allow anon insert schedules"
  on schedules for insert
  to anon
  with check (true);

create policy "allow anon delete schedules"
  on schedules for delete
  to anon
  using (true);

-- ========================================
-- 3. tasks (업무관리) 테이블
-- ========================================
create table if not exists tasks (
  id bigint generated always as identity primary key,
  title text not null,
  description text,
  assignee text not null,
  due_date date,
  status text not null default '진행중',
  created_at timestamptz default now()
);

alter table tasks enable row level security;

create policy "allow anon select tasks"
  on tasks for select
  to anon
  using (true);

create policy "allow anon insert tasks"
  on tasks for insert
  to anon
  with check (true);

create policy "allow anon update tasks"
  on tasks for update
  to anon
  using (true)
  with check (true);

create policy "allow anon delete tasks"
  on tasks for delete
  to anon
  using (true);

-- ========================================
-- 4. 자료실 파일 업로드용 Storage 버킷
-- ========================================
-- SQL로는 만들 수 없고, Supabase 대시보드에서 직접 생성해야 합니다.
-- Storage → New bucket → 이름: resources → Public bucket 체크
--
-- 버킷 생성 후, Storage 정책도 열어줘야 업로드/다운로드가 됩니다.
-- Storage → resources → Policies → New policy
--   - INSERT: role = anon, with check: true
--   - SELECT: role = anon, using: true
PORTALEOF

echo "✅ 파일 생성 완료. package.json에 @supabase/supabase-js 있는지 확인 후 npm install 하세요."