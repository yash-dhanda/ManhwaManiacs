"use client";

import { useMemo } from "react";
import { useQueries, useQuery } from "@tanstack/react-query";
import { useSourcePins, useSources } from "@/features/sources/hooks";
import { fetchGenreCover, fetchPopularPage, fetchSourceGenres, GENRE_STALE_MS } from "@/features/sources/discover-requests";
import { buildGenreIndex } from "@/features/sources/genre-index";
import { buildTrending } from "@/features/sources/trending";
import { useGenreWeights } from "@/features/library/genre-weights";
import type { SourcePin, SourceSummary } from "@/features/sources/types";

/** Pinned (available) sources in pin order, joined with their summaries (health, 18+). */
export function usePinnedSources() {
  const pins = useSourcePins();
  const sources = useSources();
  return useMemo(() => {
    const byId = new Map<string, SourceSummary>((sources.data ?? []).map((x) => [x.id, x]));
    const rows = (pins.data ?? [])
      .filter((p) => p.available)
      .map((p) => ({ pin: p, source: byId.get(p.source_id) ?? null }))
      .filter((r) => r.source !== null) as Array<{ pin: SourcePin; source: SourceSummary }>;
    return { rows, ids: rows.map((r) => r.pin.source_id), loading: pins.isLoading || sources.isLoading };
  }, [pins.data, pins.isLoading, sources.data, sources.isLoading]);
}

export function useGenreIndex(pinnedIds: string[]) {
  const weights = useGenreWeights();
  const results = useQueries({
    queries: pinnedIds.map((id) => ({
      queryKey: ["sources", id, "genres", "p3"],
      queryFn: ({ signal }: { signal: AbortSignal }) => fetchSourceGenres(id, signal),
      staleTime: GENRE_STALE_MS,
      retry: false,
    })),
  });
  const by: Record<string, string[]> = {};
  pinnedIds.forEach((id, i) => {
    by[id] = (results[i]?.data ?? []).map((g) => g.label || g.id);
  });
  return buildGenreIndex(pinnedIds, by, weights);
}

export function useTrending(pinnedIds: string[]) {
  const results = useQueries({
    queries: pinnedIds.map((id) => ({
      queryKey: ["sources", id, "popular-page"],
      queryFn: ({ signal }: { signal: AbortSignal }) => fetchPopularPage(id, signal),
      staleTime: 600_000,
      retry: false,
    })),
  });
  return buildTrending(pinnedIds.map((id, i) => ({ sourceId: id, items: results[i]?.data?.items ?? null })));
}

export function useGenreCover(sourceId: string | undefined, genre: string) {
  return useQuery({
    queryKey: ["sources", sourceId, "genre-cover", genre],
    queryFn: ({ signal }) => fetchGenreCover(sourceId!, genre, signal),
    enabled: Boolean(sourceId),
    staleTime: GENRE_STALE_MS,
    retry: false,
  });
}
