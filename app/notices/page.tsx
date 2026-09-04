import { isNew } from '@/lib/isNew'
export const dynamic = "force-dynamic";
export const revalidate = 0;
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { formatKDate } from "@/lib/formatDate";
import NoticeForm from "@/components/NoticeForm";
import AttachmentPreview from "@/components/AttachmentPreview";
import SearchBox from "@/components/SearchBox";
import { IconPin, IconTrash } from "@/components/icons";
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
          <h2>
            <IconPin size={18} className="page-title-icon" /> 업무지시공유
          </h2>
          <p>팀 업무지시 및 공유사항을 확인하세요</p>
        </div>
        <div className="top-actions">
          <SearchBox />
          <NoticeForm addNotice={addNotice} />
        </div>
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
                  <IconTrash />
                </button>
              </form>

              <Link href={`/notices/${notice.id}`} className="notice-title-link">
                <h3>{notice.title} {isNew(notice.created_at) && <span className="new-badge">NEW</span>}</h3>
              </Link>

              <div
                className="notice-content-preview"
                dangerouslySetInnerHTML={{ __html: notice.content }}
              />

              {notice.file_url && (
                <AttachmentPreview fileUrl={notice.file_url} fileName={notice.file_name} />
              )}

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
