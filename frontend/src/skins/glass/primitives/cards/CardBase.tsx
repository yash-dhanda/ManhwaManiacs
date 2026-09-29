"use client";

import type { CSSProperties, KeyboardEvent, ReactNode } from "react";
import { Icon } from "../Icon";
import { usePress, type PressState } from "../usePress";

export interface CardBaseProps {
  /** accessible name of the whole-card action */
  label: string;
  onPress?: () => void;
  /** "slab" (surface1 + slabBorder, radius 26, padding 12) or "bare" */
  slab?: "slab" | "bare";
  sink?: number;
  selectMode?: boolean;
  selected?: boolean;
  disabled?: boolean;
  disabledReason?: string;
  error?: boolean;
  forceState?: PressState;
  className?: string;
  style?: CSSProperties;
  onKeyDown?: (e: KeyboardEvent<HTMLElement>) => void;
  "data-testid"?: string;
  children: ReactNode;
}

/**
 * Cards sit on black or on the ambient field and are never glass. The card's own action is a full-cover button; controls inside
 * (Continue, chips, pin, more) sit above it. Hover lifts -2 px; pressed sinks (0.97 by default); focus draws the ring and scales 1.04;
 * selected draws a 2 px `iris500` inset ring and a check orb; disabled is 55 % with the reason in `caption1`.
 */
export function CardBase({ label, onPress, slab = "slab", sink = 0.97, selectMode, selected, disabled, disabledReason, error, forceState, className, style, onKeyDown, "data-testid": tid, children }: CardBaseProps) {
  const p = usePress<HTMLButtonElement>({ material: "content", sink, disabled, selected, error, forceState, haptic: selectMode ? "select" : "tap.primary", onPress: () => onPress?.() });
  return (
    <div className={`g-card${className ? ` ${className}` : ""}`} data-slab={slab} data-select-mode={selectMode ? "" : undefined} data-selected={selected ? "" : undefined} data-disabled={disabled ? "" : undefined} data-error={error ? "" : undefined} style={style} data-testid={tid}>
      <button {...p.props} ref={p.ref} type="button" className="g-card__main" aria-label={label} onKeyDown={onKeyDown} />
      <div className="g-card__body">{children}</div>
      {selectMode ? <span className="g-card__check" data-on={selected ? "" : undefined} aria-hidden="true">{selected ? <Icon name="check" size={16} weight="fill" /> : null}</span> : null}
      {disabled && disabledReason ? <p className="g-card__reason type-caption1">{disabledReason}</p> : null}
    </div>
  );
}
