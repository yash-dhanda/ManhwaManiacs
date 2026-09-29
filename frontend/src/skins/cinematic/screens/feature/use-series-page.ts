"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useCallback, useEffect, useMemo, useState, useSyncExternalStore } from "react";
import { useSuggestedTags } from "@/features/ai/tags";
import { seriesContinue, type SeriesContinue } from "@/features/library/history-continue";
import {
  useFollow,
  useFollowedIndex,
  usePatchSeries,
  useSeries,
  useUnfollow,
} from "@/features/library/hooks";
import {
  chaptersUpTo,
  markChaptersRead,
  markChaptersUnread,
  type MarkableChapter,
} from "@/features/library/mark-read";
import { timeHere } from "@/features/library/series-time";
import { useTags, useTagSeries, useUntagSeries } from "./tags-standin";
import { useOcrCoverage } from "@/features/ocr/coverage";
import { useChapterPicker } from "@/features/offline/use-chapter-picker";
import { useMangaChapterSaver, useNovelChapterSaver } from "@/features/offline/chapter-savers";
import { useSeriesProgress } from "@/features/reader/hooks";
import { readAllHref, readerChapterHref } from "@/features/reader/reader-link";
import { useSeriesEnrichment } from "@/features/sources/enrichment";
import { resolveChapterListState } from "@/features/sources/chapter-list-state";
import { prefetchChapterManifest } from "@/features/reader/hooks";
import { HOVER_DWELL_MS, sourcesLimiter } from "@/features/sources/request-limiter";
import {
  useSourceChapters,
  useSourceSeriesDetail,
} from "@/features/sources/hooks";
import { resolveSeriesProgress } from "@/features/sources/series-progress";
import { useSourceSeriesProgress } from "@/features/sources/source-progress";
import { novelChapterHref } from "@/features/novels/novel-link";
import { readScopedString, writeScopedString } from "@/lib/scoped-storage";
import { createHoverIntent } from "@/lib/hover-intent";
import { ApiError } from "@/types/api";
import { buildRows, sortChapters, type ChapterSort } from "./chapter-rows";
import { useToasts } from "./toasts";
import { bookmarksApi } from "@/features/bookmarks/api";
import { MATURE_GATED_QUERY_ROOTS } from "@/features/preferences/mature-gate";
import { haptic } from "../../haptics";
import { playSound } from "../../sounds";

const subscribeOnline = (cb: () => void) => {
  window.addEventListener("online", cb);
  window.addEventListener("offline", cb);
  return () => {
    window.removeEventListener("online", cb);
    window.removeEventListener("offline", cb);
  };
};

