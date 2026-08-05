import Link from 'next/link'
import { supabase } from '@/lib/supabaseClient'
import DocumentForm from './DocumentForm'
import { deleteDocument } from './documentActions'
import { IconContact, IconTrash } from '@/components/icons'

export const dynamic = 'force-dynamic'

export default async function ContactsPage() {
  const { data: documents, error } = await supabase
    .from('task_documents')
    .select('*')
    .eq('doc_type', '계정연락망')
    .order('created_at', { ascending: false })

  if (error) {
    console.error(error)
  }

  return (
    <div className="page">
      <h1>
        <IconContact size={20} className="page-title-icon" /> 계정/연락망
      </h1>

      <DocumentForm />

      <div className="doc-list">
        {(!documents || documents.length === 0) && (
          <p className="empty">등록된 자료가 없습니다.</p>
        )}
        {documents?.map((doc) => (
          <div key={doc.id} className="doc-row">
            <Link href={`/contacts/doc/${doc.id}`} className="doc-row-title">
              {doc.file_url && '📎 '}
              {doc.title}
            </Link>
            <span className="doc-row-author">{doc.author}</span>
            <span className="doc-row-date">
              {new Date(doc.created_at).toLocaleDateString('ko-KR')}
            </span>
            <form
              action={async () => {
                'use server'
                await deleteDocument(doc.id)
              }}
            >
              <button type="submit" className="doc-row-delete" aria-label="삭제">
                <IconTrash />
              </button>
            </form>
          </div>
        ))}
      </div>
    </div>
  )
}
