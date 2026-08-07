#!/bin/bash
set -e

mkdir -p app app/search components

cat > app/searchActions.ts << 'SEARCHCATEOF'
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
SEARCHCATEOF

cat > components/SearchBox.tsx << 'SEARCHCATEOF'
"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { searchAll, SEARCH_CATEGORIES, type SearchResult } from "@/app/searchActions";
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
SEARCHCATEOF

cat > app/search/page.tsx << 'SEARCHCATEOF'
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

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; type?: string }>;
}) {
  const { q, type } = await searchParams;
  const query = (q ?? "").trim();
  const category = type && type !== "전체" ? type : null;

  const includeNotices = !category || category === "업무지시공유";
  const includeDocs = !category || category in DOC_LABEL;

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
      includeNotices
        ? supabase
            .from("notices")
            .select("id, title, author, created_at")
            .or(`title.ilike.%${query}%,content.ilike.%${query}%,author.ilike.%${query}%`)
            .order("id", { ascending: false })
        : Promise.resolve({ data: [] }),
      includeDocs
        ? (() => {
            let q2 = supabaseData
              .from("task_documents")
              .select("id, doc_type, title, author, created_at")
              .or(`title.ilike.%${query}%,description.ilike.%${query}%,author.ilike.%${query}%`)
              .order("created_at", { ascending: false });
            if (category) q2 = q2.eq("doc_type", category);
            return q2;
          })()
        : Promise.resolve({ data: [] }),
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
          ? `${category ? `[${DOC_LABEL[category]?.label ?? category}] ` : ""}"${query}" 검색 결과 ${totalCount}건`
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
SEARCHCATEOF

cat > app/globals.css << 'SEARCHCATEOF'
@import url("https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.css");

:root {
  --color-navy: #0b1f3a;
  --color-navy-light: #16345d;
  --color-orange: #ea6a12;
  --color-orange-dark: #d15f0f;
  --color-orange-soft: #fdece0;
  --color-bg: #f5f6f8;
  --color-surface: #ffffff;
  --color-border: #e6e8ec;
  --color-text: #172033;
  --color-text-muted: #667085;
  --color-danger: #d92d20;
  --radius-md: 12px;
  --radius-lg: 16px;
  --shadow-card: 0 1px 2px rgba(16, 24, 40, 0.04), 0 1px 3px rgba(16, 24, 40, 0.06);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: var(--color-bg);
  font-family: "Pretendard", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
    sans-serif;
  color: var(--color-text);
}

.layout {
  display: flex;
  min-height: 100vh;
}

/* ================= 사이드바 ================= */
.sidebar {
  width: 260px;
  flex-shrink: 0;
  background: var(--color-navy);
  color: white;
  padding: 32px 20px;
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
}

.brand {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 0 6px 28px 6px;
  margin-bottom: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.12);
}

.brand-line1 {
  font-size: 20px;
  font-weight: 800;
  letter-spacing: 0.5px;
  color: var(--color-orange);
}

.brand-line2 {
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 1.2px;
  color: rgba(255, 255, 255, 0.75);
}

nav {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.menu {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 14px;
  border-radius: var(--radius-md);
  cursor: pointer;
  color: rgba(255, 255, 255, 0.82);
  font-size: 14px;
  font-weight: 500;
  border-left: 3px solid transparent;
  transition: background 0.15s ease, color 0.15s ease;
}

.menu-icon {
  display: inline-flex;
  align-items: center;
}

.menu:hover {
  background: rgba(255, 255, 255, 0.06);
  color: white;
}

.menu.active {
  background: rgba(234, 106, 18, 0.16);
  color: white;
  border-left-color: var(--color-orange);
  font-weight: 700;
}

.brand-link {
  text-decoration: none;
  cursor: pointer;
}

.sidebar nav a {
  text-decoration: none;
  color: inherit;
  font-size: inherit;
  font-weight: inherit;
  display: block;
}

.sidebar nav a:visited {
  color: inherit;
}

/* ================= 본문 ================= */
.content {
  flex: 1;
  padding: 40px 48px;
  min-width: 0;
}

.top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 28px;
}

