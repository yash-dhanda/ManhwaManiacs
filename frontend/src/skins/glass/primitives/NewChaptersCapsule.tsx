"use client";
/* eslint-disable @next/next/no-img-element -- plain img: Glass covers and viewer frames are dev assets and CDN URLs sized by their frame */

import { motion, useMotionValue } from "motion/react";
import { useEffect } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { project } from "../physics/project";
import { Icon } from "./Icon";
import { useOverlaySlot } from "./overlay-queue";
import { springTo } from "./overlay-utils";

/**
 * A `glassRegular` capsule that drops in like a toast but stays until acted on: up to 3 covers, "5 new chapters in 3 series", a
 * "View" plain button and the toast close button. A swipe up or the close button dismisses it. Top-centre of the content column
 * on desktop (top 72), under the nav row on phones. It waits in the overlay queue (a menu, a toast).
 */
export function NewChaptersCapsule({ covers, text, onView, onDismiss, show = true, "data-testid": tid }: { covers: string[]; text: string; onView: () => void; onDismiss: () => void; show?: boolean; "data-testid"?: string }) {
  const { allowed } = useOverlaySlot("chapters", show);
  const y = useMotionValue(-60);
  const fade = useMotionValue(0);
  useEffect(() => {
    if (allowed) { y.set(isGlassReduced() ? 0 : -60); play("toastFall", y, 0); play("materialise", fade, 1); }
    else { fade.set(0); }
  }, [allowed, y, fade]);
  if (!allowed) return null;
  const leave = () => { springTo(y, -60, "dismiss", { onComplete: onDismiss }); play("dematerialise", fade, 0); };
  return (
    <motion.div className="g-capsule g-capsule--chapters" style={{ y, opacity: fade }} drag="y" dragConstraints={{ top: 0, bottom: 0 }} dragElastic={{ top: 0.8, bottom: 0.1 }} dragMomentum={false}
      onDragEnd={(_, i) => { if (project(y.get(), i.velocity.y) < -40) { haptic("tap.secondary"); leave(); } }} role="status" data-testid={tid ?? "chapters-capsule"}>
      <GlassSurface tier="t3" capsule layer="hud" materialize={false} className="g-capsule__glass">
        <div className="g-capsule__inner">
          <span className="g-capsule__covers" aria-hidden="true">{covers.slice(0, 3).map((c, i) => <img key={i} alt="" src={c} style={{ zIndex: 3 - i }} />)}</span>
          <span className="g-capsule__text">{text}</span>
          <button type="button" className="g-toast__action" onClick={() => { onView(); }}>View</button>
          <button type="button" className="g-toast__close" aria-label="Dismiss" onClick={leave}><Icon name="x" size={16} /></button>
        </div>
      </GlassSurface>
    </motion.div>
  );
}
