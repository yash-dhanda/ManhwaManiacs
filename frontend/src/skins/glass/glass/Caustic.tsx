"use client";

import { useEffect, useRef, type ReactNode } from "react";
import { isGlassReduced } from "../motion";
import { MOTION_LABELS } from "../motion.generated";
import { beginRecord, trackFrames } from "../motion-recorder";

/**
 * Wraps the ONE lit (tinted) object (DESIGN 2.4.4). Its ::before, below the glass, is a blurred iris ellipse
 * offset 8 px along the light direction; 14 % at rest, 22 % pressed. The wrapper must not create a stacking
 * context (no isolation, opacity, transform or filter) or the screen blend has nothing to blend with.
 */
export function CausticWrap({ pressed = false, suppressed = false, overContent = true, className, children }: { pressed?: boolean; /** lit object suppressed by a sheet or alert: fades the caustic out over 180 ms */ suppressed?: boolean; overContent?: boolean; className?: string; children: ReactNode }) {
  return (
    <div className={`caustic${className ? ` ${className}` : ""}`} data-pressed={pressed && !isGlassReduced() ? "on" : undefined} data-over-content={overContent ? undefined : "false"} data-suppressed={suppressed ? "" : undefined}>
      {children}
    </div>
  );
}

/** Ring that plays with follow.add: from the origin element out to the band's far corner. Reduced motion: none. */
export function FollowRing({ origin, className }: { origin: { x: number; y: number } | null; className?: string }) {
  const band = useRef<HTMLDivElement>(null);
  const ring = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    const b = band.current, r = ring.current;
    if (!origin || !b || !r || isGlassReduced()) return;
    const { width, height } = b.getBoundingClientRect();
    const far = Math.max(Math.hypot(origin.x, origin.y), Math.hypot(width - origin.x, origin.y), Math.hypot(origin.x, height - origin.y), Math.hypot(width - origin.x, height - origin.y));
    r.style.left = `${origin.x}px`;
    r.style.top = `${origin.y}px`;
    const size = (radius: number) => `${radius * 2}px`;
    const anim = r.animate(
      [
        { width: size(0), height: size(0), borderWidth: "2px", borderColor: "rgb(188 176 255 / 0.30)" },
        { width: size(far), height: size(far), borderWidth: "24px", borderColor: "rgb(188 176 255 / 0)" },
      ],
      { duration: 700, easing: "cubic-bezier(0.2, 0, 0, 1)", fill: "both" },
    );
    const finish = trackFrames(beginRecord("followRing", MOTION_LABELS.followRing, 700));
    anim.onfinish = finish;
    return () => { anim.cancel(); finish(); };
  }, [origin]);
  return (
    <div ref={band} className={`follow-band${className ? ` ${className}` : ""}`} aria-hidden="true">
      <span ref={ring} className="follow-ring" />
    </div>
  );
}
