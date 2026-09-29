export interface GenreEntry {
  genre: string;
  label: string;
  sourceIds: string[];
}

/**
 * Union of the pinned sources' genres, merged case-insensitively (first spelling
 * wins as label), highest profile weight first, ties and unweighted alphabetical.
 */
export function buildGenreIndex(
  pinnedSources: readonly string[],
  genresBySource: Record<string, readonly string[] | undefined>,
  weights: ReadonlyArray<{ genre: string; weight: number }>,
): GenreEntry[] {
  const byKey = new Map<string, GenreEntry>();
  for (const id of pinnedSources) {
    for (const raw of genresBySource[id] ?? []) {
      const name = raw.trim();
      if (!name) continue;
      const key = name.toLowerCase();
      const entry = byKey.get(key) ?? { genre: key, label: name, sourceIds: [] };
      if (!entry.sourceIds.includes(id)) entry.sourceIds.push(id);
      byKey.set(key, entry);
    }
  }
  const weight = new Map<string, number>();
  for (const w of weights) weight.set(w.genre.trim().toLowerCase(), w.weight);
  return [...byKey.values()].sort((a, b) => {
    const wa = weight.get(a.genre) ?? -Infinity;
    const wb = weight.get(b.genre) ?? -Infinity;
    if (wa !== wb) return wb - wa;
    return a.label.localeCompare(b.label);
  });
}
