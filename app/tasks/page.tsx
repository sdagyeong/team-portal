import { supabase } from '@/lib/supabaseClient'
import TaskBoard from './TaskBoard'
import { IconPlane } from '@/components/icons'

export const dynamic = 'force-dynamic'

export default async function TasksPage() {
  const [{ data: documents, error: docError }, { data: airportInfo, error: infoError }] =
    await Promise.all([
      supabase.from('task_documents').select('*').order('created_at', { ascending: false }),
      supabase.from('airport_info').select('*'),
    ])

  if (docError) {
    console.error(docError)
  }
  if (infoError) {
    console.error(infoError)
  }

  return (
    <div className="page">
      <h1>
        <IconPlane size={20} className="page-title-icon" /> AIRPORT
      </h1>

      <TaskBoard documents={documents ?? []} airportInfoList={airportInfo ?? []} />
    </div>
  )
}
