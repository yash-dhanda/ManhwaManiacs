"use client";

import { createContext, useContext, useRef, useState, type ReactNode } from "react";
import { GlassSurface, type GlassTwin } from "../glass/GlassSurface";

export const GroupContext = createContext<{ light: (x: number, y: number, on: boolean) => void } | null>(null);
export const useGroup = () => useContext(GroupContext);

/**
 * One `glassThin` capsule 44 tall holding 2 to 4 icon buttons (`IconButton variant="group"`), 44 px hit boxes with an 8 px
 * gap; ONE live surface for the whole group, one light: a pressed icon's glow lights the capsule at the touch point and
 * spreads into its neighbours.
 */
export function GlassGroup({ children, label, twin, className }: { children: ReactNode; label: string; twin?: GlassTwin; className?: string }) {
  const [glow, setGlow] = useState<{ x: number; y: number; on: boolean }>({ x: 0, y: 0, on: false });
  const host = useRef<HTMLElement | null>(null);
  const count = Array.isArray(children) ? children.length : 1;
  if (process.env.NODE_ENV !== "production" && (count < 2 || count > 4)) console.error("GlassGroup holds 2 to 4 icon buttons");
  return (
    <GroupContext.Provider value={{ light: (x, y, on) => { const r = host.current?.getBoundingClientRect(); setGlow({ x: r ? x - r.left : x, y: r ? y - r.top : y, on }); } }}>
      <GlassSurface ref={host} role="group" aria-label={label} tier="t2" capsule twin={twin} pressedGlow={glow} className={`g-group${className ? ` ${className}` : ""}`} data-glass-group="">
        {children}
      </GlassSurface>
    </GroupContext.Provider>
  );
}
