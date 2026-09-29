import { sourcesApi } from "./api";
import { sourcesLimiter, type Priority } from "./standins/request-limiter"; // TODO(web/03): real limiter
import type { PaginatedSourceSeries, SourceGenre } from "./types";

/** §15.6 priorities for the calls the Discover cluster adds. */
export const PRIORITY = {
  search: "P1",
  sourceList: "P1",
  browsePage: "P1",
  ocrSearch: "P1",
  chapterManifest: "P1",
  cover: "P2",
  genreList: "P3",
  popularPage: "P3",
  genreCover: "P3",
  dialogueStill: "P3",
  previewSlate: "P3",
} as const satisfies Record<string, Priority>;

export const GENRE_STALE_MS = 86_400_000;

export const fetchSourceGenres = (sourceId: string, signal?: AbortSignal): Promise<SourceGenre[]> =>
  sourcesLimiter.run(PRIORITY.genreList, () => sourcesApi.genres(sourceId), signal);

/** First page of the `popular` browse mode, or null when the source has no such mode. */
export async function fetchPopularPage(sourceId: string, signal?: AbortSignal): Promise<PaginatedSourceSeries | null> {
  return sourcesLimiter.run(
    PRIORITY.popularPage,
    async () => {
      const modes = await sourcesApi.browseModes(sourceId);
      if (!modes.some((m) => m.id === "popular")) return null;
      return sourcesApi.listSeries(sourceId, { page: 1, sort: "popular" });
    },
    signal,
  );
}

/** First series of a genre on a source, for the genre tile's cover. */
export async function fetchGenreCover(sourceId: string, genre: string, signal?: AbortSignal) {
  const page = await sourcesLimiter.run(PRIORITY.genreCover, () => sourcesApi.listSeries(sourceId, { genre, page: 1 }), signal);
  return page.items[0] ?? null;
}
