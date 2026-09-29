"use client";

import { useRef, useState } from "react";
import { useBudgetScope } from "../glass/budget";
import { GlassSurface } from "../glass/GlassSurface";
import { Icon, type IconName } from "./Icon";
import { useLit } from "./lit";
import { usePress, type PressState } from "./usePress";

export interface SplitButtonProps {
  /** e.g. "Continue, chapter 143" */
  label: string;
  icon?: IconName;
  onPress: () => void;
  /** accessible name of the trailing segment, e.g. "More ways to read" */
  moreLabel: string;
  /** the menu itself is the web/27 Menu, which blooms from this segment on `morph` */
  onMore: (anchor: HTMLElement) => void;
  menuOpen?: boolean;
  disabled?: boolean;
  forceState?: PressState;
  "data-testid"?: string;
}

/** One glass container: a tinted primary segment (padding 0 20) and a trailing `glassThin` 50 x 50 segment with `caret-down`, a 0.5 px separator between. Pressing either lights both, the pressed one more (16 % / 8 %). */
export function SplitButton({ label, icon, onPress, moreLabel, onMore, menuOpen, disabled, forceState, "data-testid": tid }: SplitButtonProps) {
  const box = useRef<HTMLElement | null>(null);
  const scope = useBudgetScope();
  const bEl = useRef<HTMLButtonElement | null>(null);
  const [active, setActive] = useState<"a" | "b" | null>(null);
  const a = usePress<HTMLButtonElement>({ material: "glass", growth: "medium", disabled, forceState, onPress, onPressStart: () => setActive("a"), onCancel: () => setActive(null), stretch: false });
  const b = usePress<HTMLButtonElement>({ material: "glass", growth: "medium", disabled, forceState, onPress: () => { if (bEl.current) onMore(bEl.current); }, forwardRef: bEl, onPressStart: () => setActive("b"), onCancel: () => setActive(null), stretch: false });
  const lit = useLit(() => box.current, scope.exempt, true);
  const done = (h: (e: React.PointerEvent<HTMLButtonElement>) => void) => (e: React.PointerEvent<HTMLButtonElement>) => { h(e); setActive(null); };
  return (
    <GlassSurface ref={box} tier="t2" capsule finish="regular" overContent className="g-split" data-lit-suppressed={lit.suppressed ? "" : undefined} data-active={active ?? undefined}>
      <button {...a.props} onPointerUp={done(a.props.onPointerUp)} type="button" className="g-split__a" data-testid={tid}>
        <span className="g-btn__inner">{icon ? <span className="g-icon"><Icon name={icon} size={20} /></span> : null}<span className="g-label type-headline">{label}</span></span>
      </button>
      <span className="g-split__sep" aria-hidden="true" />
      <button {...b.props} onPointerUp={done(b.props.onPointerUp)} type="button" className="g-split__b" aria-label={moreLabel} aria-haspopup="menu" aria-expanded={menuOpen ?? false} data-testid={tid ? `${tid}-more` : undefined}>
        <span className="g-icon"><Icon name="caret-down" size={20} /></span>
      </button>
    </GlassSurface>
  );
}
