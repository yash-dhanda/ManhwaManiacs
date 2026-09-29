import { readerApi, type ChapterManifest } from "@/features/reader/api";
import { withPageWidth } from "@/features/reader/page-url";
import { PRIORITY } from "@/features/sources/discover-requests";
import { sourcesLimiter } from "@/features/sources/standins/request-limiter"; // TODO(web/03)
import type { ChapterId } from "@/types/api";

/** The chapter manifest a dialogue still needs to find its page URL (P1). */
export const fetchStillManifest = (ref: ChapterId, signal?: AbortSignal): Promise<ChapterManifest> =>
  sourcesLimiter.run(PRIORITY.chapterManifest, () => readerApi.manifest(ref), signal);

/** URL of page `page` (1-based) at 480 px wide, or null when the manifest has no such page. */
export function stillPageUrl(manifest: ChapterManifest | undefined, page: number | null): string | null {
  if (!manifest || page === null) return null;
  const hit = manifest.pages.find((p) => p.number === page) ?? manifest.pages[page - 1];
  return hit ? withPageWidth(hit.url, 480) : null;
}

export function pageAspect(manifest: ChapterManifest | undefined, page: number | null): number {
  const hit = manifest?.pages.find((p) => p.number === page);
  return hit?.width && hit?.height ? hit.width / hit.height : 0.7;
}
