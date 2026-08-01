'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function addTask(formData: FormData) {
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const assignee = formData.get('assignee') as string
  const due_date = (formData.get('due_date') as string) || null
  const category = formData.get('category') as string

  const { error } = await supabase.from('tasks').insert({
    title,
    description,
    assignee,
    due_date,
    category,
    status: '진행중',
  })

  if (error) {
    console.error(error)
    throw new Error('업무 등록에 실패했습니다.')
  }

  revalidatePath('/tasks')
}

export async function toggleTaskStatus(id: number, currentStatus: string) {
  const nextStatus = currentStatus === '완료' ? '진행중' : '완료'

  const { error } = await supabase
    .from('tasks')
    .update({ status: nextStatus })
    .eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('상태 변경에 실패했습니다.')
  }

  revalidatePath('/tasks')
}

export async function deleteTask(id: number) {
  const { error } = await supabase.from('tasks').delete().eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/tasks')
}
