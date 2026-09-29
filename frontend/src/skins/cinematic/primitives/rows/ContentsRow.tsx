"use client";
import type { ReactNode } from "react";
import { Icon } from "../../Icon";
import { RowFrame, type RowState } from "./Row";
import { DotLeader } from "./DotLeader";

/** Novel TOC row: ordinal folio (right-aligned) -> title (Newsreader 16) -> dot leaders -> length -> state mark. 48. */
export function ContentsRow({ ordinal, title, minutes, progress, read, narrated, downloadMark, onClick, ...p }: RowState & {
  ordinal: number | string; title: string; minutes?: number; progress?: number; read?: boolean; narrated?: boolean; downloadMark?: ReactNode; onClick?: () => void; "data-gallery"?: string;
}) {
  return (
    <RowFrame {...p} onClick={onClick} min={48}>
      <span className="type-folio w-10 shrink-0 text-right text-ink-45">{ordinal}</span>
      <span className={`type-body min-w-0 truncate ${read ? "text-ink-45" : ""}`}>{title}</span>
      <DotLeader />
      {minutes !== undefined ? <span className="type-folio shrink-0 text-ink-45">{`${minutes} MIN`}</span> : null}
      {read ? <span className="type-micro shrink-0 text-ink-45">READ</span> : progress ? <span className="type-folio shrink-0 text-spot">{`${Math.round(progress)}%`}</span> : null}
      {narrated ? <Icon name="listen" size={20} className="shrink-0 text-ink-60" label="Narrated" /> : null}
      {downloadMark}
    </RowFrame>
  );
}
