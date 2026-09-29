"use client";

import { useEffect } from "react";
import { animate, motion, useMotionValue } from "motion/react";
import { isGlassReduced } from "../motion";
import { spring } from "../tokens.generated";
import { Icon } from "./Icon";

/** Lists and select mode: a 24 px circle, iris600 fill, white check, springing in from scale 0 on `tick`. Unselected shows only a hairline ring. */
export function SelectionCheck({ selected, className }: { selected: boolean; className?: string }) {
  const s = useMotionValue(selected ? 1 : 0);
  useEffect(() => {
    if (isGlassReduced()) { s.set(selected ? 1 : 0); return; }
    const c = animate(s, selected ? 1 : 0, { ...spring.tick } as never);
    return () => c.stop();
  }, [selected, s]);
  return (
    <span className={`g-selcheck${className ? ` ${className}` : ""}`} data-selected={selected ? "" : undefined} aria-hidden="true">
      <motion.span className="g-selcheck__fill" style={{ scale: s }}><Icon name="check" size={16} weight="regular" color="#fff" /></motion.span>
    </span>
  );
}
