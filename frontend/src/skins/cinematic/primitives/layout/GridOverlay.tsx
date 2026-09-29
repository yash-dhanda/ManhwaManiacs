"use client";
import { useState } from "react";
import { useShortcut } from "@/lib/keyboard";
import { z } from "../../tokens.generated";
import { gridMargin, gridMarginRight } from "./Grid";

/** Development builds only: columns at 6 % spot, the 4 px baseline at 4 % bone, at z.debug; toggled by mod+shift+g. */
export function GridOverlay() {
  const [on, setOn] = useState(false);
  useShortcut({ id: "cinematic.grid-overlay", keys: ["mod+shift+g", "ctrl+shift+g"], description: "Toggle the layout grid", group: "Developer", allowInInput: true, handler: () => setOn((v) => !v) });
  if (process.env.NODE_ENV === "production" || !on) return null;
  return (
    <div aria-hidden data-grid-overlay className="pointer-events-none fixed inset-0" style={{ zIndex: z.debug }}>
      <div className="mx-auto size-full" style={{ display: "grid", gridTemplateColumns: "var(--mm-grid-template)", columnGap: "var(--mm-grid-gutter)", maxWidth: "var(--mm-grid-max)", paddingLeft: gridMargin, paddingRight: gridMarginRight }}>
        {Array.from({ length: 12 }).map((_, i) => <div key={i} className="hidden h-full [&:nth-child(-n+4)]:block frame:[&:nth-child(-n+8)]:block desktop:block" style={{ background: "color-mix(in srgb, var(--mm-color-spot) 6%, transparent)" }} />)}
      </div>
      <div className="absolute inset-0" style={{ backgroundImage: "repeating-linear-gradient(to bottom, transparent 0, transparent 3px, color-mix(in srgb, var(--mm-color-ink-100) 4%, transparent) 3px, color-mix(in srgb, var(--mm-color-ink-100) 4%, transparent) 4px)" }} />
    </div>
  );
}
