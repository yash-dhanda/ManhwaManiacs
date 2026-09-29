"use client";

import { motion, useReducedMotion } from "motion/react";
import type { CSSProperties, ReactNode } from "react";
import { Icon } from "./Icon";
import { LiquidProgress, type LiquidTone } from "./LiquidProgress";
import { useGlassReduced } from "../motion";
import { spring } from "../tokens.generated";

/** The liquid ring: a 90 deg arc that stretches to 270 deg and back while rotating once per 900 ms; reduced motion: a static ring pulsing 0.4 to 1 over 1.2 s. */
export function Spinner({ size = 16, className }: { size?: 10 | 12 | 16 | 24; className?: string }) {
  return (
    <span className={`g-spinner${className ? ` ${className}` : ""}`} data-size={size} style={{ width: size, height: size } as CSSProperties} aria-hidden="true">
      <svg viewBox="0 0 24 24" width={size} height={size}><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" pathLength={100} /></svg>
    </span>
  );
}

/** Three 5 px `onGlass` dots 6 px apart, each bobbing 3 px on `tick`, 80 ms apart (button loading); reduced motion: static. */
export function Dots({ className }: { className?: string }) {
  return <span className={`g-dots${className ? ` ${className}` : ""}`} aria-hidden="true"><i /><i /><i /></span>;
}

export type ProgressKind = "linear" | "hairline" | "ring" | "liquid" | "spinner" | "segmented";
export type ProgressStatus = "default" | "loading" | "complete" | "paused" | "error" | "disabled";

export interface ProgressProps {
  kind?: ProgressKind;
  /** 0..1; undefined with kind linear/liquid = indeterminate */
  value?: number;
  /** accessible text, e.g. "12 of 40 pages saved" */
  valueText?: string;
  label?: string;
  status?: ProgressStatus;
  tone?: LiquidTone;
  /** ring: 24 or 32 */
  size?: 24 | 32;
  /** segmented: widths (fractions summing to <= 1) and their colour tokens */
  segments?: readonly { value: number; color?: string; label?: string }[];
  onRetry?: () => void;
  className?: string;
  children?: ReactNode;
}

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));

export function Progress({ kind = "linear", value, valueText, label, status = "default", tone = "iris", size = 24, segments, onRetry, className, children }: ProgressProps) {
  const reduced = useGlassReduced();
  useReducedMotion();
  const determinate = value !== undefined && status !== "loading";
  const v = clamp01(value ?? 0);
  const st = status === "complete" ? "success" : status === "error" ? "danger" : status === "paused" ? "warning" : tone;
  const aria = {
    role: "progressbar" as const,
    "aria-label": label,
    "aria-valuemin": 0,
    "aria-valuemax": 100,
    "aria-valuenow": determinate ? Math.round(v * 100) : undefined,
    "aria-valuetext": valueText,
    "aria-busy": status === "loading" || !determinate ? true : undefined,
    "aria-disabled": status === "disabled" ? true : undefined,
  };
  const cls = `g-progress${className ? ` ${className}` : ""}`;
  if (kind === "spinner") return <span className={cls} data-kind="spinner" data-status={status} {...aria}><Spinner size={size === 32 ? 24 : 16} /></span>;
  if (kind === "ring") {
    const r = size / 2 - 1.5, c = 2 * Math.PI * r;
    return (
      <span className={cls} data-kind="ring" data-status={status} data-tone={st} style={{ width: size, height: size }} {...aria}>
        <svg viewBox={`0 0 ${size} ${size}`} width={size} height={size}>
          <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="var(--mm-color-fill1)" strokeWidth="3" />
          <motion.circle cx={size / 2} cy={size / 2} r={r} fill="none" strokeWidth="3" strokeLinecap="round" className="g-ring-arc" strokeDasharray={c} transform={`rotate(-90 ${size / 2} ${size / 2})`} initial={false} animate={{ strokeDashoffset: c * (1 - v) }} transition={reduced ? { duration: 0 } : spring.snappy} />
        </svg>
        {children}
      </span>
    );
  }
  if (kind === "segmented") {
    return (
      <span className={cls} data-kind="segmented" data-status={status} {...aria}>
        {(segments ?? []).map((s, i) => <motion.i key={i} title={s.label} style={{ background: s.color ?? "var(--mm-color-iris500)" }} initial={false} animate={{ width: `${clamp01(s.value) * 100}%` }} transition={reduced ? { duration: 0 } : spring.snappy} />)}
      </span>
    );
  }
  if (kind === "liquid") {
    return <span className={cls} data-kind="liquid" data-status={status} {...aria}><LiquidProgress value={determinate ? v : 0.3} tone={st as LiquidTone} paused={status === "paused"} /></span>;
  }
  // linear and hairline
  return (
    <span className={cls} data-kind={kind} data-status={status} data-tone={st} data-indeterminate={!determinate ? "" : undefined} {...aria}>
      {determinate ? (
        <motion.i className="g-fill" initial={false} animate={{ width: `${v * 100}%` }} transition={reduced ? { duration: 0 } : kind === "hairline" ? spring.track : spring.snappy} />
      ) : <i className="g-band" />}
      {status === "complete" ? <motion.span className="g-check" initial={reduced ? false : { scale: 0.6 }} animate={{ scale: 1 }} transition={spring.tick}><Icon name="check" size={12} weight="fill" /></motion.span> : null}
      {status === "error" && onRetry ? <button type="button" className="g-retry" aria-label="Retry" onClick={onRetry}><Icon name="arrow-clockwise" size={14} /></button> : null}
    </span>
  );
}
