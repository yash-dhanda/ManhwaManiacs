"use client";

import { useSyncExternalStore, type ReactNode } from "react";
import { formatKeyCombo, type KeyCombo } from "@/lib/keyboard";

const noop = () => () => {};

/** `mono` 12/600 `label1` on `surface3`, radius 6, min width 20, height 20, a 0.5 px rim. */
export function Keycap({ children }: { children: ReactNode }) {
  return <kbd className="g-keycap">{children}</kbd>;
}

/** Every token of formatKeyCombo(combo) as a Keycap, 4 px apart ("⌘ K" on macOS, "Ctrl" "K" elsewhere). Empty on the server so hydration agrees. */
export function KeyCombos({ combo }: { combo: KeyCombo }) {
  const joined = useSyncExternalStore(noop, () => formatKeyCombo(combo).join("\u0000"), () => "");
  const tokens = joined ? joined.split("\u0000") : [];
  return (
    <span className="g-keycaps" aria-label={tokens.join(" ")}>
      {tokens.map((t, i) => <Keycap key={i}>{t}</Keycap>)}
    </span>
  );
}
