"use client";

import { LayoutGroup, motion, motionValue } from "motion/react";
import { Children, useCallback, useEffect, useLayoutEffect, useMemo, useRef, type KeyboardEvent, type ReactNode } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { spring } from "../tokens.generated";
import { Chip } from "./Chip";
import type { IconName } from "./Icon";
import { dropletStretch, keyTarget } from "./segmented-math";

export interface ChoiceOption { value: string; label: string; glyph?: IconName }
export interface ChipRowProps {
  label: string;
  /** any chips (filter, count, input, assist, tag) */
  children?: ReactNode;
  /** single-select group: the selected chip sits under one shared droplet (a content twin) that slides on `tab` and stretches with velocity */
  choice?: { options: readonly ChoiceOption[]; value: string; onChange: (value: string) => void };
}

/** Scrolls horizontally with momentum, rubber-bands where the platform does, masks its trailing 24 px, never snaps, pads 8 px vertically so focus rings are never clipped. */
export function ChipRow({ label, children, choice }: ChipRowProps) {
  const scroller = useRef<HTMLDivElement>(null);
  const drop = useRef<HTMLSpanElement>(null);
  const chips = useRef<(HTMLElement | null)[]>([]);
  const x = useMemo(() => motionValue(0), []);
  const w = useMemo(() => motionValue(0), []);
  const placed = useRef(false);
  const idx = choice ? Math.max(0, choice.options.findIndex((o) => o.value === choice.value)) : 0;

  const paint = useCallback(() => {
    const el = drop.current;
    if (!el) return;
    const { sx, sy } = isGlassReduced() ? { sx: 1, sy: 1 } : dropletStretch(x.getVelocity());
    el.style.transform = `translateX(${x.get()}px) scale(${sx}, ${sy})`;
    el.style.width = `${w.get()}px`;
  }, [x, w]);
  useEffect(() => { const a = x.on("change", paint), b = w.on("change", paint); return () => { a(); b(); }; }, [x, w, paint]);
  useLayoutEffect(() => {
    if (!choice) return;
    const c = chips.current[idx];
    if (!c) return;
    const tx = c.offsetLeft, tw = c.offsetWidth;
    if (!placed.current) { x.set(tx); w.set(tw); placed.current = true; paint(); return; }
    const a = play("tabDroplet", x, tx), b = play("tabDroplet", w, tw);
    return () => { a.stop(); b.stop(); };
  }, [choice, idx, x, w, paint]);

  const onKey = (e: KeyboardEvent<HTMLDivElement>) => {
    if (!choice) return;
    const t = keyTarget(e.key, idx, choice.options.length);
    if (t === null) return;
    e.preventDefault();
    chips.current[t]?.focus();
    if (t !== idx) { haptic("select"); choice.onChange(choice.options[t].value); }
  };
  return (
    <div className="g-chiprow" role={choice ? "radiogroup" : "group"} aria-label={label} onKeyDown={onKey}>
      <div ref={scroller} className="g-chiprow__scroll">
        <LayoutGroup>
          {choice ? (
            <>
              <span ref={drop} className="g-chiprow__drop" aria-hidden="true">
                <GlassSurface as="span" twin="content" tier="t1" finish="clear" capsule materialize={false} className="g-chip__glass" />
              </span>
              {choice.options.map((o, i) => (
                <Chip key={o.value} ref={(el) => { chips.current[i] = el; }} kind="choice" droplet label={o.label} glyph={o.glyph} selected={o.value === choice.value} onPress={() => choice.onChange(o.value)} />
              ))}
            </>
          ) : (
            Children.map(children, (c, i) => <motion.span layout transition={spring.snappy} key={i} className="g-chiprow__item">{c}</motion.span>)
          )}
        </LayoutGroup>
      </div>
    </div>
  );
}
