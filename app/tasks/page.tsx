import { supabase } from '@/lib/supabaseClient'
import TaskBoard from './TaskBoard'

export const dynamic = 'force-dynamic'

export default async function TasksPage() {
  const { data: documents, error } = await supabase
    .from('task_documents')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    console.error(error)
  }

  return (
    <div className="page">
      <h1>✅ 업무관리</h1>

      <TaskBoard documents={documents ?? []} />
    </div>
  )
}
