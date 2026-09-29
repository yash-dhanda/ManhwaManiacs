"use client";

import { downloadMarkLabel, type DownloadMarkState } from "@/features/offline/download-mark";
import { DownloadMark } from "./DownloadMark";
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
    </main>
  );
}