.top h2 {
  font-size: 24px;
  font-weight: 800;
  margin: 0 0 6px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.page-title-icon {
  color: var(--color-orange);
}

.top p {
  color: var(--color-text-muted);
  margin: 0;
}

.top span {
  background: var(--color-orange-soft);
  color: var(--color-orange-dark);
  padding: 8px 15px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
}

/* 카드 / 작성 박스 */
.writeBox,
.card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 24px;
  margin-top: 20px;
  box-shadow: var(--shadow-card);
}

.card h3 {
  margin-top: 0;
  font-size: 16px;
  font-weight: 700;
}

.noticeList {
  display: grid;
  gap: 14px;
  margin-top: 16px;
}

.meta {
  margin-top: 14px;
  font-size: 13px;
  color: var(--color-text-muted);
  line-height: 1.6;
}

/* 폼 */
input,
textarea {
  width: 100%;
  padding: 12px 14px;
  margin-bottom: 12px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  font-family: inherit;
  font-size: 14px;
}

input:focus,
textarea:focus {
  outline: none;
  border-color: var(--color-orange);
  box-shadow: 0 0 0 3px var(--color-orange-soft);
}

textarea {
  height: 110px;
  resize: vertical;
}

/* 버튼 */
button {
  font-family: inherit;
  font-size: 14px;
  font-weight: 600;
  border: 0;
  border-radius: 10px;
  padding: 12px 22px;
  cursor: pointer;
  transition: background 0.15s ease, opacity 0.15s ease;
}

.btn-primary,
.top > button,
form > button[type="submit"] {
  background: var(--color-orange);
  color: white;
}

.btn-primary:hover {
  background: var(--color-orange-dark);
}

.btn-secondary {
  background: var(--color-bg);
  color: var(--color-text);
  border: 1px solid var(--color-border);
}

.form-actions {
  display: flex;
  gap: 8px;
}

.deleteButton {
  margin-top: 15px;
  background: transparent;
  color: var(--color-danger);
  border: 1px solid #fda29b;
  cursor: pointer;
}

.deleteButton:hover {
  background: #fef3f2;
}

.notice-card {
  position: relative;
  padding-right: 70px;
}

.notice-delete-form {
  position: absolute;
  top: 16px;
  right: 16px;
  margin: 0;
}

.notice-delete-form .deleteButton {
  margin-top: 0;
  padding: 6px 10px;
  border-radius: 8px;
}

/* 업무지시 - 리치텍스트 에디터 */
.rte-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}

.rte-toolbar select,
.rte-toolbar button,
.rte-image-btn {
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 6px 10px;
  font-size: 13px;
  background: #fff;
  cursor: pointer;
  color: var(--color-text);
}

.rte-toolbar input[type="color"] {
  width: 34px;
  height: 32px;
  padding: 2px;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  cursor: pointer;
}

.rte-image-btn {
  display: inline-flex;
  align-items: center;
}

.rte-divider {
  width: 1px;
  height: 20px;
  background: var(--color-border);
  margin: 0 2px;
}

.rte-hint {
  font-size: 12px;
  color: var(--color-text-muted);
  margin: -4px 0 8px 0;
}

.rte-table-menu {
  position: relative;
}

.rte-table-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  z-index: 20;
  display: flex;
  flex-direction: column;
  min-width: 120px;
  background: #fff;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  box-shadow: var(--shadow-card);
  padding: 6px;
  gap: 2px;
}

.rte-table-dropdown button {
  border: none;
  background: none;
  text-align: left;
  padding: 8px 10px;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
}

.rte-table-dropdown button:hover {
  background: var(--color-bg);
}

/* 공용 작성 팝업 (DocForm) */
.doc-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 24px;
}

