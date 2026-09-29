"use client";
import { Radio as BaseRadio } from "@base-ui/react/radio";
import { RadioGroup } from "@base-ui/react/radio-group";
import type { ReactNode } from "react";
import { haptic } from "../haptics";

export type RadioOption = { value: string; label: ReactNode; description?: ReactNode; disabled?: boolean };

/** §7.21 radio group: 20 px circle (round is allowed here), 1 px ink.45, selected a 10 px ink.100 dot. */
export function Radios({ value, onValueChange, options, label, className = "", ...rest }: {
  value: string; onValueChange: (v: string) => void; options: RadioOption[]; label: string; className?: string; "data-gallery"?: string;
}) {
  return (
    <RadioGroup value={value} onValueChange={(v) => { haptic("select"); onValueChange(String(v)); }} aria-label={label} data-gallery={rest["data-gallery"]} className={`flex flex-col ${className}`}>
      {options.map((o) => <Radio key={o.value} {...o} />)}
    </RadioGroup>
  );
}

export function Radio({ value, label, description, disabled = false }: RadioOption) {
  return (
    <label className={`inline-flex min-h-(--mm-hit-min) items-center gap-3 ${disabled ? "text-ink-30" : "text-ink-100"}`}>
      <BaseRadio.Root value={value} disabled={disabled}
        className={`flex size-5 shrink-0 items-center justify-center rounded-round border transition-colors duration-(--mm-dur-snap) ${disabled ? "border-rule-1" : "border-ink-45 hover:border-ink-100 "}`}>
        <BaseRadio.Indicator keepMounted className="size-2.5 rounded-round bg-ink-100 transition-opacity duration-(--mm-dur-snap) data-[unchecked]:opacity-0" />
      </BaseRadio.Root>
      <span className="flex flex-col"><span className="type-ui">{label}</span>{description ? <span className="type-caption text-ink-45">{description}</span> : null}</span>
    </label>
  );
}
