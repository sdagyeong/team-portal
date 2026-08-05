'use client'

import { useState } from 'react'
import { saveAirportInfo, clearAirportInfoField } from './airportInfoActions'

type AirportInfo = {
  airport: string
  apron_diagram_url: string | null
  parking_stand: string | null
  active_runway: string | null
  deicing_pad: string | null
}

const FIELDS: {
  key: keyof Omit<AirportInfo, 'airport'>
  label: string
  type: 'image' | 'text'
}[] = [
  { key: 'apron_diagram_url', label: '주기장요도', type: 'image' },
  { key: 'parking_stand', label: '주기장', type: 'text' },
  { key: 'active_runway', label: '사용 활주로', type: 'text' },
  { key: 'deicing_pad', label: '제방빙장', type: 'text' },
]

export default function AirportInfoCard({
  airport,
  info,
}: {
  airport: string
  info: AirportInfo | null
}) {
  const [editing, setEditing] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSave(field: string, formData: FormData) {
    formData.set('airport', airport)
    formData.set('field', field)
    setSubmitting(true)
    try {
      await saveAirportInfo(formData)
      setEditing(null)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  async function handleClear(field: string) {
    if (!confirm('등록된 내용을 삭제할까요?')) return
    setSubmitting(true)
    try {
      await clearAirportInfoField(airport, field)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="airport-info-card">
      {FIELDS.map((f) => {
        const value = info?.[f.key] ?? null
        const isEditing = editing === f.key

        return (
          <div key={f.key} className="airport-info-row">
            <span className="airport-info-label">{f.label}</span>

            {!isEditing && (
              <>
                <div className="airport-info-value">
                  {f.type === 'image' ? (
                    value ? (
                      <img src={value} alt={f.label} className="airport-info-image" />
                    ) : (
                      <span className="empty">등록된 이미지가 없습니다.</span>
                    )
                  ) : value ? (
                    value
                  ) : (
                    <span className="empty">등록된 내용이 없습니다.</span>
                  )}
                </div>
                <button
                  type="button"
                  className="airport-info-edit-btn"
                  onClick={() => setEditing(f.key)}
                >
                  수정
                </button>
                {value && (
                  <button
                    type="button"
                    className="airport-info-clear-btn"
                    onClick={() => handleClear(f.key)}
                    disabled={submitting}
                  >
                    삭제
                  </button>
                )}
              </>
            )}

            {isEditing && (
              <form
                action={(fd) => handleSave(f.key, fd)}
                className="airport-info-edit-form"
              >
                {f.type === 'image' ? (
                  <input type="file" name="value_file" accept="image/*" />
                ) : (
                  <input
                    type="text"
                    name="value_text"
                    defaultValue={value ?? ''}
                    placeholder={f.label}
                  />
                )}
                <div className="airport-info-edit-actions">
                  <button type="submit" className="btn-primary" disabled={submitting}>
                    {submitting ? '저장 중...' : '저장'}
                  </button>
                  <button
                    type="button"
                    className="btn-secondary"
                    onClick={() => setEditing(null)}
                  >
                    취소
                  </button>
                </div>
              </form>
            )}
          </div>
        )
      })}
    </div>
  )
}
