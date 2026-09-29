"use client";

import { motion, useMotionValue } from "motion/react";
import { useCallback, useEffect, useRef, useState, type ReactElement } from "react";
import { toast as sonner } from "sonner";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { project } from "../physics/project";
import { announce } from "./announce";
import { Icon, type IconName } from "./Icon";
import { PausableTimer, useOverlaySlot } from "./overlay-queue";
import { springTo } from "./overlay-utils";

export type ToastKind = "info" | "success" | "warning" | "error";
export interface ToastAction { label: string; onPress: () => void }
export interface ToastOptions {
  kind?: ToastKind;
  text: string;
  /** a second line: makes the capsule the 60 px two-line variant (radius 22) */
  secondary?: string;
  /** a plain action: "View", "Retry" */
  action?: ToastAction;
  /** registers the undo action: 10 s instead of 4, the rim drains, and `undoLast()` can run it for 60 s after the toast leaves */
  undo?: () => void;
  /** override the default 4 s (10 s with Undo) */
  durationMs?: number;
}

const GLYPH: Record<ToastKind, { icon: IconName; color: string }> = {
  info: { icon: "info", color: "var(--mm-color-info)" },
  success: { icon: "check-circle", color: "var(--mm-color-success)" },
  warning: { icon: "warning", color: "var(--mm-color-warning)" },
  error: { icon: "warning-circle", color: "var(--mm-color-danger)" },
};

/* ---- undo registry: the last destructive action stays undoable while its toast shows and for 60 s after ---- */
const UNDO_GRACE_MS = 60_000;
let lastUndo: { fn: () => void; leftAt: number | null } | null = null;

/** Runs the last destructive action's undo (the `mod+z` binding is registered by web/29). Returns whether one ran. */
export function undoLast(now = Date.now()): boolean {
  if (!lastUndo) return false;
  if (lastUndo.leftAt !== null && now - lastUndo.leftAt > UNDO_GRACE_MS) { lastUndo = null; return false; }
  const { fn } = lastUndo;
  lastUndo = null;
  haptic("undo");
  fn();
  return true;
}

export const dismissToast = (id?: string | number) => void sonner.dismiss(id);

/** Show a toast. It goes through the overlay queue: it appears once no menu (or phone alert) is open. */
export function showToast(o: ToastOptions): string | number {
  if (o.undo) lastUndo = { fn: o.undo, leftAt: null };
  return sonner.custom((id) => <ToastCapsule id={id} {...o} />, { duration: Infinity });
}

/** `html[data-toast]` while a toast shows on a phone: the Shell's top edge plateau extends to safe-top + 104 (web/29). */
let visibleToasts = 0;
function flagToast(on: boolean) {
  visibleToasts = Math.max(0, visibleToasts + (on ? 1 : -1));
  if (visibleToasts > 0 && window.matchMedia("(max-width: 767px)").matches) document.documentElement.setAttribute("data-toast", "");
  else document.documentElement.removeAttribute("data-toast");
}

const srOn = () => document.documentElement.dataset.sr === "on";
const DEFAULT_MS = 4000, UNDO_MS = 10_000;

