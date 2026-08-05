#!/bin/bash
set -e

mkdir -p "app"
mkdir -p "app/contacts"
mkdir -p "app/contacts/doc/[id]"
mkdir -p "app/resources"
mkdir -p "app/search"
mkdir -p "components"

cat > "components/icons.tsx" << 'EXTRASEOF'
type IconProps = {
  size?: number;
  className?: string;
};

const base = {
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.7,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
};

export function IconFilePreview({ size = 18, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <circle cx="11" cy="11" r="7" />
      <line x1="16.2" y1="16.2" x2="21" y2="21" />
    </svg>
  );
}

export function IconDownload({ size = 18, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M12 3v12" />
      <path d="M7.5 10.5 12 15l4.5-4.5" />
      <path d="M5 19h14" />
    </svg>
  );
}

export function IconTrash({ size = 15, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M3.5 6h17" />
      <path d="M8.5 6V4.5a1 1 0 0 1 1-1h5a1 1 0 0 1 1 1V6" />
      <path d="M18.5 6 17.7 20a1 1 0 0 1-1 1H7.3a1 1 0 0 1-1-1L5.5 6" />
      <path d="M10.2 10.5v6.5" />
      <path d="M13.8 10.5v6.5" />
    </svg>
  );
}

export function IconClose({ size = 16, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M5 5l14 14" />
      <path d="M19 5 5 19" />
    </svg>
  );
}

export function IconChevronLeft({ size = 15, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M15 5 8 12l7 7" />
    </svg>
  );
}

export function IconPlus({ size = 15, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M12 5v14" />
      <path d="M5 12h14" />
    </svg>
  );
}

export function IconPin({ size = 17, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M12 2.5a5 5 0 0 0-5 5c0 3.5 5 9.5 5 9.5s5-6 5-9.5a5 5 0 0 0-5-5Z" />
      <circle cx="12" cy="7.5" r="1.8" />
    </svg>
  );
}

export function IconFolder({ size = 17, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M3.5 6.5a1 1 0 0 1 1-1H10l2 2h7.5a1 1 0 0 1 1 1V18a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1V6.5Z" />
    </svg>
  );
}

export function IconPlane({ size = 17, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="m3 13 7-2 6-8 2 1-3.5 8L21 10l1 2-6.5 3.5.5 5-2 1-2.5-4.5L6 19l-1-2 3-3.5L3 13Z" />
    </svg>
  );
}

export function IconFileText({ size = 16, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M7 3h6l4 4v13a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1Z" />
      <path d="M13 3v4h4" />
      <path d="M9 13h6" />
      <path d="M9 16.5h6" />
    </svg>
  );
}

export function IconMap({ size = 16, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M9 4 4 6v14l5-2 6 2 5-2V4l-5 2-6-2Z" />
      <path d="M9 4v14" />
      <path d="M15 6v14" />
    </svg>
  );
}

export function IconBookOpen({ size = 16, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <path d="M12 6.5c-1.5-1.3-3.5-2-6-2v13c2.5 0 4.5.7 6 2 1.5-1.3 3.5-2 6-2v-13c-2.5 0-4.5.7-6 2Z" />
      <path d="M12 6.5v13" />
    </svg>
  );
}

export function IconImage({ size = 16, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <rect x="3.5" y="4.5" width="17" height="15" rx="1.5" />
      <circle cx="9" cy="10" r="1.7" />
      <path d="m4.5 17.5 5-5 4 4 3-3 4 4" />
    </svg>
  );
}

export function IconContact({ size = 17, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} {...base}>
      <rect x="3" y="4.5" width="18" height="15" rx="2" />
      <circle cx="9" cy="10.5" r="2.1" />
      <path d="M5.8 16.5c.5-1.9 1.9-2.8 3.2-2.8s2.7.9 3.2 2.8" />
      <path d="M14.5 9h4" />
      <path d="M14.5 12.3h4" />
    </svg>
  );
}
EXTRASEOF

cat > "components/Sidebar.tsx" << 'EXTRASEOF'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { IconPin, IconFolder, IconPlane, IconContact } from "./icons";

const menuItems = [
  { href: "/notices", label: "업무지시공유", Icon: IconPin },
  { href: "/resources", label: "자료실", Icon: IconFolder },
  { href: "/tasks", label: "AIRPORT", Icon: IconPlane },
  { href: "/contacts", label: "계정/연락망", Icon: IconContact },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="sidebar">
      <Link href="/" className="brand-link">
        <div className="brand">
          <span className="brand-line1">JEJUAIR</span>
          <span className="brand-line2">RAMP CONTROL TEAM</span>
        </div>
      </Link>

      <nav>
        {menuItems.map((item) => (
          <Link key={item.href} href={item.href}>
            <div className={`menu ${pathname === item.href ? "active" : ""}`}>
              <span className="menu-icon">
                <item.Icon size={16} />
              </span>
              {item.label}
            </div>
          </Link>
        ))}
      </nav>
    </aside>
  );
}
EXTRASEOF

