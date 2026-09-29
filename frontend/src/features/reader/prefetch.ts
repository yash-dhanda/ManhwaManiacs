import { sourcesLimiter, type Priority } from "@/features/sources/request-limiter";
import { readerApi } from "./api";

const warmed = new Set<string>();

/**
 * Warm the start of a chapter before the reader opens it: the manifest, then the first two pages, through the sources limiter.
 * P3 for a hover or focus dwell, P1 on press. Skin-neutral; idempotent per chapter and priority band.
 */
export async function prefetchChapterStart(ref: { sourceId: string; seriesKey: string; chapterKey: string }, priority: Priority = "P3"): Promise<void> {
  const key = `${ref.sourceId}\u0000${ref.seriesKey}\u0000${ref.chapterKey}\u0000${priority === "P1" ? 1 : 3}`;
  if (warmed.has(key)) return;
  warmed.add(key);
  try {
    const manifest = await sourcesLimiter.run(priority, () => readerApi.manifest(ref));
    for (const p of manifest.pages.slice(0, 2)) {
      if (typeof Image === "undefined") break;
      const img = new Image();
      img.decoding = "async";
      img.src = p.url;
    }
  } catch {
    warmed.delete(key); // a failed warm may be retried; the reader itself is unaffected
  }
}
