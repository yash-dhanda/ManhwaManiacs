"use client";
import { Switch as BaseSwitch } from "@base-ui/react/switch";
import { useEffect, useState, type ReactNode } from "react";
import { haptic } from "../haptics";
import { playSound } from "../sounds";
import { LeaderDial } from "./Progress";
import { MaybeTip } from "./Tooltip";

/**
 * §7.21 slug switch: 44 x 24, 1 px ink.45 outline, 16 x 16 knob inset 4 px. On: spot track, black knob at the right.
 * `loading` (server-backed): the knob becomes a 12 px leader dial. `error`: outline proof for 2000 ms; the caller reverts `checked`.
 */
export function Switch({ checked, onCheckedChange, label, description, disabled = false, disabledReason, loading = false, error, hideLabel = false, className = "", ...rest }: {
  checked: boolean; onCheckedChange: (next: boolean) => void; label: ReactNode; description?: ReactNode;
  disabled?: boolean; disabledReason?: string; loading?: boolean; error?: string; hideLabel?: boolean; className?: string; "data-gallery"?: string;
}) {
  const [flash, setFlash] = useState(false);
  useEffect(() => {
    if (!error) return;
    setFlash(true); // eslint-disable-line react-hooks/set-state-in-effect -- 2000 ms error outline
    const t = setTimeout(() => setFlash(false), 2000);
    return () => clearTimeout(t);
  }, [error]);
  const soft = disabled && !!disabledReason; // aria-disabled stays focusable so the tooltip opens
  const off = (disabled && !soft) || loading;
  const outline = disabled ? "border-rule-1" : flash ? "border-proof" : "border-ink-45 hover:border-ink-100";
  const knob = disabled ? "bg-ink-30" : checked ? "bg-paper-0" : "bg-ink-45";
  return (
    <div className={className}>
      <label className={`inline-flex min-h-(--mm-hit-min) items-center gap-3 ${disabled ? "text-ink-30" : "text-ink-100"}`}>
        <MaybeTip reason={soft ? disabledReason : undefined}><BaseSwitch.Root
          checked={checked} disabled={off} readOnly={soft || undefined} aria-disabled={soft || undefined} aria-busy={loading || undefined} data-gallery={rest["data-gallery"]}
          onCheckedChange={(v) => { haptic(v ? "toggle.on" : "toggle.off"); playSound(v ? "toggle.on" : "toggle.off"); onCheckedChange(v); }}
          className={`group relative inline-block h-6 w-11 shrink-0 border transition-colors duration-(--mm-dur-beat) ${outline} ${checked && !disabled ? "bg-spot " : ""}`}
        >
          <BaseSwitch.Thumb
            className={`absolute top-1 left-1 flex h-4 w-4 items-center justify-center transition-[transform,width,background-color] duration-(--mm-dur-beat) ease-set group-active:w-5 ${knob} data-[checked]:translate-x-[22px] data-[checked]:group-active:translate-x-[18px]`}
          >
            {loading ? <span className="bg-paper-0"><LeaderDial size={12} immediate /></span> : null}
          </BaseSwitch.Thumb>
        </BaseSwitch.Root></MaybeTip>
        <span className={hideLabel ? "sr-only" : "flex flex-col"}>
          <span className="type-ui">{label}</span>
          {description && !hideLabel ? <span className="type-caption text-ink-45">{description}</span> : null}
        </span>
      </label>
      {error && flash ? <p role="alert" className="type-caption text-proof">{error}</p> : null}
    </div>
  );
}
