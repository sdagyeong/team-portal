#!/bin/bash
set -e

mkdir -p app/notices app/resources app/tasks lib

cat > lib/formatDate.ts << 'TZFIXEOF'
// Supabase가 시간대 표시 없이 "YYYY-MM-DD HH:mm:ss" 형태로 줄 때도
// 항상 UTC로 해석해서 한국 시간(KST)으로 정확히 변환합니다.
export function formatKDate(value: string) {
  if (!value) return ''

  let iso = value.includes('T') ? value : value.replace(' ', 'T')

  const hasZone = /[Zz]$|[+-]\d\d:?\d\d$/.test(iso)
  if (!hasZone) {
    iso = `${iso}Z`
  }

  return new Date(iso).toLocaleDateString('ko-KR', { timeZone: 'Asia/Seoul' })
}
TZFIXEOF

cat > app/tasks/TaskBoard.tsx << 'TZFIXEOF'
'use client'

import { useState } from 'react'
import { deleteDocument } from './documentActions'
import { formatKDate } from '@/lib/formatDate'
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
            {formatKDate(doc.created_at)}
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
TZFIXEOF

cat > app/resources/ResourceBoard.tsx << 'TZFIXEOF'
'use client'

import { useState } from 'react'
import { deleteDocument } from './documentActions'
import { formatKDate } from '@/lib/formatDate'
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
            {formatKDate(doc.created_at)}
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
TZFIXEOF

cat > app/notices/page.tsx << 'TZFIXEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;
import { supabase } from "@/lib/supabase";
import { formatKDate } from "@/lib/formatDate";
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
                {formatKDate(notice.created_at)}
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
TZFIXEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."