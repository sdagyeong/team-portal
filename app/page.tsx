export const dynamic = "force-dynamic";
export const revalidate = 0;

import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { supabase as supabaseData } from "@/lib/supabaseClient";
import { getAllAirportMetar, getAllAirportTaf, getAllWarnings } from "@/lib/kmaWeather";
import { IconPlane, IconPin, IconCloud } from "@/components/icons";
import MealBoard from "./MealBoard";
import SearchBox from "@/components/SearchBox";
import WeatherPanel from "@/components/WeatherPanel";

export default async function DashboardPage() {
  const [{ data: notices }, { data: mealInfo }, metarList, tafList, warnings] =
    await Promise.all([
      supabase
        .from("notices")
        .select("*")
        .order("id", { ascending: false })
        .limit(3),
      supabaseData.from("meal_board").select("*").eq("id", 1).maybeSingle(),
      getAllAirportMetar(),
      getAllAirportTaf(),
      getAllWarnings(),
    ]);

  return (
    <>
      <header className="top">
        <div>
          <h2>
            <IconPlane size={20} className="page-title-icon" /> Ramp Control Team 포털
          </h2>
          <p>오늘의 업무지시와 자료 현황을 한눈에 확인하세요</p>
        </div>

        <SearchBox />
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
      </div>

      {/* 공항별 날씨 (METAR / TAF / 경보) */}
      <section className="dashboard-card weather-card">
        <div className="dashboard-card-header">
          <h3>
            <IconCloud size={15} className="page-title-icon" /> 공항별 날씨
          </h3>
        </div>
        <WeatherPanel metarList={metarList} tafList={tafList} warnings={warnings} />
      </section>

      <MealBoard info={mealInfo ?? null} />
    </>
  );
}
