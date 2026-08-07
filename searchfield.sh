#!/bin/bash
set -e

mkdir -p app app/search lib

cat > lib/searchCategories.ts << 'SEARCHFIELDEOF'
export const SEARCH_CATEGORIES = [
  { value: '전체', label: '전체' },
  { value: '제목', label: '제목' },
  { value: '작성자', label: '작성자' },
  { value: '내용', label: '내용' },
] as const
SEARCHFIELDEOF

cat > app/searchActions.ts << 'SEARCHFIELDEOF'
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
SEARCHFIELDEOF

cat > app/search/page.tsx << 'SEARCHFIELDEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { supabase as supabaseData } from "@/lib/supabaseClient";
import { formatKDate } from "@/lib/formatDate";
import { IconFilePreview, IconPin, IconFolder } from "@/components/icons";

const DOC_LABEL: Record<string, { label: string; base: string }> = {
  보고서: { label: "AIRPORT · 보고서", base: "/tasks/doc" },
  매뉴얼: { label: "자료실 · 매뉴얼", base: "/resources/doc" },
  계정연락망: { label: "계정/연락망", base: "/contacts/doc" },
};

function buildNoticeFilter(q: string, field: string) {
  if (field === "제목") return `title.ilike.%${q}%`;
  if (field === "작성자") return `author.ilike.%${q}%`;
  if (field === "내용") return `content.ilike.%${q}%`;
  return `title.ilike.%${q}%,content.ilike.%${q}%,author.ilike.%${q}%`;
}

function buildDocFilter(q: string, field: string) {
  if (field === "제목") return `title.ilike.%${q}%`;
  if (field === "작성자") return `author.ilike.%${q}%`;
  if (field === "내용") return `description.ilike.%${q}%`;
  return `title.ilike.%${q}%,description.ilike.%${q}%,author.ilike.%${q}%`;
}

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; type?: string }>;
}) {
  const { q, type } = await searchParams;
  const query = (q ?? "").trim();
  const field = type ?? "전체";

  let notices: { id: number; title: string; author: string; created_at: string }[] = [];
  let documents: {
    id: number;
    doc_type: string;
    title: string;
    author: string;
    created_at: string;
  }[] = [];

  if (query) {
    const [noticeRes, docRes] = await Promise.all([
      supabase
        .from("notices")
        .select("id, title, author, created_at")
        .or(buildNoticeFilter(query, field))
        .order("id", { ascending: false }),
      supabaseData
        .from("task_documents")
        .select("id, doc_type, title, author, created_at")
        .or(buildDocFilter(query, field))
        .order("created_at", { ascending: false }),
    ]);

    notices = noticeRes.data ?? [];
    documents = docRes.data ?? [];
  }

  const totalCount = notices.length + documents.length;

  return (
    <div className="page">
      <h1>
        <IconFilePreview size={20} className="page-title-icon" /> 검색 결과
      </h1>
      <p className="page-desc">
        {query
          ? `${field !== "전체" ? `[${field}] ` : ""}"${query}" 검색 결과 ${totalCount}건`
          : "검색어를 입력해주세요."}
      </p>

      {query && totalCount === 0 && <p className="empty">일치하는 게시글이 없습니다.</p>}

      {notices.length > 0 && (
        <section>
          <h3 className="search-section-title">
            <IconPin size={15} /> 업무지시공유
          </h3>
          <div className="doc-list">
            {notices.map((n) => (
              <div key={n.id} className="doc-row">
                <Link href={`/notices/${n.id}`} className="doc-row-title">
                  {n.title}
                </Link>
                <span className="doc-row-author">{n.author}</span>
                <span className="doc-row-date">{formatKDate(n.created_at)}</span>
              </div>
            ))}
          </div>
        </section>
      )}

      {documents.length > 0 && (
        <section style={{ marginTop: 24 }}>
          <h3 className="search-section-title">
            <IconFolder size={15} /> 자료실 / AIRPORT / 계정·연락망
          </h3>
          <div className="doc-list">
            {documents.map((d) => {
              const meta = DOC_LABEL[d.doc_type] ?? { label: d.doc_type, base: "/resources/doc" };
              return (
                <div key={d.id} className="doc-row">
                  <Link href={`${meta.base}/${d.id}`} className="doc-row-title">
                    [{meta.label}] {d.title}
                  </Link>
                  <span className="doc-row-author">{d.author}</span>
                  <span className="doc-row-date">{formatKDate(d.created_at)}</span>
                </div>
              );
            })}
          </div>
        </section>
      )}
    </div>
  );
}
SEARCHFIELDEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."