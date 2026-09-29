"use client";

import { useEffect, useRef, useState } from "react";
import { motion } from "motion/react";
import { useGlassReduced } from "../motion";
import { spring } from "../tokens.generated";

/**
 * The daily goal ring: 2 px, 3 px outside the orb, fills clockwise from 12 o'clock in `streak` at 80 %. When the goal is met
 * it closes and fills solid for 600 ms (`success`, then a shimmer), then stays closed in `streakCore` for the rest of the day.
 * Put it inside ProfileOrb's children.
 */
export function GoalRing({ orbSize, minutes, goal, onDisc = false }: { orbSize: number; minutes: number; goal: number; onDisc?: boolean }) {
  const reduced = useGlassReduced();
  const met = goal > 0 && minutes >= goal;
  const [phase, setPhase] = useState<"open" | "flash" | "closed">(met ? "closed" : "open");
  const was = useRef(met);
  useEffect(() => {
    if (met && !was.current) {
      was.current = true;
      const a = setTimeout(() => setPhase("flash"), 0);
      const b = setTimeout(() => setPhase("closed"), reduced ? 0 : 600);
      return () => { clearTimeout(a); clearTimeout(b); };
    }
    if (!met && was.current) {
      was.current = false;
      const a = setTimeout(() => setPhase("open"), 0);
      return () => clearTimeout(a);
    }
  }, [met, reduced]);
  const pad = onDisc ? 8 : 0;
  const box = orbSize + 2 * (3 + 1) + pad;
  const r = (orbSize + 2 * 3 + 2) / 2 + pad / 2;
  const c = 2 * Math.PI * r;
  const frac = goal > 0 ? Math.min(1, minutes / goal) : 0;
  const colour = phase === "closed" ? "var(--mm-color-streak-core)" : phase === "flash" ? "var(--mm-color-success)" : "rgb(255 138 61 / 0.8)";
  return (
    <span className="g-goal" data-onDisc={onDisc ? "" : undefined} data-phase={phase} role="img" aria-label={`Today: ${minutes} of ${goal} minutes`} style={{ width: box, height: box }}>
      {onDisc ? <span className="g-goal__disc" /> : null}
      <svg viewBox={`0 0 ${box} ${box}`} width={box} height={box} aria-hidden="true">
        <motion.circle cx={box / 2} cy={box / 2} r={r} fill="none" strokeWidth={phase === "flash" ? 3 : 2} strokeLinecap="round" stroke={colour} strokeDasharray={c} initial={false} animate={{ strokeDashoffset: c * (1 - (phase === "open" ? frac : 1)) }} transition={reduced ? { duration: 0 } : spring.snappy} transform={`rotate(-90 ${box / 2} ${box / 2})`} className={phase === "flash" ? "g-goal__shimmer" : undefined} />
      </svg>
    </span>
  );
}
