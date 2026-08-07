'use server'

import { supabase } from '@/lib/supabase'
import { supabase as supabaseData } from '@/lib/supabaseClient'

export type SearchResult = {
  id: number
  title: string
  author: string
  type: string
  href: string
}

const DOC_BASE: Record<string, string> = {
  보고서: '/tasks/doc',
  매뉴얼: '/resources/doc',
  계정연락망: '/contacts/doc',
}

const DOC_LABEL: Record<string, string> = {
  보고서: 'AIRPORT · 보고서',
  매뉴얼: '자료실 · 매뉴얼',
  계정연락망: '계정/연락망',
}

function buildNoticeFilter(q: string, field: string) {
  if (field === '제목') return `title.ilike.%${q}%`
  if (field === '작성자') return `author.ilike.%${q}%`
  if (field === '내용') return `content.ilike.%${q}%`
  return `title.ilike.%${q}%,content.ilike.%${q}%,author.ilike.%${q}%`
}

function buildDocFilter(q: string, field: string) {
  if (field === '제목') return `title.ilike.%${q}%`
  if (field === '작성자') return `author.ilike.%${q}%`
  if (field === '내용') return `description.ilike.%${q}%`
  return `title.ilike.%${q}%,description.ilike.%${q}%,author.ilike.%${q}%`
}

export async function searchAll(
  rawQuery: string,
  field: string = '전체'
): Promise<SearchResult[]> {
  const q = rawQuery.trim()
  if (!q) return []

  const [noticeRes, docRes] = await Promise.all([
    supabase
      .from('notices')
      .select('id, title, author')
      .or(buildNoticeFilter(q, field))
      .order('id', { ascending: false })
      .limit(6),
    supabaseData
      .from('task_documents')
      .select('id, title, author, doc_type')
      .or(buildDocFilter(q, field))
      .order('created_at', { ascending: false })
      .limit(6),
  ])

  const notices: SearchResult[] = (noticeRes.data ?? []).map((n) => ({
    id: n.id,
    title: n.title,
    author: n.author,
    type: '업무지시공유',
    href: `/notices/${n.id}`,
  }))

  const docs: SearchResult[] = (docRes.data ?? []).map((d) => ({
    id: d.id,
    title: d.title,
    author: d.author,
    type: DOC_LABEL[d.doc_type] ?? d.doc_type,
    href: `${DOC_BASE[d.doc_type] ?? '/resources/doc'}/${d.id}`,
  }))

  return [...notices, ...docs]
}
