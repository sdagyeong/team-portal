export const dynamic = "force-dynamic";
export const revalidate = 0;

import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { supabase as supabaseData } from "@/lib/supabaseClient";

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
  const gridCount = documents?.filter((d) => d.doc_type === "주기장요도").length ?? 0;
  const manualCount = documents?.filter((d) => d.doc_type === "매뉴얼").length ?? 0;

  return (
    <>
      <header className="top">
        <div>
          <h2>🛫 Ramp Control Team 포털</h2>
          <p>오늘의 업무지시와 자료 현황을 한눈에 확인하세요</p>
        </div>
      </header>

      <div className="dashboard-grid">
        {/* 최근 업무지시공유 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>📌 최근 업무지시공유</h3>
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
                <span className="dashboard-list-title">{notice.title}</span>
                <span className="dashboard-list-meta">{notice.author}</span>
              </li>
            ))}
          </ul>
        </section>

        {/* 자료 현황 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>📁 자료 현황</h3>
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
              <span className="dashboard-stat-num">{gridCount}</span>
              <span className="dashboard-stat-label">주기장요도</span>
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
