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
