"use client";

import { motion, useMotionValue } from "motion/react";
import { useEffect } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { isGlassReduced, play } from "../motion";
import { useOverlaySlot } from "./overlay-queue";

/** "A new version is ready" + "Reload" (web): bottom-centre above the dock on phones, bottom-centre of the content column on desktop. On desktop it waits while a bottom bar shows. */
export function AppUpdateCapsule({ onReload, show = true, "data-testid": tid }: { onReload: () => void; show?: boolean; "data-testid"?: string }) {
  const { allowed } = useOverlaySlot("update", show);
  const y = useMotionValue(40);
  const fade = useMotionValue(0);
  useEffect(() => {
    if (!allowed) { fade.set(0); return; }
    y.set(isGlassReduced() ? 0 : 40); play("toastFall", y, 0); play("materialise", fade, 1);
  }, [allowed, y, fade]);
  if (!allowed) return null;
  return (
    <motion.div className="g-capsule g-capsule--update" style={{ y, opacity: fade }} role="status" data-testid={tid ?? "update-capsule"}>
      <GlassSurface tier="t2" capsule layer="hud" materialize={false} className="g-capsule__glass">
        <div className="g-capsule__inner">
          <span className="g-capsule__text">A new version is ready</span>
          <button type="button" className="g-toast__action" onClick={onReload}>Reload</button>
        </div>
      </GlassSurface>
    </motion.div>
  );
}
