'use client'

import { useRef, useState } from 'react'
import { addResource } from './actions'

export default function ResourceForm() {
  const formRef = useRef<HTMLFormElement>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(formData: FormData) {
    setSubmitting(true)
    try {
      await addResource(formData)
      formRef.current?.reset()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form ref={formRef} action={handleSubmit} className="resource-form">
      <input name="title" placeholder="제목" required />
      <textarea name="description" placeholder="설명" rows={3} />
      <input name="author" placeholder="작성자" required />
      <input type="file" name="file" />
      <button type="submit" disabled={submitting}>
        {submitting ? '업로드 중...' : '+ 자료 등록'}
      </button>
    </form>
  )
}
