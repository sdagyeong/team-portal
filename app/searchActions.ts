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

export const SEARCH_CATEGORIES = [
  { value: '전체', label: '전체' },
  { value: '업무지시공유', label: '업무지시공유' },
  { value: '보고서', label: 'AIRPORT · 보고서' },
  { value: '매뉴얼', label: '자료실 · 매뉴얼' },
  { value: '계정연락망', label: '계정/연락망' },
] as const

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

export async function searchAll(
  rawQuery: string,
  category: string = '전체'
): Promise<SearchResult[]> {
  const q = rawQuery.trim()
  if (!q) return []

  const includeNotices = category === '전체' || category === '업무지시공유'
  const includeDocs = category === '전체' || category in DOC_BASE

  const [noticeRes, docRes] = await Promise.all([
    includeNotices
      ? supabase
          .from('notices')
          .select('id, title, author')
          .or(`title.ilike.%${q}%,content.ilike.%${q}%,author.ilike.%${q}%`)
          .order('id', { ascending: false })
          .limit(6)
      : Promise.resolve({ data: [] as { id: number; title: string; author: string }[] }),
    includeDocs
      ? (() => {
          let query = supabaseData
            .from('task_documents')
            .select('id, title, author, doc_type')
            .or(`title.ilike.%${q}%,description.ilike.%${q}%,author.ilike.%${q}%`)
            .order('created_at', { ascending: false })
            .limit(6)
          if (category !== '전체') {
            query = query.eq('doc_type', category)
          }
          return query
        })()
      : Promise.resolve({
          data: [] as { id: number; title: string; author: string; doc_type: string }[],
        }),
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
