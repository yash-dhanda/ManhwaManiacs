export interface TrendingItem {
  title: string;
  sourceId: string;
  seriesKey: string;
}

export interface PopularPageItem {
  id: string;
  title: string;
}

const PER_SOURCE = 2;
const CAP = 10;

/** First two titles per pinned source (pin order), de-duplicated by case-folded title, max 10. */
export function buildTrending(
  pagesBySource: ReadonlyArray<{ sourceId: string; items: readonly PopularPageItem[] | null | undefined }>,
): TrendingItem[] {
  const seen = new Set<string>();
  const out: TrendingItem[] = [];
  for (const { sourceId, items } of pagesBySource) {
    let taken = 0;
    for (const item of items ?? []) {
      if (taken >= PER_SOURCE || out.length >= CAP) break;
      const key = item.title.trim().toLowerCase();
      if (!key || seen.has(key)) continue;
      seen.add(key);
      out.push({ title: item.title, sourceId, seriesKey: item.id });
      taken += 1;
    }
  }
  return out;
}
