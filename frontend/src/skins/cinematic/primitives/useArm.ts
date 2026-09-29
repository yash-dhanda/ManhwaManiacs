"use client";
import { useEffect, useRef, useState } from "react";
import { ARM_MS, armIdle, armStart, canCommit, isArmed, type ArmState } from "./arm";

/**
 * The destructive arm as a hook (§7.10). While `active`, `armed` turns true after `ms`; `phase` drives the 2 px proof rule.
 * `canFire(condition)` re-checks the wall clock so a press at 999 ms can never confirm even if the timer is late.
 */
export function useArm(active: boolean, ms: number = ARM_MS) {
  const state = useRef<ArmState>(armIdle(ms));
  const [phase, setPhase] = useState<"idle" | "arming" | "armed">("idle");
  useEffect(() => {
    if (!active) { state.current = armIdle(ms); setPhase("idle"); return; } // eslint-disable-line react-hooks/set-state-in-effect -- reset when inactive
    state.current = armStart(performance.now(), ms);
    const raf = requestAnimationFrame(() => setPhase("arming"));
    const t = setTimeout(() => setPhase("armed"), ms);
    return () => { cancelAnimationFrame(raf); clearTimeout(t); };
  }, [active, ms]);
  return {
    phase,
    armed: phase === "armed",
    isArmedNow: () => isArmed(state.current, performance.now()),
    canFire: (conditionMet = true) => canCommit(state.current, performance.now(), conditionMet),
  };
}
