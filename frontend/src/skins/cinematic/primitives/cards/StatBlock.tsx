"use client";
import { GalleyNumeral } from "../Skeleton";

/** §7.6 stat block: 3 px rule.heavy on top, kicker, type.numeral value, caption. No frame; value changes cross-fade 160 ms. */
export function StatBlock({ kicker, value, caption, loading }: { kicker: string; value: string | number; caption?: string; loading?: boolean }) {
  return (
    <div className="flex flex-col gap-2" aria-busy={loading || undefined}>
      <div aria-hidden className="cine-rule h-[3px] w-full bg-ink-100" />
      <p className="type-kicker text-ink-45">{kicker}</p>
      {loading ? <GalleyNumeral /> : <p key={String(value)} className="type-numeral text-ink-100" style={{ animation: "cine-fade 160ms var(--mm-ease-settle) both" }}>{value}</p>}
      {caption ? <p className="type-caption text-ink-60">{caption}</p> : null}
    </div>
  );
}
