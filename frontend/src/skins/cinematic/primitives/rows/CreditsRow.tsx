import type { ReactNode } from "react";
import { DotLeader } from "./DotLeader";

/** Credits row: label -> dot leaders -> value on one baseline; 40. */
export function CreditsRow({ label, value }: { label: ReactNode; value: ReactNode }) {
  return (
    <div className="flex min-h-10 items-baseline border-b border-rule-1 px-4 py-2">
      <span className="type-credit-label text-ink-60">{label}</span><DotLeader /><span className="type-credit text-ink-100">{value}</span>
    </div>
  );
}
