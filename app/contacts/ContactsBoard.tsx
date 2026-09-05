'use client'

import { useState } from 'react'
import EditableTable, { type Column } from './EditableTable'
import PhoneContactPanels from './PhoneContactPanels'
import { IconFilePreview } from '@/components/icons'
import {
  addSystemAccountRow,
  updateSystemAccountCell,
  deleteSystemAccountRow,
} from './contactActions'

const ACCOUNT_COLUMNS: Column[] = [
  { key: 'group_name', label: '그룹', width: '110px' },
  { key: 'system_name', label: '시스템명', width: '160px' },
  { key: 'url', label: 'URL', width: '180px' },
  { key: 'detail', label: '내용', width: '120px' },
  { key: 'account_id', label: 'ID', width: '110px' },
  { key: 'password', label: 'PW', width: '110px' },
  { key: 'note', label: '비고' },
]

const SYSTEM_SEARCH_FIELDS = ['group_name', 'system_name', 'url', 'detail', 'account_id', 'note']
const PHONE_SEARCH_FIELDS = ['name', 'position', 'office_phone', 'mobile', 'note']

type Row = Record<string, string | number | null>

function filterRows(rows: Row[], query: string, fields: string[]) {
  const q = query.trim().toLowerCase()
  if (!q) return rows
  return rows.filter((row) =>
    fields.some((f) => String(row[f] ?? '').toLowerCase().includes(q))
  )
}

export default function ContactsBoard({
  systemAccounts,
  phoneContacts,
}: {
  systemAccounts: Row[]
  phoneContacts: Row[]
}) {
  const [tab, setTab] = useState<'system' | 'phone'>('system')
  const [systemQuery, setSystemQuery] = useState('')
  const [phoneQuery, setPhoneQuery] = useState('')

  const filteredSystemAccounts = filterRows(systemAccounts, systemQuery, SYSTEM_SEARCH_FIELDS)
  const filteredPhoneContacts = filterRows(phoneContacts, phoneQuery, PHONE_SEARCH_FIELDS)

  return (
    <div className="task-board">
      <div className="contacts-tab-header">
        <div className="task-folder-tabs">
          <button
            type="button"
            className={`task-folder-tab ${tab === 'system' ? 'active' : ''}`}
            onClick={() => setTab('system')}
          >
            시스템 계정
          </button>
          <button
            type="button"
            className={`task-folder-tab ${tab === 'phone' ? 'active' : ''}`}
            onClick={() => setTab('phone')}
          >
            유선 연락망
          </button>
        </div>

        {tab === 'system' ? (
          <div className="local-search-box">
            <IconFilePreview size={14} />
            <input
              type="text"
              placeholder="계정 폴더 내 검색..."
              value={systemQuery}
              onChange={(e) => setSystemQuery(e.target.value)}
            />
          </div>
        ) : (
          <div className="local-search-box">
            <IconFilePreview size={14} />
            <input
              type="text"
              placeholder="연락망 폴더 내 검색..."
              value={phoneQuery}
              onChange={(e) => setPhoneQuery(e.target.value)}
            />
          </div>
        )}
      </div>

      {tab === 'system' ? (
        <EditableTable
          rows={filteredSystemAccounts}
          columns={ACCOUNT_COLUMNS}
          onUpdateCell={updateSystemAccountCell}
          onDeleteRow={deleteSystemAccountRow}
          onAddRow={addSystemAccountRow}
          mergeColumns={['group_name', 'system_name', 'url', 'note']}
          boldBoundaryColumns={['group_name', 'system_name']}
        />
      ) : (
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        <PhoneContactPanels rows={filteredPhoneContacts as any} />
      )}
    </div>
  )
}
