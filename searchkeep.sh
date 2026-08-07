#!/bin/bash
set -e

cat > app/search/page.tsx << 'SEARCHKEEPEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { supabase as supabaseData } from "@/lib/supabaseClient";
import { formatKDate } from "@/lib/formatDate";
import { IconFilePreview, IconPin, IconFolder } from "@/components/icons";
import SearchBox from "@/components/SearchBox";

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
      <header className="top">
        <div>
          <h1>
            <IconFilePreview size={20} className="page-title-icon" /> 검색 결과
          </h1>
          <p className="page-desc">
            {query
              ? `${field !== "전체" ? `[${field}] ` : ""}"${query}" 검색 결과 ${totalCount}건`
              : "검색어를 입력해주세요."}
          </p>
        </div>
        <SearchBox />
      </header>

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
SEARCHKEEPEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."