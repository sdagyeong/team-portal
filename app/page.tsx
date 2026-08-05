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
