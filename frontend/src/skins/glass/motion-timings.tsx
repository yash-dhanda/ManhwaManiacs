"use client";

import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import { clearRecords, getRecords, subscribeRecords, type MoveRecord } from "./motion-recorder";

const FRAME_MS = 1000 / 60;

const rowText = (r: MoveRecord) => {
  const actual = r.end === null ? "…" : String(Math.round(r.end - r.start));
  return `${r.label.padEnd(14)} ${r.plannedMs} → ${actual} MS   ${r.frames}/${r.frames} F   ${r.dropped} DROP`;
};

const bad = (r: MoveRecord) =>
  r.end !== null && (r.dropped > 0 || (r.plannedMs > 0 && r.end - r.start - r.plannedMs > FRAME_MS));

/**
 * Development overlay (mod+shift+m): the last 20 moves from the recorder. Returns null in production so the
 * bundler drops it. Mirrors Cinematic's overlay in behaviour; it does not import it.
 */
export function GlassMotionTimings() {
  const records = useSyncExternalStore(subscribeRecords, getRecords, getRecords);
  const [open, setOpen] = useState(false);
  const logged = useRef(new Set<number>());
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key.toLowerCase() === "m") { e.preventDefault(); setOpen((o) => !o); }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);
  useEffect(() => {
    const fresh = records.filter((r) => r.end !== null && !logged.current.has(r.id));
    for (const r of fresh) logged.current.add(r.id);
    if (fresh.length) console.table(fresh.map((r) => ({ move: r.label, planned: r.plannedMs, actual: Math.round(r.end! - r.start), frames: r.frames, dropped: r.dropped })));
  }, [records]);
  if (process.env.NODE_ENV === "production" || !open) return null;
  const last = records.slice(-20).reverse();
  return (
    <div
      role="log"
      aria-label="Glass motion timings"
      style={{
        position: "fixed", left: 12, bottom: 12, width: 320, maxHeight: "50vh", overflow: "auto", zIndex: 90,
        background: "rgba(0,0,0,0.92)", border: "1px solid rgba(255,255,255,0.22)", borderRadius: 12, padding: 8,
        font: "11px/16px var(--mm-font-mono, ui-monospace, monospace)", color: "var(--mm-color-label1, #fff)",
      }}
    >
      <div style={{ display: "flex", gap: 8, marginBottom: 4 }}>
        <strong style={{ flex: 1 }}>MOTION TIMINGS</strong>
        <button type="button" style={{ minHeight: 24 }} onClick={clearRecords}>Clear</button>
        <button type="button" style={{ minHeight: 24 }} onClick={() => void navigator.clipboard?.writeText(last.map(rowText).join("\n"))}>Copy log</button>
      </div>
      {last.map((r) => (
        <div key={r.id} style={{ whiteSpace: "pre", color: bad(r) ? "#FF5C5C" : undefined }}>{rowText(r)}</div>
      ))}
      {last.length === 0 && <div>No moves yet.</div>}
    </div>
  );
}
