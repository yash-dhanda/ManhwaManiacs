"use client";

import { motion, useMotionValue, useTransform } from "motion/react";
import { useCallback, useEffect, useImperativeHandle, useRef, useState, type ReactNode, type Ref } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { play, useGlassReduced } from "../motion";
import { playSound } from "../sounds";
import { announce } from "./announce";
import { Icon } from "./Icon";
import { springTo } from "./overlay-utils";
import { Spinner } from "./Progress";
import { armed, displayedPull, dropletRadius, glyphRotation, neckWidth, REST_LINE } from "./pull-physics";

export type RefreshResult = { changed: boolean } | void;
export interface PullToRefreshHandle { refresh: () => void }

type Phase = "idle" | "pulling" | "refreshing" | "done";

/**
 * Pull to refresh (glass 7.33): touch only, at scrollTop 0, the list gets `overscroll-behavior-y: contain`. A glassThin droplet hangs
 * from the top edge on a meniscus neck; at exactly 100 raw px the neck snaps (`refresh.arm`), the droplet springs to the 60 px rest
 * line on `lens` and turns into a liquid ring while `onRefresh()` runs. `{ changed: true }` ends in a check, `{ changed: false }` in a fade.
 * Reduced motion: a static spinner at the rest line once triggered. `ref.refresh()` is the alternative (menu item, `r`).
 */
export function PullToRefresh({ onRefresh, children, className, disabled, handle, "data-testid": tid }: { onRefresh: () => Promise<RefreshResult> | RefreshResult; children: ReactNode; className?: string; disabled?: boolean; handle?: Ref<PullToRefreshHandle>; "data-testid"?: string }) {
  const scroller = useRef<HTMLDivElement>(null);
  const pull = useMotionValue(0);
  const reduced = useGlassReduced();
  const [phase, setPhase] = useState<Phase>("idle");
  const [raw, setRaw] = useState(0);
  const [outcome, setOutcome] = useState<"check" | "fade" | null>(null);
  const [status, setStatus] = useState("");
  const state = useRef({ phase: "idle" as Phase, startY: 0, raw: 0, active: false, armedFired: false });
  const set = (p: Phase) => { state.current.phase = p; setPhase(p); };
  const onRefreshRef = useRef(onRefresh);
  useEffect(() => { onRefreshRef.current = onRefresh; });

  const run = useCallback(async () => {
    if (state.current.phase === "refreshing") return;
    set("refreshing");
    setOutcome(null);
    haptic("refresh.fire");
    if (reduced) pull.set(REST_LINE); else play("meniscusRefresh", pull, REST_LINE);
    let result: RefreshResult = undefined;
    try {
      result = await onRefreshRef.current();
      setStatus("Updated");
      announce("Updated", 1500);
    } catch (e) {
      const text = e instanceof Error && e.message ? e.message : "Couldn't refresh";
      setStatus(text);
      announce(text);
    }
    const changed = !!result && result.changed;
    if (changed) { haptic("refresh.done"); setOutcome("check"); } else setOutcome("fade");
    set("done");
    setTimeout(() => {
      springTo(pull, 0, "settle", { onComplete: () => { set("idle"); setOutcome(null); setRaw(0); } });
    }, changed ? 450 : 250);
  }, [pull, reduced]);

  useImperativeHandle(handle, () => ({ refresh: () => void run() }), [run]);

  useEffect(() => {
    const el = scroller.current;
    if (!el || disabled) return;
    const s = state.current;
    const start = (e: TouchEvent) => {
      if (s.phase !== "idle" || el.scrollTop > 0 || e.touches.length !== 1) { s.active = false; return; }
      s.active = true; s.startY = e.touches[0].clientY; s.raw = 0; s.armedFired = false;
    };
    const move = (e: TouchEvent) => {
      if (!s.active) return;
      const dy = e.touches[0].clientY - s.startY;
      if (dy <= 0 || el.scrollTop > 0) { if (s.raw > 0) { s.raw = 0; pull.set(0); setRaw(0); set("idle"); } return; }
      if (e.cancelable) e.preventDefault();
      s.raw = dy;
      if (s.phase !== "pulling") set("pulling");
      setRaw(dy);
      pull.set(displayedPull(dy, window.innerHeight));
      if (armed(dy) && !s.armedFired) {
        s.armedFired = true;
        haptic("refresh.arm");
        playSound("refresh.arm");
      }
    };
    const end = () => {
      if (!s.active) return;
      s.active = false;
      if (s.phase !== "pulling") return;
      if (armed(s.raw)) void run();
      else { set("idle"); springTo(pull, 0, "settle", { onComplete: () => setRaw(0) }); }
    };
    el.addEventListener("touchstart", start, { passive: true });
    el.addEventListener("touchmove", move, { passive: false });
    el.addEventListener("touchend", end);
    el.addEventListener("touchcancel", end);
    return () => { el.removeEventListener("touchstart", start); el.removeEventListener("touchmove", move); el.removeEventListener("touchend", end); el.removeEventListener("touchcancel", end); };
  }, [disabled, pull, run]);

  const busy = phase === "refreshing" || phase === "done";
  const radius = busy ? 16 : dropletRadius(raw);
  const neck = busy ? 0 : neckWidth(raw);
  const dropY = useTransform(pull, (v) => v - 16);
  const contentY = pull;
  const rot = glyphRotation(raw);
  return (
    <div ref={scroller} className={`g-pull${className ? ` ${className}` : ""}`} data-phase={phase} data-outcome={outcome ?? undefined} data-testid={tid ?? "pull"}>
      <div className="g-pull__drop" aria-hidden="true">
        <motion.div className="g-pull__neck" style={{ height: pull, width: neck, opacity: raw > 0 && !busy ? 1 : 0 }} data-testid="pull-neck" data-width={neck.toFixed(2)} />
        <motion.div className="g-pull__ball" style={{ y: dropY, scale: radius > 0 ? 1 : 0 }} data-testid="pull-droplet" data-radius={radius.toFixed(2)} data-armed={armed(raw) || busy ? "" : undefined}>
          <GlassSurface tier="t1" capsule layer="hud" materialize={false} className="g-pull__glass" style={{ width: radius * 2, height: radius * 2 }}>
            <span className="g-pull__glyph">
              {outcome === "check" ? <Icon name="check" size={16} /> : busy ? (reduced ? <Spinner size={16} className="g-spinner--static" /> : <Spinner size={16} />) : <span style={{ display: "inline-flex", transform: `rotate(${rot}deg)` }}><Icon name="droplet" size={Math.max(1, Math.round(radius))} /></span>}
            </span>
          </GlassSurface>
        </motion.div>
      </div>
      <motion.div className="g-pull__content" style={{ y: contentY }}>{children}</motion.div>
      <span className="sr-only" role="status" aria-live="polite">{status}</span>
    </div>
  );
}
