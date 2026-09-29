"use client";
import { useEffect, useState, useSyncExternalStore } from "react";
import { clearEntries, entries, formatEntry, isLate, setRecording, subscribe, type MotionEntry } from "@/lib/motion-timings";
import { useShortcut } from "@/lib/keyboard";

const snap = () => entries();

/**
 * Motion-timings overlay (§15.9), development builds only: a 320 px panel bottom-left at z.debug listing the last 20 recorder entries
 * in IBM Plex Mono 11/16, `proof` when late and `set` otherwise. `Clear`, `Copy log`. Toggled by mod+shift+m; off after reload.
 */
export default function MotionTimings() {
  const [on, setOn] = useState(false);
  useShortcut({ id: "cinematic.motion-timings", keys: ["mod+shift+m", "ctrl+shift+m"], description: "Toggle the motion-timings overlay", group: "Developer", allowInInput: true, handler: () => setOn((v) => !v) });
  useEffect(() => { setRecording(on); return () => setRecording(false); }, [on]);
  const list = useSyncExternalStore(subscribe, snap, () => [] as readonly MotionEntry[]);
  if (!on) return null;
  const last = list.slice(-20);
  return (
    <aside aria-label="Motion timings" data-motion-timings className="fixed bottom-4 left-4 w-80 border border-rule-2 bg-paper-2/92 text-ink-100" style={{ zIndex: "var(--mm-z-debug)" }}>
      <div className="flex items-center justify-between border-b border-rule-1 px-3 py-2">
        <span className="type-kicker text-ink-45">MOTION</span>
        <span className="flex gap-3">
          <button type="button" className="type-label text-ink-60 hover:text-ink-100" onClick={() => clearEntries()}>Clear</button>
          <button type="button" className="type-label text-ink-60 hover:text-ink-100" onClick={() => { void navigator.clipboard.writeText(JSON.stringify(list, null, 2)); }}>Copy log</button>
        </span>
      </div>
      <ol className="max-h-72 overflow-y-auto px-3 py-2" style={{ fontFamily: "var(--mm-font-folio)", fontSize: 11, lineHeight: "16px" }}>
        {last.length === 0 ? <li className="text-ink-45">No moves recorded yet.</li> : null}
        {last.map((e, i) => <li key={i} className={`whitespace-pre ${isLate(e) ? "text-proof" : "text-set"}`}>{formatEntry(e)}</li>)}
      </ol>
    </aside>
  );
}
