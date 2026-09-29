"use client";
import { Checkbox as BaseCheckbox } from "@base-ui/react/checkbox";
import type { ReactNode } from "react";
import { haptic } from "../haptics";

/** §7.21: 20 x 20 square, 1 px ink.45 outline; checked fills ink.100 with a #000 square-capped check; indeterminate a 10 x 2 dash. */
export function Checkbox({ checked, onCheckedChange, label, disabled = false, hideLabel = false, className = "", ...rest }: {
  checked: boolean | "indeterminate";
  onCheckedChange: (next: boolean) => void;
  label: ReactNode;
  disabled?: boolean;
  /** Visually hide the label (select-mode rows); it stays the accessible name. */
  hideLabel?: boolean;
  className?: string;
  "data-gallery"?: string;
}) {
  const on = checked === true;
  const mixed = checked === "indeterminate";
  return (
    <label className={`inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center gap-3 ${disabled ? "text-ink-30" : "text-ink-100"} ${className}`}>
      <BaseCheckbox.Root
        checked={on} indeterminate={mixed} disabled={disabled} data-gallery={rest["data-gallery"]}
        onCheckedChange={(v) => { haptic("select"); onCheckedChange(v); }}
        className={`group relative flex size-5 shrink-0 items-center justify-center border transition-colors duration-(--mm-dur-snap) ${disabled ? "border-rule-1" : on || mixed ? "border-ink-100 bg-ink-100 " : "border-ink-45 hover:border-ink-100 "}`}
      >
        <BaseCheckbox.Indicator keepMounted className="flex size-full items-center justify-center text-paper-0">
          {mixed ? <span aria-hidden className="h-0.5 w-2.5 bg-paper-0" /> : on ? (
            <svg aria-hidden viewBox="0 0 20 20" className="size-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="square"><path d="M5 10.5 8.5 14 15 6.5" /></svg>
          ) : null}
        </BaseCheckbox.Indicator>
      </BaseCheckbox.Root>
      <span className={hideLabel ? "sr-only" : "type-ui"}>{label}</span>
    </label>
  );
}
