"use client";

import { useState } from "react";
import { IconFilePreview, IconDownload, IconClose } from "./icons";

function getFileKind(name: string | null | undefined) {
  if (!name) return "other";
  const ext = name.split(".").pop()?.toLowerCase() ?? "";
  if (["jpg", "jpeg", "png", "gif", "webp", "bmp", "svg"].includes(ext)) return "image";
  if (ext === "pdf") return "pdf";
  if (["doc", "docx", "xls", "xlsx", "ppt", "pptx"].includes(ext)) return "office";
  return "other";
}

export default function AttachmentPreview({
  fileUrl,
  fileName,
}: {
  fileUrl: string;
  fileName: string | null;
}) {
  const [open, setOpen] = useState(false);
  const kind = getFileKind(fileName);

  return (
    <div className="attachment-inline">
      <span className="attachment-name">{fileName}</span>

      <button
        type="button"
        className="attachment-icon-btn"
        onClick={() => setOpen(true)}
        title="미리보기"
        aria-label="미리보기"
      >
        <IconFilePreview />
      </button>

      <a
        href={fileUrl}
        download={fileName ?? true}
        target="_blank"
        rel="noreferrer"
        className="attachment-icon-btn"
        title="다운로드"
        aria-label="다운로드"
      >
        <IconDownload />
      </a>

      {open && (
        <div className="doc-modal-overlay" onClick={() => setOpen(false)}>
          <div
            className="doc-modal attachment-modal"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="doc-modal-header">
              <h3>{fileName}</h3>
              <button
                type="button"
                className="doc-modal-close"
                onClick={() => setOpen(false)}
                aria-label="닫기"
              >
                <IconClose />
              </button>
            </div>

            <div className="attachment-modal-body">
              {kind === "image" && (
                <img src={fileUrl} alt={fileName ?? ""} className="attached-image" />
              )}

              {kind === "pdf" && (
                <iframe
                  src={`${fileUrl}#toolbar=0&navpanes=0`}
                  className="attachment-frame"
                  title={fileName ?? "미리보기"}
                />
              )}

              {kind === "office" && (
                <iframe
                  src={`https://view.officeapps.live.com/op/embed.aspx?src=${encodeURIComponent(
                    fileUrl
                  )}`}
                  className="attachment-frame"
                  title={fileName ?? "미리보기"}
                />
              )}

              {kind === "other" && (
                <p className="empty">이 파일 형식은 미리보기를 지원하지 않아요.</p>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
