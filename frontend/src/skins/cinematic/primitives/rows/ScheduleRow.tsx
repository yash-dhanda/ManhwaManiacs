"use client";
import type { ReactNode } from "react";
import { RowFrame, type RowState } from "./Row";
import type { MenuItemDef } from "../menu-types";

const DAY = 86_400_000;
/** TODAY, YESTERDAY, 3 D AGO, then 12 SEP 2026. */
export function releaseLabel(date: Date, now: Date = new Date()): string {
  const a = Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()), b = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate());
  const d = Math.round((b - a) / DAY);
  if (d <= 0) return "TODAY";
  if (d === 1) return "YESTERDAY";
  if (d < 7) return `${d} D AGO`;
  return `${date.getDate()} ${date.toLocaleString("en-GB", { month: "short" }).toUpperCase()} ${date.getFullYear()}`;
}
/** Drops "Chapter 12" from the title when it only repeats the number. */
export function dedupeTitle(title: string, number: number | string | null): string {
  if (number === null) return title;
  const m = title.trim().match(/^(?:chapter|ch\.?)\s*([\d.]+)\s*[:\-–—.]?\s*(.*)$/i);
  return m && m[1] === String(number) ? (m[2] || `Chapter ${number}`) : title;
}

/** Chapter row: number folio (56 px column, `·` when null) -> title + release caption -> progress / READ -> download mark -> reaction slot. */
export function ScheduleRow({ number, title, released, pages, page, complete, downloadMark, reactions, onClick, menu, end, ...p }: RowState & {
  number: number | string | null; title: string; released?: Date; pages?: number; page?: number; complete?: boolean; downloadMark?: ReactNode; reactions?: ReactNode; onClick?: () => void; menu?: MenuItemDef[]; end?: ReactNode; "data-gallery"?: string;
}) {
  const shown = dedupeTitle(title, number);
  const cap = [released ? releaseLabel(released) : null, pages ? `${pages} PAGES` : null].filter(Boolean).join(" · ");
  return (
    <RowFrame {...p} menu={menu} end={end} onClick={onClick} min={56}>
      <span className="type-folio-lg w-14 shrink-0 text-right text-ink-100">{number ?? "·"}</span>
      <div className={`min-w-0 flex-1 py-2 ${complete ? "text-ink-45" : ""}`}>
        <p className="type-title truncate">{shown}</p>{cap ? <p className="type-caption text-ink-45">{cap}</p> : null}
      </div>
      {complete ? <span className="type-micro shrink-0 text-ink-45">READ</span> : page && pages ? <span className="type-folio shrink-0 text-spot">{`${page}/${pages}`}</span> : null}
      {downloadMark}{reactions}
    </RowFrame>
  );
}
