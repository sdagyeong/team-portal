#!/bin/bash
set -e

mkdir -p app app/tasks components

cat > components/Sidebar.tsx << 'CALEOF'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const menuItems = [
  { href: "/notices", label: "업무지시공유", icon: "📌" },
  { href: "/resources", label: "자료실", icon: "📁" },
  { href: "/tasks", label: "업무관리", icon: "✅" },
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
CALEOF

cat > app/page.tsx << 'CALEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;

import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { supabase as supabaseData } from "@/lib/supabaseClient";

export default async function DashboardPage() {
  const [{ data: notices }, { data: documents }] = await Promise.all([
    supabase
      .from("notices")
      .select("*")
      .order("id", { ascending: false })
      .limit(3),
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
          <p>오늘의 업무지시와 자료 현황을 한눈에 확인하세요</p>
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
CALEOF

cat > app/tasks/TaskBoard.tsx << 'CALEOF'
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
  const [step, setStep] = useState<Step>({ level: 'root' })
  const [formOpen, setFormOpen] = useState(false)

  function go(next: Step) {
    setFormOpen(false)
    setStep(next)
  }

  // 1단계: 주기장요도 폴더
  if (step.level === 'root') {
    return (
      <div className="task-board">
        <div className="folder-menu">
          <button
            type="button"
            className="folder-item"
            onClick={() => go({ level: 'region' })}
          >
            🗺️ 주기장요도
          </button>
        </div>
      </div>
    )
  }

  // 2단계: 국내/해외
  if (step.level === 'region') {
    return (
      <div className="task-board">
        <button type="button" className="breadcrumb-back" onClick={() => go({ level: 'root' })}>
          ← 뒤로
        </button>
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

  // 3단계: 컨텐츠 (작성/목록)
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
CALEOF

# 일정관리 기능 삭제
rm -rf app/calendar

echo "적용 완료. npm run dev 재시작 후 확인하세요."