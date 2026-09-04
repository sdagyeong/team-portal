'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function addDocument(formData: FormData) {
  const doc_type = formData.get('doc_type') as string
  const region = formData.get('region') as string
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const author = formData.get('author') as string
  const file = formData.get('file') as File | null

  let file_url: string | null = null
  let file_name: string | null = null

  if (file && file.size > 0) {
    const safeName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_')
    const filePath = `${Date.now()}_${safeName}`

    const { error: uploadError } = await supabase.storage
      .from('task-documents')
      .upload(filePath, file)

    if (uploadError) {
      console.error(uploadError)
      throw new Error('파일 업로드에 실패했습니다.')
    }

    const { data: publicUrlData } = supabase.storage
      .from('task-documents')
      .getPublicUrl(filePath)

    file_url = publicUrlData.publicUrl
    file_name = file.name
  }

  const { error } = await supabase.from('task_documents').insert({
    doc_type,
    region,
    title,
    description,
    author,
    file_url,
    file_name,
  })

  if (error) {
    console.error(error)
    throw new Error('등록에 실패했습니다.')
  }

  revalidatePath('/tasks')
}

export async function deleteDocument(id: number) {
  const { error } = await supabase.from('task_documents').delete().eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/tasks')
}
