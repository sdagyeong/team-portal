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
