export const dynamic = "force-dynamic";
export const revalidate = 0;
import Link from "next/link";
import { IconChevronLeft } from "@/components/icons";
import { supabase } from "@/lib/supabaseClient";
import { formatKDate } from "@/lib/formatDate";
import AttachmentPreview from "@/components/AttachmentPreview";

export default async function TaskDocDetailPage({
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
        <Link href="/tasks" className="breadcrumb-back">
          <IconChevronLeft size={13} /> 뒤로
        </Link>
        <p className="empty">글을 찾을 수 없습니다.</p>
      </div>
    );
  }

  return (
    <div className="page">
      <Link href="/tasks" className="breadcrumb-back">
        <IconChevronLeft size={13} /> 뒤로
      </Link>

      <h1>{doc.title}</h1>
      <p className="meta">
        {doc.region} - {doc.doc_type} &nbsp;·&nbsp; 작성자 : {doc.author} &nbsp;·&nbsp; 작성일 :{" "}
        {formatKDate(doc.created_at)}
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
