'use client'

import { useRef, useState } from 'react'
import { addTask } from './actions'

export default function TaskForm() {
  const formRef = useRef<HTMLFormElement>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(formData: FormData) {
    setSubmitting(true)
    try {
      await addTask(formData)
      formRef.current?.reset()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form ref={formRef} action={handleSubmit} className="task-form">
      <input type="hidden" name="category" value="업무지시공유" />
      <input name="title" placeholder="업무 제목" required />
      <textarea name="description" placeholder="내용" rows={2} />
      <div className="date-row">
        <label>
          담당자
          <input name="assignee" placeholder="담당자" required />
        </label>
        <label>
          마감일
          <input type="date" name="due_date" />
        </label>
      </div>
      <button type="submit" disabled={submitting}>
        {submitting ? '등록 중...' : '+ 업무 등록'}
      </button>
    </form>
  )
}
