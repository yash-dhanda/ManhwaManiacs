"use client";
import { useId, type MouseEvent, type ReactNode } from "react";
import { MaybeTip } from "./Tooltip";
import { Icon } from "../Icon";
import type { IconRole } from "../icons/roles.generated";
import { haptic } from "../haptics";
import { playSound } from "../sounds";
import { useDelayedFlag } from "../motion";
import { folioLabelJoin } from "../a11y/folio";
import { Glyph } from "./glyphs";
import { useHold, useRootScale } from "./hooks";

export type ButtonVariant = "primary" | "split" | "secondary" | "quiet" | "destructive" | "on-art" | "play" | "link";
export type ButtonSize = "lg" | "md" | "sm";

export type ButtonProps = {
  variant?: ButtonVariant;
  size?: ButtonSize;
  children?: ReactNode;
  icon?: IconRole;
  /** Split button: the right-hand folio, e.g. "CH 143 · p.12". */
  folio?: string;
  loading?: boolean;
  /** Present participle shown after 400 ms of loading ("Signing in…"). */
  loadingLabel?: string;
  /** Toggle buttons ("Following"). */
  selected?: boolean;
  /** Error line in words; colours the control for 2000 ms. */
  error?: string;
  disabled?: boolean;
  /** Tooltip-style reason when not obvious (rendered as title-less aria-description). */
  disabledReason?: string;
  playing?: boolean;
  type?: "button" | "submit";
  className?: string;
  ariaLabel?: string;
  onClick?: (e: MouseEvent<HTMLButtonElement>) => void;
  "data-gallery"?: string;
};

const SIZE_H = { lg: "min-h-[56px]", md: "min-h-12 frame:min-h-11", sm: "min-h-8" } as const;
const PLAY = { lg: 64, md: 56, sm: 36 } as const;

function face(v: ButtonVariant, o: { selected: boolean; disabled: boolean; error: boolean }) {
  if (o.disabled) {
    if (v === "primary" || v === "split") return "bg-paper-3 text-ink-30";
    return "border border-ink-30 text-ink-30";
  }
  if (o.error) return v === "primary" || v === "split" ? "bg-proof text-paper-0" : "border border-proof text-proof";
  switch (v) {
    case "primary": case "split": return "bg-ink-100 text-paper-0 active:bg-ink-80";
    case "secondary": return o.selected ? "bg-ink-100 text-paper-0 border border-ink-100" : "border border-ink-100 text-ink-100 hover:bg-paper-4 active:bg-paper-3";
    case "quiet": return "text-ink-60 hover:underline hover:underline-offset-4";
    case "destructive": return "border border-proof text-proof hover:bg-proof-wash active:bg-proof-press active:text-paper-0";
    case "on-art": return "bg-onart border border-ink-100/40 text-ink-100";
    case "play": return "bg-ink-100 text-paper-0 rounded-round";
    case "link": return "type-body text-ink-100 underline underline-offset-[3px]";
  }
}

/** §7.1. The face is the visual box; the button around it carries the 44 px (32 fine pointer) hit area. */
export function Button({ variant = "primary", size = "md", children, icon, folio, loading, loadingLabel, selected = false, error, disabled, disabledReason, playing, type = "button", className = "", ariaLabel, onClick, ...rest }: ButtonProps) {
  const showLoadingLabel = useDelayedFlag(400, !!loading);
  const errHeld = useHold(error, 2000);
  const scale = useRootScale();
  const isPlay = variant === "play";
  const stacked = variant === "split" && scale >= 1.5;
  const label = loading && showLoadingLabel && loadingLabel ? loadingLabel : children;
  const off = !!disabled;
  const accessible = ariaLabel ?? (variant === "split" && folio && typeof children === "string" ? folioLabelJoin(children, folio) : undefined);
  const reasonId = useId();
  const withRule = variant === "primary" || variant === "split";
  return (
    <span className={`inline-flex flex-col ${className}`}>
      {off && disabledReason ? <span id={reasonId} className="sr-only">{disabledReason}</span> : null}
      <MaybeTip reason={off ? disabledReason : undefined}><button
        type={type}
        aria-disabled={off || undefined}
        aria-busy={loading || undefined}
        aria-pressed={selected && variant === "secondary" ? true : undefined}
        aria-label={accessible}
        aria-describedby={off && disabledReason ? reasonId : undefined}
        disabled={off && !disabledReason ? true : undefined}
        data-gallery={rest["data-gallery"]} data-clickable={off ? undefined : ""}
        onClick={(e) => {
          if (off || loading) { e.preventDefault(); return; }
          if (variant === "primary" || variant === "split") { haptic("tap.primary"); playSound("tap.primary"); }
          onClick?.(e);
        }}
        className={`cine-hoverable relative inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center transition-transform duration-(--mm-dur-beat) ease-settle active:translate-y-px active:duration-(--mm-dur-tick) ${off ? "cursor-default" : ""}`}
      >
        <span className={`type-label relative inline-flex ${isPlay ? "items-center justify-center" : "items-center"} gap-2 px-5 ${isPlay ? "" : SIZE_H[size]} ${face(variant, { selected, disabled: off, error: errHeld })} ${variant === "quiet" || variant === "link" ? "px-1" : ""} ${stacked ? "flex-col py-2" : ""}`}
          style={isPlay ? { width: PLAY[size], height: PLAY[size], padding: 0 } : undefined}>
          {isPlay ? <PlayGlyph playing={!!playing} /> : (
            <>
              {(selected && variant === "secondary") || icon ? (selected && variant === "secondary" ? <Glyph name="check" size={20} /> : <Icon name={icon!} size={20} />) : null}
              <span className="inline-flex items-center gap-1 transition-opacity duration-(--mm-dur-beat)">{label}</span>
              {variant === "split" && folio && !off ? (
                <>
                  <span aria-hidden className={`${stacked ? "h-px w-full" : "h-5 w-px"} bg-paper-0`} />
                  <span aria-hidden className="type-folio text-paper-0">{folio}</span>
                </>
              ) : null}
            </>
          )}
          {loading ? (
            <span aria-hidden className="absolute inset-x-0 bottom-0 h-0.5 overflow-hidden">
              <span className="animate-loop-rule block h-full w-1/4 bg-spot" />
            </span>
          ) : null}
          {withRule && !off ? <span aria-hidden className="cine-hover-rule absolute inset-x-0 h-0.5 bg-spot" style={{ bottom: -6 }} /> : null}
        </span>
      </button></MaybeTip>
      {error && errHeld ? <span role="alert" className="type-caption mt-2 text-proof">{error}</span> : null}
    </span>
  );
}

function PlayGlyph({ playing }: { playing: boolean }) {
  return <Icon name={playing ? "pause" : "play"} size={28} filled className="" />;
}
