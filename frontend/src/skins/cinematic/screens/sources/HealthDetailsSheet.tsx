"use client";

import type { SourceSummary } from "@/features/sources/types";
import { describeHealth } from "@/features/sources/health";
import { Sheet, kit as s } from "../kit/Kit";

export function HealthDetailsSheet({ source, onClose, now }: { source: SourceSummary | null; onClose: () => void; now: number }) {
  const h = source?.health ?? null;
  return (
    <Sheet open={source !== null} onClose={onClose} kicker="HEALTH" title={source?.name ?? ""}>
      <p className={s.caption}>{describeHealth(h, now).label}</p>
      <p className={s.caption}>Last OK: {h?.last_ok_at ? `${h.last_ok_at} UTC` : "never"}</p>
      <div className={s.mono}>{h?.last_error ?? "No error recorded."}</div>
    </Sheet>
  );
}
