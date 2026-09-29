"use client";

import { useEffect, useState, useSyncExternalStore } from "react";
import { subscribeMotion, type MotionRow } from "./motion-log";
import s from "./feature.module.css";

const EMPTY: MotionRow[] = [];
const snap = () => window.__mmMotion ?? EMPTY;

/** The motion-timings overlay (mod+shift+m): planned against measured, `proof` when over by 25%+. */
export function MotionTimings() {
  const [open, setOpen] = useState(false);
  const rows = useSyncExternalStore(subscribeMotion, snap, () => EMPTY);
  useEffect(() => {
    const on = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key.toLowerCase() === "m") {
        e.preventDefault();
        setOpen((v) => !v);
      }
    };
    window.addEventListener("keydown", on);
    return () => window.removeEventListener("keydown", on);
  }, []);
  if (!open) return null;
  return (
    <div className={s.timings} role="region" aria-label="Motion timings">
      <div className={s.timingsHead}>MOTION TIMINGS</div>
      {rows.length === 0 ? <div>No motion yet.</div> : null}
      {rows.map((r, i) => (
        <div key={i} className={s.timingsRow} data-over={r.measured > r.planned * 1.25 + 40 || undefined}>
          <span>{r.name}</span>
          <span>{r.planned} ms</span>
          <span>{r.measured} ms</span>
        </div>
      ))}
    </div>
  );
}
