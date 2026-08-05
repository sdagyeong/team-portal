"use client";

import DocForm from "@/components/DocForm";
import { addDocument } from "./documentActions";

export default function DocumentForm({
  docType,
  region,
  onDone,
}: {
  docType: string;
  region: string;
  onDone?: () => void;
}) {
  return (
    <DocForm
      heading={`✏️ ${docType} 작성`}
      triggerLabel="+ 작성"
      contentFieldName="description"
      extraFields={{ doc_type: docType, region }}
      addAction={addDocument}
      onSaved={onDone}
      fileAccept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png"
    />
  );
}
