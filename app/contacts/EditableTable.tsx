'use client'

import { useState } from 'react'
import { IconTrash, IconPlus } from '@/components/icons'

export type Column = { key: string; label: string; width?: string }

type Row = Record<string, string | number | null>

function computeMergeGroups(rows: Row[], mergeColumns: string[]) {
  const spanAt: Record<number, Record<string, { span: number; ids: number[] }>> = {}
  const hidden: Record<number, Set<string>> = {}

  mergeColumns.forEach((field) => {
    let i = 0
    while (i < rows.length) {
      const val = rows[i][field]
      if (val === null || val === undefined || val === '') {
        i += 1
        continue
      }
      let j = i + 1
      while (j < rows.length && rows[j][field] === val) j += 1
      const span = j - i
      if (span > 1) {
        if (!spanAt[i]) spanAt[i] = {}
        spanAt[i][field] = { span, ids: rows.slice(i, j).map((r) => r.id as number) }
        for (let k = i + 1; k < j; k++) {
          if (!hidden[k]) hidden[k] = new Set()
          hidden[k].add(field)
        }
      }
      i = j
    }
  })

  return { spanAt, hidden }
}

// 지정한 컬럼 기준으로, 연속된 같은 값 묶음의 "마지막 행" 인덱스들을 반환 (구간 경계선용)
function computeRunEnds(rows: Row[], field: string): Set<number> {
  const ends = new Set<number>()
  for (let i = 0; i < rows.length; i++) {
    const isLast = i === rows.length - 1 || rows[i][field] !== rows[i + 1][field]
    if (isLast) ends.add(i)
  }
  return ends
}

export default function EditableTable({
  rows,
  columns,
  onUpdateCell,
  onDeleteRow,
  onAddRow,
  mergeColumns = [],
  boldBoundaryColumns,
}: {
  rows: Row[]
  columns: Column[]
  onUpdateCell: (id: number, field: string, value: string) => Promise<void>
  onDeleteRow: (id: number) => Promise<void>
  onAddRow: () => Promise<void>
  mergeColumns?: string[]
  boldBoundaryColumns?: string[]
}) {
  const [editing, setEditing] = useState<{ id: number; field: string } | null>(null)
  const [busy, setBusy] = useState(false)

  const { spanAt, hidden } = computeMergeGroups(rows, mergeColumns)

  const boundaryCols = boldBoundaryColumns ?? mergeColumns
  const blockEnds = new Set<number>()
  boundaryCols.forEach((field) => {
    computeRunEnds(rows, field).forEach((idx) => blockEnds.add(idx))
  })

  async function save(id: number, field: string, value: string, groupIds?: number[]) {
    setBusy(true)
    try {
      if (groupIds && groupIds.length > 1) {
        await Promise.all(groupIds.map((gid) => onUpdateCell(gid, field, value)))
      } else {
        await onUpdateCell(id, field, value)
      }
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
          {rows.map((row, rowIndex) => {
            const id = row.id as number
            const isBlockEndRow = blockEnds.has(rowIndex)
            return (
              <tr key={id} className={isBlockEndRow ? 'edit-table-row-block-end' : undefined}>
                {columns.map((c) => {
                  const isMergeCol = mergeColumns.includes(c.key)

                  if (isMergeCol && hidden[rowIndex]?.has(c.key)) {
                    return null
                  }

                  const mergeInfo = isMergeCol ? spanAt[rowIndex]?.[c.key] : undefined
                  const span = mergeInfo?.span ?? 1
                  // 병합된 셀은 시작 행에만 존재하므로, 병합이 끝나는 실제 행 기준으로
                  // 굵은 경계선 여부를 따로 판정해서 셀 자체에 직접 적용한다.
                  const endIndex = rowIndex + span - 1
                  const isCellBlockEnd = blockEnds.has(endIndex)

                  const isEditing = editing?.id === id && editing.field === c.key
                  const value = row[c.key]

                  const cellClassNames = [
                    isMergeCol ? 'edit-table-merge-col-cell' : '',
                    isMergeCol && isCellBlockEnd ? 'edit-table-cell-block-end' : '',
                  ]
                    .filter(Boolean)
                    .join(' ')

                  return (
                    <td
                      key={c.key}
                      rowSpan={mergeInfo?.span}
                      className={cellClassNames || undefined}
                      onClick={() => !isEditing && setEditing({ id, field: c.key })}
                    >
                      {isEditing ? (
                        <textarea
                          autoFocus
                          defaultValue={(value as string) ?? ''}
                          disabled={busy}
                          onBlur={(e) => save(id, c.key, e.target.value, mergeInfo?.ids)}
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
