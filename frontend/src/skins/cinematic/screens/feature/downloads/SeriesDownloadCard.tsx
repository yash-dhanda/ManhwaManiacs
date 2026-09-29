"use client";

import Link from "next/link";
import type { ChapterPicker } from "@/features/offline/use-chapter-picker";
import s from "../feature.module.css";
import t from "../type.module.css";

/** F5: "ON THIS DEVICE" — only when anything is saved or queued. */
export function SeriesDownloadCard({ picker }: { picker: ChapterPicker }) {
  const d = picker.downloads;
  const paused = [...d.saved.values()].some((e) => e.status === "paused");
  const failed = [...d.saved.values()].filter((e) => e.status === "partial").length;
  const waiting = d.pending.size;
  if (picker.savedCount === 0 && waiting === 0 && !d.running && failed === 0) return null;
  const done = picker.savedCount === picker.total && picker.total > 0;
  return (
    <section className={s.card} aria-label="Downloads on this device">
      <div className={`${t.kicker}`} style={{ color: "var(--mm-color-ink-60)" }}>ON THIS DEVICE</div>
      <div className={t.folio}>{picker.savedCount} OF {picker.total} CHAPTERS SAVED</div>
      <div className={`${s.rule2} ${done ? s.rule2Set : ""}`}>
        <i style={{ width: `${picker.total ? (picker.savedCount / picker.total) * 100 : 0}%` }} />
      </div>
      {d.running && d.progress ? (
        <div className={t.folio}>DOWNLOADING NOW · {d.progress.completed + 1} OF {d.progress.total}</div>
      ) : null}
      {waiting > 0 || failed > 0 ? (
        <div className={t.folio}>{waiting} WAITING · {failed} FAILED</div>
      ) : null}
      {paused ? (
        <p className={`${t.caption} ${s.note}`}>
          <span className={`${t.kicker} ${s.noteTone}`}>NOTE </span>Paused: this browser is out of room.{" "}
          <Link className={s.link} href="/downloads?tab=storage">Storage settings</Link>
        </p>
      ) : null}
    </section>
  );
}
