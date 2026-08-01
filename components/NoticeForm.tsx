"use client";
import { useState } from "react";

export default function NoticeForm({
  addNotice,
}: {
  addNotice: (formData: FormData) => Promise<void>;
}) {
  const [open, setOpen] = useState(false);

  if (open) {
    return (
      <section className="writeBox">
        <h3>✏️ 업무지시 작성</h3>
        <form
          action={async (formData) => {
            await addNotice(formData);
            setOpen(false);
          }}
        >
          <input name="title" placeholder="제목" required />
          <textarea name="content" placeholder="내용" required />
          <input name="author" placeholder="작성자" required />
          <div className="form-actions">
            <button type="submit" className="btn-primary">
              등록
            </button>
            <button
              type="button"
              className="btn-secondary"
              onClick={() => setOpen(false)}
            >
              닫기
            </button>
          </div>
        </form>
      </section>
    );
  }

  return (
    <button type="button" className="btn-primary" onClick={() => setOpen(true)}>
      + 새 글 작성
    </button>
  );
}
