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
