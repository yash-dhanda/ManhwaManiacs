"use client";
import { useEffect, useState } from "react";
import { haptic } from "../haptics";
import { ArmButton } from "./ArmButton";
import { useArm } from "./useArm";

const REVERT_MS = 4000;

/** A destructive button that turns into "Confirm {verb}" with the arm, and reverts after 4000 ms without a press (§7.10). */
export function InlineConfirm({ verb, onConfirm, ...rest }: { verb: string; onConfirm: () => void; "data-gallery"?: string }) {
  const [asking, setAsking] = useState(false);
  const arm = useArm(asking);
  useEffect(() => {
    if (!asking) return;
    const t = setTimeout(() => setAsking(false), REVERT_MS);
    return () => clearTimeout(t);
  }, [asking]);
  if (!asking) {
    return (
      <button type="button" data-gallery={rest["data-gallery"]} onClick={() => setAsking(true)}
        className="type-label inline-flex min-h-12 min-w-(--mm-hit-min) items-center justify-center border border-proof px-5 text-proof hover:bg-proof-wash">{verb}</button>
    );
  }
  return (
    <ArmButton data-gallery={rest["data-gallery"]} phase={arm.phase} onPress={() => { if (!arm.canFire()) return; haptic("delete.confirm"); setAsking(false); onConfirm(); }}>{`Confirm ${verb.toLowerCase()}`}</ArmButton>
  );
}
