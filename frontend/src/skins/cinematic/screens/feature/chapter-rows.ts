import { chapterLabel } from "@/features/sources/chapter-label";
import { chapterDateLabel } from "@/features/sources/chapter-date";
import type { SourceChapterSummary } from "@/features/sources/types";
import type { SourceSeriesProgressMap } from "@/features/sources/source-progress";

export type ChapterSort = "newest" | "oldest";

export interface ChapterRow {
  id: string;
  number: number | null;
  /** "12", "12.5" or null. */
  ordinal: string | null;
  title: string | null;
  date: string | null;
  pages: number;
  page: number;
  completed: boolean;
  inProgress: boolean;
}

/** Sorted by number, nulls last, for both directions. */
export function sortChapters(
  chapters: readonly SourceChapterSummary[],
  sort: ChapterSort,
): SourceChapterSummary[] {
  return [...chapters].sort((a, b) => {
    if (a.number == null && b.number == null) return 0;
    if (a.number == null) return 1;
    if (b.number == null) return -1;
    return sort === "newest" ? b.number - a.number : a.number - b.number;
  });
}

export function buildRows(
  chapters: readonly SourceChapterSummary[],
  progress: SourceSeriesProgressMap,
): ChapterRow[] {
  return chapters.map((c) => {
    const p = progress[c.id];
    const label = chapterLabel(c);
    return {
      id: c.id,
      number: c.number,
      ordinal: c.number == null ? null : String(c.number),
      title: c.number == null ? label.primary : label.secondary,
      date: chapterDateLabel(c.release_date)?.toUpperCase() ?? null,
      pages: c.page_count,
      page: p?.page ?? 0,
      completed: p?.completed ?? false,
      inProgress: Boolean(p) && !p!.completed,
    };
  });
}
