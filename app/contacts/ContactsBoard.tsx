'use client'

import { useState } from 'react'
import EditableTable, { type Column } from './EditableTable'
import PhoneContactPanels from './PhoneContactPanels'
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

type Row = Record<string, string | number | null>

export default function ContactsBoard({
  systemAccounts,
  phoneContacts,
}: {
  systemAccounts: Row[]
  phoneContacts: Row[]
}) {
  const [tab, setTab] = useState<'system' | 'phone'>('system')

  return (
    <div className="task-board">
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
        <EditableTable
          rows={systemAccounts}
          columns={ACCOUNT_COLUMNS}
          onUpdateCell={updateSystemAccountCell}
          onDeleteRow={deleteSystemAccountRow}
          onAddRow={addSystemAccountRow}
        />
      ) : (
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        <PhoneContactPanels rows={phoneContacts as any} />
      )}
    </div>
  )
}
