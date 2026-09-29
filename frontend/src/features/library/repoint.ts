import { useMutation, useQueryClient } from "@tanstack/react-query";
import { http } from "@/services/http";
import type { FollowedSeries } from "./types";

export interface RepointResult {
  followed: FollowedSeries;
  mapped_chapter_key: string | null;
  mapped_chapter_number: number | null;
}

export interface RepointInput {
  source_id: string;
  series_key: string;
  keep_old: boolean;
}

export function useRepoint(followedId: number | null) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: RepointInput) =>
      http.post<RepointResult>(`/library/series/${followedId}/repoint`, body),
    onSuccess: () => void qc.invalidateQueries({ queryKey: ["library"] }),
  });
}

/** The §8.17 step-2 sentence. `candidateRange` is the candidate's [first, last] chapter number. */
export function mappingSentence({
  currentNumber,
  candidateRange,
  sourceName,
}: {
  currentNumber: number | null;
  candidateRange: readonly [number, number] | null;
  sourceName: string;
}): string {
  if (
    currentNumber != null &&
    candidateRange &&
    currentNumber >= candidateRange[0] &&
    currentNumber <= candidateRange[1]
  ) {
    return `Your place moves by chapter number. You're on chapter ${currentNumber}; ${sourceName} has chapters ${candidateRange[0]}–${candidateRange[1]}, so chapter ${currentNumber} there becomes your place.`;
  }
  return `Chapter numbers don't line up, so you'll start at chapter 1 on ${sourceName}.`;
}
