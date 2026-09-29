"use client";
import { useEffect, useState } from "react";
import { isEditableTarget } from "@/lib/keyboard/match";
import { singleKeyShortcutsEnabled } from "@/lib/keyboard/single-key";

export const G_ARM_MS = 1500;
export const G_ONE_MS = 600;

/** §8.0.6 targets: 1..12, 0 = Settings. `g 9` (Dialogue) is manga only. */
const TARGETS: Record<number, string> = { 1: "/", 2: "/library", 3: "/updates", 4: "/search", 5: "/downloads", 6: "/library/collections", 7: "/library/history", 8: "/library/bookmarks", 9: "/ocr", 10: "/library/statistics", 11: "/circle", 12: "/library/recommendations", 0: "/settings" };
export function gTarget(n: number, novels: boolean): string | null {
  if (n === 9 && novels) return null;
  return TARGETS[n] ?? null;
}

export type GState = { phase: "idle" } | { phase: "armed"; at: number } | { phase: "one"; at: number };
export const IDLE: GState = { phase: "idle" };
export type GResult = { state: GState; consumed: boolean; jump?: number };

/** Pure timeout step: armed expires after 1500 ms, `g 1` jumps to 01 after 600 ms. */
export function gTick(state: GState, now: number): GResult {
  if (state.phase === "armed" && now - state.at >= G_ARM_MS) return { state: IDLE, consumed: false };
  if (state.phase === "one" && now - state.at >= G_ONE_MS) return { state: IDLE, consumed: false, jump: 1 };
  return { state, consumed: false };
}

/** Pure key step. `now` in ms. */
export function gKey(state: GState, key: string, now: number, mods = false): GResult {
  const s = gTick(state, now);
  const st = s.state;
  if (["Shift", "Control", "Alt", "Meta"].includes(key)) return { state: st, consumed: false, jump: s.jump };
  if (st.phase === "idle") {
    if (key === "g" && !mods) return { state: { phase: "armed", at: now }, consumed: true, jump: s.jump };
    return { state: st, consumed: false, jump: s.jump };
  }
  if (mods) return { state: IDLE, consumed: false };
  if (st.phase === "armed") {
    if (key === "Enter") return { state: IDLE, consumed: true, jump: 1 };
    if (key === "1") return { state: { phase: "one", at: now }, consumed: true };
    if (/^[02-9]$/.test(key)) return { state: IDLE, consumed: true, jump: Number(key) };
    return { state: IDLE, consumed: false };
  }
  // phase "one": g 1 waits for 0, 1, 2
  if (key === "0" || key === "1" || key === "2") return { state: IDLE, consumed: true, jump: 10 + Number(key) };
  if (key === "Enter") return { state: IDLE, consumed: true, jump: 1 };
  return { state: IDLE, consumed: false, jump: 1 };
}

export const gChip = (s: GState): string | null => (s.phase === "armed" ? "G _" : s.phase === "one" ? "G 1_" : null);

/**
 * The window-level listener. Capture phase and `stopImmediatePropagation()` for consumed keys so page bindings never see them.
 * `enabled` is false in Reader and Page frames; typing in a field and "single-key shortcuts off" also stand it down.
 */
export function useGSequence({ enabled, novels, onJump }: { enabled: boolean; novels: boolean; onJump: (href: string) => void }): { chip: string | null } {
  const [state, setState] = useState<GState>(IDLE);
  useEffect(() => {
    if (state.phase === "idle") return;
    const ms = state.phase === "armed" ? G_ARM_MS : G_ONE_MS;
    const t = setTimeout(() => {
      const r = gTick(state, state.at + ms);
      setState(r.state);
      if (r.jump !== undefined) { const h = gTarget(r.jump, novels); if (h) onJump(h); }
    }, ms);
    return () => clearTimeout(t);
  }, [state, novels, onJump]);
  useEffect(() => {
    if (!enabled) return;
    let cur: GState = IDLE;
    const on = (e: KeyboardEvent) => {
      if (isEditableTarget(e.target) || !singleKeyShortcutsEnabled()) { if (cur.phase !== "idle") { cur = IDLE; setState(IDLE); } return; }
      const r = gKey(cur, e.key, performance.now(), e.ctrlKey || e.metaKey || e.altKey);
      cur = r.state;
      setState(r.state);
      if (r.consumed) { e.preventDefault(); e.stopImmediatePropagation(); }
      if (r.jump !== undefined) { const h = gTarget(r.jump, novels); if (h) onJump(h); }
    };
    window.addEventListener("keydown", on, true);
    return () => window.removeEventListener("keydown", on, true);
  }, [enabled, novels, onJump]);
  return { chip: gChip(state) };
}
