#!/bin/bash
set -e

mkdir -p app app/notices app/resources app/tasks components

cat > components/Sidebar.tsx << 'RESTRUCTEOF'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const menuItems = [
  { href: "/notices", label: "업무지시공유", icon: "📌" },
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
RESTRUCTEOF

cat > components/NoticeForm.tsx << 'RESTRUCTEOF'
"use client";
import { useState } from "react";

export default function NoticeForm({
  addNotice,
}: {
  addNotice: (formData: FormData) => Promise<void>;
}) {
  const [open, setOpen] = useState(false);

  if (open) {
    return (
      <section className="writeBox">
        <h3>✏️ 업무지시 작성</h3>
        <form
          action={async (formData) => {
            await addNotice(formData);
            setOpen(false);
          }}
        >
          <input name="title" placeholder="제목" required />
          <textarea name="content" placeholder="내용" required />
          <input name="author" placeholder="작성자" required />
          <div className="form-actions">
            <button type="submit" className="btn-primary">
              등록
            </button>
            <button
              type="button"
              className="btn-secondary"
              onClick={() => setOpen(false)}
            >
              닫기
            </button>
          </div>
        </form>
      </section>
    );
  }

  return (
    <button type="button" className="btn-primary" onClick={() => setOpen(true)}>
      + 새 글 작성
    </button>
  );
}
RESTRUCTEOF

cat > app/notices/page.tsx << 'RESTRUCTEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;
import { supabase } from "@/lib/supabase";
import NoticeForm from "@/components/NoticeForm";
import { addNotice, deleteNotice } from "./actions";

export default async function NoticesPage() {
  const { data: notices, error } = await supabase
    .from("notices")
    .select("*")
    .order("id", { ascending: false });

  if (error) {
    console.error("불러오기 오류:", error);
  }

  return (
    <>
      <header className="top">
        <div>
          <h2>📌 업무지시공유</h2>
          <p>팀 업무지시 및 공유사항을 확인하세요</p>
        </div>
        <NoticeForm addNotice={addNotice} />
      </header>

      <section>
        <h3>📌 최근 업무지시</h3>
        <div className="noticeList">
          {notices?.map((notice) => (
            <article key={notice.id} className="card">
              <h3>📌 {notice.title}</h3>
              <p>{notice.content}</p>
              <div className="meta">
                작성자 : {notice.author}
                <br />
                작성일 :{" "}
                {new Date(notice.created_at).toLocaleDateString("ko-KR")}
              </div>
              <form action={deleteNotice.bind(null, notice.id)}>
                <button type="submit" className="deleteButton">
                  🗑 삭제
                </button>
              </form>
            </article>
          ))}
        </div>
      </section>
    </>
  );
}
RESTRUCTEOF

cat > app/page.tsx << 'RESTRUCTEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;

import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { supabase as supabaseData } from "@/lib/supabaseClient";

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

export default async function DashboardPage() {
  const [{ data: notices }, { data: schedules }, { data: documents }] = await Promise.all([
    supabase
      .from("notices")
      .select("*")
      .order("id", { ascending: false })
      .limit(3),
    supabaseData
      .from("schedules")
      .select("*")
      .gte("end_date", todayKey())
      .order("start_date", { ascending: true })
      .limit(5),
    supabaseData.from("task_documents").select("doc_type"),
  ]);

  const reportCount = documents?.filter((d) => d.doc_type === "보고서").length ?? 0;
  const gridCount = documents?.filter((d) => d.doc_type === "주기장요도").length ?? 0;
  const manualCount = documents?.filter((d) => d.doc_type === "매뉴얼").length ?? 0;

  return (
    <>
      <header className="top">
        <div>
          <h2>🛫 Ramp Control Team 포털</h2>
          <p>오늘의 업무지시, 일정, 자료 현황을 한눈에 확인하세요</p>
        </div>
      </header>

      <div className="dashboard-grid">
        {/* 최근 업무지시공유 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>📌 최근 업무지시공유</h3>
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
                <span className="dashboard-list-title">{notice.title}</span>
                <span className="dashboard-list-meta">{notice.author}</span>
              </li>
            ))}
          </ul>
        </section>

        {/* 다가오는 일정 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>📅 다가오는 일정</h3>
            <Link href="/calendar" className="dashboard-more">
              전체보기
            </Link>
          </div>
          {(!schedules || schedules.length === 0) && (
            <p className="empty">예정된 일정이 없습니다.</p>
          )}
          <ul className="dashboard-list">
            {schedules?.map((s) => (
              <li key={s.id}>
                <span className="dashboard-list-title">{s.title}</span>
                <span className="dashboard-list-meta">{s.start_date}</span>
              </li>
            ))}
          </ul>
        </section>

        {/* 자료 현황 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>📁 자료 현황</h3>
            <Link href="/resources" className="dashboard-more">
              전체보기
            </Link>
          </div>
          <div className="dashboard-stats">
            <div className="dashboard-stat">
              <span className="dashboard-stat-num">{reportCount}</span>
              <span className="dashboard-stat-label">보고서</span>
            </div>
            <div className="dashboard-stat">
              <span className="dashboard-stat-num">{gridCount}</span>
              <span className="dashboard-stat-label">주기장요도</span>
            </div>
            <div className="dashboard-stat">
              <span className="dashboard-stat-num">{manualCount}</span>
              <span className="dashboard-stat-label">매뉴얼</span>
            </div>
          </div>
        </section>
      </div>
    </>
  );
}
RESTRUCTEOF

cat > app/resources/documentActions.ts << 'RESTRUCTEOF'
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

  revalidatePath('/resources')
}

export async function deleteDocument(id: number) {
  const { error } = await supabase.from('task_documents').delete().eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/resources')
}
RESTRUCTEOF

cat > app/resources/DocumentForm.tsx << 'RESTRUCTEOF'
'use client'

import { useRef, useState } from 'react'
import { addDocument } from './documentActions'

export default function DocumentForm({
  docType,
  region,
  onDone,
}: {
  docType: string
  region: string
  onDone: () => void
}) {
  const formRef = useRef<HTMLFormElement>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(formData: FormData) {
    setSubmitting(true)
    try {
      await addDocument(formData)
      formRef.current?.reset()
      onDone()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form ref={formRef} action={handleSubmit} className="document-form-compact">
      <input type="hidden" name="doc_type" value={docType} />
      <input type="hidden" name="region" value={region} />
      <input name="title" placeholder="제목" required />
      <input name="author" placeholder="작성자" required />
      <textarea name="description" placeholder="내용 (선택)" rows={2} />
      <input type="file" name="file" accept=".pdf,.jpg,.jpeg,.png,.xlsx,.xls" />
      <div className="form-actions">
        <button type="submit" disabled={submitting}>
          {submitting ? '업로드 중...' : '등록'}
        </button>
        <button type="button" className="btn-secondary" onClick={onDone}>
          닫기
        </button>
      </div>
    </form>
  )
}
RESTRUCTEOF

cat > app/resources/ResourceBoard.tsx << 'RESTRUCTEOF'
'use client'

import { useState } from 'react'
import { deleteDocument } from './documentActions'
import DocumentForm from './DocumentForm'

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

type Step =
  | { level: 'root' }
  | { level: 'sub'; folder: '보고서' | '매뉴얼' }
  | { level: 'content'; folder: '보고서'; region: '국내' | '해외' }
  | { level: 'content'; folder: '매뉴얼'; region: 'DLA CODE' }

function DocList({ docs }: { docs: Doc[] }) {
  return (
    <div className="doc-list">
      {docs.length === 0 && <p className="empty">등록된 자료가 없습니다.</p>}
      {docs.map((doc) => (
        <div key={doc.id} className="doc-row">
          {doc.file_url ? (
            <a
              className="doc-row-title"
              href={doc.file_url}
              target="_blank"
              rel="noreferrer"
            >
              📎 {doc.title}
            </a>
          ) : (
            <span className="doc-row-title">{doc.title}</span>
          )}
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
              🗑
            </button>
          </form>
        </div>
      ))}
    </div>
  )
}

export default function ResourceBoard({ documents }: { documents: Doc[] }) {
  const [step, setStep] = useState<Step>({ level: 'root' })
  const [formOpen, setFormOpen] = useState(false)

  function go(next: Step) {
    setFormOpen(false)
    setStep(next)
  }

  // 1단계: 보고서 / 매뉴얼
  if (step.level === 'root') {
    return (
      <div className="task-board">
        <div className="folder-menu">
          <button
            type="button"
            className="folder-item"
            onClick={() => go({ level: 'sub', folder: '보고서' })}
          >
            📋 보고서
          </button>
          <button
            type="button"
            className="folder-item"
            onClick={() => go({ level: 'sub', folder: '매뉴얼' })}
          >
            📘 매뉴얼
          </button>
        </div>
      </div>
    )
  }

  // 2단계
  if (step.level === 'sub') {
    return (
      <div className="task-board">
        <button type="button" className="breadcrumb-back" onClick={() => go({ level: 'root' })}>
          ← 뒤로
        </button>
        <h2 className="folder-title">
          {step.folder === '보고서' ? '📋' : '📘'} {step.folder}
        </h2>

        {step.folder === '보고서' ? (
          <div className="folder-menu">
            <button
              type="button"
              className="folder-item"
              onClick={() => go({ level: 'content', folder: '보고서', region: '국내' })}
            >
              국내
            </button>
            <button
              type="button"
              className="folder-item"
              onClick={() => go({ level: 'content', folder: '보고서', region: '해외' })}
            >
              해외
            </button>
          </div>
        ) : (
          <div className="folder-menu">
            <button
              type="button"
              className="folder-item"
              onClick={() => go({ level: 'content', folder: '매뉴얼', region: 'DLA CODE' })}
            >
              DLA CODE
            </button>
          </div>
        )}
      </div>
    )
  }

  // 3단계: 컨텐츠 (작성/목록)
  const filteredDocs = documents.filter(
    (d) => d.doc_type === step.folder && d.region === step.region
  )

  return (
    <div className="task-board">
      <button
        type="button"
        className="breadcrumb-back"
        onClick={() => go({ level: 'sub', folder: step.folder })}
      >
        ← 뒤로
      </button>

      <div className="folder-title-row">
        <h2 className="folder-title">
          {step.folder} - {step.region}
        </h2>
        <button type="button" className="btn-compact-add" onClick={() => setFormOpen((o) => !o)}>
          {formOpen ? '닫기' : '+ 작성'}
        </button>
      </div>

      {formOpen && (
        <DocumentForm docType={step.folder} region={step.region} onDone={() => setFormOpen(false)} />
      )}

      <DocList docs={filteredDocs} />
    </div>
  )
}
RESTRUCTEOF

cat > app/resources/page.tsx << 'RESTRUCTEOF'
import { supabase } from '@/lib/supabaseClient'
import ResourceBoard from './ResourceBoard'

export const dynamic = 'force-dynamic'

export default async function ResourcesPage() {
  const { data: documents, error } = await supabase
    .from('task_documents')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    console.error(error)
  }

  return (
    <div className="page">
      <h1>📁 자료실</h1>

      <ResourceBoard documents={documents ?? []} />
    </div>
  )
}
RESTRUCTEOF

cat > app/tasks/TaskBoard.tsx << 'RESTRUCTEOF'
'use client'

import { useState } from 'react'
import { deleteDocument } from './documentActions'
import DocumentForm from './DocumentForm'

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

type Step =
  | { level: 'region' }
  | { level: 'content'; region: '국내' | '해외' }

function DocList({ docs }: { docs: Doc[] }) {
  return (
    <div className="doc-list">
      {docs.length === 0 && <p className="empty">등록된 자료가 없습니다.</p>}
      {docs.map((doc) => (
        <div key={doc.id} className="doc-row">
          {doc.file_url ? (
            <a
              className="doc-row-title"
              href={doc.file_url}
              target="_blank"
              rel="noreferrer"
            >
              📎 {doc.title}
            </a>
          ) : (
            <span className="doc-row-title">{doc.title}</span>
          )}
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
              🗑
            </button>
          </form>
        </div>
      ))}
    </div>
  )
}

export default function TaskBoard({ documents }: { documents: Doc[] }) {
  const [step, setStep] = useState<Step>({ level: 'region' })
  const [formOpen, setFormOpen] = useState(false)

  function go(next: Step) {
    setFormOpen(false)
    setStep(next)
  }

  // 1단계: 주기장요도 - 국내/해외
  if (step.level === 'region') {
    return (
      <div className="task-board">
        <h2 className="folder-title">🗺️ 주기장요도</h2>
        <div className="folder-menu">
          <button
            type="button"
            className="folder-item"
            onClick={() => go({ level: 'content', region: '국내' })}
          >
            국내
          </button>
          <button
            type="button"
            className="folder-item"
            onClick={() => go({ level: 'content', region: '해외' })}
          >
            해외
          </button>
        </div>
      </div>
    )
  }

  // 2단계: 컨텐츠 (작성/목록)
  const filteredDocs = documents.filter(
    (d) => d.doc_type === '주기장요도' && d.region === step.region
  )

  return (
    <div className="task-board">
      <button type="button" className="breadcrumb-back" onClick={() => go({ level: 'region' })}>
        ← 뒤로
      </button>

      <div className="folder-title-row">
        <h2 className="folder-title">주기장요도 - {step.region}</h2>
        <button type="button" className="btn-compact-add" onClick={() => setFormOpen((o) => !o)}>
          {formOpen ? '닫기' : '+ 작성'}
        </button>
      </div>

      {formOpen && (
        <DocumentForm
          docType="주기장요도"
          region={step.region}
          onDone={() => setFormOpen(false)}
        />
      )}

      <DocList docs={filteredDocs} />
    </div>
  )
}
RESTRUCTEOF

cat > app/tasks/page.tsx << 'RESTRUCTEOF'
import { supabase } from '@/lib/supabaseClient'
import TaskBoard from './TaskBoard'

export const dynamic = 'force-dynamic'

export default async function TasksPage() {
  const { data: documents, error } = await supabase
    .from('task_documents')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    console.error(error)
  }

  return (
    <div className="page">
      <h1>✅ 업무관리</h1>

      <TaskBoard documents={documents ?? []} />
    </div>
  )
}
RESTRUCTEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."