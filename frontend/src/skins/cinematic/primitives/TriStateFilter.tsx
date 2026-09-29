"use client";
import { useState } from "react";
import { cn } from "@/lib/cn";
import { haptic } from "../haptics";
import { useLongPress } from "./hooks";

export type TriState = "neutral" | "include" | "exclude";
const NEXT: Record<TriState, TriState> = { neutral: "include", include: "exclude", exclude: "neutral" };
const SPOKEN: Record<TriState, string> = { neutral: "not filtered", include: "included", exclude: "excluded" };

/** §7.5: tap cycles neutral -> include -> exclude -> neutral; long-press (450 ms) or right-click jumps to exclude. */
export function TriStateFilter({ label, state, onChange, "data-gallery": gallery }: { label: string; state: TriState; onChange: (s: TriState) => void; "data-gallery"?: string }) {
  const [live, setLive] = useState("");
  const set = (s: TriState) => { haptic("select"); onChange(s); setLive(`${label}: ${SPOKEN[s]}`); };
  const press = useLongPress(() => set("exclude"));
  return (
    <>
      <button type="button" data-gallery={gallery} aria-label={`${label}: ${SPOKEN[state]}`} onClick={() => set(NEXT[state])} {...press}
        className={cn("type-nav relative inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center px-3 transition-colors duration-(--mm-dur-beat) active:translate-y-px", state === "include" ? "text-ink-100" : "text-ink-45 hover:text-ink-100")}>
        <span className="relative">
          {label}
          {state === "include" ? <span aria-hidden className="absolute inset-x-0 h-0.5 bg-spot" style={{ bottom: -4 }} /> : null}
          {state === "exclude" ? <span aria-hidden className="absolute inset-x-0 top-1/2 h-px bg-proof" /> : null}
        </span>
      </button>
      <span aria-live="polite" className="sr-only">{live}</span>
    </>
  );
}
