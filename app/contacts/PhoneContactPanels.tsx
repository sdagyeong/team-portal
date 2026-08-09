'use client'

import { useState } from 'react'
import type { ReactNode } from 'react'
import { IconTrash, IconPlus } from '@/components/icons'
import {
  updatePhoneContactCell,
  deletePhoneContactRow,
  addPhoneContactRow,
} from './contactActions'

type Row = {
  id: number
  name: string | null
  position: string | null
  office_phone: string | null
  mobile: string | null
  note: string | null
}

const COLUMN_COUNT = 3
const PRIORITY = ['인천공항', '김포공항', 'OAL 및 기타']

export default function PhoneContactPanels({ rows }: { rows: Row[] }) {
  const [editing, setEditing] = useState<{ id: number; field: string } | null>(null)
  const [busy, setBusy] = useState(false)
  const [newCategory, setNewCategory] = useState('')
  const [newName, setNewName] = useState('')
  const [newPhone, setNewPhone] = useState('')

  const groups = new Map<string, Row[]>()
  rows.forEach((r) => {
    const key = r.position?.trim() || '미분류'
    if (!groups.has(key)) groups.set(key, [])
    groups.get(key)!.push(r)
  })

  const sortedGroups = [...groups.entries()].sort((a, b) => {
    const ai = PRIORITY.indexOf(a[0])
    const bi = PRIORITY.indexOf(b[0])
    const aRank = ai === -1 ? PRIORITY.length : ai
    const bRank = bi === -1 ? PRIORITY.length : bi
    return aRank - bRank
  })

  async function save(id: number, field: string, value: string) {
    setBusy(true)
    try {
      await updatePhoneContactCell(id, field, value)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
      setEditing(null)
    }
  }

  async function handleDelete(id: number) {
    if (!confirm('이 항목을 삭제할까요?')) return
    setBusy(true)
    try {
      await deletePhoneContactRow(id)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
    }
  }

  async function handleAddToCategory(category: string) {
    setBusy(true)
    try {
      await addPhoneContactRow(category)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
    }
  }

  async function handleCreateCategory() {
    if (!newCategory.trim()) return
    setBusy(true)
    try {
      await addPhoneContactRow(newCategory.trim(), newName.trim(), newPhone.trim())
      setNewCategory('')
      setNewName('')
      setNewPhone('')
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
    }
  }

  function renderCategoryPanel(category: string, catRows: Row[]) {
    return (
      <div key={category} className="phone-panel">
        <h3 className="phone-panel-title">{category}</h3>
        <table className="phone-panel-table">
          <tbody>
            {catRows.map((row) => {
              const editingNote = editing?.id === row.id && editing.field === 'note'
              const editingName = editing?.id === row.id && editing.field === 'name'
              const editingPhone = editing?.id === row.id && editing.field === 'office_phone'

              return (
                <tr key={row.id}>
                  <td className="phone-row-name-cell">
                    <div className="phone-row-name-wrap">
                      {editingNote ? (
                        <input
                          autoFocus
                          className="phone-row-badge-input"
                          defaultValue={row.note ?? ''}
                          disabled={busy}
                          onBlur={(e) => save(row.id, 'note', e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') (e.target as HTMLInputElement).blur()
                            if (e.key === 'Escape') setEditing(null)
                          }}
                        />
                      ) : row.note ? (
                        <button
                          type="button"
                          className="phone-row-badge"
                          onClick={() => setEditing({ id: row.id, field: 'note' })}
                          title="단축번호 수정"
                        >
                          {row.note}
                        </button>
                      ) : (
                        <button
                          type="button"
                          className="phone-row-badge phone-row-badge-empty"
                          onClick={() => setEditing({ id: row.id, field: 'note' })}
                          title="단축번호 추가"
                        >
                          +
                        </button>
                      )}

                      {editingName ? (
                        <input
                          autoFocus
                          className="phone-row-name-input"
                          defaultValue={row.name ?? ''}
                          disabled={busy}
                          onBlur={(e) => save(row.id, 'name', e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') (e.target as HTMLInputElement).blur()
                            if (e.key === 'Escape') setEditing(null)
                          }}
                        />
                      ) : (
                        <span
                          className="phone-row-name"
                          onClick={() => setEditing({ id: row.id, field: 'name' })}
                        >
                          {row.name || <span className="edit-table-cell-empty">-</span>}
                        </span>
                      )}
                    </div>
                  </td>

                  <td
                    className="phone-row-phone-cell"
                    onClick={() => !editingPhone && setEditing({ id: row.id, field: 'office_phone' })}
                  >
                    {editingPhone ? (
                      <input
                        autoFocus
                        defaultValue={row.office_phone ?? ''}
                        disabled={busy}
                        onBlur={(e) => save(row.id, 'office_phone', e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') (e.target as HTMLInputElement).blur()
                          if (e.key === 'Escape') setEditing(null)
                        }}
                      />
                    ) : (
                      <span className="edit-table-cell-value">
                        {row.office_phone || <span className="edit-table-cell-empty">-</span>}
                      </span>
                    )}
                  </td>

                  <td className="phone-panel-delete-cell">
                    <button
                      type="button"
                      className="doc-row-delete"
                      onClick={() => handleDelete(row.id)}
                      aria-label="삭제"
                    >
                      <IconTrash />
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
        <button
          type="button"
          className="phone-panel-add"
          onClick={() => handleAddToCategory(category)}
          disabled={busy}
        >
          <IconPlus size={12} /> 항목 추가
        </button>
      </div>
    )
  }

  const newCategoryPanel = (
    <div key="__new_category__" className="phone-panel phone-panel-new">
      <h3 className="phone-panel-title">+ 새 구분 만들기</h3>
      <input
        className="phone-panel-new-input"
        placeholder="구분 이름 (예: 국제선 카운터)"
        value={newCategory}
        onChange={(e) => setNewCategory(e.target.value)}
      />
      <input
        className="phone-panel-new-input"
        placeholder="명칭"
        value={newName}
        onChange={(e) => setNewName(e.target.value)}
      />
      <input
        className="phone-panel-new-input"
        placeholder="전화번호"
        value={newPhone}
        onChange={(e) => setNewPhone(e.target.value)}
      />
      <button
        type="button"
        className="phone-panel-add"
        onClick={handleCreateCategory}
        disabled={busy}
      >
        <IconPlus size={12} /> 구분 추가
      </button>
    </div>
  )

  // 첫 줄이 순서대로(인천공항/김포공항/OAL...) 가로로 채워지도록,
  // 열 개수만큼 라운드로빈으로 배분하고 그 아래는 각 열이 알아서 이어지게 함(정렬 불일치 허용)
  const allPanels = [
    ...sortedGroups.map(([category, catRows]) => renderCategoryPanel(category, catRows)),
    newCategoryPanel,
  ]

  const columns: ReactNode[][] = Array.from({ length: COLUMN_COUNT }, () => [])
  allPanels.forEach((panel, i) => {
    columns[i % COLUMN_COUNT].push(panel)
  })

  return (
    <div className="phone-panels">
      {columns.map((col, ci) => (
        <div key={ci} className="phone-panels-column">
          {col}
        </div>
      ))}
    </div>
  )
}