.doc-modal {
  background: #fff;
  border-radius: var(--radius-lg);
  width: 100%;
  max-width: 760px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.25);
}

.doc-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid var(--color-border);
  position: sticky;
  top: 0;
  background: #fff;
  z-index: 1;
}

.doc-modal-header h3 {
  margin: 0;
  font-size: 17px;
}

.doc-modal-close {
  background: none;
  border: none;
  font-size: 16px;
  cursor: pointer;
  color: var(--color-text-muted);
  padding: 4px 8px;
}

.doc-modal-close:hover {
  color: var(--color-text);
}

.doc-modal-form {
  padding: 20px 24px 24px;
}

.doc-modal-title {
  width: 100%;
  font-size: 16px;
  font-weight: 700;
  border: none;
  border-bottom: 1px solid var(--color-border);
  padding: 8px 0;
  margin-bottom: 14px;
  border-radius: 0;
}

.doc-modal-title:focus {
  outline: none;
  border-bottom-color: var(--color-orange);
}

.doc-modal-editor {
  min-height: 320px;
}

.doc-modal-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 14px;
  flex-wrap: wrap;
}

.doc-modal-file-label {
  font-size: 13px;
  color: var(--color-text-muted);
  display: flex;
  align-items: center;
  gap: 6px;
}

.doc-modal-file {
  border: none;
  padding: 0;
  font-size: 13px;
}

.doc-modal-author {
  max-width: 200px;
  margin-bottom: 0 !important;
}

.rte-editor {
  min-height: 160px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  padding: 12px 14px;
  margin-bottom: 12px;
  font-size: 14px;
  line-height: 1.6;
  white-space: pre-wrap;
  overflow-wrap: break-word;
}

.rte-editor:focus {
  outline: none;
  border-color: var(--color-orange);
  box-shadow: 0 0 0 3px var(--color-orange-soft);
}

.rte-editor img {
  max-width: 100%;
  border-radius: 6px;
  margin: 6px 0;
}

.rte-editor table,
.notice-content-preview table,
.notice-detail-content table {
  border-collapse: collapse;
  margin: 8px 0;
}

.rte-editor td,
.notice-content-preview td,
.notice-detail-content td {
  border: 1px solid #d1d5db;
  padding: 8px;
}

.notice-content-preview td,
.notice-detail-content td {
  resize: none !important;
  overflow: visible !important;
}

/* 업무지시 목록/상세 */
.notice-title-link {
  text-decoration: none;
  color: inherit;
}

.notice-title-link h3 {
  margin: 0 0 8px 0;
}

.notice-title-link:hover h3 {
  color: var(--color-orange-dark);
}

.notice-content-preview {
  font-size: 14px;
  line-height: 1.6;
  max-height: 120px;
  overflow: hidden;
  color: var(--color-text);
}

.notice-content-preview img {
  max-width: 100%;
  border-radius: 6px;
}

.notice-detail-content {
  margin-top: 20px;
  font-size: 15px;
  line-height: 1.7;
}

.notice-detail-content img {
  max-width: 100%;
  border-radius: 8px;
  margin: 10px 0;
}

.attached-image {
  max-width: 100%;
  border-radius: 8px;
  margin-top: 16px;
  border: 1px solid var(--color-border);
}

.attachment-block {
  margin-top: 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.attachment-frame {
  width: 100%;
  height: 600px;
  border: 1px solid var(--color-border);
  border-radius: 8px;
}

.attachment-inline {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 16px;
}

.attachment-name {
  font-size: 14px;
  color: var(--color-text);
}

.attachment-preview-btn {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-navy);
  cursor: pointer;
}

.attachment-preview-btn:hover {
  border-color: var(--color-orange);
  color: var(--color-orange-dark);
}

.attachment-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  font-size: 13px;
  cursor: pointer;
  text-decoration: none;
  color: var(--color-navy);
}

