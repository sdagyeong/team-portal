#!/bin/bash
set -e

cat > app/tasks/TaskBoard.tsx << 'AIRPORTCITIESEOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { deleteDocument } from './documentActions'
import DocumentForm from './DocumentForm'
import AirportInfoCard from './AirportInfoCard'
import { IconFileText, IconTrash, IconChevronLeft } from '@/components/icons'

type AirportInfo = {
  airport: string
  apron_diagram_url: string | null
  parking_stand: string | null
  active_runway: string | null
  deicing_pad: string | null
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

const DOMESTIC = ['ICN', 'GMP', 'CJU', 'PUS', 'TAE', 'CJJ', 'KWJ']

const INTERNATIONAL_REGIONS: Record<string, string[]> = {
  Japan: ['FUK', 'HIJ', 'KOJ', 'UKB', 'MYJ', 'NGO', 'OIT', 'OKA', 'KIX', 'CTS', 'FSZ', 'NRT'],
  'Northeast Asia': [
    'PEK',
    'PKX',
    'KWL',
    'HRB',
    'JMU',
    'TAO',
    'PVG',
    'SJW',
    'WEH',
    'YNJ',
    'DYG',
    'HKG',
    'MFM',
    'KHH',
    'TPE',
  ],
  Vietnam: ['DAD', 'HAN', 'CXR', 'PQC'],
  Philippines: ['CRK', 'CEB', 'MNL', 'TAG'],
  Indonesia: ['BTH', 'DPS'],
  Singapore: ['SIN'],
  'Thailand / Laos': ['BKK', 'CNX', 'VTE'],
  Malaysia: ['BKI'],
  Saipan: ['SPN'],
  Mongolia: ['UBN'],
}

type Step =
  | { level: 'list' }
  | { level: 'region'; region: string }
  | { level: 'sub'; airport: string; parent: Step }
  | { level: 'content'; airport: string; parent: Step }

function DocList({ docs }: { docs: Doc[] }) {
  return (
    <div className="doc-list">
      {docs.length === 0 && <p className="empty">등록된 자료가 없습니다.</p>}
      {docs.map((doc) => (
        <div key={doc.id} className="doc-row">
          <Link href={`/tasks/doc/${doc.id}`} className="doc-row-title">
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

export default function TaskBoard({
  documents,
  airportInfoList = [],
}: {
  documents: Doc[]
  airportInfoList?: AirportInfo[]
}) {
  const [step, setStep] = useState<Step>({ level: 'list' })

  function go(next: Step) {
    setStep(next)
  }

  // 1단계: 국내 / 해외 2분할 목록
  if (step.level === 'list') {
    return (
      <div className="task-board">
        <div className="airport-columns">
          <div className="airport-column">
            <h3 className="airport-column-title">국내</h3>
            <div className="folder-menu">
              {DOMESTIC.map((code) => (
                <button
                  key={code}
                  type="button"
                  className="folder-item"
                  onClick={() => go({ level: 'sub', airport: code, parent: { level: 'list' } })}
                >
                  {code}
                </button>
              ))}
            </div>
          </div>

          <div className="airport-column">
            <h3 className="airport-column-title">해외</h3>
            <div className="folder-menu">
              {Object.keys(INTERNATIONAL_REGIONS).map((name) => (
                <button
                  key={name}
                  type="button"
                  className="folder-item"
                  onClick={() => go({ level: 'region', region: name })}
                >
                  {name}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    )
  }

  // 2단계: 해외 지역 안의 개별 도시/공항 코드
  if (step.level === 'region') {
    return (
      <div className="task-board">
        <button type="button" className="breadcrumb-back" onClick={() => go({ level: 'list' })}>
          <IconChevronLeft size={13} /> 뒤로
        </button>
        <h2 className="folder-title">{step.region}</h2>
        <div className="folder-menu">
          {INTERNATIONAL_REGIONS[step.region].map((code) => (
            <button
              key={code}
              type="button"
              className="folder-item"
              onClick={() =>
                go({ level: 'sub', airport: code, parent: { level: 'region', region: step.region } })
              }
            >
              {code}
            </button>
          ))}
        </div>
      </div>
    )
  }

  // 3단계: 공항별 하위 폴더 (공항 정보 카드 + 보고서)
  if (step.level === 'sub') {
    return (
      <div className="task-board">
        <button type="button" className="breadcrumb-back" onClick={() => go(step.parent)}>
          <IconChevronLeft size={13} /> 뒤로
        </button>
        <h2 className="folder-title">{step.airport}</h2>

        <AirportInfoCard
          airport={step.airport}
          info={airportInfoList.find((i) => i.airport === step.airport) ?? null}
        />

        <div className="folder-menu">
          <button
            type="button"
            className="folder-item"
            onClick={() => go({ level: 'content', airport: step.airport, parent: step })}
          >
            <IconFileText size={16} /> 보고서
          </button>
        </div>
      </div>
    )
  }

  // 4단계: 컨텐츠 (작성/목록)
  const filteredDocs = documents.filter(
    (d) => d.doc_type === '보고서' && d.region === step.airport
  )

  return (
    <div className="task-board">
      <button type="button" className="breadcrumb-back" onClick={() => go(step.parent)}>
        <IconChevronLeft size={13} /> 뒤로
      </button>

      <h2 className="folder-title">{step.airport} - 보고서</h2>

      <DocumentForm docType="보고서" region={step.airport} />

      <DocList docs={filteredDocs} />
    </div>
  )
}
AIRPORTCITIESEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."