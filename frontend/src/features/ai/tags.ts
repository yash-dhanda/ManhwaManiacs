import { useQuery } from "@tanstack/react-query";
import { http } from "@/services/http";
import type { SeriesId } from "@/types/api";
import { sendAiFeedback } from "./feedback";

export interface SuggestedTags {
  tags: string[];
  available: boolean;
  reason?: string | null;
}

const NONE: SuggestedTags = { tags: [], available: false };

/** Any failure (a 404 before the backend route exists) is "nothing suggested". */
export function useSuggestedTags(sourceId: string, seriesKey: string) {
  return useQuery({
    queryKey: ["ai", "tags", sourceId, seriesKey],
    queryFn: async (): Promise<SuggestedTags> => {
      try {
        const r = await http.get<SuggestedTags>("/ai/tags", {
          query: { source: sourceId, series: seriesKey },
        });
        return r && Array.isArray(r.tags) ? r : NONE;
      } catch {
        return NONE;
      }
    },
    enabled: Boolean(sourceId) && Boolean(seriesKey),
    staleTime: 10 * 60 * 1000,
    retry: false,
  });
}

export function rejectSuggestedTag(ref: SeriesId, tag: string) {
  return sendAiFeedback({
    signal: "tag_rejected",
    source_id: ref.sourceId,
    series_key: ref.seriesKey,
    tag,
  });
}
