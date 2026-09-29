"use client";

import Link from "next/link";
import { useRef } from "react";
import { GripVertical, Pin } from "lucide-react";
import type { SourceSummary } from "@/features/sources/types";
import { ROUTES } from "@/skins/contract.generated";
import { Certificate18 } from "../../icons/glyphs.generated";
import { HealthMark, SourceLogo, kit as s, cx } from "../kit/Kit";
import d from "./sources.module.css";

export interface RowProps {
  source: SourceSummary;
  pinned: boolean;
  now: number;
  pinDisabledReason: string | null;
  onTogglePin: () => void;
  onMenu: () => void;
  handle?: { onPointerDown: (e: React.PointerEvent) => void } | null;
}

/** 450 ms long-press opens the row menu; the native context menu is suppressed on these rows. */
function useLongPress(cb: () => void) {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const clear = () => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = null;
  };
  return {
    onPointerDown: (e: React.PointerEvent) => {
      if (e.pointerType === "mouse") return;
      timer.current = setTimeout(cb, 450);
    },
    onPointerUp: clear,
    onPointerLeave: clear,
    onPointerCancel: clear,
    onContextMenu: (e: React.MouseEvent) => {
      e.preventDefault();
      cb();
    },
  };
}

export function SourceRow({ source, pinned, now, pinDisabledReason, onTogglePin, onMenu, handle }: RowProps) {
  const press = useLongPress(onMenu);
  const desc = source.description ?? "";
  return (
    <div className={cx(d.row, !handle && d.rowAll)} data-source-id={source.id} {...press} style={{ WebkitTouchCallout: "none" }}>
      {handle ? (
        <button type="button" className={cx(s.iconBtn, d.handle)} aria-label={`Reorder ${source.name}`} onPointerDown={handle.onPointerDown}>
          <GripVertical size={20} aria-hidden />
        </button>
      ) : null}
      <SourceLogo id={source.id} name={source.name} iconUrl={source.icon_url} size={32} />
      <Link href={ROUTES.source(source.id)} className={d.main} data-row-link="">
        <span className={d.text}>
          <p className={d.name}>{source.name}</p>
          {desc ? (
            <p className={cx(s.caption, d.desc)} title={desc}>
              {desc}
            </p>
          ) : null}
        </span>
      </Link>
      <span className={cx(d.col, d.lang)}>{source.language ? source.language.toUpperCase() : "—"}</span>
      <span className={cx(d.col, d.kindCol)}>{source.content_kind === "novel" ? "NOVEL" : "MANGA"}</span>
      <span className={cx(d.healthCol, s.healthCompact)}>
        <HealthMark health={source.health} now={now} />
      </span>
      <span className={d.certCell}>{source.mature ? <Certificate18 size={16} weight="regular" title="18+" /> : null}</span>
      <button
        type="button"
        className={cx(s.iconBtn, d.pinBtn, pinned && d.pinned)}
        aria-pressed={pinned}
        aria-label={`Pin ${source.name}`}
        title={pinDisabledReason ?? (pinned ? `Unpin ${source.name}` : `Pin ${source.name}`)}
        disabled={pinDisabledReason !== null}
        onClick={onTogglePin}
      >
        <Pin size={24} aria-hidden fill={pinned ? "currentColor" : "none"} />
      </button>
    </div>
  );
}
