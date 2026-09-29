"use client";

import Link from "next/link";
import type { SeriesDownloads } from "@/features/offline/use-series-downloads";
import s from "../feature.module.css";
import t from "../type.module.css";

/** The line `describeRun()` writes after a run; problems use the NOTE tone. */
export function RunSummary({ downloads }: { downloads: SeriesDownloads }) {
  const sum = downloads.summary;
  if (!sum) return null;
  const problem = sum.tone !== "ready";
  const outOfRoom = /out of room/i.test(sum.label);
  return (
    <p className={`${t.caption} ${s.note}`} role="status">
      {problem ? <span className={`${t.kicker} ${s.noteTone}`}>NOTE </span> : null}
      {sum.label}{" "}
      {outOfRoom ? (
        <Link className={s.link} href="/downloads">Manage downloads</Link>
      ) : null}{" "}
      <button type="button" className={s.quiet} onClick={downloads.dismissSummary}>Dismiss</button>
    </p>
  );
}
