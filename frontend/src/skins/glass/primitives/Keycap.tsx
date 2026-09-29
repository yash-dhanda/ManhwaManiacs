"use client";

import { Fragment, useEffect, useState, type ReactNode } from "react";
import { formatKeyCombo, type KeyCombo } from "@/lib/keyboard";

/** `mono` 12/600 `label1` on `surface3`, radius 6, min width 20, height 20, a 0.5 px rim. */
export function Keycap({ children }: { children: ReactNode }) {
  return <kbd className="g-keycap">{children}</kbd>;
}

/** Every token of formatKeyCombo(combo) as a Keycap, 4 px apart ("⌘ K" on macOS, "Ctrl" "K" elsewhere). Resolved after mount so SSR and hydration agree. */
export function KeyCombos({ combo }: { combo: KeyCombo }) {
  const [tokens, setTokens] = useState<string[]>([]);
  useEffect(() => setTokens(formatKeyCombo(combo)), [combo]);
  return (
    <span className="g-keycaps" aria-label={tokens.join(" ")}>
      {tokens.map((t, i) => <Fragment key={i}><Keycap>{t}</Keycap></Fragment>)}
    </span>
  );
}
