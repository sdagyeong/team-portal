'use client'

import { useState } from 'react'
import { saveMealImage, clearMealImage } from './mealActions'
import { IconImage } from '@/components/icons'

type MealInfo = {
  left_image_url: string | null
  right_image_url: string | null
} | null

export default function MealBoard({ info }: { info: MealInfo }) {
  const [editing, setEditing] = useState<'left' | 'right' | null>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleUpload(side: 'left' | 'right', formData: FormData) {
    formData.set('side', side)
    setSubmitting(true)
    try {
      await saveMealImage(formData)
      setEditing(null)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  async function handleClear(side: 'left' | 'right') {
    if (!confirm('이미지를 삭제할까요?')) return
    setSubmitting(true)
    try {
      await clearMealImage(side)
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  const slots: { key: 'left' | 'right'; url: string | null }[] = [
    { key: 'left', url: info?.left_image_url ?? null },
    { key: 'right', url: info?.right_image_url ?? null },
  ]

  return (
    <section className="dashboard-card meal-card">
      <div className="dashboard-card-header">
        <h3>
          <IconImage size={15} className="page-title-icon" /> 식단
        </h3>
      </div>

      <div className="meal-images">
        {slots.map((slot) => (
          <div key={slot.key} className="meal-slot">
            {editing !== slot.key && slot.url && (
              <img src={slot.url} alt="식단 이미지" className="meal-image" />
            )}
            {editing !== slot.key && !slot.url && (
              <div className="meal-empty">등록된 이미지가 없습니다.</div>
            )}

            {editing !== slot.key && (
              <div className="meal-slot-actions">
                <button
                  type="button"
                  className="airport-info-edit-btn"
                  onClick={() => setEditing(slot.key)}
                >
                  수정
                </button>
                {slot.url && (
                  <button
                    type="button"
                    className="airport-info-clear-btn"
                    onClick={() => handleClear(slot.key)}
                    disabled={submitting}
                  >
                    삭제
                  </button>
                )}
              </div>
            )}

            {editing === slot.key && (
              <form action={(fd) => handleUpload(slot.key, fd)} className="meal-edit-form">
                <input type="file" name="file" accept="image/*" />
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
        ))}
      </div>
    </section>
  )
}