cat > "app/contacts/documentActions.ts" << 'EXTRASEOF'
'use server'

import { supabase } from '@/lib/supabaseClient'
import { revalidatePath } from 'next/cache'

export async function addDocument(formData: FormData) {
  const doc_type = formData.get('doc_type') as string
  const region = formData.get('region') as string
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const author = formData.get('author') as string
  const file = formData.get('file') as File | null

  let file_url: string | null = null
  let file_name: string | null = null

  if (file && file.size > 0) {
    const filePath = `${Date.now()}_${file.name}`

    const { error: uploadError } = await supabase.storage
      .from('task-documents')
      .upload(filePath, file)

    if (uploadError) {
      console.error(uploadError)
      throw new Error('파일 업로드에 실패했습니다.')
    }

    const { data: publicUrlData } = supabase.storage
      .from('task-documents')
      .getPublicUrl(filePath)

    file_url = publicUrlData.publicUrl
    file_name = file.name
  }

  const { error } = await supabase.from('task_documents').insert({
    doc_type,
    region,
    title,
    description,
    author,
    file_url,
    file_name,
  })

  if (error) {
    console.error(error)
    throw new Error('등록에 실패했습니다.')
  }

  revalidatePath('/contacts')
}

export async function deleteDocument(id: number) {
  const { error } = await supabase.from('task_documents').delete().eq('id', id)

  if (error) {
    console.error(error)
    throw new Error('삭제에 실패했습니다.')
  }

  revalidatePath('/contacts')
}
EXTRASEOF

cat > "app/contacts/DocumentForm.tsx" << 'EXTRASEOF'
"use client";

import DocForm from "@/components/DocForm";
import { addDocument } from "./documentActions";

export default function DocumentForm() {
  return (
    <DocForm
      heading="✏️ 계정/연락망 작성"
      triggerLabel="+ 작성"
      contentFieldName="description"
      extraFields={{ doc_type: "계정연락망", region: "전체" }}
      addAction={addDocument}
      fileAccept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png"
    />
  );
}
EXTRASEOF

cat > "app/contacts/page.tsx" << 'EXTRASEOF'
import Link from 'next/link'
import { supabase } from '@/lib/supabaseClient'
import DocumentForm from './DocumentForm'
import { deleteDocument } from './documentActions'
import { IconContact, IconTrash } from '@/components/icons'

export const dynamic = 'force-dynamic'

export default async function ContactsPage() {
  const { data: documents, error } = await supabase
    .from('task_documents')
    .select('*')
    .eq('doc_type', '계정연락망')
    .order('created_at', { ascending: false })

  if (error) {
    console.error(error)
  }

  return (
    <div className="page">
      <h1>
        <IconContact size={20} className="page-title-icon" /> 계정/연락망
      </h1>

      <DocumentForm />

      <div className="doc-list">
        {(!documents || documents.length === 0) && (
          <p className="empty">등록된 자료가 없습니다.</p>
        )}
        {documents?.map((doc) => (
          <div key={doc.id} className="doc-row">
            <Link href={`/contacts/doc/${doc.id}`} className="doc-row-title">
              {doc.file_url && '📎 '}
              {doc.title}
            </Link>
            <span className="doc-row-author">{doc.author}</span>
            <span className="doc-row-date">
              {new Date(doc.created_at).toLocaleDateString('ko-KR')}
            </span>
            <form
              action={async () => {
                'use server'
                await deleteDocument(doc.id)
              }}
            >
              <button type="submit" className="doc-row-delete" aria-label="삭제">
                <IconTrash />
              </button>
            </form>
          </div>
        ))}
      </div>
    </div>
  )
}
EXTRASEOF

cat > "app/contacts/doc/[id]/page.tsx" << 'EXTRASEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;
import Link from "next/link";
import { supabase } from "@/lib/supabaseClient";
import { formatKDate } from "@/lib/formatDate";
import AttachmentPreview from "@/components/AttachmentPreview";
import { IconChevronLeft } from "@/components/icons";

