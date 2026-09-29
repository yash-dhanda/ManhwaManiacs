import { useQuery } from "@tanstack/react-query";
import { http } from "@/services/http";

/** `GET /series/enrichment` — credits the catalogue adds beyond the source. */
export interface SeriesEnrichment {
  anilist_id: number | null;
  format: string | null;
  score: number | null;
  official: { site: string; url: string }[];
}

export function seriesEnrichmentQueryKey(sourceId: string, seriesKey: string) {
  return ["sources", "enrichment", sourceId, seriesKey] as const;
}

/** Null when the catalogue has nothing; never an error state for the page. */
export function useSeriesEnrichment(sourceId: string, seriesKey: string) {
  return useQuery({
    queryKey: seriesEnrichmentQueryKey(sourceId, seriesKey),
    queryFn: async (): Promise<SeriesEnrichment | null> => {
      try {
        return await http.get<SeriesEnrichment | null>("/series/enrichment", {
          query: { source: sourceId, series: seriesKey },
        });
      } catch {
        return null;
      }
    },
    enabled: Boolean(sourceId) && Boolean(seriesKey),
    staleTime: 60 * 60 * 1000,
  });
}
