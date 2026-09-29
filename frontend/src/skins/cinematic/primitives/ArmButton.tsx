"use client";
import type { ReactNode } from "react";
import { LeaderDial } from "./Progress";

/**
 * The committing button of a destructive confirm (§7.10): disabled with a filling 2 px proof rule until `phase === "armed"`;
 * `aria-disabled` (not `disabled`) so it stays focusable. `filled` = the final filled confirm (proof fill, #000 text).
 */
export function ArmButton({ children, phase, ready = true, pending = false, filled = false, onPress, ...rest }: {
  children: ReactNode; phase: "idle" | "arming" | "armed"; ready?: boolean; pending?: boolean; filled?: boolean; onPress: () => void; "data-gallery"?: string;
}) {
  const live = phase === "armed" && ready && !pending;
  const face = phase !== "armed" || !ready ? "border-ink-30 text-ink-30" : filled ? "border-proof bg-proof text-paper-0" : "border-proof text-proof";
  return (
    <span className="relative inline-flex flex-col">
      <button type="button" data-gallery={rest["data-gallery"]} aria-disabled={!live || undefined} aria-busy={pending || undefined}
        onClick={(e) => { if (!live) { e.preventDefault(); return; } onPress(); }}
        className={`type-label relative inline-flex min-h-12 min-w-(--mm-hit-min) items-center justify-center gap-2 border px-5 ${face} ${live ? "cursor-pointer" : "cursor-default"}`}>
        {pending ? <LeaderDial size={16} immediate /> : null}{children}
      </button>
      <span aria-hidden className="cine-arm-rule absolute inset-x-0 bottom-0 h-0.5 bg-proof" data-arming={phase === "arming"} data-armed={phase === "armed"} />
      <span role="status" className="sr-only">{phase === "armed" ? "Ready" : ""}</span>
    </span>
  );
}
