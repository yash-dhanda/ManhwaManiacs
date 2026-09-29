"use client";
import type { ReactNode } from "react";
import { Glyph } from "../glyphs";
import { RowFrame, type RowState } from "./Row";
import { DotLeader } from "./DotLeader";

/** Settings row: label + description -> a trailing control (switch), a value with dot leaders, or a chevron. Min 56. */
export function SettingsRow({ label, description, control, value, chevron, onClick, ...p }: RowState & {
  label: ReactNode; description?: ReactNode; control?: ReactNode; value?: ReactNode; chevron?: boolean; onClick?: () => void; "data-gallery"?: string;
}) {
  return (
    <RowFrame {...p} onClick={onClick} min={56}>
      <div className="min-w-0 py-2"><p className="type-ui">{label}</p>{description ? <p className="type-caption text-ink-45">{description}</p> : null}</div>
      {value !== undefined ? <><DotLeader /><span className="type-folio shrink-0 text-ink-60">{value}</span></> : <span className="flex-1" />}
      {control}
      {chevron ? <Glyph name="caret-right" size={20} className="shrink-0 text-ink-45" /> : null}
    </RowFrame>
  );
}