.attachment-icon-btn:hover {
  border-color: var(--color-orange);
  background: var(--color-orange-soft);
}

.attachment-modal {
  max-width: 900px;
}

.attachment-modal-body {
  padding: 20px 24px 24px;
}

.dashboard-list-title {
  text-decoration: none;
  color: var(--color-text);
}

.dashboard-list-title:hover {
  color: var(--color-orange-dark);
  text-decoration: underline;
}

/* AIRPORT - 국내/해외 2분할 */
.airport-columns {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 40px;
  max-width: 720px;
}

.airport-column-title {
  font-size: 15px;
  font-weight: 800;
  color: var(--color-navy);
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 2px solid var(--color-orange);
}

/* 메인 - 식단 게시판 */
.meal-card {
  margin-top: 16px;
  max-width: 640px;
}

.meal-images {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.meal-slot {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.meal-image {
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
  border-radius: 10px;
  border: 1px solid var(--color-border);
}

.meal-empty {
  width: 100%;
  aspect-ratio: 4 / 3;
  border: 1px dashed var(--color-border);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 12px;
  font-size: 12px;
  color: var(--color-text-muted);
  background: var(--color-bg);
}

.meal-slot-actions {
  display: flex;
  gap: 6px;
}

.meal-edit-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  padding: 12px;
}

.meal-edit-form input[type="file"] {
  font-size: 12px;
}

/* 메인 헤더 - 전체 검색 */
.header-search {
  display: flex;
  align-items: center;
  background: #fff;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  overflow: hidden;
  height: 38px;
  flex-shrink: 0;
}

.header-search-category {
  border: none;
  border-right: 1px solid var(--color-border);
  background: var(--color-bg);
  height: 100%;
  padding: 0 10px;
  font-size: 12px;
  font-weight: 600;
  color: var(--color-navy);
  max-width: 130px;
  cursor: pointer;
}

.header-search-category:focus {
  outline: none;
}

.header-search input {
  border: none;
  padding: 0 12px;
  font-size: 13px;
  width: 220px;
  height: 100%;
  margin: 0;
  border-radius: 0;
}

.header-search input:focus {
  outline: none;
  box-shadow: none;
}

.header-search button[type="submit"] {
  border: none;
  background: var(--color-navy);
  color: #fff;
  height: 100%;
  width: 44px;
  padding: 0;
  margin: 0;
  border-radius: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
}

.header-search button[type="submit"]:hover {
  background: var(--color-navy-light);
}

/* 헤더 오른쪽 영역(검색+작성버튼) 정렬 */
.top-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

/* 검색 드롭다운 */
.header-search-wrap {
  position: relative;
  flex-shrink: 0;
}

.search-dropdown {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  width: 340px;
  max-height: 360px;
  overflow-y: auto;
  background: #fff;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.12);
  z-index: 50;
  padding: 6px;
}

.search-dropdown-item {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  width: 100%;
  text-align: left;
  background: none;
  border: none;
  border-radius: 8px;
  padding: 8px 10px;
  cursor: pointer;
  gap: 2px;
}

.search-dropdown-item:hover {
  background: var(--color-bg);
}

.search-dropdown-type {
  font-size: 11px;
  font-weight: 700;
  color: var(--color-orange-dark);
}

.search-dropdown-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text);
}

.search-dropdown-author {
  font-size: 11px;
  color: var(--color-text-muted);
}

.search-dropdown-empty {
  padding: 14px 10px;
  font-size: 13px;
  color: var(--color-text-muted);
  text-align: center;
}

.search-dropdown-more {
  width: 100%;
  text-align: center;
  background: var(--color-bg);
  border: none;
  border-radius: 8px;
  padding: 9px;
  font-size: 12px;
  font-weight: 600;
  color: var(--color-navy);
  cursor: pointer;
  margin-top: 4px;
}

.search-dropdown-more:hover {
  color: var(--color-orange-dark);
}
SEARCHCATEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."