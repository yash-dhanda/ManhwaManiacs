"use client";

import { createContext, useCallback, useContext, useRef, type ReactNode } from "react";
import { moveFocus, type RailPos } from "./rail-columns";

interface Ctx { register: (el: HTMLElement | null, i: number) => void; move: (from: RailPos, key: Parameters<typeof moveFocus>[2]) => boolean }
export const RailGroupContext = createContext<Ctx | null>(null);
export const useRailGroup = () => useContext(RailGroupContext);

/** Rails inside a group are reached with up and down, keeping the column. Each rail must be given its `index`. */
export function RailGroup({ children, label }: { children: ReactNode; label?: string }) {
  const rails = useRef<(HTMLElement | null)[]>([]);
  const items = (r: number) => Array.from(rails.current[r]?.querySelectorAll<HTMLElement>(".g-poster__main") ?? []);
  const register = useCallback((el: HTMLElement | null, i: number) => { rails.current[i] = el; }, []);
  const move = useCallback((from: RailPos, key: Parameters<typeof moveFocus>[2]) => {
    const counts = rails.current.map((_, r) => items(r).length);
    const to = moveFocus(counts, from, key);
    if (!to) return false;
    const el = items(to.rail)[to.col];
    el?.focus();
    el?.scrollIntoView({ block: "nearest", inline: "nearest" });
    return true;
  }, []);
  return <RailGroupContext.Provider value={{ register, move }}><div className="g-railgroup" role="group" aria-label={label}>{children}</div></RailGroupContext.Provider>;
}
