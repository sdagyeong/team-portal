"use client";

import DocForm from "./DocForm";

export default function NoticeForm({
  addNotice,
}: {
  addNotice: (formData: FormData) => Promise<void>;
}) {
  return (
    <DocForm
      heading="✏️ 업무지시 작성"
      triggerLabel="+ 새 글 작성"
      contentFieldName="content"
      addAction={addNotice}
      fileAccept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png"
    />
  );
}
