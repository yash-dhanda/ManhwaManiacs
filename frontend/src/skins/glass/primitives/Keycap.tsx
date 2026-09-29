"use client";
// STUB (interface frozen; the icon-button agent replaces the bodies).
import type { ReactNode } from "react";
import type { KeyCombo } from "@/lib/keyboard";

export function Keycap({ children }: { children: ReactNode }) {
  return <kbd className="g-keycap">{children}</kbd>;
}
/** Renders every token of formatKeyCombo(combo) as Keycaps, 4 px apart. */
export function KeyCombos({ combo }: { combo: KeyCombo }) {
  return <span className="g-keycaps">{String(combo)}</span>;
}
