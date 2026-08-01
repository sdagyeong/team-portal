import { supabase } from '@/lib/supabaseClient'
import ResourceBoard from './ResourceBoard'

export const dynamic = 'force-dynamic'

export default async function ResourcesPage() {
  const { data: documents, error } = await supabase
    .from('task_documents')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    console.error(error)
  }

  return (
    <div className="page">
      <h1>📁 자료실</h1>

      <ResourceBoard documents={documents ?? []} />
    </div>
  )
}
