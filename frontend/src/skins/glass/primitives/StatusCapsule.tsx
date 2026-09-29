"use client";

import { useEffect, useState } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { Icon, type IconName } from "./Icon";
import { Spinner } from "./Progress";

export type StatusKind = "offline" | "saved" | "syncing" | "busy";

/**
 * `glassThin` 32 tall, glyph + footnote 600 `onGlass`: "Offline", "Saved copy · 2 h", "Syncing", and the rate-limit capsule with a
 * live countdown. Offline and the rate-limit capsule announce once through a polite live region when they first appear; the
 * countdown is not re-announced. With `inGroup` (the desktop toolbar) it draws as a shape of its host group: no glass of its own.
 */
export function StatusCapsule({ kind, savedAge = "2 h", retryIn = 12, inGroup, "data-testid": tid }: { kind: StatusKind; savedAge?: string; retryIn?: number; inGroup?: boolean; "data-testid"?: string }) {
  const [left, setLeft] = useState(retryIn);
  useEffect(() => {
    if (kind !== "busy") return;
    // eslint-disable-next-line react-hooks/set-state-in-effect -- a new retry window restarts the countdown
    setLeft(retryIn);
    const t = setInterval(() => setLeft((n) => Math.max(0, n - 1)), 1000);
    return () => clearInterval(t);
  }, [kind, retryIn]);
  const glyph: IconName = "wifi-slash";
  const text = kind === "offline" ? "Offline" : kind === "saved" ? `Saved copy · ${savedAge}` : kind === "syncing" ? "Syncing" : `Sources are busy. Retrying in ${left} s`;
  const announceOnce = kind === "offline" ? "Offline" : kind === "busy" ? "Sources are busy. Retrying shortly." : "";
  const lead = kind === "syncing" ? <Spinner size={12} /> : kind === "busy" ? <Spinner size={12} /> : <span className="g-disc" data-small=""><Icon name={glyph} size={16} color="var(--mm-color-warning)" /></span>;
  const body = <span className="g-status__inner">{lead}<span className="g-status__text">{text}</span></span>;
  return (
    <>
      {announceOnce ? <span className="sr-only" role="status" aria-live="polite">{announceOnce}</span> : null}
      {inGroup ? <span className="g-status g-status--group" data-kind={kind} data-testid={tid}>{body}</span> : (
        <GlassSurface tier="t2" capsule layer="hud" className="g-status" data-kind={kind} data-testid={tid}>{body}</GlassSurface>
      )}
    </>
  );
}
