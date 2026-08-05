'use client'

import { useState } from 'react'
import Link from 'next/link'
import { deleteDocument } from './documentActions'
import DocumentForm from './DocumentForm'
import { IconTrash, IconChevronLeft } from '@/components/icons'

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

const SUBFOLDERS = ['DLA CODE', '자격변경', '제방빙']

type Step = { level: 'root' } | { level: 'content'; region: string }

function DocList({ docs }: { docs: Doc[] }) {
  return (
    <div className="doc-list">
      {docs.length === 0 && <p className="empty">등록된 자료가 없습니다.</p>}
      {docs.map((doc) => (
        <div key={doc.id} className="doc-row">
          <Link href={`/resources/doc/${doc.id}`} className="doc-row-title">
            {doc.file_url && '📎 '}
            {doc.title}
          </Link>
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
              <IconTrash />
            </button>
          </form>
        </div>
      ))}
    </div>
  )
}

export default function ResourceBoard({ documents }: { documents: Doc[] }) {
  const [step, setStep] = useState<Step>({ level: 'root' })

  function go(next: Step) {
    setStep(next)
  }

  // 1단계: DLA CODE / 자격변경 / 제방빙 (매뉴얼 단계 생략)
  if (step.level === 'root') {
    return (
      <div className="task-board">
        <div className="folder-menu">
          {SUBFOLDERS.map((region) => (
            <button
              key={region}
              type="button"
              className="folder-item"
              onClick={() => go({ level: 'content', region })}
            >
              {region}
            </button>
          ))}
        </div>
      </div>
    )
  }

  // 2단계: 컨텐츠 (작성/목록)
  const filteredDocs = documents.filter(
    (d) => d.doc_type === '매뉴얼' && d.region === step.region
  )

  return (
    <div className="task-board">
      <button type="button" className="breadcrumb-back" onClick={() => go({ level: 'root' })}>
        <IconChevronLeft size={13} /> 뒤로
      </button>

      <h2 className="folder-title">{step.region}</h2>

      <DocumentForm docType="매뉴얼" region={step.region} />

      <DocList docs={filteredDocs} />
    </div>
  )
}
