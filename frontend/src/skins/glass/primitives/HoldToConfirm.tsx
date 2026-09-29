"use client";

import { useCallback, useEffect, useRef, useState, type PointerEvent } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { useGlassReduced } from "../motion";
import { MOTION_LABELS } from "../motion.generated";
import { beginRecord, trackFrames } from "../motion-recorder";
import { holdStep, initialHold, type HoldEvent, type HoldState } from "./hold";
import { Icon, type IconName } from "./Icon";
import { LiquidProgress } from "./LiquidProgress";
import { usePress, type PressState } from "./usePress";
import { Button } from "./Button";

export interface HoldToConfirmProps {
  label: string;
  icon?: IconName;
  /** `standalone`: a click calls onRequestConfirm (the confirm alert, web/27). `inAlert`: an explicit confirm button is always visible under the hold button. */
  mode: "standalone" | "inAlert";
  onConfirm: () => void;
  /** required in standalone mode: opens the explicit confirm alert (WCAG 2.5.1 fallback) */
  onRequestConfirm?: () => void;
  /** inAlert: label of the always-visible explicit button, e.g. "Turn on 18+" */
  fallbackLabel?: string;
  holdingLabel?: string;
  disabled?: boolean;
  forceState?: PressState;
  /** gallery: draw the hold at this level without input */
  previewLevel?: number;
  "data-testid"?: string;
}

/** Hold-to-confirm: a `glassThin` capsule, L 50, whose liquid fill rises from 200 ms to 1,200 ms. The fallback is never optional. */
export function HoldToConfirm({ label, icon, mode, onConfirm, onRequestConfirm, fallbackLabel = "Confirm", holdingLabel = "Keep holding…", disabled, forceState, previewLevel, "data-testid": tid }: HoldToConfirmProps) {
  if (process.env.NODE_ENV !== "production" && mode === "standalone" && !onRequestConfirm) console.error("HoldToConfirm mode=standalone requires onRequestConfirm");
  const reduced = useGlassReduced();
  const [level, setLevel] = useState(0);
  const [phase, setPhase] = useState<HoldState["phase"]>("idle");
  const [helper, setHelper] = useState<string | null>(null);
  const [flash, setFlash] = useState(false);
  const [draining, setDraining] = useState(false);
  const machine = useRef<HoldState>(initialHold);
  const raf = useRef(0);
  const endRec = useRef<(() => void) | null>(null);
  const origin = useRef({ x: 0, y: 0 });
  const helperT = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const fallback = useRef<HTMLButtonElement>(null);
  const cbs = useRef({ onConfirm, onRequestConfirm });
  useEffect(() => { cbs.current = { onConfirm, onRequestConfirm }; });

  const showHelper = useCallback((text: string) => {
    setHelper(text);
    clearTimeout(helperT.current);
    helperT.current = setTimeout(() => setHelper(null), 2000);
  }, []);
  const onClick = useCallback(() => {
    if (mode === "standalone") cbs.current.onRequestConfirm?.();
    else { fallback.current?.focus(); showHelper("Hold, or use the button below"); }
  }, [mode, showHelper]);

  const feed = useCallback((e: HoldEvent) => {
    const r = holdStep(machine.current, e, reduced);
    machine.current = r.state;
    for (const fx of r.effects) {
      if (fx.type === "ramp") haptic("hold.ramp");
      else if (fx.type === "done") {
        haptic("hold.done");
        setFlash(true);
        setTimeout(() => setFlash(false), 400);
        cbs.current.onConfirm();
      } else if (fx.type === "abort") { setDraining(true); showHelper("Keep holding, or click once to confirm"); }
      else if (fx.type === "click") onClick();
    }
    if (r.state.phase === "filling" && !endRec.current) endRec.current = trackFrames(beginRecord("holdFill", MOTION_LABELS.holdFill, 1200));
    if (r.state.phase !== "filling" && r.state.phase !== "pending" && endRec.current) { endRec.current(); endRec.current = null; }
    setPhase(r.state.phase);
    setLevel(r.state.phase === "filling" || r.state.phase === "done" ? r.state.level : 0);
    if (r.state.phase === "done" || r.state.phase === "aborted" || r.state.phase === "cancelled" || r.state.phase === "clicked") { cancelAnimationFrame(raf.current); raf.current = 0; }
  }, [reduced, onClick, showHelper]);

  const loop = useRef<() => void>(() => {});
  useEffect(() => {
    loop.current = () => {
      feed({ type: "tick", t: performance.now() });
      if (raf.current) raf.current = requestAnimationFrame(loop.current);
    };
  }, [feed]);
  useEffect(() => () => { endRec.current?.(); cancelAnimationFrame(raf.current); clearTimeout(helperT.current); }, []);

  const p = usePress<HTMLButtonElement>({ material: "glass", growth: "medium", disabled, forceState, haptic: false, onPress: (e) => { if (e.type !== "pointerup") onClick(); }, stretch: false });
  const down = (e: PointerEvent<HTMLButtonElement>) => {
    if (disabled || (e.pointerType === "mouse" && e.button !== 0)) return;
    p.props.onPointerDown(e);
    origin.current = { x: e.clientX, y: e.clientY };
    setDraining(false);
    setHelper(null);
    feed({ type: "down", t: performance.now() });
    raf.current = requestAnimationFrame(loop.current);
  };
  const dist = (e: PointerEvent) => Math.hypot(e.clientX - origin.current.x, e.clientY - origin.current.y);
  const move = (e: PointerEvent<HTMLButtonElement>) => { p.props.onPointerMove(e); feed({ type: "move", t: performance.now(), dist: dist(e) }); };
  const up = (e: PointerEvent<HTMLButtonElement>) => { feed({ type: "up", t: performance.now(), dist: dist(e) }); p.props.onPointerUp(e); };
  const cancel = () => { feed({ type: "cancel" }); p.props.onPointerCancel(); };
  // pointer clicks were handled by the machine; only a click with no pointer (Enter, Space) reaches usePress' onClick
  const holding = phase === "filling" || phase === "pending" && level > 0;
  const shown = previewLevel ?? level;

  return (
    <div className="g-hold" data-mode={mode}>
      <GlassSurface
        {...p.props}
        onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerCancel={cancel}
        as="button" type="button" tier="t2" capsule finish={flash ? "tinted" : "regular"} pressedGlow={p.glow}
        className="g-hold__btn" data-testid={tid} data-phase={phase} data-level={shown.toFixed(2)} data-reduced-steps={reduced ? "" : undefined}
        aria-disabled={disabled ? true : undefined}
      >
        <LiquidProgress value={shown} direct={!draining} move="holdFill" />
        <span className="g-hold__label">
          {icon ? <span className="g-icon"><Icon name={icon} size={20} /></span> : null}
          <span className="g-label">{holding ? holdingLabel : label}</span>
        </span>
      </GlassSurface>
      <p className="g-hold__helper" role="status" data-testid={tid ? `${tid}-helper` : undefined}>{helper}</p>
      {mode === "inAlert" ? <Button ref={fallback} variant="secondary" size="M" label={fallbackLabel} onPress={() => cbs.current.onConfirm()} data-testid={tid ? `${tid}-fallback` : undefined} /> : null}
    </div>
  );
}