function ToastCapsule({ id, kind = "info", text, secondary, action, undo, durationMs }: ToastOptions & { id: string | number }): ReactElement {
  const { allowed } = useOverlaySlot("toast");
  const total = durationMs ?? (undo ? UNDO_MS : DEFAULT_MS);
  const y = useMotionValue(-60);
  const x = useMotionValue(0);
  const fade = useMotionValue(0);
  const el = useRef<HTMLDivElement | null>(null);
  const timer = useRef<PausableTimer | null>(null);
  const holds = useRef({ hover: false, focus: false, touch: false });
  const leaving = useRef(false);
  const shown = useRef(false);
  const [rimDrain, setRimDrain] = useState(false);

  const finish = useCallback(() => {
    if (leaving.current) return;
    leaving.current = true;
    timer.current?.stop();
    if (undo && lastUndo) lastUndo.leftAt = Date.now();
    const done = () => sonner.dismiss(id);
    if (isGlassReduced()) { play("materialise", fade, 0, { onComplete: done }); return; }
    springTo(y, -60, "dismiss", { onComplete: done });
    play("dematerialise", fade, 0);
  }, [fade, id, undo, y]);

  const sync = useCallback(() => {
    const t = timer.current;
    if (!t) return;
    const held = holds.current.hover || holds.current.focus || holds.current.touch || !shown.current || srOn();
    if (held) t.pause(); else t.start();
  }, []);

  useEffect(() => {
    timer.current = new PausableTimer(srOn() ? Infinity : total, finish);
    if (undo) setRimDrain(true);
    return () => { timer.current?.stop(); if (shown.current) { shown.current = false; flagToast(false); } };
  }, [total, finish, undo]);

  // falls in on `snappy`; leaves on `dismiss` when the queue holds it (a menu opened), back in when it closes
  useEffect(() => {
    if (leaving.current) return;
    if (allowed) {
      shown.current = true;
      flagToast(true);
      y.stop();
      if (isGlassReduced()) { y.set(0); play("materialise", fade, 1); }
      else { play("toastFall", y, 0); play("materialise", fade, 1); }
      if (kind === "error") announce(text, 6000);
    } else if (shown.current) {
      shown.current = false;
      flagToast(false);
      if (isGlassReduced()) play("materialise", fade, 0);
      else { springTo(y, -60, "dismiss"); play("dematerialise", fade, 0); }
    }
    sync();
  }, [allowed, fade, kind, sync, text, y]);

  // the rim drains clockwise from 12 o'clock while the timer runs
  useEffect(() => {
    if (!rimDrain) return;
    let raf = 0;
    const tick = () => {
      const t = timer.current;
      if (t && el.current) el.current.style.setProperty("--drain", `${(360 * Math.max(0, t.remaining / total)).toFixed(1)}deg`);
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [rimDrain, total]);

  const prevFocus = useRef<Element | null>(null);
  const twoLine = !!secondary;
  const g = GLYPH[kind];
  return (
    <motion.div
      ref={el}
      className="g-toast"
      data-glass-toast=""
      data-kind={kind}
      data-two-line={twoLine ? "" : undefined}
      data-hidden={allowed ? undefined : ""}
      role={kind === "error" ? "alert" : "status"}
      aria-live={kind === "error" ? "assertive" : "polite"}
      tabIndex={-1}
      drag
      dragConstraints={{ top: 0, bottom: 0, left: 0, right: 0 }}
      dragElastic={{ top: 0.9, bottom: 0.12, left: 0.9, right: 0.9 }}
      dragMomentum={false}
      style={{ y, x, opacity: fade }}
      onPointerEnter={(e) => { if (e.pointerType === "mouse") { holds.current.hover = true; sync(); } }}
      onPointerLeave={() => { holds.current.hover = false; sync(); }}
      onFocus={() => { holds.current.focus = true; sync(); }}
      onBlur={() => { holds.current.focus = false; sync(); }}
      onPointerDown={() => { holds.current.touch = true; sync(); }}
      onPointerUp={() => { holds.current.touch = false; sync(); }}
      onPointerCancel={() => { holds.current.touch = false; sync(); }}
      onDragEnd={(_, info) => {
        holds.current.touch = false;
        const px = project(x.get(), info.velocity.x), py = project(y.get(), info.velocity.y);
        if (py < -40 || Math.abs(px) > 40) { finish(); return; }
        sync();
      }}
      onKeyDown={(e) => {
        if (e.key === "Escape") { e.stopPropagation(); finish(); const p = prevFocus.current; if (p instanceof HTMLElement && p.isConnected) p.focus(); }
      }}
      onFocusCapture={(e) => { if (!prevFocus.current && e.relatedTarget instanceof Element && !el.current?.contains(e.relatedTarget)) prevFocus.current = e.relatedTarget; }}
    >
      <GlassSurface tier="t2" capsule={!twoLine} radius={twoLine ? 22 : undefined} finish="regular" layer="hud" className="g-toast__glass" materialize={false}>
        <div className="g-toast__inner">
          <span className="g-disc g-toast__glyph"><Icon name={g.icon} size={20} color={g.color} /></span>
          <span className="g-toast__text">
            <span className="g-toast__line">{text}</span>
            {secondary ? <span className="g-toast__secondary">{secondary}</span> : null}
          </span>
          {action ? <button type="button" className="g-toast__action" onClick={() => { action.onPress(); finish(); }}>{action.label}</button> : null}
          {undo ? <button type="button" className="g-toast__action" data-testid="toast-undo" onClick={() => { undoLast(); finish(); }}>Undo</button> : null}
          <button type="button" className="g-toast__close" aria-label="Dismiss" onClick={finish}><Icon name="x" size={16} /></button>
        </div>
        {rimDrain ? <span className="g-toast__rim" aria-hidden="true" /> : null}
      </GlassSurface>
    </motion.div>
  );
}