export default async function ContactDocDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const { data: doc, error } = await supabase
    .from("task_documents")
    .select("*")
    .eq("id", id)
    .single();

  if (error) {
    console.error(error);
  }

  if (!doc) {
    return (
      <div className="page">
        <Link href="/contacts" className="breadcrumb-back">
          <IconChevronLeft size={13} /> 뒤로
        </Link>
        <p className="empty">글을 찾을 수 없습니다.</p>
      </div>
    );
  }

  return (
    <div className="page">
      <Link href="/contacts" className="breadcrumb-back">
        <IconChevronLeft size={13} /> 뒤로
      </Link>

      <h1>{doc.title}</h1>
      <p className="meta">
        작성자 : {doc.author} &nbsp;·&nbsp; 작성일 : {formatKDate(doc.created_at)}
      </p>

      <div
        className="notice-detail-content"
        dangerouslySetInnerHTML={{ __html: doc.description ?? "" }}
      />

      {doc.file_url && (
        <AttachmentPreview fileUrl={doc.file_url} fileName={doc.file_name} />
      )}
    </div>
  );
}
EXTRASEOF

cat > "app/resources/ResourceBoard.tsx" << 'EXTRASEOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { deleteDocument } from './documentActions'
import DocumentForm from './DocumentForm'
import { IconTrash, IconChevronLeft } from '@/components/icons'

type Doc = {
  id: number
  doc_type: string
  region: string
  title: string
  description: string | null
  author: string
  file_url: string | null
  file_name: string | null
  created_at: string
}

const SUBFOLDERS = ['DLA CODE', '자격변경', '제방빙']

type Step = { level: 'root' } | { level: 'content'; region: string }

function DocList({ docs }: { docs: Doc[] }) {
  return (
    <div className="doc-list">
      {docs.length === 0 && <p className="empty">등록된 자료가 없습니다.</p>}
      {docs.map((doc) => (
        <div key={doc.id} className="doc-row">
          <Link href={`/resources/doc/${doc.id}`} className="doc-row-title">
            {doc.file_url && '📎 '}
            {doc.title}
          </Link>
          <span className="doc-row-author">{doc.author}</span>
          <span className="doc-row-date">
            {new Date(doc.created_at).toLocaleDateString('ko-KR')}
          </span>
          <form
            action={async () => {
              await deleteDocument(doc.id)
            }}
          >
            <button type="submit" className="doc-row-delete" aria-label="삭제">
              <IconTrash />
            </button>
          </form>
        </div>
      ))}
    </div>
  )
}

export default function ResourceBoard({ documents }: { documents: Doc[] }) {
  const [step, setStep] = useState<Step>({ level: 'root' })

  function go(next: Step) {
    setStep(next)
  }

  // 1단계: DLA CODE / 자격변경 / 제방빙 (매뉴얼 단계 생략)
  if (step.level === 'root') {
    return (
      <div className="task-board">
        <div className="folder-menu">
          {SUBFOLDERS.map((region) => (
            <button
              key={region}
              type="button"
              className="folder-item"
              onClick={() => go({ level: 'content', region })}
            >
              {region}
            </button>
          ))}
        </div>
      </div>
    )
  }

  // 2단계: 컨텐츠 (작성/목록)
  const filteredDocs = documents.filter(
    (d) => d.doc_type === '매뉴얼' && d.region === step.region
  )

  return (
    <div className="task-board">
      <button type="button" className="breadcrumb-back" onClick={() => go({ level: 'root' })}>
        <IconChevronLeft size={13} /> 뒤로
      </button>

      <h2 className="folder-title">{step.region}</h2>

      <DocumentForm docType="매뉴얼" region={step.region} />

      <DocList docs={filteredDocs} />
    </div>
  )
}
EXTRASEOF

cat > "app/page.tsx" << 'EXTRASEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;

import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { supabase as supabaseData } from "@/lib/supabaseClient";
import { IconPlane, IconPin, IconFolder, IconFilePreview } from "@/components/icons";

