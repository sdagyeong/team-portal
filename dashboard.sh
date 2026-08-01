#!/bin/bash
# 프로젝트 루트에서 실행하세요: bash dashboard.sh
set -e

mkdir -p app app/notices

cat > app/notices/actions.ts << 'DASHEOF'
"use server";

import { revalidatePath } from "next/cache";
import { supabase } from "@/lib/supabase";

export async function addNotice(formData: FormData) {
  const { error } = await supabase.from("notices").insert({
    title: formData.get("title"),
    content: formData.get("content"),
    author: formData.get("author"),
  });

  if (error) {
    console.error("저장 오류:", error);
  }

  revalidatePath("/notices");
  revalidatePath("/");
}

export async function deleteNotice(id: number) {
  const { error } = await supabase
    .from("notices")
    .delete()
    .eq("id", id);

  if (error) {
    console.error("삭제 오류:", error);
  }

  revalidatePath("/notices");
  revalidatePath("/");
}
DASHEOF

cat > app/notices/page.tsx << 'DASHEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;
import { supabase } from "@/lib/supabase";
import NoticeForm from "@/components/NoticeForm";
import { addNotice, deleteNotice } from "./actions";

export default async function NoticesPage() {
  const { data: notices, error } = await supabase
    .from("notices")
    .select("*")
    .order("id", { ascending: false });

  if (error) {
    console.error("불러오기 오류:", error);
  }

  return (
    <>
      <header className="top">
        <div>
          <h2>📢 공지사항</h2>
          <p>팀 주요 안내사항을 확인하세요</p>
        </div>
        <NoticeForm addNotice={addNotice} />
      </header>

      <section>
        <h3>📌 최근 공지</h3>
        <div className="noticeList">
          {notices?.map((notice) => (
            <article key={notice.id} className="card">
              <h3>📌 {notice.title}</h3>
              <p>{notice.content}</p>
              <div className="meta">
                작성자 : {notice.author}
                <br />
                작성일 :{" "}
                {new Date(notice.created_at).toLocaleDateString("ko-KR")}
              </div>
              <form action={deleteNotice.bind(null, notice.id)}>
                <button type="submit" className="deleteButton">
                  🗑 삭제
                </button>
              </form>
            </article>
          ))}
        </div>
      </section>
    </>
  );
}
DASHEOF

cat > app/page.tsx << 'DASHEOF'
export const dynamic = "force-dynamic";
export const revalidate = 0;

import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { supabase as supabaseData } from "@/lib/supabaseClient";

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

export default async function DashboardPage() {
  const [{ data: notices }, { data: schedules }, { data: tasks }] = await Promise.all([
    supabase
      .from("notices")
      .select("*")
      .order("id", { ascending: false })
      .limit(3),
    supabaseData
      .from("schedules")
      .select("*")
      .gte("end_date", todayKey())
      .order("start_date", { ascending: true })
      .limit(5),
    supabaseData.from("tasks").select("status"),
  ]);

  const doneCount = tasks?.filter((t) => t.status === "완료").length ?? 0;
  const progressCount = tasks?.filter((t) => t.status === "진행중").length ?? 0;

  return (
    <>
      <header className="top">
        <div>
          <h2>🛫 Ramp Control Team 포털</h2>
          <p>오늘의 공지, 일정, 업무 현황을 한눈에 확인하세요</p>
        </div>
      </header>

      <div className="dashboard-grid">
        {/* 최근 공지 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>📢 최근 공지</h3>
            <Link href="/notices" className="dashboard-more">
              전체보기
            </Link>
          </div>
          {(!notices || notices.length === 0) && (
            <p className="empty">등록된 공지가 없습니다.</p>
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

        {/* 다가오는 일정 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>📅 다가오는 일정</h3>
            <Link href="/calendar" className="dashboard-more">
              전체보기
            </Link>
          </div>
          {(!schedules || schedules.length === 0) && (
            <p className="empty">예정된 일정이 없습니다.</p>
          )}
          <ul className="dashboard-list">
            {schedules?.map((s) => (
              <li key={s.id}>
                <span className="dashboard-list-title">{s.title}</span>
                <span className="dashboard-list-meta">{s.start_date}</span>
              </li>
            ))}
          </ul>
        </section>

        {/* 업무 현황 */}
        <section className="dashboard-card">
          <div className="dashboard-card-header">
            <h3>✅ 업무 현황</h3>
            <Link href="/tasks" className="dashboard-more">
              전체보기
            </Link>
          </div>
          <div className="dashboard-stats">
            <div className="dashboard-stat">
              <span className="dashboard-stat-num">{progressCount}</span>
              <span className="dashboard-stat-label">진행중</span>
            </div>
            <div className="dashboard-stat">
              <span className="dashboard-stat-num">{doneCount}</span>
              <span className="dashboard-stat-label">완료</span>
            </div>
          </div>
        </section>
      </div>
    </>
  );
}
DASHEOF

cat > app/portal-styles.css << 'DASHEOF'
/* 자료실 / 일정관리 / 업무관리 공통 스타일
   globals.css 의 :root 변수(--color-orange 등)를 그대로 사용합니다 */

.page {
  padding: 0;
}

