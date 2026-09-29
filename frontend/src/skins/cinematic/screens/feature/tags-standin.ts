import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { http } from "@/services/http";
import type { SeriesId } from "@/types/api";

// TODO(web/09): stand-in for web/09's tag hooks. Lives in the skin because the tag-surface guard forbids the endpoints under features/library until web/09 lifts it.
export interface SeriesTag {
  id: number;
  name: string;
  category?: string;
  color?: string | null;
}

const TAGS_KEY = ["library", "tags"] as const;

export function useTags() {
  return useQuery({ queryKey: TAGS_KEY, queryFn: () => http.get<SeriesTag[]>("/library/tags") });
}

export function useCreateTag() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (name: string) => http.post<SeriesTag>("/library/tags", { name }),
    onSuccess: () => void qc.invalidateQueries({ queryKey: TAGS_KEY }),
  });
}

function useSeriesTagWrite(method: "post" | "delete") {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ ref, tagId }: { ref: SeriesId; tagId: number }) => {
      const body = { source_id: ref.sourceId, series_key: ref.seriesKey, tag_id: tagId };
      return method === "post"
        ? http.post("/library/series-tags", body)
        : http.delete("/library/series-tags", { body });
    },
    onSuccess: () => void qc.invalidateQueries({ queryKey: ["library"] }),
  });
}

export const useTagSeries = () => useSeriesTagWrite("post");
export const useUntagSeries = () => useSeriesTagWrite("delete");
