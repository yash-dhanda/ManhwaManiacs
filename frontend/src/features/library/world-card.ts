import type { WorldItem } from "./types";

/**
 * What a world-recommendation card says and where it goes, kept out of the
 * component so each rule can be tested.
 *
 * The one decision that matters: a title one of the reader's sources carries
 * opens that source's series page; a title none carries opens nothing, and
 * offers a search and the official platform instead of a dead tap.
 */

/** The first carrying source's series page, or null when no source has it. */
export function worldSeriesHref(item: Pick<WorldItem, "available">): string | null {
  const first = item.available[0];
  if (!first) return null;
  return `/sources/${first.source_id}/series/${encodeURIComponent(first.series_key)}`;
}

/** "On: Asura Scans", "On: Asura Scans +2 more", or "Not on your sources". */
export function worldAvailabilityLabel(item: Pick<WorldItem, "available">): string {
  const [first, ...rest] = item.available;
  if (!first) return "Not on your sources";
  return rest.length > 0
    ? `On: ${first.source_name} +${rest.length} more`
    : `On: ${first.source_name}`;
}

/** The app's normal global search for this title. */
export function worldSearchHref(title: string): string {
  return `/search?q=${encodeURIComponent(title)}`;
}

/** "Manhwa · Ongoing", either half alone, or null when both are unknown. */
export function worldBadgeLine(item: Pick<WorldItem, "format" | "status">): string | null {
  return [item.format, item.status].filter(Boolean).join(" · ") || null;
}

/** "181 ch", or null when the latest chapter is unknown. */
export function worldChaptersLabel(chapters: number | null): string | null {
  return chapters == null ? null : `${chapters} ch`;
}

/** "★ 8.1", or null when unrated. */
export function worldRatingLabel(rating: number | null): string | null {
  return rating == null ? null : `★ ${rating.toFixed(1)}`;
}

/**
 * The first official platform as an outbound link ("Read on Webtoon").
 *
 * Only http(s): the URL comes from a third-party catalogue and lands in an
 * `href`, where a `javascript:` value would run on click.
 */
export function worldPlatformLink(
  item: Pick<WorldItem, "platforms">,
): { label: string; url: string } | null {
  const platform = item.platforms.find((p) => /^https?:\/\//i.test(p.url));
  return platform ? { label: `Read on ${platform.site}`, url: platform.url } : null;
}
