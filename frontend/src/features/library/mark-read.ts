import { http } from "@/services/http";
import type { SeriesId } from "@/types/api";

// TODO(web/09): web/09 owns this file (markChaptersRead / markChaptersUnread);
// this is the smallest stand-in with web/11's B6 helpers, merge when it lands.

export const MARK_CHUNK = 200;

export interface MarkableChapter {
  chapterKey: string;
  number: number | null;
  pageCount: number;
  completed: boolean;
}

export interface ManualRow {
  source_id: string;
  series_key: string;
  chapter_key: string;
  chapter_number: number | null;
  last_page: number;
  page_count: number;
  scroll_offset_px: 0;
  is_completed: true;
  time_spent_seconds: 0;
  manual: true;
}

/** Every numbered chapter at or below `chapterNumber` that is not completed yet. */
export function chaptersUpTo(
  chapters: readonly MarkableChapter[],
  chapterNumber: number,
): MarkableChapter[] {
  return chapters.filter(
    (c) => c.number != null && c.number <= chapterNumber && !c.completed,
  );
}

/** The keys an Undo deletes: only those that were not completed before. */
export function undoMarkRead(
  previouslyCompleted: ReadonlySet<string>,
  marked: readonly string[],
): string[] {
  return marked.filter((k) => !previouslyCompleted.has(k));
}

export function manualRow(ref: SeriesId, c: MarkableChapter): ManualRow {
  const pages = Math.max(c.pageCount, 1);
  return {
    source_id: ref.sourceId,
    series_key: ref.seriesKey,
    chapter_key: c.chapterKey,
    chapter_number: c.number,
    last_page: pages,
    page_count: pages,
    scroll_offset_px: 0,
    is_completed: true,
    time_spent_seconds: 0,
    manual: true,
  };
}

function chunks<T>(items: readonly T[]): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += MARK_CHUNK) out.push(items.slice(i, i + MARK_CHUNK));
  return out;
}

export async function markChaptersRead(ref: SeriesId, chapters: readonly MarkableChapter[]) {
  for (const part of chunks(chapters)) {
    await http.post("/reader/progress/batch", part.map((c) => manualRow(ref, c)));
  }
}

export async function markChaptersUnread(ref: SeriesId, chapterKeys: readonly string[]) {
  for (const part of chunks(chapterKeys)) {
    await http.delete("/reader/progress", {
      body: { source_id: ref.sourceId, series_key: ref.seriesKey, chapter_keys: part },
    });
  }
}
