"use client";

import { useRef, type CSSProperties, type Ref } from "react";
import { CausticWrap } from "../glass/Caustic";
import { GlassSurface, type GlassTwin } from "../glass/GlassSurface";
import { Icon, type IconName } from "./Icon";
import { LiquidProgress } from "./LiquidProgress";
import { Dots, Spinner } from "./Progress";
import { Tooltip } from "./Tooltip";
import { useLit } from "./lit";
import { useErrorFlash } from "./useErrorFlash";
import { usePress, type PressState } from "./usePress";
import { announce } from "./announce";

export type ButtonVariant = "primary" | "secondary" | "plain" | "destructive" | "destructiveConfirm" | "progress";
export type ButtonSize = "L" | "M" | "S";
export type DownloadState = { status: "idle" } | { status: "queued" } | { status: "saving"; done: number; total: number } | { status: "done" } | { status: "failed" };

export interface ButtonProps {
  variant?: ButtonVariant;
  size?: ButtonSize;
  label: string;
  icon?: IconName;
  /** toggle buttons ("In library", "Following"): stays a secondary; the icon morphs Regular to Fill; NO aria-pressed (the visible label changes, WCAG 2.5.3) */
  selected?: boolean;
  onPress?: () => void;
  disabled?: boolean;
  /** tooltip on a disabled button: the reason */
  disabledReason?: string;
  loading?: boolean;
  /** short text such as "Couldn't save": swaps the label for 2 s, shake, assertive announcement */
  error?: string | null;
  /** secondary on a cover or photo: glassRegular */
  overMedia?: boolean;
  /** a button repeated per item takes twin="content" (2.4.1 rule 1) */
  twin?: GlassTwin;
  /** the tinted primary sits over content: adds the caustic */
  overContent?: boolean;
  /** variant "progress" (download) */
  download?: DownloadState;
  onRetry?: () => void;
  forceState?: PressState;
  ref?: Ref<HTMLButtonElement>;
  className?: string;
  "data-testid"?: string;
}

const HEIGHT = { L: 50, M: 44, S: 34 } as const;
const PAD = { L: 24, M: 20, S: 14 } as const;

export function Button({ variant = "secondary", size = "M", label, icon, selected, onPress, disabled, disabledReason, loading, error, overMedia, twin, overContent = true, download, onRetry, forceState, ref, className, "data-testid": tid }: ButtonProps) {
  const host = useRef<HTMLButtonElement | null>(null);
  const dl = download ?? { status: "idle" as const };
  const isProgress = variant === "progress";
  const failed = isProgress && dl.status === "failed";
  const busy = loading || (isProgress && (dl.status === "queued" || dl.status === "saving"));
  const p = usePress<HTMLButtonElement>({
    material: variant === "plain" ? "content" : "glass", growth: "medium", sink: 0.96,
    disabled, loading: busy && !isProgress, selected, error: !!error || failed, forceState,
    haptic: selected === undefined ? (isProgress ? (dl.status === "idle" ? "download.start" : false) : "tap.primary") : selected ? "toggle.off" : "toggle.on",
    onPress: () => (failed ? onRetry?.() : onPress?.()),
  });
  const lit = useLit(p.ref, false, variant === "primary");
  const { flashing, text } = useErrorFlash(error, p.ref, 8);
  const setRef = (el: HTMLButtonElement | null) => { p.ref.current = el; host.current = el; if (typeof ref === "function") ref(el); else if (ref) (ref as { current: HTMLButtonElement | null }).current = el; };

  const glassy = variant !== "plain" && variant !== "destructiveConfirm";
  const tinted = variant === "primary" && !lit.suppressed;
  const onTint = tinted;
  const shownLabel = flashing ? text : isProgress ? progressLabel(dl) : label;
  const glyphName: IconName | undefined = flashing || failed ? "warning-circle" : isProgress ? (dl.status === "done" ? "check" : dl.status === "idle" ? "cloud-arrow-down" : undefined) : icon;
  const danger = flashing || failed || variant === "destructive";
  const glyph = glyphName ? (
    <span className="g-icon">
      {danger && glassy ? <span className="g-disc" data-small=""><Icon name={variant === "destructive" && !flashing && !failed ? (icon ?? "trash") : glyphName} size={16} color="var(--mm-color-danger)" /></span>
        : <Icon name={glyphName} size={20} weight={selected ? "fill" : "regular"} />}
    </span>
  ) : null;
  const spinner = isProgress && (dl.status === "queued" || dl.status === "saving") ? <Spinner size={16} /> : null;
  const type = size === "S" ? "type-subhead" : "type-headline";
  const reason = disabled && disabledReason ? disabledReason : undefined;
  const value = dl.status === "saving" ? dl.done / Math.max(1, dl.total) : dl.status === "queued" ? 0.02 : dl.status === "done" ? 1 : 0;

  const content = (
    <>
      {isProgress ? <LiquidProgress value={value} tone={dl.status === "done" ? "success" : "iris"} /> : null}
      {selected ? <span className="g-wipe" aria-hidden="true" /> : null}
      <span className="g-btn__row" data-busy={loading ? "" : undefined}>
        {loading ? <Dots className="g-btn__dots" /> : null}
        <span className="g-btn__inner">
          {glyph}{spinner}
          <span className={`g-label ${type}`}>{shownLabel}{isProgress && dl.status === "saving" ? <span className="type-mono g-count"> {dl.done}/{dl.total}</span> : null}</span>
        </span>
      </span>
    </>
  );
  const style = { "--btn-h": `${HEIGHT[size]}px`, "--btn-pad": `${PAD[size]}px` } as CSSProperties;
  const aria: Record<string, unknown> = {};
  if (isProgress && dl.status === "saving") { aria.role = "progressbar"; aria["aria-valuemin"] = 0; aria["aria-valuemax"] = 100; aria["aria-valuenow"] = Math.round(value * 100); aria["aria-valuetext"] = `${dl.done} of ${dl.total} pages saved`; }
  const button = (
    <button
      {...p.props} {...aria} ref={setRef} type="button" data-testid={tid}
      className={`g-btn${className ? ` ${className}` : ""}`} data-variant={variant} data-size={size} data-tinted={tinted ? "" : undefined}
      style={style} onClick={(e) => { p.props.onClick(e); if (failed && e.detail === 0) announce("Retrying"); }}
    >
      {glassy ? (
        <GlassSurface as="span" tier={overMedia ? "t3" : "t2"} finish={tinted ? "tinted" : "regular"} capsule twin={twin} pressedGlow={p.glow} overContent={overContent} layer="controls" className="g-btn__glass" data-disabled={disabled ? "" : undefined}>
          {content}
        </GlassSurface>
      ) : (
        <span className="g-btn__glass g-btn__flat">{content}</span>
      )}
    </button>
  );
  const wrapped = tinted && overContent ? <CausticWrap pressed={p.pressed} className="g-btn-wrap">{button}</CausticWrap> : button;
  void onTint;
  return <Tooltip label={reason} disabled={!reason}>{wrapped}</Tooltip>;
}

function progressLabel(d: DownloadState): string {
  switch (d.status) {
    case "idle": return "Download";
    case "queued": return "Queued";
    case "saving": return "Saving";
    case "done": return "Saved";
    case "failed": return "Retry";
  }
}
