export const dynamic = "force-dynamic";
export const revalidate = 0;
import Link from "next/link";
import { IconChevronLeft } from "@/components/icons";
import { supabase } from "@/lib/supabase";
import { formatKDate } from "@/lib/formatDate";
import AttachmentPreview from "@/components/AttachmentPreview";

export default async function NoticeDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const { data: notice, error } = await supabase
    .from("notices")
    .select("*")
    .eq("id", id)
    .single();

  if (error) {
    console.error(error);
  }

  if (!notice) {
    return (
      <div className="page">
        <Link href="/notices" className="breadcrumb-back">
          <IconChevronLeft size={13} /> 뒤로
        </Link>
        <p className="empty">글을 찾을 수 없습니다.</p>
      </div>
    );
  }

  return (
    <div className="page">
      <Link href="/notices" className="breadcrumb-back">
        <IconChevronLeft size={13} /> 뒤로
      </Link>

      <h1>{notice.title}</h1>
      <p className="meta">
        작성자 : {notice.author} &nbsp;·&nbsp; 작성일 : {formatKDate(notice.created_at)}
      </p>

      <div
        className="notice-detail-content"
        dangerouslySetInnerHTML={{ __html: notice.content }}
      />

      {notice.file_url && (
        <AttachmentPreview fileUrl={notice.file_url} fileName={notice.file_name} />
      )}
    </div>
  );
}
