"use client";

import Link from "next/link";
import type { ChapterPicker } from "@/features/offline/use-chapter-picker";
import s from "../feature.module.css";
import t from "../type.module.css";

/** §7.29 select-mode bar: count, quick picks, Done, Download N; and the running state. */
export function SelectionBar({
  picker,
  novel,
  hasProfile,
  onDone,
}: {
  picker: ChapterPicker;
  novel: boolean;
  hasProfile: boolean;
  onDone: () => void;
}) {
  const { downloads } = picker;
  if (!hasProfile) {
    return (
      <div className={s.selbar} role="region" aria-label="Chapter selection">
        <span className={t.caption}>Downloads belong to a reading profile. Choose one to save chapters.</span>
        <Link className={`${s.btn} ${s.secondary} ${s.sm}`} href="/profiles">Choose a profile</Link>
        <button type="button" className={s.quiet} onClick={onDone}>Done</button>
      </div>
    );
  }
  if (downloads.running && downloads.progress) {
    const { completed, total } = downloads.progress;
    return (
      <div className={s.selbar} role="region" aria-label="Chapter selection">
        <span className={t.folio}>
          {novel && total > 20 ? "SAVING THE TEXT…" : `DOWNLOADING ${Math.min(completed + 1, total)} OF ${total}`}
        </span>
        <div className={s.rule2} style={{ flex: 1, minWidth: 120 }}>
          <i style={{ width: `${total ? (completed / total) * 100 : 0}%` }} />
        </div>
        <button type="button" className={s.quiet} onClick={downloads.cancel}>Stop</button>
      </div>
    );
  }
  const helpers = picker.helpers;
  return (
    <div className={s.selbar} role="region" aria-label="Chapter selection">
      <span className={t.folio}>
        {picker.selectedCount === 0
          ? "Select chapters to download"
          : `${picker.selectedCount} SELECTED · ${picker.savedCount} ALREADY SAVED`}
      </span>
      <div className={`${s.slug} ${t.kicker}`}>
        {helpers.map((h) => (
          <button key={h.id} type="button" onClick={() => picker.applyHelper(h.keys)}>
            {h.label}
            {h.keys.length > 0 ? <sup> {h.keys.length}</sup> : null}
          </button>
        ))}
      </div>
      <span className={s.spacer} />
      <button type="button" className={s.quiet} onClick={onDone}>Done</button>
      <button
        type="button"
        className={`${s.btn} ${s.primary}`}
        style={{ minHeight: 44 }}
        disabled={picker.plan.length === 0}
        onClick={picker.start}
      >
        <span style={{ minHeight: 44 }}>Download {picker.plan.length || ""}</span>
      </button>
    </div>
  );
}
