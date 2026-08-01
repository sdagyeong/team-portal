'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function addResource(formData: FormData) {
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const author = formData.get('author') as string
  const file = formData.get('file') as File | null

  let file_url: string | null = null
  let file_name: string | null = null

  // 파일이 첨부된 경우에만 Supabase Storage에 업로드
  if (file && file.size > 0) {
    const filePath = `${Date.now()}_${file.name}`

    const { error: uploadError } = await supabase.storage
      .from('resources')
      .upload(filePath, file)

    if (uploadError) {
      console.error(uploadError)
      throw new Error('파일 업로드에 실패했습니다.')
    }

    const { data: publicUrlData } = supabase.storage
      .from('resources')
      .getPublicUrl(filePath)

    file_url = publicUrlData.publicUrl
    file_name = file.name
  }

  const { error } = await supabase.from('resources').insert({
    title,
    description,
    author,
    file_url,
    file_name,
  })

  if (error) {
    console.error(error)
    throw new Error('자료 등록에 실패했습니다.')
  }

  revalidatePath('/resources')
}

export async function deleteResource(id: number) {
  const { error } = await supabase.from('resources').delete().eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/resources')
}
