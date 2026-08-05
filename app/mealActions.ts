'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function saveMealImage(formData: FormData) {
  const side = formData.get('side') as string
  const file = formData.get('file') as File | null

  if (!file || file.size === 0) {
    throw new Error('이미지를 선택해주세요.')
  }

  const filePath = `meal/${side}_${Date.now()}_${file.name}`

  const { error: uploadError } = await supabase.storage
    .from('task-documents')
    .upload(filePath, file)

  if (uploadError) {
    console.error(uploadError)
    throw new Error('이미지 업로드에 실패했습니다.')
  }

  const { data } = supabase.storage.from('task-documents').getPublicUrl(filePath)
  const column = side === 'left' ? 'left_image_url' : 'right_image_url'

  const { error } = await supabase
    .from('meal_board')
    .upsert(
      { id: 1, [column]: data.publicUrl, updated_at: new Date().toISOString() },
      { onConflict: 'id' }
    )

  if (error) {
    console.error(error)
    throw new Error('저장에 실패했습니다.')
  }

  revalidatePath('/')
}

export async function clearMealImage(side: 'left' | 'right') {
  const column = side === 'left' ? 'left_image_url' : 'right_image_url'

  const { error } = await supabase
    .from('meal_board')
    .upsert(
      { id: 1, [column]: null, updated_at: new Date().toISOString() },
      { onConflict: 'id' }
    )

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/')
}
