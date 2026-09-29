import type { RequestLimiter, Ticket } from "@/features/sources/request-limiter";

/** Local images skip the sources limiter (§15.6). */
export const isLocalImage = (src: string) => /^(\/gallery\/|\/skin-preview\/|data:|blob:)/.test(src);

/** The nearest snapped width >= cssWidth x dpr, from the ladder of §7.7. */
export const COVER_LADDER = [96, 160, 240, 360, 480, 720] as const;
export function snapCoverWidth(cssWidth: number, dpr: number): number {
  const want = cssWidth * dpr;
  return COVER_LADDER.find((w) => w >= want) ?? COVER_LADDER[COVER_LADDER.length - 1];
}

/**
 * Covers are P2 in the sources limiter: wait for a grant before assigning `src`; refund when the resource timing says the
 * response came from a local cache (transferSize 0). Abort the wait if the image leaves the viewport first.
 */
export async function acquireCover(limiter: Pick<RequestLimiter, "acquire">, signal?: AbortSignal): Promise<Ticket> {
  return limiter.acquire("P2", signal);
}

/** A grant is taken once per src; after it lands (`grant.src === src`) the effect must not run `start()` again. */
export const needsGrant = (grant: { src: string } | null, src: string) => grant?.src !== src;

/** Resource timing keys are absolute URLs, so a relative proxy URL is resolved first. */
export const timingKey = (url: string, base = typeof location === "undefined" ? "http://localhost/" : location.href) => new URL(url, base).href;

export function refundIfCached(limiter: Pick<RequestLimiter, "refund">, ticket: Ticket, url: string, entries: (name: string) => PerformanceEntryList = (n) => performance.getEntriesByName(n), base?: string): boolean {
  const last = entries(timingKey(url, base)).at(-1) as PerformanceResourceTiming | undefined;
  if (last && last.transferSize === 0) { limiter.refund(ticket); return true; }
  return false;
}
