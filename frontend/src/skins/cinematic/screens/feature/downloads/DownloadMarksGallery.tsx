"use client";

import { downloadMarkLabel, type DownloadMarkState } from "@/features/offline/download-mark";
import { describeRun, type DownloadRun } from "@/features/offline/download-queue";
import type { SeriesDownloads } from "@/features/offline/use-series-downloads";
import { DownloadMark } from "./DownloadMark";
import { RunSummary } from "./RunSummary";
import t from "../type.module.css";

const MARKS: DownloadMarkState[] = [
  { kind: "none" },
  { kind: "queued" },
  { kind: "downloading", progress: 0.3 },
  { kind: "saved" },
  { kind: "failed" },
  { kind: "paused" },
  { kind: "stale" },
];

const RUN: DownloadRun = { requested: 6, saved: 6, incomplete: 0, failed: 0, skipped: 0, outOfSpace: false, cancelled: false } as DownloadRun;
const SUMMARIES: [string, DownloadRun, number | null][] = [
  ["saved", RUN, null],
  ["nothing", { ...RUN, requested: 0, saved: 0 }, null],
  ["partial", { ...RUN, saved: 4, incomplete: 1, failed: 1 }, null],
  ["stopped", { ...RUN, saved: 2, cancelled: true, skipped: 4 }, null],
  ["out-of-room", { ...RUN, saved: 3, outOfSpace: true, skipped: 3 }, 52_428_800],
];

/** The seven marks side by side; the tooltip and accessible name are the DP7 wording. */
export function DownloadMarksGallery() {
  return (
    <main style={{ background: "var(--mm-color-paper-0)", color: "var(--mm-color-ink-100)", minHeight: "100dvh", padding: 48 }}>
      <h1 className={t.kicker} style={{ margin: 0 }}>DOWNLOAD MARKS</h1>
      <ul data-testid="marks" style={{ listStyle: "none", padding: 0, margin: "32px 0 0", display: "grid", gap: 20, maxWidth: 640 }}>
        {MARKS.map((m) => (
          <li key={m.kind} style={{ display: "grid", gridTemplateColumns: "48px 120px 1fr", alignItems: "center", gap: 16 }}>
            <DownloadMark state={m} onPress={() => undefined} />
            <span className={t.folio}>{m.kind.toUpperCase()}</span>
            <span className={t.caption} style={{ color: "var(--mm-color-ink-60)" }}>{downloadMarkLabel(m)}</span>
          </li>
        ))}
      </ul>
      <h2 className={t.kicker} style={{ margin: "48px 0 0", color: "var(--mm-color-ink-60)" }}>RUN SUMMARIES</h2>
      <div data-testid="summaries" style={{ display: "grid", gap: 16, maxWidth: 640, marginTop: 16 }}>
        {SUMMARIES.map(([id, run, free]) => (
          <div key={id} data-variant={id}>
            <RunSummary downloads={{ summary: describeRun(run, free), dismissSummary: () => undefined } as unknown as SeriesDownloads} />
          </div>
        ))}
      </div>
    </main>
  );
}
