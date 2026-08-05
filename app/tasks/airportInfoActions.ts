'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function saveAirportInfo(formData: FormData) {
  const airport = formData.get('airport') as string
  const field = formData.get('field') as string
  const textValue = formData.get('value_text') as string | null
  const file = formData.get('value_file') as File | null

  let updateValue: string | null = textValue

  if (field === 'apron_diagram_url' && file && file.size > 0) {
    const filePath = `airport-info/${airport}_${Date.now()}_${file.name}`

    const { error: uploadError } = await supabase.storage
      .from('task-documents')
      .upload(filePath, file)

    if (uploadError) {
      console.error(uploadError)
      throw new Error('이미지 업로드에 실패했습니다.')
    }

    const { data } = supabase.storage.from('task-documents').getPublicUrl(filePath)
    updateValue = data.publicUrl
  }

  const { error } = await supabase
    .from('airport_info')
    .upsert(
      { airport, [field]: updateValue, updated_at: new Date().toISOString() },
      { onConflict: 'airport' }
    )

  if (error) {
    console.error(error)
    throw new Error('저장에 실패했습니다.')
  }

  revalidatePath('/tasks')
}

export async function clearAirportInfoField(airport: string, field: string) {
  const { error } = await supabase
    .from('airport_info')
    .upsert(
      { airport, [field]: null, updated_at: new Date().toISOString() },
      { onConflict: 'airport' }
    )

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/tasks')
}
