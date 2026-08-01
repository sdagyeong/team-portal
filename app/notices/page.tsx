export const dynamic = "force-dynamic";
export const revalidate = 0;
import { supabase } from "@/lib/supabase";
import { formatKDate } from "@/lib/formatDate";
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
          <h2>📌 업무지시공유</h2>
          <p>팀 업무지시 및 공유사항을 확인하세요</p>
        </div>
        <NoticeForm addNotice={addNotice} />
      </header>

      <section>
        <div className="noticeList">
          {notices?.map((notice) => (
            <article key={notice.id} className="card notice-card">
              <form
                action={deleteNotice.bind(null, notice.id)}
                className="notice-delete-form"
              >
                <button type="submit" className="deleteButton" aria-label="삭제">
                  🗑
                </button>
              </form>

              <h3>{notice.title}</h3>
              <p>{notice.content}</p>
              <div className="meta">
                작성자 : {notice.author}
                <br />
                작성일 : {formatKDate(notice.created_at)}
              </div>
            </article>
          ))}
        </div>
      </section>
    </>
  );
}
