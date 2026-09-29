"use client";
import { useEffect, useState, type ReactNode } from "react";
import { Icon } from "../Icon";
import type { IconRole } from "../icons/roles.generated";
import { RuleDraw } from "../motion-components";
import { Button } from "./Button";
import { useDesktopFrame } from "./overlay-hooks";
import { TypedHeadline } from "./TypedHeadline";

export type NoticeTone = "empty" | "error" | "offline" | "caution" | "rateLimit";
const KICKER: Record<NoticeTone, string> = { empty: "EMPTY SHELF", error: "CORRECTION", offline: "OFFLINE EDITION", caution: "NOTE", rateLimit: "SLOW DOWN" };
const KICKER_TONE: Record<NoticeTone, string> = { empty: "text-ink-45", error: "text-proof", offline: "text-ink-45", caution: "text-spot", rateLimit: "text-ink-45" };

export type NoticeAction = { label: string; onPress: () => void };

/** "Retrying in 12 s" folio, counted down from `Retry-After` (ApiError.retryAfterMs). Calls `onDone` at zero. */
function useRetryCountdown(ms: number | null | undefined, onDone?: () => void) {
  const [left, setLeft] = useState(ms ? Math.ceil(ms / 1000) : 0);
  useEffect(() => {
    if (!ms) return;
    const t0 = performance.now();
    const id = setInterval(() => {
      const rest = Math.max(0, Math.ceil((ms - (performance.now() - t0)) / 1000));
      setLeft(rest);
      if (rest <= 0) { clearInterval(id); onDone?.(); }
    }, 250);
    return () => clearInterval(id);
  }, [ms, onDone]);
  return left;
}

/**
 * §7.23 one component for empty, error, offline, caution and rate-limit states, set like a short article. Never shows a count or
 * placeholder for 18+ content the gate hides (absence, never a lock).
 */
export function Notice({ tone, headline, deck, kicker, primary, quiet, glyph, page = false, retryAfterMs, onRetryElapsed, offlinePreset = false, ...rest }: {
  tone: NoticeTone; headline: string; deck?: ReactNode; kicker?: string; primary?: NoticeAction; quiet?: NoticeAction; glyph?: IconRole;
  /** The notice is the whole page: h1 and offset 15 vh from the top. */
  page?: boolean; retryAfterMs?: number | null; onRetryElapsed?: () => void;
  /** Global offline: adds "Saved chapters still open." and a Go to Downloads action. */
  offlinePreset?: boolean; "data-gallery"?: string;
}) {
  const desktop = useDesktopFrame();
  const left = useRetryCountdown(tone === "rateLimit" ? retryAfterMs : null, onRetryElapsed);
  const Tag = page ? "h1" : "h2";
  return (
    <section aria-labelledby={undefined} data-gallery={rest["data-gallery"]} data-tone={tone} role={tone === "error" ? "alert" : undefined}
      className="w-full frame:w-1/2" style={page ? { marginTop: "15vh" } : undefined}>
      <RuleDraw kind="heavy" />
      <div className="flex flex-col gap-3 pt-4">
        {glyph ? <Icon name={glyph} size={32} className="text-ink-45" /> : null}
        <p className={`type-kicker ${KICKER_TONE[tone]}`}>{kicker ?? KICKER[tone]}</p>
        <TypedHeadline as={Tag} text={headline} className={desktop ? "type-headline text-ink-100 [font-size:0.6em]" : "type-subhead text-ink-100"} />
        {deck || tone === "rateLimit" || offlinePreset ? (
          <p className="type-deck max-w-[48ch] text-ink-60">
            {deck}{deck && (tone === "rateLimit" && left > 0 || offlinePreset) ? " " : ""}
            {tone === "rateLimit" && left > 0 ? <span className="type-folio text-ink-100">{`Retrying in ${left} s`}</span> : null}
            {offlinePreset ? "Saved chapters still open." : null}
          </p>
        ) : null}
        {primary || quiet || offlinePreset ? (
          <div className="mt-2 flex flex-wrap items-center gap-3">
            {primary ? <Button variant="primary" onClick={primary.onPress}>{primary.label}</Button> : null}
            {offlinePreset && !primary ? <Button variant="primary" onClick={() => { window.location.assign("/downloads"); }}>Go to Downloads</Button> : null}
            {quiet ? <Button variant="quiet" onClick={quiet.onPress}>{quiet.label}</Button> : null}
          </div>
        ) : null}
      </div>
    </section>
  );
}
