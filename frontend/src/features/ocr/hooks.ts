import { useInfiniteQuery, useQuery } from "@tanstack/react-query";
import { http } from "@/services/http";
import type { ChapterId } from "@/types/api";
import { ApiError } from "@/types/api";
import { ocrApi } from "./api";
import { sourcesLimiter } from "@/features/sources/standins/request-limiter"; // TODO(web/03)

const p1 = <T,>(task: () => Promise<T>) => sourcesLimiter.run("P1", task);

const OCR_KEY = ["ocr"] as const;

/**
 * Dialogue search over extracted OCR text. Disabled (no request) until a
 * non-empty query is supplied; callers should debounce the raw input before
 * passing it here so keystrokes don't each fire a request.
 */
export function useOcrSearch(query: string) {
  const q = query.trim();
  return useQuery({
    queryKey: [...OCR_KEY, "search", q],
    queryFn: () => p1(() => ocrApi.search({ q, limit: 20 })),
    enabled: q.length > 0,
  });
}

/**
 * Stored per-page OCR text for one chapter, for the in-reader dialogue reveal.
 * Read-only: a 404 (no transcript yet) resolves to `null` rather than erroring,
 * so the feature is simply off for that chapter.
 */
export function useOcrChapter(ref: ChapterId | null) {
  return useQuery({
    queryKey: [
      ...OCR_KEY,
      "chapter",
      ref?.sourceId ?? "",
      ref?.seriesKey ?? "",
      ref?.chapterKey ?? "",
    ],
    queryFn: async () => {
      try {
        return await ocrApi.chapter(ref!);
      } catch (error) {
        if (error instanceof ApiError && error.status === 404) return null;
        throw error;
      }
    },
    enabled: ref !== null,
    staleTime: 5 * 60_000,
  });
}

/** Whether this server reads dialogue (`GET /settings` capabilities.ocr). Defaults to false until known. */
export function useOcrCapability(): boolean | undefined {
  const q = useQuery({
    queryKey: [...OCR_KEY, "capabilities"],
    queryFn: () => http.get<{ capabilities?: { ocr?: boolean } }>("/settings"),
    staleTime: 10 * 60_000,
  });
  return q.data ? q.data.capabilities?.ocr === true : undefined;
}

export function useOcrAvailable(): boolean {
  return useOcrCapability() === true;
}

/** Dialogue search paged by offset (`Show more`), 20 per page. */
export function useInfiniteOcrSearch(query: string) {
  const q = query.trim();
  return useInfiniteQuery({
    queryKey: [...OCR_KEY, "search-infinite", q],
    queryFn: ({ pageParam }) => p1(() => ocrApi.search({ q, limit: 20, offset: pageParam })),
    initialPageParam: 0,
    getNextPageParam: (last) => (last.has_more ? last.offset + last.items.length : undefined),
    enabled: q.length > 0,
  });
}
