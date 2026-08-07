'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

// ---------- 시스템 계정 ----------
export async function addSystemAccountRow() {
  const { error } = await supabase.from('system_accounts').insert({})
  if (error) {
    console.error(error)
    throw new Error('추가에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

export async function updateSystemAccountCell(id: number, field: string, value: string) {
  const { error } = await supabase
    .from('system_accounts')
    .update({ [field]: value, updated_at: new Date().toISOString() })
    .eq('id', id)
  if (error) {
    console.error(error)
    throw new Error('저장에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

export async function deleteSystemAccountRow(id: number) {
  const { error } = await supabase.from('system_accounts').delete().eq('id', id)
  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

// ---------- 유선 연락망 ----------
export async function addPhoneContactRow(
  position: string = '',
  name: string = '',
  office_phone: string = ''
) {
  const { error } = await supabase
    .from('phone_contacts')
    .insert({ position, name, office_phone })
  if (error) {
    console.error(error)
    throw new Error('추가에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

export async function updatePhoneContactCell(id: number, field: string, value: string) {
  const { error } = await supabase
    .from('phone_contacts')
    .update({ [field]: value, updated_at: new Date().toISOString() })
    .eq('id', id)
  if (error) {
    console.error(error)
    throw new Error('저장에 실패했습니다.')
  }
  revalidatePath('/contacts')
}

export async function deletePhoneContactRow(id: number) {
  const { error } = await supabase.from('phone_contacts').delete().eq('id', id)
  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }
  revalidatePath('/contacts')
}
