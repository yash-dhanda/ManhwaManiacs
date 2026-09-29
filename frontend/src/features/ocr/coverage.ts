import { useQuery } from "@tanstack/react-query";
import { http } from "@/services/http";

export interface OcrCoverage {
  chapters: { chapter_key: string; word_count: number }[];
}

export function useOcrCoverage(sourceId: string, seriesKey: string) {
  return useQuery({
    queryKey: ["ocr", "coverage", sourceId, seriesKey],
    queryFn: () =>
      http.get<OcrCoverage>("/ocr/coverage", { query: { source: sourceId, series: seriesKey } }),
    enabled: Boolean(sourceId) && Boolean(seriesKey),
    staleTime: 5 * 60 * 1000,
    retry: false,
  });
}
