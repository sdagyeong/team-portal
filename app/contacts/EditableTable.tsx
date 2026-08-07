'use client'

import { useState } from 'react'
import { IconTrash, IconPlus } from '@/components/icons'

export type Column = { key: string; label: string; width?: string }

export default function EditableTable({
  rows,
  columns,
  onUpdateCell,
  onDeleteRow,
  onAddRow,
}: {
  rows: Record<string, string | number | null>[]
  columns: Column[]
  onUpdateCell: (id: number, field: string, value: string) => Promise<void>
  onDeleteRow: (id: number) => Promise<void>
  onAddRow: () => Promise<void>
}) {
  const [editing, setEditing] = useState<{ id: number; field: string } | null>(null)
  const [busy, setBusy] = useState(false)

  async function save(id: number, field: string, value: string) {
    setBusy(true)
    try {
      await onUpdateCell(id, field, value)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
      setEditing(null)
    }
  }

  async function handleDelete(id: number) {
    if (!confirm('이 행을 삭제할까요?')) return
    setBusy(true)
    try {
      await onDeleteRow(id)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
    }
  }

  async function handleAdd() {
    setBusy(true)
    try {
      await onAddRow()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="edit-table-wrap">
      <table className="edit-table">
        <thead>
          <tr>
            {columns.map((c) => (
              <th key={c.key} style={{ width: c.width }}>
                {c.label}
              </th>
            ))}
            <th style={{ width: 40 }} />
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 && (
            <tr>
              <td colSpan={columns.length + 1} className="edit-table-empty-row">
                등록된 항목이 없습니다.
              </td>
            </tr>
          )}
          {rows.map((row) => {
            const id = row.id as number
            return (
              <tr key={id}>
                {columns.map((c) => {
                  const isEditing = editing?.id === id && editing.field === c.key
                  const value = row[c.key]
                  return (
                    <td
                      key={c.key}
                      onClick={() => !isEditing && setEditing({ id, field: c.key })}
                    >
                      {isEditing ? (
                        <textarea
                          autoFocus
                          defaultValue={(value as string) ?? ''}
                          disabled={busy}
                          onBlur={(e) => save(id, c.key, e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter' && !e.shiftKey) {
                              e.preventDefault()
                              ;(e.target as HTMLTextAreaElement).blur()
                            }
                            if (e.key === 'Escape') setEditing(null)
                          }}
                        />
                      ) : value ? (
                        <span className="edit-table-cell-value">{value}</span>
                      ) : (
                        <span className="edit-table-cell-empty">-</span>
                      )}
                    </td>
                  )
                })}
                <td>
                  <button
                    type="button"
                    className="doc-row-delete"
                    onClick={() => handleDelete(id)}
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

      <button type="button" className="edit-table-add" onClick={handleAdd} disabled={busy}>
        <IconPlus size={13} /> 행 추가
      </button>
    </div>
  )
}
