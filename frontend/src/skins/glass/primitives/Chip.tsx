"use client";

import { animate } from "motion/react";
import { useCallback, useRef, useState, type ReactNode } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { spring } from "../tokens.generated";
import { Icon, type IconName } from "./Icon";
import { Spinner } from "./Progress";
import { Tooltip } from "./Tooltip";
import { usePress, type PressState } from "./usePress";

export type ChipKind = "filter" | "choice" | "count" | "input" | "assist" | "tag";

export interface ChipProps {
  kind?: ChipKind;
  label: string;
  glyph?: IconName;
  selected?: boolean;
  onPress?: () => void;
  /** count chip: "Pinned 4" */
  count?: number;
  /** input chip: the trailing x (hit 44 x 44, extending beyond the chip) */
  onRemove?: () => void;
  disabled?: boolean;
  loading?: boolean;
  /** error: the glyph becomes a `warning-circle` in `danger` and the tooltip explains */
  error?: string;
  /** tag as a link */
  href?: string;
  forceState?: PressState;
  "data-testid"?: string;
  /** used by ChipRow: the choice chip draws no glass of its own, the shared droplet does */
  droplet?: boolean;
  ref?: React.Ref<HTMLElement>;
}

/**
 * Chips live in scrolling rows, so the selected filter chip's glass, the assist chip's rim and the choice droplet are CONTENT TWINS
 * (2.4.1 rule 1): same capsule, rim and inner light, no backdrop read. 32 tall inside a 44 tall hit box.
 */
export function Chip({ kind = "filter", label, glyph, selected, onPress, count, onRemove, disabled, loading, error, href, forceState, droplet, "data-testid": tid, ref }: ChipProps) {
  const own = useRef<HTMLButtonElement | null>(null);
  const setBoth = useCallback((el: HTMLButtonElement | null) => { own.current = el; if (typeof ref === "function") ref(el as HTMLElement | null); else if (ref) (ref as { current: HTMLElement | null }).current = el; }, [ref]);
  const p = usePress<HTMLButtonElement>({ material: "content", sink: 0.96, disabled, loading: false, selected, error: !!error, forceState, haptic: "select", onPress: () => onPress?.(), forwardRef: setBoth });
  const [removing, setRemoving] = useState(false);

  if (kind === "tag") {
    const Tag = href ? "a" : "span";
    return <Tag className="g-chip g-chip--tag" data-kind="tag" href={href} data-press={href ? "content" : undefined} data-testid={tid}>{label}</Tag>;
  }
  const lead = error ? <span className="g-chip__glyph" style={{ color: "var(--mm-color-danger)" }}><Icon name="warning-circle" size={16} /></span>
    : selected && kind === "filter" ? <span className="g-chip__glyph g-chip__check"><Icon name="check" size={16} weight="fill" /></span>
    : glyph ? <span className="g-chip__glyph"><Icon name={glyph} size={16} /></span> : null;
  const twin = (selected && (kind === "filter" || kind === "count")) || kind === "assist";
  const inner = (
    <>
      {twin ? <GlassSurface as="span" twin="content" tier="t2" capsule finish="regular" className="g-chip__glass" data-outline={kind === "assist" ? "" : undefined} aria-hidden="true" /> : null}
      <span className="g-chip__label">
        {lead}
        <span className="g-label">{label}</span>
        {kind === "count" ? loading ? <Spinner size={12} /> : <span className="g-chip__count type-mono">{count}</span> : null}
      </span>
    </>
  );
  const button = (
    <button
      {...p.props} type="button" className="g-chip" data-kind={kind} data-droplet={droplet ? "" : undefined} data-removing={removing ? "" : undefined} data-testid={tid}
      role={kind === "choice" ? "radio" : undefined} aria-checked={kind === "choice" ? !!selected : undefined} aria-pressed={kind === "filter" || kind === "count" ? !!selected : undefined}
    >
      {inner}
    </button>
  );
  if (kind === "input") {
    const remove = () => {
      const el = own.current?.parentElement;
      if (!el) return onRemove?.();
      setRemoving(true);
      animate(el, { scale: 0.6, opacity: 0 }, { ...spring.dismiss, onComplete: () => onRemove?.() } as never);
    };
    return (
      <span className="g-chip-input" data-removing={removing ? "" : undefined}>
        {button}
        <button type="button" className="g-chip__x" aria-label={`Remove ${label}`} onClick={remove}><Icon name="x" size={16} /></button>
      </span>
    );
  }
  return error ? <Tooltip label={error}>{button}</Tooltip> : button;
}
export type { ReactNode };