export default async function DashboardPage() {
  const [{ data: notices }, { data: documents }] = await Promise.all([
    supabase
      .from("notices")
      .select("*")
      .order("id", { ascending: false })
      .limit(3),
    supabaseData.from("task_documents").select("doc_type"),
  ]);

  const reportCount = documents?.filter((d) => d.doc_type === "보고서").length ?? 0;
  const contactCount = documents?.filter((d) => d.doc_type === "계정연락망").length ?? 0;
  const manualCount = documents?.filter((d) => d.doc_type === "매뉴얼").length ?? 0;

  return (
    <>
      <header className="top">
        <div>
          <h2>
            <IconPlane size={20} className="page-title-icon" /> Ramp Control Team 포털
          </h2>
          <p>오늘의 업무지시와 자료 현황을 한눈에 확인하세요</p>
        </div>

        <form action="/search" method="GET" className="header-search">
          <input type="text" name="q" placeholder="전체 검색..." />
          <button type="submit" aria-label="검색">
            <IconFilePreview size={16} />
          </button>
        </form>
      </header>

      <div className="dashboard-grid">
        {/* 최근 업무지시공유 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>
              <IconPin size={15} className="page-title-icon" /> 최근 업무지시공유
            </h3>
            <Link href="/notices" className="dashboard-more">
              전체보기
            </Link>
          </div>
          {(!notices || notices.length === 0) && (
            <p className="empty">등록된 글이 없습니다.</p>
          )}
          <ul className="dashboard-list">
            {notices?.map((notice) => (
              <li key={notice.id}>
                <Link href={`/notices/${notice.id}`} className="dashboard-list-title">
                  {notice.title}
                </Link>
                <span className="dashboard-list-meta">{notice.author}</span>
              </li>
            ))}
          </ul>
        </section>

        {/* 자료 현황 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>
              <IconFolder size={15} className="page-title-icon" /> 자료 현황
            </h3>
            <Link href="/resources" className="dashboard-more">
              전체보기
            </Link>
          </div>
          <div className="dashboard-stats">
            <div className="dashboard-stat">
              <span className="dashboard-stat-num">{reportCount}</span>
              <span className="dashboard-stat-label">보고서</span>
            </div>
            <div className="dashboard-stat">
              <span className="dashboard-stat-num">{contactCount}</span>
              <span className="dashboard-stat-label">계정/연락망</span>
            </div>
            <div className="dashboard-stat">
              <span className="dashboard-stat-num">{manualCount}</span>
              <span className="dashboard-stat-label">매뉴얼</span>
            </div>
          </div>
        </section>
      </div>
    </>
  );
}
EXTRASEOF

cat > "app/search/page.tsx" << 'EXTRASEOF'
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
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const query = (q ?? "").trim();

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
        .or(`title.ilike.%${query}%,content.ilike.%${query}%`)
        .order("id", { ascending: false }),
      supabaseData
        .from("task_documents")
        .select("id, doc_type, title, author, created_at")
        .or(`title.ilike.%${query}%,description.ilike.%${query}%`)
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
        {query ? `"${query}" 검색 결과 ${totalCount}건` : "검색어를 입력해주세요."}
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
EXTRASEOF

cat > "app/globals.css" << 'EXTRASEOF'
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
  padding: 0;
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

/* AIRPORT - 공항 정보 카드 */
.airport-info-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
  margin-bottom: 20px;
  overflow: hidden;
  max-width: 640px;
}

.airport-info-row {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 20px;
  border-bottom: 1px solid var(--color-border);
}

.airport-info-row:last-child {
  border-bottom: none;
}

.airport-info-label {
  width: 90px;
  flex-shrink: 0;
  font-weight: 700;
  font-size: 13px;
  color: var(--color-navy);
}

.airport-info-value {
  flex: 1;
  font-size: 13px;
  color: var(--color-text);
}

.airport-info-image {
  max-height: 120px;
  border-radius: 6px;
  border: 1px solid var(--color-border);
}

.airport-info-edit-btn {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 5px 12px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  color: var(--color-navy);
  flex-shrink: 0;
}

.airport-info-edit-btn:hover {
  border-color: var(--color-orange);
  color: var(--color-orange-dark);
}

.airport-info-clear-btn {
  background: var(--color-bg);
  border: 1px solid #fda29b;
  border-radius: 8px;
  padding: 5px 12px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  color: var(--color-danger);
  flex-shrink: 0;
}

.airport-info-clear-btn:hover {
  background: #fef3f2;
}

.airport-info-clear-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.airport-info-edit-form {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 8px;
}

.airport-info-edit-form input[type="text"] {
  flex: 1;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 6px 10px;
  font-size: 13px;
}

.airport-info-edit-actions {
  display: flex;
  gap: 6px;
  flex-shrink: 0;
}

.airport-info-edit-actions button {
  font-size: 12px;
  padding: 6px 10px;
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

/* 메인 헤더 - 전체 검색 */
.header-search {
  display: flex;
  align-items: center;
  gap: 0;
  background: #fff;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  overflow: hidden;
  height: 38px;
}

.header-search input {
  border: none;
  padding: 0 12px;
  font-size: 13px;
  width: 220px;
  height: 100%;
  margin: 0;
}

.header-search input:focus {
  outline: none;
  box-shadow: none;
}

.header-search button {
  border: none;
  background: var(--color-navy);
  color: #fff;
  height: 100%;
  padding: 0 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.header-search button:hover {
  background: var(--color-navy-light);
}

.search-section-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 700;
  color: var(--color-navy);
  margin-bottom: 10px;
}
EXTRASEOF

echo "적용 완료. npm run dev 재시작 후 확인하세요."