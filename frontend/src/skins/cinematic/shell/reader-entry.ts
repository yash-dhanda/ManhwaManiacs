"use client";
import { useEffect, useRef } from "react";
import { prefetchChapterStart } from "@/features/reader/prefetch";
import { HOVER_DWELL_MS } from "@/features/sources/request-limiter";
import { columnWipe, dip, shellPush } from "./Overlays";

/** §8.0.4: `wipe` from Tonight, feature and book pages and recaps opened from them; `dip` from everywhere else. */
export type EntryKind = "wipe" | "dip";
type ChapterRef = { sourceId: string; seriesKey: string; chapterKey: string };

/** Which entry a pathname earns. */
export function entryKindFor(pathname: string): EntryKind {
  const s = pathname.split("?")[0].split("/").filter(Boolean);
  if (s.length === 0) return "wipe";
  if (s[0] === "recap") return "wipe";
  if (s[0] === "sources" && s[2] === "series") return "wipe";
  if (s[0] === "library" && s.length === 2 && !["browse", "collections", "history", "bookmarks", "statistics", "recommendations"].includes(s[1])) return "wipe";
  return "dip";
}

/** Open a reader: the overlay closes, the push runs under it, the overlay opens. Prefetch (P1) fires on press. */
export async function enterReader(href: string, opts: { entry: EntryKind; prefetch?: () => void }): Promise<void> {
  opts.prefetch?.();
  const go = () => shellPush(href, "forward");
  if (opts.entry === "wipe") await columnWipe(go);
  else await dip(go);
}

/**
 * Pointer and focus handlers for a chapter link: after a 150 ms dwell it prefetches the manifest and the first two pages at P3,
 * on press at P1.
 */
export function useReaderPrefetch(chapter: ChapterRef | null) {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => () => { if (timer.current) clearTimeout(timer.current); }, []);
  const start = () => {
    if (!chapter || timer.current) return;
    timer.current = setTimeout(() => { void prefetchChapterStart(chapter, "P3"); }, HOVER_DWELL_MS);
  };
  const stop = () => { if (timer.current) { clearTimeout(timer.current); timer.current = null; } };
  return {
    onPointerEnter: start, onPointerLeave: stop, onFocus: start, onBlur: stop,
    onPointerDown: () => { stop(); if (chapter) void prefetchChapterStart(chapter, "P1"); },
  };
}