.page h1 {
  font-size: 24px;
  font-weight: 800;
  margin-bottom: 6px;
}

.page-desc {
  color: var(--color-text-muted);
  margin-bottom: 28px;
}

/* 등록 폼 */
.resource-form,
.schedule-form,
.task-form {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-width: 480px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 20px;
  margin-bottom: 28px;
  box-shadow: var(--shadow-card);
}

.resource-form input,
.resource-form textarea,
.schedule-form input,
.schedule-form textarea,
.task-form input,
.task-form textarea,
.task-form select {
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 10px 12px;
  font-size: 14px;
  font-family: inherit;
  background: #fff;
}

.date-row {
  display: flex;
  gap: 12px;
}

.date-row label {
  display: flex;
  flex-direction: column;
  font-size: 12px;
  color: var(--color-text-muted);
  gap: 4px;
  flex: 1;
}

.resource-form button,
.schedule-form button,
.task-form button {
  background: var(--color-orange);
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 10px 16px;
  font-weight: 600;
  cursor: pointer;
  align-self: flex-start;
}

.resource-form button:hover,
.schedule-form button:hover,
.task-form button:hover {
  background: var(--color-orange-dark);
}

.resource-form button:disabled,
.schedule-form button:disabled,
.task-form button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* 카드 목록 */
.card-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.card .meta {
  font-size: 13px;
  color: var(--color-text-muted);
}

.file-link {
  display: inline-block;
  margin-top: 8px;
  color: var(--color-navy);
  font-weight: 600;
  text-decoration: underline;
}

.file-link:hover {
  color: var(--color-orange);
}

.empty {
  color: #9ca3af;
  padding: 20px 0;
}

.btn-delete {
  margin-top: 12px;
  background: transparent;
  color: var(--color-danger);
  border: 1px solid #fda29b;
  border-radius: 8px;
  padding: 8px 16px;
  font-weight: 600;
  cursor: pointer;
}

.btn-delete:hover {
  background: #fef3f2;
}

/* 캘린더 그리드 */
.calendar {
  max-width: 640px;
}

.calendar-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 12px;
}

.calendar-header h3 {
  font-size: 16px;
  font-weight: 700;
}

.calendar-header button {
  background: none;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  width: 32px;
  height: 32px;
  cursor: pointer;
  padding: 0;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
  margin-bottom: 24px;
}

.calendar-weekday {
  text-align: center;
  font-size: 12px;
  color: #9ca3af;
  padding: 6px 0;
}

.calendar-cell {
  position: relative;
  aspect-ratio: 1;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
}

.calendar-cell.empty {
  border: none;
  cursor: default;
}

.calendar-cell.today {
  border-color: var(--color-orange);
  font-weight: 700;
}

.calendar-cell.selected {
  background: var(--color-navy);
  color: #fff;
  border-color: var(--color-navy);
}

.calendar-cell .dot {
  position: absolute;
  bottom: 4px;
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--color-orange);
}

.calendar-cell.selected .dot {
  background: #fff;
}

.schedule-list h4 {
  margin-bottom: 12px;
  font-size: 15px;
}

/* 업무관리 */
.task-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.badge {
  font-size: 12px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 999px;
  white-space: nowrap;
}

.badge.progress {
  background: #fef3c7;
  color: #92400e;
}

.badge.done {
  background: #dcfce7;
  color: #166534;
}

.task-actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

.btn-toggle {
  background: var(--color-navy);
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-weight: 600;
  cursor: pointer;
}

.btn-toggle:hover {
  background: var(--color-navy-light);
}

.task-category {
  margin-top: 32px;
}

.task-category-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  font-weight: 700;
  color: var(--color-navy);
  padding-bottom: 8px;
  margin-bottom: 14px;
  border-bottom: 1px solid var(--color-border);
}

.task-category-count {
  background: var(--color-orange-soft);
  color: var(--color-orange-dark);
  font-size: 12px;
  font-weight: 700;
  padding: 2px 9px;
  border-radius: 999px;
}

/* 메인 대시보드 */
.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 16px;
  margin-top: 8px;
}

.dashboard-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 22px;
  box-shadow: var(--shadow-card);
}

.dashboard-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.dashboard-card-header h3 {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
}

.dashboard-more {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-orange-dark);
  text-decoration: none;
}

.dashboard-more:hover {
  text-decoration: underline;
}

.dashboard-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.dashboard-list li {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 13px;
  padding-bottom: 10px;
  border-bottom: 1px solid var(--color-border);
}

.dashboard-list li:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.dashboard-list-title {
  font-weight: 600;
  color: var(--color-text);
}

.dashboard-list-meta {
  color: var(--color-text-muted);
  white-space: nowrap;
}

.dashboard-stats {
  display: flex;
  gap: 24px;
}

.dashboard-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.dashboard-stat-num {
  font-size: 28px;
  font-weight: 800;
  color: var(--color-navy);
}

.dashboard-stat-label {
  font-size: 12px;
  color: var(--color-text-muted);
}
DASHEOF

# 이제 안 쓰는 옛 공지 액션 파일 정리 (공지 로직은 app/notices/actions.ts 로 이동됨)
rm -f app/actions.ts

echo "✅ 메인 대시보드 적용 완료. npm run dev 재시작 후 확인하세요."