/** Every piece of data and every action both series pages share. */
export function useSeriesPage(opts: {
  sourceId: string;
  seriesKey: string;
  followedId: number | null;
  isNovel: boolean;
}) {
  const { sourceId, seriesKey, isNovel } = opts;
  const ref = useMemo(() => ({ sourceId, seriesKey }), [sourceId, seriesKey]);
  const qc = useQueryClient();
  const toasts = useToasts();
  const online = useSyncExternalStore(subscribeOnline, () => navigator.onLine, () => true);

  const seriesQuery = useSourceSeriesDetail(sourceId, seriesKey);
  const chaptersQuery = useSourceChapters(sourceId, seriesKey);
  const followedIndex = useFollowedIndex();
  const series = seriesQuery.data;
  const followedId =
    opts.followedId ?? followedIndex.lookup(ref, series?.series_identity) ?? null;
  const follow = useSeries(followedId).data;
  const enrichment = useSeriesEnrichment(sourceId, seriesKey).data ?? null;
  const suggested = useSuggestedTags(sourceId, seriesKey).data;
  const coverage = useOcrCoverage(sourceId, seriesKey).data;
  const allTags = useTags().data ?? [];
  const tagSeries = useTagSeries();
  const untagSeries = useUntagSeries();

  const followM = useFollow();
  const unfollowM = useUnfollow();
  const patchM = usePatchSeries();

  // --- progress --------------------------------------------------------
  const local = useSourceSeriesProgress(sourceId, seriesKey);
  const progressQuery = useSeriesProgress(ref);
  const progressRows = useMemo(() => progressQuery.data ?? [], [progressQuery.data]);
  const { map: progress } = useMemo(
    () => resolveSeriesProgress({ serverRows: progressRows, localMap: local.map }),
    [progressRows, local.map],
  );

  // --- chapters --------------------------------------------------------
  const chapters = useMemo(() => chaptersQuery.data ?? [], [chaptersQuery.data]);
  const sortKey = `mm.chapter-sort:${sourceId}:${seriesKey}`;
  const [chosen, setChosen] = useState<ChapterSort | null>(() => {
    const stored = readScopedString(sortKey);
    return stored === "newest" || stored === "oldest" ? stored : null;
  });
  const sort: ChapterSort = chosen ?? (isNovel ? "oldest" : "newest");
  const setSort = (next: ChapterSort) => {
    setChosen(next);
    writeScopedString(sortKey, next);
  };
  const ordered = useMemo(() => sortChapters(chapters, sort), [chapters, sort]);
  const rows = useMemo(() => buildRows(ordered, progress), [ordered, progress]);
  const continueTo: SeriesContinue | null = useMemo(
    () => seriesContinue(chapters, progress),
    [chapters, progress],
  );
  const listState = resolveChapterListState({
    isLoading: chaptersQuery.isLoading,
    error: chaptersQuery.error,
    chapterCount: chapters.length,
    reportedChapterCount: series?.chapter_count ?? 0,
  });
  const readCount = useMemo(() => chapters.filter((c) => progress[c.id]?.completed).length, [chapters, progress]);

  const chapterHref = useCallback(
    (chapterKey: string, page?: number) =>
      isNovel
        ? novelChapterHref({ ...ref, chapterKey }, page)
        : readerChapterHref({ ...ref, chapterKey }, page),
    [isNovel, ref],
  );
  const point = continueTo && continueTo.kind !== "caught-up" ? continueTo.point : null;
  const primaryHref = point ? chapterHref(point.chapterKey, point.page) : null;
  const readAll = !isNovel && chapters.length > 1 ? readAllHref(ref, point?.chapterKey ?? null) : null;

  // --- hover prefetch (150 ms dwell) -----------------------------------
  const prefetchP3 = useCallback(
    (id: string) => {
      if (!isNovel) void sourcesLimiter.run("P3", () => prefetchChapterManifest(qc, { sourceId, seriesKey, chapterKey: id })).catch(() => undefined);
    },
    [isNovel, qc, sourceId, seriesKey],
  );
  const hover = useMemo(() => createHoverIntent<string>(prefetchP3, HOVER_DWELL_MS), [prefetchP3]);
  useEffect(() => () => hover.dispose(), [hover]);
  // A press is P1: the limiter never makes it wait.
  const prefetchP1 = useCallback(
    (id: string) => {
      if (!isNovel) void sourcesLimiter.run("P1", () => prefetchChapterManifest(qc, { sourceId, seriesKey, chapterKey: id })).catch(() => undefined);
    },
    [isNovel, qc, sourceId, seriesKey],
  );
  // The first two rows on load, as P3.
  const firstTwo = rows
    .slice(0, 2)
    .map((r) => r.id)
    .join("|");
  useEffect(() => {
    if (firstTwo) firstTwo.split("|").forEach(prefetchP3);
  }, [firstTwo, prefetchP3]);

  // --- downloads -------------------------------------------------------
  const titleOf = useCallback(
    (key: string) => chapters.find((c) => c.id === key)?.title || "Chapter",
    [chapters],
  );
  const mangaSaver = useMangaChapterSaver({ sourceId, seriesKey, seriesTitle: series?.title ?? null });
  const novelSaver = useNovelChapterSaver({ sourceId, seriesKey, seriesTitle: series?.title ?? null, titleOf });
  const saver = isNovel ? novelSaver : mangaSaver;
  const picker = useChapterPicker({
    sourceId,
    seriesKey,
    chapters: rows.map((r) => ({ key: r.id, number: r.number, read: r.completed })),
    buildRequest: saver.buildRequest,
    prepare: saver.prepare,
    medium: isNovel ? "novel" : "manga",
  });

  // --- follow / patch --------------------------------------------------
  const title = series?.title ?? follow?.title ?? "";
  const toggleFollow = useCallback(async () => {
    try {
      if (followedId !== null) {
        const id = followedId;
        await unfollowM.mutateAsync(id);
        toasts.push(`Removed ${title}.`, {
          label: "Undo",
          run: () => void followM.mutateAsync(ref),
        });
      } else {
        await followM.mutateAsync(ref);
        haptic("follow.add");
        playSound("follow.add");
        toasts.push(
          isNovel
            ? `Added ${title}. New chapters will notify you.`
            : `Following ${title}. New chapters will notify you.`,
        );
      }
    } catch (e) {
      toasts.push(
        e instanceof ApiError && e.code === "follow_limit_reached"
          ? "You're following 1,000 series, the limit for a profile."
          : "Couldn't update your library.",
      );
    }
  }, [followedId, followM, unfollowM, ref, title, toasts, isNovel]);

  const patch = useCallback(
    (body: Parameters<typeof patchM.mutate>[0]["body"]) => {
      if (followedId !== null) patchM.mutate({ followedId, body });
      if (body.is_favorite === true) {
        haptic("favorite");
        playSound("favorite");
      }
    },
    [followedId, patchM],
  );

  const setMature = (value: boolean | null) => {
    // TODO(web/07): also re-stamp this series' locally stored rows through web/07's mature filter (not integrated; see owner-todo.md).
    patch({ mature_override: value });
    toasts.push(
      value === true
        ? `Treating ${title} as 18+.`
        : value === false
          ? `Treating ${title} as not 18+.`
          : "Using the source's rating.",
    );
    MATURE_GATED_QUERY_ROOTS.forEach((root) => void qc.invalidateQueries({ queryKey: [root] }));
  };

  // --- download haptics: start on run begin, done/fail on its summary ----
  const { running, summary } = picker.downloads;
  useEffect(() => {
    if (running) haptic("download.start");
  }, [running]);
  useEffect(() => {
    if (!summary) return;
    haptic(summary.tone === "warn" ? "download.fail" : "download.done");
    playSound(summary.tone === "warn" ? "download.fail" : "download.done");
  }, [summary]);

  /** A bookmark at page 1 of a chapter, through the existing bookmarks API. */
  const bookmarkStart = async (key: string) => {
    const c = chapters.find((x) => x.id === key);
    try {
      await bookmarksApi.create({
        source_id: sourceId,
        series_key: seriesKey,
        chapter_key: key,
        chapter_number: c?.number ?? null,
        media_type: isNovel ? "novel" : "manga",
        anchor_index: 0,
        anchor_fraction: 0,
        anchor_total: c?.page_count ?? 0,
      });
      void qc.invalidateQueries({ queryKey: ["bookmarks"] });
      haptic("bookmark.add");
      playSound("bookmark.add");
      toasts.push(`Bookmarked the start of chapter ${c?.number ?? ""}.`.replace("  ", " "));
    } catch {
      toasts.push("Couldn't save the bookmark.");
    }
  };

  // --- mark read / unread ---------------------------------------------
  const markable = useMemo<MarkableChapter[]>(
    () =>
      chapters.map((c) => ({
        chapterKey: c.id,
        number: c.number,
        pageCount: c.page_count,
        completed: progress[c.id]?.completed ?? false,
      })),
    [chapters, progress],
  );
  const refreshProgress = () => void qc.invalidateQueries({ queryKey: ["reader", "progress"] });

  const markRead = useCallback(
    async (list: MarkableChapter[], label: string) => {
      if (!online || list.length === 0) return;
      await markChaptersRead(ref, list);
      refreshProgress();
      toasts.push(label, {
        label: "Undo",
        run: () =>
          void markChaptersUnread(ref, list.map((c) => c.chapterKey)).then(refreshProgress),
      });
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [online, ref, toasts],
  );
  const markOne = (key: string) => {
    const c = markable.find((m) => m.chapterKey === key);
    if (c && !c.completed) void markRead([c], `Marked chapter ${c.number ?? ""} read.`.replace("  ", " "));
  };
  const markUpTo = (key: string) => {
    const c = markable.find((m) => m.chapterKey === key);
    if (!c || c.number == null) return markOne(key);
    const list = chaptersUpTo(markable, c.number);
    void markRead(list, `Marked ${list.length} chapter${list.length === 1 ? "" : "s"} read.`);
  };
  const markUnread = async (key: string) => {
    if (!online) return;
    const c = markable.find((m) => m.chapterKey === key);
    await markChaptersUnread(ref, [key]);
    refreshProgress();
    toasts.push(`Marked chapter ${c?.number ?? ""} unread.`.replace("  ", " "), {
      label: "Undo",
      run: () => c && void markChaptersRead(ref, [c]).then(refreshProgress),
    });
  };

  const tagIds = new Set(
    ((follow as unknown as { tags?: { id: number }[] } | undefined)?.tags ?? []).map((t) => t.id),
  );

  return {
    ref, sourceId, seriesKey, isNovel, online,
    series, seriesQuery, chaptersQuery, chapters, ordered, rows, listState,
    followedId, follow, followBusy: followM.isPending || unfollowM.isPending,
    followError: followM.error,
    enrichment, suggested, coverage, allTags, tagIds, tagSeries, untagSeries,
    progress, progressRows, readCount, continueTo, primaryHref, readAll, chapterHref,
    sort, setSort, hover, prefetchP1, picker, title,
    toggleFollow, patch, setMature, markOne, markUpTo, markUnread, bookmarkStart,
    timeSpent: timeHere(progressRows),
    toasts,
  };
}

export type SeriesPage = ReturnType<typeof useSeriesPage>;
