#!/bin/bash
set -e

mkdir -p app components lib

cat > lib/searchCategories.ts << 'FIXSEARCHFIXEOF'
export const SEARCH_CATEGORIES = [
  { value: '전체', label: '전체' },
  { value: '업무지시공유', label: '업무지시공유' },
  { value: '보고서', label: 'AIRPORT · 보고서' },
  { value: '매뉴얼', label: '자료실 · 매뉴얼' },
  { value: '계정연락망', label: '계정/연락망' },
] as const
FIXSEARCHFIXEOF

cat > app/searchActions.ts << 'FIXSEARCHFIXEOF'
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
FIXSEARCHFIXEOF

cat > components/SearchBox.tsx << 'FIXSEARCHFIXEOF'
"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { searchAll, type SearchResult } from "@/app/searchActions";
import { SEARCH_CATEGORIES } from "@/lib/searchCategories";
import { IconFilePreview } from "./icons";

export default function SearchBox() {
  const [category, setCategory] = useState<string>("전체");
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const boxRef = useRef<HTMLDivElement>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (boxRef.current && !boxRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  function runSearch(value: string, cat: string) {
    if (timerRef.current) clearTimeout(timerRef.current);

    if (!value.trim()) {
      setResults([]);
      setOpen(false);
      return;
    }

    timerRef.current = setTimeout(async () => {
      setLoading(true);
      try {
        const res = await searchAll(value, cat);
        setResults(res);
        setOpen(true);
      } finally {
        setLoading(false);
      }
    }, 300);
  }

  function handleQueryChange(value: string) {
    setQuery(value);
    runSearch(value, category);
  }

  function handleCategoryChange(value: string) {
    setCategory(value);
    if (query.trim()) runSearch(query, value);
  }

  function goFullSearch() {
    if (!query.trim()) return;
    setOpen(false);
    router.push(`/search?q=${encodeURIComponent(query)}&type=${encodeURIComponent(category)}`);
  }

  function goResult(href: string) {
    setOpen(false);
    setQuery("");
    router.push(href);
  }

  return (
    <div className="header-search-wrap" ref={boxRef}>
      <form
        className="header-search"
        onSubmit={(e) => {
          e.preventDefault();
          goFullSearch();
        }}
      >
        <select
          className="header-search-category"
          value={category}
          onChange={(e) => handleCategoryChange(e.target.value)}
        >
          {SEARCH_CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>
              {c.label}
            </option>
          ))}
        </select>

        <input
          type="text"
          placeholder="검색어 입력..."
          value={query}
          onChange={(e) => handleQueryChange(e.target.value)}
          onFocus={() => query.trim() && setOpen(true)}
        />

        <button type="submit" aria-label="검색">
          <IconFilePreview size={16} />
        </button>
      </form>

      {open && (
        <div className="search-dropdown">
          {loading && <p className="search-dropdown-empty">검색 중...</p>}

          {!loading && results.length === 0 && (
            <p className="search-dropdown-empty">일치하는 결과가 없습니다.</p>
          )}

          {!loading &&
            results.map((r) => (
              <button
                key={`${r.type}-${r.id}`}
                type="button"
                className="search-dropdown-item"
                onClick={() => goResult(r.href)}
              >
                <span className="search-dropdown-type">{r.type}</span>
                <span className="search-dropdown-title">{r.title}</span>
                <span className="search-dropdown-author">{r.author}</span>
              </button>
            ))}

          {!loading && (
            <button type="button" className="search-dropdown-more" onClick={goFullSearch}>
              &quot;{query}&quot; 전체 검색결과 보기
            </button>
          )}
        </div>
      )}
    </div>
  );
}
FIXSEARCHFIXEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."