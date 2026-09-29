"use client";
import { useDelayedFlag, useCineReduced } from "../motion";
import { useEffect, useState } from "react";

import { Icon } from "../Icon";
import { cn } from "@/lib/cn";

const pct = (v: number) => Math.min(100, Math.max(0, v));

/** §7.18: 2 px, square ends, track rule.1, fill spot, width 240 ms ease.set. */
export function RuleProgress({ value, label = "Progress", className = "" }: { value: number; label?: string; className?: string }) {
  return (
    <div role="progressbar" aria-label={label} aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(pct(value))} aria-valuetext={`${Math.round(pct(value))} percent`} className={`h-0.5 w-full bg-rule-1 ${className}`}>
      <div className="h-full bg-spot transition-[width] duration-(--mm-dur-line) ease-set" style={{ width: `${pct(value)}%` }} />
    </div>
  );
}

export function IndeterminateRule({ label = "Loading", className = "" }: { label?: string; className?: string }) {
  return (
    <div role="progressbar" aria-label={label} aria-busy className={`h-0.5 w-full overflow-hidden bg-rule-1 ${className}`}>
      <div className="animate-loop-rule h-full w-1/4 bg-spot" />
    </div>
  );
}

/** 2 px spot flush on a cover's bottom edge. */
export function PosterProgress({ value, className = "" }: { value: number; className?: string }) {
  return <div aria-hidden className={`absolute inset-x-0 bottom-0 h-0.5 bg-rule-1/60 ${className}`}><div className="h-full bg-spot" style={{ width: `${pct(value)}%` }} /></div>;
}

/** 2 px spot at the very bottom of a reader (web/12). */
export function MicroProgress({ value }: { value: number }) {
  return <div aria-hidden className="fixed inset-x-0 bottom-0 h-0.5"><div className="h-full bg-spot transition-[width] duration-(--mm-dur-line) ease-set" style={{ width: `${pct(value)}%` }} /></div>;
}

/** Replaces every spinner: 1 px ink.30 ring, 1 px crosshair, conic sweep, one revolution per 1000 ms. Mounts only after 400 ms of waiting. */
export function LeaderDial({ size = 32, immediate = false, sweep = "var(--mm-color-leader-sweep)", label }: { size?: 12 | 16 | 24 | 32 | 40; immediate?: boolean; sweep?: string; label?: string }) {
  const late = useDelayedFlag(400);
  if (!immediate && !late) return <span style={{ width: size, height: size }} className="inline-block" aria-hidden />;
  return (
    <span role={label ? "img" : undefined} aria-label={label} aria-hidden={label ? undefined : true} className="relative inline-block rounded-round border border-ink-30" style={{ width: size, height: size }}>
      <span aria-hidden className="absolute inset-y-0 left-1/2 w-px bg-ink-30" />
      <span aria-hidden className="absolute inset-x-0 top-1/2 h-px bg-ink-30" />
      <span aria-hidden className="animate-leader absolute inset-0 rounded-round" style={{ background: `conic-gradient(from 0deg, ${sweep} 0deg, transparent 90deg)` }} />
    </span>
  );
}

/** The leader dial at 40 px, one spot pass over 5000 ms. Reduced motion: no sweep, a `5 S` ... `1 S` folio once per second. */
export function CountdownDial({ ms = 5000, onDone }: { ms?: number; onDone?: () => void }) {
  const reduced = useCineReduced();
  const [left, setLeft] = useState(Math.ceil(ms / 1000));
  useEffect(() => {
    const t0 = performance.now();
    const id = setInterval(() => {
      const rest = Math.ceil((ms - (performance.now() - t0)) / 1000);
      setLeft(Math.max(0, rest));
      if (rest <= 0) { clearInterval(id); onDone?.(); }
    }, 250);
    return () => clearInterval(id);
  }, [ms, onDone]);
  if (reduced) return <span role="timer" className="type-folio text-ink-60">{left} S</span>;
  return (
    <span role="timer" aria-label={`${left} seconds`} className="relative inline-block rounded-round border border-ink-30" style={{ width: 40, height: 40 }}>
      <span aria-hidden className="absolute inset-0 rounded-round" style={{ background: "conic-gradient(from 0deg, var(--mm-color-spot) 0deg, transparent 90deg)", animation: `leader ${ms}ms linear 1 forwards` }} />
    </span>
  );
}

export function FolioCounter({ index, total }: { index: number; total: number }) {
  const p = (n: number) => String(n).padStart(2, "0");
  return <span className="type-folio-lg text-ink-60" aria-label={`${index} of ${total}`}><span aria-hidden>{p(index)} / {p(total)}</span></span>;
}

export type DownloadState = "not" | "queued" | "downloading" | "saved" | "failed" | "paused" | "stale";
const DL_LABEL: Record<DownloadState, (p: number) => string> = {
  not: () => "Not downloaded", queued: () => "Queued", downloading: (p) => `Downloading, ${Math.round(p)} percent`, saved: () => "Saved",
  failed: () => "Failed, tap to retry", paused: () => "Paused", stale: () => "Saved copy is out of date, download again",
};
export function DownloadMark({ state, progress = 0, onClick }: { state: DownloadState; progress?: number; onClick?: () => void }) {
  return (
    <button type="button" aria-label={DL_LABEL[state](progress)} onClick={onClick} className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center">
      {state === "not" ? <Icon name="download" size={16} className="text-ink-45" />
        : state === "stale" ? <Icon name="download" size={16} className="text-spot" />
        : state === "saved" ? <Icon name="downloaded" size={16} filled className="text-set" />
        : (
          <span aria-hidden className={cn("relative inline-flex size-4 items-center justify-center overflow-hidden border", state === "queued" && "border-dashed border-ink-45", state === "failed" && "border-proof text-proof", state !== "queued" && state !== "failed" && "border-ink-100")}>
            {state === "downloading" ? <span className="absolute inset-x-0 bottom-0 bg-spot" style={{ height: `${pct(progress)}%` }} /> : null}
            {state === "paused" ? <><span className="mr-0.5 h-2.5 w-0.5 bg-spot" /><span className="h-2.5 w-0.5 bg-spot" /></> : null}
            {state === "failed" ? <span className="type-micro">!</span> : null}
          </span>
        )}
    </button>
  );
}

/** 8 px bar in three segments; the cap is a 2 px ink.100 tick above the bar. */
export function StorageMeter({ other, app, capGb, totalGb, floorGb = 1.5, freeGb }: { other: number; app: number; capGb: number; totalGb: number; floorGb?: number; freeGb: number }) {
  const w = (v: number) => `${(v / totalGb) * 100}%`;
  const note = app >= capGb ? "Storage cap reached" : freeGb <= floorGb ? "Under the 1.5 GB floor" : null;
  return (
    <div className="flex flex-col gap-2">
      <div role="meter" aria-valuemin={0} aria-valuemax={totalGb} aria-valuenow={app} aria-valuetext={`${app} of ${totalGb} gigabytes used`} className="relative flex h-2 w-full bg-rule-1">
        <span className="h-full bg-ink-60" style={{ width: w(other) }} /><span className="h-full bg-spot" style={{ width: w(app) }} />
        <span aria-hidden className="absolute -top-1 h-1 w-0.5 bg-ink-100" style={{ left: w(capGb) }} />
      </div>
      {note ? <p className="type-kicker text-spot"><span className="text-ink-60">NOTE </span>{note}</p> : null}
    </div>
  );
}

