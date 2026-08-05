"use client";

import { useRef, useState } from "react";
import { IconClose, IconImage } from "./icons";

const CELL_STYLE =
  "border:1px solid #d1d5db;padding:8px;min-width:40px;resize:horizontal;overflow:hidden";

export type DocFormProps = {
  heading: string;
  triggerLabel?: string;
  contentFieldName: string; // 'content' (업무지시공유) | 'description' (자료실/AIRPORT)
  extraFields?: Record<string, string>;
  fileAccept?: string;
  addAction: (formData: FormData) => Promise<void>;
  onSaved?: () => void;
};

export default function DocForm({
  heading,
  triggerLabel = "+ 작성",
  contentFieldName,
  extraFields,
  fileAccept = ".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png",
  addAction,
  onSaved,
}: DocFormProps) {
  const [open, setOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [tableMenuOpen, setTableMenuOpen] = useState(false);
  const editorRef = useRef<HTMLDivElement>(null);
  const formRef = useRef<HTMLFormElement>(null);

  function exec(cmd: string, value?: string) {
    editorRef.current?.focus();
    document.execCommand(cmd, false, value);
  }

  function getCurrentCell(): HTMLTableCellElement | null {
    const sel = window.getSelection();
    if (!sel || sel.rangeCount === 0) return null;
    let node: Node | null = sel.getRangeAt(0).startContainer;
    while (node && node.nodeType !== 1) node = node.parentNode;
    const el = node as HTMLElement | null;
    return el?.closest("td, th") as HTMLTableCellElement | null;
  }

  function insertTable() {
    editorRef.current?.focus();
    const row = `<tr><td style="${CELL_STYLE}">&nbsp;</td><td style="${CELL_STYLE}">&nbsp;</td><td style="${CELL_STYLE}">&nbsp;</td></tr>`;
    const html = `<table style="border-collapse:collapse;margin:8px 0">${row}${row}${row}</table><p><br></p>`;
    exec("insertHTML", html);
  }

  function addRow() {
    const cell = getCurrentCell();
    const row = cell?.closest("tr");
    if (!row) {
      alert("표 안에 커서를 놓고 눌러주세요.");
      return;
    }
    const newRow = document.createElement("tr");
    for (let i = 0; i < row.children.length; i++) {
      const td = document.createElement("td");
      td.setAttribute("style", CELL_STYLE);
      td.innerHTML = "&nbsp;";
      newRow.appendChild(td);
    }
    row.after(newRow);
  }

  function deleteRow() {
    const cell = getCurrentCell();
    const row = cell?.closest("tr");
    const table = row?.closest("table");
    if (!row || !table) {
      alert("표 안에 커서를 놓고 눌러주세요.");
      return;
    }
    if (table.querySelectorAll("tr").length <= 1) {
      table.remove();
      return;
    }
    row.remove();
  }

  function addColumn() {
    const cell = getCurrentCell();
    const row = cell?.closest("tr");
    const table = row?.closest("table");
    if (!cell || !row || !table) {
      alert("표 안에 커서를 놓고 눌러주세요.");
      return;
    }
    const index = Array.from(row.children).indexOf(cell);
    table.querySelectorAll("tr").forEach((tr) => {
      const ref = tr.children[index] as HTMLElement;
      if (!ref) return;
      const td = document.createElement(ref.tagName.toLowerCase());
      td.setAttribute("style", CELL_STYLE);
      td.innerHTML = "&nbsp;";
      ref.after(td);
    });
  }

  function deleteColumn() {
    const cell = getCurrentCell();
    const row = cell?.closest("tr");
    const table = row?.closest("table");
    if (!cell || !row || !table) {
      alert("표 안에 커서를 놓고 눌러주세요.");
      return;
    }
    const index = Array.from(row.children).indexOf(cell);
    const firstRow = table.querySelector("tr");
    if (firstRow && firstRow.children.length <= 1) {
      table.remove();
      return;
    }
    table.querySelectorAll("tr").forEach((tr) => {
      tr.children[index]?.remove();
    });
  }

  function insertImage(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      exec("insertImage", reader.result as string);
    };
    reader.readAsDataURL(file);
    e.target.value = "";
  }

  async function handleSubmit(formData: FormData) {
    formData.set(contentFieldName, editorRef.current?.innerHTML ?? "");
    if (extraFields) {
      Object.entries(extraFields).forEach(([k, v]) => formData.set(k, v));
    }
    setSubmitting(true);
    try {
      await addAction(formData);
      if (editorRef.current) editorRef.current.innerHTML = "";
      formRef.current?.reset();
      setOpen(false);
      onSaved?.();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <>
      <button type="button" className="btn-primary" onClick={() => setOpen(true)}>
        {triggerLabel}
      </button>

      {open && (
        <div className="doc-modal-overlay" onClick={() => setOpen(false)}>
          <div className="doc-modal" onClick={(e) => e.stopPropagation()}>
            <div className="doc-modal-header">
              <h3>{heading}</h3>
              <button
                type="button"
                className="doc-modal-close"
                onClick={() => setOpen(false)}
                aria-label="닫기"
              >
                <IconClose size={15} />
              </button>
            </div>

            <form ref={formRef} action={handleSubmit} className="doc-modal-form">
              <input
                name="title"
                placeholder="제목"
                required
                className="doc-modal-title"
              />

              <div className="rte-toolbar">
                <select
                  defaultValue="3"
                  onChange={(e) => exec("fontSize", e.target.value)}
                  title="글자 크기"
                >
                  <option value="2">작게</option>
                  <option value="3">보통</option>
                  <option value="5">크게</option>
                  <option value="7">아주 크게</option>
                </select>
                <input
                  type="color"
                  defaultValue="#172033"
                  onChange={(e) => exec("foreColor", e.target.value)}
                  title="글자 색상"
                />
                <span className="rte-divider" />
                <button type="button" onClick={() => exec("bold")} title="굵게">
                  <b>B</b>
                </button>
                <button type="button" onClick={() => exec("underline")} title="밑줄">
                  <u>U</u>
                </button>
                <span className="rte-divider" />
                <button type="button" onClick={() => exec("justifyLeft")} title="왼쪽 정렬">
                  ⯇
                </button>
                <button type="button" onClick={() => exec("justifyCenter")} title="가운데 정렬">
                  ≡
                </button>
                <button type="button" onClick={() => exec("justifyRight")} title="오른쪽 정렬">
                  ⯈
                </button>
                <span className="rte-divider" />
                <div className="rte-table-menu">
                  <button type="button" onClick={() => setTableMenuOpen((o) => !o)}>
                    ▦ 표 ▾
                  </button>
                  {tableMenuOpen && (
                    <div className="rte-table-dropdown">
                      <button
                        type="button"
                        onClick={() => {
                          insertTable();
                          setTableMenuOpen(false);
                        }}
                      >
                        표 삽입
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          addRow();
                          setTableMenuOpen(false);
                        }}
                      >
                        행 추가
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          deleteRow();
                          setTableMenuOpen(false);
                        }}
                      >
                        행 삭제
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          addColumn();
                          setTableMenuOpen(false);
                        }}
                      >
                        열 추가
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          deleteColumn();
                          setTableMenuOpen(false);
                        }}
                      >
                        열 삭제
                      </button>
                    </div>
                  )}
                </div>
                <span className="rte-divider" />
                <label className="rte-image-btn">
                  <IconImage size={15} /> 이미지
                  <input type="file" accept="image/*" onChange={insertImage} hidden />
                </label>
              </div>

              <div
                ref={editorRef}
                className="rte-editor doc-modal-editor"
                contentEditable
                suppressContentEditableWarning
              />

              <div className="doc-modal-footer">
                <label className="doc-modal-file-label">
                  📎 파일첨부(PDF·Word·Excel 등)
                  <input
                    type="file"
                    name="file"
                    accept={fileAccept}
                    className="doc-modal-file"
                  />
                </label>
                <input
                  name="author"
                  placeholder="작성자"
                  required
                  className="doc-modal-author"
                />
              </div>

              <div className="form-actions">
                <button type="submit" className="btn-primary" disabled={submitting}>
                  {submitting ? "저장 중..." : "저장"}
                </button>
                <button type="button" className="btn-secondary" onClick={() => setOpen(false)}>
                  취소
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
