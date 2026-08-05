#!/bin/bash
set -e

cat > app/resources/ResourceBoard.tsx << 'REMOVEGRIDEOF'
'use client'

import { useState } from 'react'
import type { ComponentType } from 'react'
import Link from 'next/link'
import { deleteDocument } from './documentActions'
import DocumentForm from './DocumentForm'
import { IconBookOpen, IconTrash, IconChevronLeft } from '@/components/icons'

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

type Folder = '매뉴얼'

const REGION_TABS: Record<Folder, string[]> = {
  매뉴얼: ['DLA CODE', '자격변경', '제방빙'],
}

const FOLDER_ICON: Record<Folder, ComponentType<{ size?: number }>> = {
  매뉴얼: IconBookOpen,
}

type Step =
  | { level: 'root' }
  | { level: 'sub'; folder: Folder }
  | { level: 'content'; folder: Folder; region: string }

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

  // 1단계: 주기장요도 / 매뉴얼
  if (step.level === 'root') {
    return (
      <div className="task-board">
        <div className="folder-menu">
          {(Object.keys(REGION_TABS) as Folder[]).map((folder) => (
            <button
              key={folder}
              type="button"
              className="folder-item"
              onClick={() => go({ level: 'sub', folder })}
            >
              {(() => { const Icon = FOLDER_ICON[folder]; return <Icon size={16} /> })()} {folder}
            </button>
          ))}
        </div>
      </div>
    )
  }

  // 2단계: 하위 폴더
  if (step.level === 'sub') {
    return (
      <div className="task-board">
        <button type="button" className="breadcrumb-back" onClick={() => go({ level: 'root' })}>
          <IconChevronLeft size={13} /> 뒤로
        </button>
        <h2 className="folder-title">
          {(() => { const Icon = FOLDER_ICON[step.folder]; return <Icon size={17} /> })()} {step.folder}
        </h2>
        <div className="folder-menu">
          {REGION_TABS[step.folder].map((region) => (
            <button
              key={region}
              type="button"
              className="folder-item"
              onClick={() => go({ level: 'content', folder: step.folder, region })}
            >
              {region}
            </button>
          ))}
        </div>
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
        <IconChevronLeft size={13} /> 뒤로
      </button>

      <h2 className="folder-title">
        {step.folder} - {step.region}
      </h2>

      <DocumentForm docType={step.folder} region={step.region} />

      <DocList docs={filteredDocs} />
    </div>
  )
}
REMOVEGRIDEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."