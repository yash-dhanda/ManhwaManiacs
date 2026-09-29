import { useQuery } from "@tanstack/react-query";
import { useActiveProfileStore } from "@/features/profiles/store";
import { http } from "@/services/http";

export interface GenreWeight {
  genre: string;
  weight: number;
}

export const genreWeightsApi = {
  get: (limit: number) => http.get<GenreWeight[]>("/library/recommendations", { query: { limit } }),
};

export function sortGenreWeights(rows: readonly GenreWeight[] | null | undefined): GenreWeight[] {
  return [...(rows ?? [])].sort((a, b) => b.weight - a.weight || a.genre.localeCompare(b.genre));
}

/** The one genre-weights client; web/19 and web/21 import this. */
export function useGenreWeights(limit = 40) {
  const profileId = useActiveProfileStore((s) => s.activeProfile?.id ?? null);
  // The profile snapshot carries no 18+ flag; the server gates the answer per profile, so profileId is the scope.
  const matureEnabled = null;
  const query = useQuery({
    queryKey: ["library", "genre-weights", profileId, matureEnabled, limit],
    queryFn: () => genreWeightsApi.get(limit),
    staleTime: 600_000,
    retry: false,
  });
  return query.isError ? [] : sortGenreWeights(query.data);
}
