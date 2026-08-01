'use client'

import { useRef, useState } from 'react'
import { addDocument } from './documentActions'

export default function DocumentForm({
  docType,
  region,
  onDone,
}: {
  docType: '보고서' | '주기장요도'
  region: '국내' | '해외'
  onDone: () => void
}) {
  const formRef = useRef<HTMLFormElement>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(formData: FormData) {
    setSubmitting(true)
    try {
      await addDocument(formData)
      formRef.current?.reset()
      onDone()
    } catch (e) {
      alert(e instanceof Error ? e.message : '오류가 발생했습니다.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form ref={formRef} action={handleSubmit} className="document-form-compact">
      <input type="hidden" name="doc_type" value={docType} />
      <input type="hidden" name="region" value={region} />
      <input name="title" placeholder="제목" required />
      <input name="author" placeholder="작성자" required />
      <textarea name="description" placeholder="내용 (선택)" rows={2} />
      <input type="file" name="file" accept=".pdf,.jpg,.jpeg,.png,.xlsx,.xls" />
      <div className="form-actions">
        <button type="submit" disabled={submitting}>
          {submitting ? '업로드 중...' : '등록'}
        </button>
        <button type="button" className="btn-secondary" onClick={onDone}>
          닫기
        </button>
      </div>
    </form>
  )
}
