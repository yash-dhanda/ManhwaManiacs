"use client";

import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { skipToken, useQuery, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useScrollContainer } from "@/lib/scroll-container";
import { useUiStore } from "@/stores/ui-store";
import { createReadingPercent } from "@/features/novels/reading-percent";
import {
  BOOKMARK_MEDIA_MANGA,
  bookmarksQueryKey,
  fractionWithin,
  pointWithin,
  resolveAnchor,
  useBookmarkCapture,
  type Bookmark,
  type BookmarkCreate,
} from "@/features/bookmarks";
import { chapterCacheKey } from "@/features/offline/save-request";
import { isServiceWorkerSupported, saveChapterOffline } from "@/features/offline/client";
import { useMangaChapterSaver } from "@/features/offline/chapter-savers";
import { useOfflineState, useStorageScope } from "@/features/offline/hooks";
import { readSaveNext } from "@/features/offline/save-next";
import { useContentPreferences } from "@/features/preferences/hooks";
import { useSourceChapters } from "@/features/sources/hooks";
import { autoScrollPxPerSecond } from "../auto-scroll";
import { readerDebug } from "../debug";
import { clampZoom, effectiveFitMode, wheelZoomSteps, zoomBy } from "../fit";
import { ensureChapterPages } from "../hooks";
import {
  defaultTapZoneConfig,
  resolveEscapeTarget,
  resolveTapZone,
  TOGGLE_ONLY_TAP_ZONES,
  type PageTurn,
  type TapZone,
} from "../keymap";
import {
  estimatePageHeight,
  estimateScrollOffsetToPage,
  resolveContainerWidth,
} from "../page-layout";
import { readerSeriesKey } from "../preferences";
import { orderIndexOf, readAllEntryKey, readingOrder } from "../read-all";
import { readAllHref, readerChapterHref, seriesPageHref } from "../reader-link";
import {
  clearChapterScrollPreparation,
  estimateResumeOffset,
  scrollReaderBy,
  setReaderScrollTop,
  syncChapterScroll,
} from "../scroll-preparation";
import {
  readReaderPosition,
  writeReaderPosition,
  type ReaderPosition,
} from "../scroll-storage";
import { scrubPercent } from "../scrub";
import {
  buildPageViews,
  findViewIndex,
  pagedProgressPosition,
  viewLeadPage,
} from "../spread";
import { useReaderStore } from "../store";
import {
  chapterIndexOf,
  nextChapterLabelFor,
  READER_STRIP_WINDOW,
  READ_ALL_STRIP_WINDOW,
  stripChapterLabel,
  type StripChapter,
  type StripPosition,
} from "../strip";
import { bulkChapterSource, linkedChapterSource } from "../strip-source";
import { useAutoScroll } from "../use-auto-scroll";
import { useChapterPreload } from "../use-chapter-preload";
import { useChapterStrip } from "../use-chapter-strip";
import { useCinema } from "../use-cinema";
import { useFullscreen } from "../use-fullscreen";
import { useReaderPreferences } from "../use-reader-preferences";
import { useReaderSettings } from "../use-reader-settings";
import { useReaderShortcuts } from "../use-reader-shortcuts";
import { useStripProgress } from "../use-strip-progress";
import type { ReadingMode } from "../types";
import { installWheelZoomArming } from "../wheel-zoom-arming";
import { READING_LINE_PX, type StripHandle } from "./ContinuousStrip";
import { shouldAutoQueueNext } from "./auto-queue";
import type {
  ChapterRef,
  NextState,
  ReaderEngine,
  ReaderEngineInput,
  ReaderEngineState,
} from "./types";

/** The exact spot a bookmark records: a page, how far into it, and of how many. */
export interface CapturedAnchor {
  /** 1-based page in the ACTIVE chapter. */
  index: number;
  /** 0.0-1.0 down that page. */
  fraction: number;
  /** Pages in that chapter right now. */
  total: number;
}

export interface ReaderEngineOptions {
  /**
   * Save the chapter after this one while reading (cinematic §8.14.11). Off for
   * the legacy readers, which keep today's behaviour.
   */
  autoQueueNext?: boolean;
}

/** How long the "opened at the nearest page" explanation stays up. */
const MOVED_NOTICE_MS = 5200;
const SCROLL_EDGE_THRESHOLD = 48;
const SCROLL_SAVE_MS = 250;
/** Fraction of the viewport a Space press travels, leaving an overlap to re-read. */
const SCREEN_SCROLL_RATIO = 0.9;
/** Wheel travel past the top that pulls the previous chapter onto the strip. */
const OVERSCROLL_TRIGGER = 140;
const LIST_FAILED =
  "This series' chapter list didn't come through, so there is nothing to read through.";

/** Stable no-op so `useChapterPreload` is not re-armed by an identity change. */
const NO_PRELOAD = async (): Promise<ReadonlyArray<{ imageUrl: string }>> => [];
/** Stable placeholder view for the frame before any page is known. */
const FIRST_PAGE_VIEW = [1];
const NO_BOOKMARKS: readonly Bookmark[] = [];

/** The per-chapter key reading positions have always been stored under. */
function chapterScrollKey(chapter: StripChapter): string {
  return `${chapter.sourceId}:${chapter.seriesKey}:${chapter.chapterKey}`;
}

/**
 * The reader's state and commands with no pixels attached: everything that
 * lived in `SourceReader`, `ReadAllReader` and the non-visual half of
 * `ChapterReader`. The chapter strip, progress writes, bookmark capture,
 * preload, zoom, auto-scroll, chrome visibility, cinema, settings, the
 * jump/scrub handlers and the keyboard map are composed here unchanged; no
 * threshold or timing differs from what those components had.
 */
export function useReaderEngine(
  input: ReaderEngineInput,
  options: ReaderEngineOptions = {},
): ReaderEngine {
  const autoQueueNext = options.autoQueueNext ?? false;
  const { kind, sourceId, seriesKey } = input;
  const initialPage = input.initialPage ?? 1;
  const initialAnchorFraction = input.at ?? null;
  const continuousOnly = kind === "readAll";
  const routedChapterKey = input.kind === "chapter" ? input.chapterKey : "";
  const fromChapterKey = input.kind === "readAll" ? (input.from ?? null) : null;

  const queryClient = useQueryClient();
  const router = useRouter();
  const scrollElement = useScrollContainer();
  const prefsSeriesKey = readerSeriesKey(sourceId, seriesKey);
  const seriesHref = seriesPageHref({ sourceId, seriesKey });

  // ---- The strip's identity (was SourceReader / ReadAllReader) -----------------

  // Read-all names the run through the series' own chapter list; a plain
  // chapter has no need of it, so the query stays disabled (no request).
  const chaptersQuery = useSourceChapters(kind === "readAll" ? sourceId : "", seriesKey);
  const order = useMemo(
    () => (kind === "readAll" ? readingOrder(chaptersQuery.data ?? []) : []),
    [chaptersQuery.data, kind],
  );
  const entryChapterKey = useMemo(
    () => (kind === "readAll" ? (readAllEntryKey(order, fromChapterKey) ?? "") : routedChapterKey),
    [fromChapterKey, kind, order, routedChapterKey],
  );

  // The chapter the strip's window is centred on. Starts at the routed key;
  // crossing a seam moves it with no navigation at all.
  const [stripActiveKey, setStripActiveKey] = useState(routedChapterKey);
  const [routed, setRouted] = useState({
    chapterKey: routedChapterKey,
    initialPage,
    initialAnchorFraction,
  });
  if (
    kind === "chapter" &&
    (routed.chapterKey !== routedChapterKey ||
      routed.initialPage !== initialPage ||
      routed.initialAnchorFraction !== initialAnchorFraction)
  ) {
    setRouted({ chapterKey: routedChapterKey, initialPage, initialAnchorFraction });
    setStripActiveKey(routedChapterKey);
  }

  const source = useMemo(
    () =>
      kind === "readAll"
        ? bulkChapterSource(queryClient, sourceId, seriesKey, order)
        : linkedChapterSource(queryClient, sourceId, seriesKey),
    [kind, order, queryClient, seriesKey, sourceId],
  );
  const strip = useChapterStrip({
    entryChapterKey,
    activeChapterKey: stripActiveKey || entryChapterKey,
    source,
    window: kind === "readAll" ? READ_ALL_STRIP_WINDOW : READER_STRIP_WINDOW,
    // Nothing can be named before the chapter list arrives.
    ready: kind === "readAll" ? order.length > 0 && entryChapterKey !== "" : true,
  });

  const bookmark = useBookmarkCapture();
  const chapters = strip.chapters;

  const listFailed =
    kind === "readAll" &&
    (chaptersQuery.isError || (!chaptersQuery.isLoading && order.length === 0));
  const isLoading = kind === "readAll" ? strip.isLoading && !listFailed : strip.isLoading;
  const error = listFailed ? LIST_FAILED : strip.error;
  const refetchChapters = chaptersQuery.refetch;
  const stripReload = strip.reload;
  const onRetry = useCallback(() => {
    if (listFailed) void refetchChapters();
    else stripReload();
  }, [listFailed, refetchChapters, stripReload]);

  const effectiveInitialPage = kind === "chapter" ? routed.initialPage : initialPage;
  const effectiveAnchorFraction =
    kind === "chapter" ? routed.initialAnchorFraction : initialAnchorFraction;

  // ---- Preferences and settings (external stores, shared with the chrome) ------

  const toggleControls = useReaderStore((state) => state.toggleControls);
  const { pageGap, cinema, pageTransition, tapZones, setCinema } = useReaderSettings();
  const {
    readingMode: preferredReadingMode,
    fitMode,
    direction,
    zoom,
    autoScrollSpeed,
    hydrated: preferencesReady,
    update: updatePreferences,
  } = useReaderPreferences(prefsSeriesKey);
  // Resolved once, here, so every layout decision below reads the mode the
  // reader is actually in.
  const readingMode: ReadingMode = continuousOnly ? "continuous" : preferredReadingMode;
  const fullscreen = useFullscreen();

  const scrollSaveTimerRef = useRef<number | null>(null);
  const stripHandleRef = useRef<StripHandle | null>(null);
  const pendingScrollPageRef = useRef<number | null>(null);
  const restoreDoneRef = useRef(false);
  const readingModeRef = useRef(readingMode);
  // How far through the chapter, for the chrome's "62%". Not state: see
  // `reading-percent.ts`.
  const [percentStore] = useState(createReadingPercent);
  const [visiblePage, setVisiblePage] = useState(Math.max(1, initialPage));
  const [activeChapterKey, setActiveChapterKey] = useState(entryChapterKey);
  const [atTop, setAtTop] = useState(false);
  const [atBottom, setAtBottom] = useState(false);
  const helpOpen = useUiStore((state) => state.shortcutsOpen);
  const closeShortcuts = useUiStore((state) => state.closeShortcuts);

  // The chapter the chrome describes: the one whose pages the reader is on.
  const activeIndex = chapterIndexOf(chapters, activeChapterKey);
  const chapter = activeIndex >= 0 ? chapters[activeIndex] : chapters[0];
  const entryChapter = useMemo(
    () => chapters.find((entry) => entry.chapterKey === entryChapterKey) ?? chapters[0],
    [chapters, entryChapterKey],
  );

  const pages = useMemo(() => chapter?.pages ?? [], [chapter]);
  const chapterTitle = chapter ? stripChapterLabel(chapter) : "Chapter";
  const continuous = readingMode === "continuous";

  const previousChapterHref = chapter?.previousChapterKey
    ? readerChapterHref({
        sourceId: chapter.sourceId,
        seriesKey: chapter.seriesKey,
        chapterKey: chapter.previousChapterKey,
      })
    : null;
  const nextChapterHref = chapter?.nextChapterKey
    ? readerChapterHref({
        sourceId: chapter.sourceId,
        seriesKey: chapter.seriesKey,
        chapterKey: chapter.nextChapterKey,
      })
    : null;
  const nextChapterLabel = chapter ? nextChapterLabelFor(chapter) : null;

  const activeChapterKeyRef = useRef(activeChapterKey);
  useEffect(() => {
    activeChapterKeyRef.current = activeChapterKey;
  }, [activeChapterKey]);

  // Follow the route when it names a different chapter.
  const [routedEntry, setRoutedEntry] = useState(entryChapterKey);
  if (routedEntry !== entryChapterKey) {
    setRoutedEntry(entryChapterKey);
    setActiveChapterKey(entryChapterKey);
  }

  // Tap-zone customisation: `tapZones` is null until a reader customises it,
  // and the two views disagree about what "not customised" means.
  const effectiveTapZones = useMemo(
    () => tapZones ?? (continuous ? TOGGLE_ONLY_TAP_ZONES : defaultTapZoneConfig(direction)),
    [tapZones, continuous, direction],
  );

  const autoScroll = useAutoScroll({
    scrollElement,
    active: continuous && Boolean(chapter) && !isLoading && !error,
    // Auto-scroll stops at the end of the STRIP, not at the end of a chapter.
    atBottom,
    pxPerSecond: autoScrollPxPerSecond(autoScrollSpeed),
  });

  const cinemaCtl = useCinema({
    persistedEnabled: cinema,
    scrollElement,
    active: Boolean(chapter) && !isLoading && !error,
    onEnabledChange: setCinema,
    atEnd: continuous && atBottom,
    pagedPosition: continuous ? null : `${activeChapterKey}#${visiblePage}`,
    autoScrolling: autoScroll.playing,
  });

  const chromeVisible = cinemaCtl.chromeVisible;
  const toggleCinema = cinemaCtl.toggle;
  const intendScroll = cinemaCtl.intendScroll;

  useEffect(() => {
    readingModeRef.current = readingMode;
  }, [readingMode]);

  const views = useMemo(
    () => buildPageViews(pages.length, readingMode),
    [pages.length, readingMode],
  );
  const viewIndex = useMemo(() => findViewIndex(views, visiblePage), [views, visiblePage]);
  const currentView = views[viewIndex];

  const entryPages = useMemo(() => entryChapter?.pages ?? [], [entryChapter]);

  // The bookmark this reader was opened from, resolved against what the entry
  // chapter actually holds. `null` unless the route carried a `?at=`.
  const bookmarkTarget = useMemo(() => {
    if (effectiveAnchorFraction == null) return null;
    return resolveAnchor(
      { index: effectiveInitialPage, fraction: effectiveAnchorFraction },
      entryPages.length,
    );
  }, [entryPages.length, effectiveAnchorFraction, effectiveInitialPage]);

  // Where the reader left the ENTRY chapter: a page, and how far into it. The
  // route's own `?page=` wins, a bookmark target outranks both.
  const savedPosition = useMemo((): ReaderPosition | null => {
    if (!entryChapter) return null;
    if (bookmarkTarget) return { page: bookmarkTarget.index, offset: 0 };
    if (effectiveInitialPage > 1) return { page: effectiveInitialPage, offset: 0 };
    return readReaderPosition(chapterScrollKey(entryChapter));
  }, [bookmarkTarget, entryChapter, effectiveInitialPage]);

  // Where the strip lands on its first paint, before anything is measured. An
  // estimate on purpose: the exact landing is done through the strip's handle.
  const initialScrollTop = useMemo(() => {
    if (entryPages.length === 0) {
      return 0;
    }

    const containerWidth = resolveContainerWidth(scrollElement);
    const targetPage = Math.max(1, Math.min(savedPosition?.page ?? 1, entryPages.length));
    const within = bookmarkTarget
      ? bookmarkTarget.fraction *
        estimatePageHeight(entryPages[targetPage - 1], containerWidth, zoom)
      : (savedPosition?.offset ?? 0);
    return estimateResumeOffset({
      position: savedPosition && { page: targetPage, offset: within },
      pageCount: entryPages.length,
      estimatedOffsetToPage: estimateScrollOffsetToPage(
        entryPages,
        targetPage,
        containerWidth,
        zoom,
      ),
    });
  }, [bookmarkTarget, entryPages, savedPosition, scrollElement, zoom]);

  const stripScrollKey = entryChapter ? chapterScrollKey(entryChapter) : entryChapterKey;

  const savedPositionRef = useRef(savedPosition);
  useEffect(() => {
    savedPositionRef.current = savedPosition;
  }, [savedPosition]);

  const bookmarkTargetRef = useRef(bookmarkTarget);
  useEffect(() => {
    bookmarkTargetRef.current = bookmarkTarget;
  }, [bookmarkTarget]);

  // Where to resume the chapter being read, resolved at the moment the reader
  // leaves: a PAGE and a distance into it, not a raw scroll offset.
  const scrollAnchorRef = useRef<() => { key: string; position: ReaderPosition } | null>(
    () => null,
  );
  useEffect(() => {
    scrollAnchorRef.current = () => {
      if (!scrollElement || !chapter || pages.length === 0) return null;
      const key = chapterScrollKey(chapter);
      if (readingModeRef.current !== "continuous") {
        return { key, position: { page: visiblePage, offset: 0 } };
      }
      const start = stripHandleRef.current?.pageStart(chapter.chapterKey, visiblePage);
      return {
        key,
        position: {
          page: visiblePage,
          offset: start == null ? 0 : scrollElement.scrollTop - start,
        },
      };
    };
  }, [chapter, pages.length, scrollElement, visiblePage]);

  useEffect(() => {
    return () => {
      if (scrollSaveTimerRef.current) {
        clearTimeout(scrollSaveTimerRef.current);
        scrollSaveTimerRef.current = null;
      }
      const anchor = scrollAnchorRef.current();
      if (anchor != null) {
        writeReaderPosition(anchor.key, anchor.position);
      }
      clearChapterScrollPreparation(stripScrollKey);
    };
  }, [scrollElement, stripScrollKey]);

  useEffect(() => {
    readerDebug("route-entered", {
      entryChapterKey,
      initialPage,
      isLoading,
      chapters: chapters.length,
    });
  }, [entryChapterKey, initialPage, isLoading, chapters.length]);

  useEffect(() => {
    if (isLoading) {
      readerDebug("loading-state", { entryChapterKey, reason: "chapter-pending" });
    }
  }, [isLoading, entryChapterKey]);

  useEffect(() => {
    if (!chapter) return;
    readerDebug("chapter-render-ready", {
      chapterKey: chapter.chapterKey,
      pagesLength: pages.length,
      title: chapter.title,
    });
  }, [chapter, pages.length]);

  const handleImagesReady = useCallback(() => {
    readerDebug("reader-ready", {
      entryChapterKey,
      pageCount: pages.length,
      scrollReady: Boolean(scrollElement),
    });
  }, [entryChapterKey, pages.length, scrollElement]);

  // ---- Progress ---------------------------------------------------------------

  /**
   * The run's URL names the chapter being read, so a refresh resumes there
   * rather than at the top: the plain reader corrects `/reader/...`, Read-all
   * corrects its `?from=`.
   */
  const handleChapterChange = useCallback(
    (nextChapterKey: string) => {
      setStripActiveKey(nextChapterKey);
      window.history.replaceState(
        window.history.state,
        "",
        kind === "readAll"
          ? readAllHref({ sourceId, seriesKey }, nextChapterKey)
          : readerChapterHref({ sourceId, seriesKey, chapterKey: nextChapterKey }),
      );
    },
    [kind, seriesKey, sourceId],
  );

  const onPosition = useStripProgress({
    sourceId,
    seriesKey,
    chapters,
    onChapterChange: handleChapterChange,
  });

  // The strip's report, on every scroll frame: which chapter, which page.
  const handleStripPosition = useCallback(
    (position: StripPosition) => {
      setActiveChapterKey(position.chapterKey);
      setVisiblePage(position.pageNumber);
      onPosition(position);
    },
    [onPosition],
  );

  // The paged modes' report: one per screen, through the same `onPosition`.
  const pagedPosition = pagedProgressPosition(
    readingMode,
    chapter?.chapterKey,
    currentView,
    pages.length,
  );
  const pagedChapterKey = pagedPosition?.chapterKey;
  const pagedPageNumber = pagedPosition?.pageNumber;
  const pagedPageCount = pagedPosition?.pageCount;
  useEffect(() => {
    if (pagedChapterKey == null || pagedPageNumber == null || pagedPageCount == null) return;
    onPosition({
      chapterKey: pagedChapterKey,
      pageNumber: pagedPageNumber,
      pageCount: pagedPageCount,
    });
  }, [onPosition, pagedChapterKey, pagedPageCount, pagedPageNumber]);

  const registerStripHandle = useCallback(
    (handle: StripHandle | null) => {
      stripHandleRef.current = handle;
      if (!handle) return;

      // A pending target means the strip was just re-entered from a paged mode.
      const pending = pendingScrollPageRef.current;
      if (pending != null) {
        pendingScrollPageRef.current = null;
        handle.scrollToPosition(activeChapterKeyRef.current, pending);
        return;
      }

      // The exact landing for a resumed chapter, done once and only through the
      // strip: it is the only thing that knows where a page really begins.
      if (restoreDoneRef.current) return;
      restoreDoneRef.current = true;

      // A bookmark lands on the exact position: the exact inverse of
      // `captureAnchor` below.
      const target = bookmarkTargetRef.current;
      if (target) {
        const extent = handle.pageExtent(entryChapterKey, target.index);
        const offset = extent
          ? Math.round(
              pointWithin(target.fraction, extent.start, extent.end) -
                extent.start -
                READING_LINE_PX,
            )
          : 0;
        handle.scrollToPosition(entryChapterKey, target.index, Math.max(0, offset));
        return;
      }

      const saved = savedPositionRef.current;
      if (!saved || (saved.page <= 1 && saved.offset <= 0)) return;
      handle.scrollToPosition(entryChapterKey, saved.page, saved.offset);
    },
    [entryChapterKey],
  );

  const updateScrollState = useCallback(() => {
    if (!scrollElement || chapters.length === 0) return;
    if (readingModeRef.current !== "continuous") return;

    const { scrollTop, scrollHeight, clientHeight } = scrollElement;
    // Progress is per CHAPTER, not per strip.
    const range = stripHandleRef.current?.chapterRange(activeChapterKey);
    if (range && range.end > range.start) {
      const span = Math.max(1, range.end - range.start - clientHeight);
      const ratio = (scrollTop - range.start) / span;
      percentStore.set(Math.min(1, Math.max(0, ratio)) * 100);
    } else {
      const maxScroll = Math.max(scrollHeight - clientHeight, 0);
      percentStore.set(maxScroll > 0 ? (scrollTop / maxScroll) * 100 : 100);
    }
    setAtTop(scrollTop <= SCROLL_EDGE_THRESHOLD);
    setAtBottom(scrollTop + clientHeight >= scrollHeight - SCROLL_EDGE_THRESHOLD);

    if (scrollSaveTimerRef.current) {
      clearTimeout(scrollSaveTimerRef.current);
    }
    scrollSaveTimerRef.current = window.setTimeout(() => {
      const anchor = scrollAnchorRef.current();
      if (anchor) writeReaderPosition(anchor.key, anchor.position);
      scrollSaveTimerRef.current = null;
    }, SCROLL_SAVE_MS);
    // Re-made whenever the active chapter changes OR the strip does, so the
    // listener effect below re-attaches and recomputes at once.
  }, [activeChapterKey, chapters, percentStore, scrollElement]);

  // The paged modes have no scroll, so their percent is the page's place in
  // the chapter.
  const pagedPercent = continuous ? null : scrubPercent(visiblePage, pages.length);
  useLayoutEffect(() => {
    if (pagedPercent != null) percentStore.set(pagedPercent);
  }, [pagedPercent, percentStore]);

  useEffect(() => {
    if (!scrollElement) return;

    let frame = 0;
    const handleScroll = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(updateScrollState);
    };

    handleScroll();
    scrollElement.addEventListener("scroll", handleScroll, { passive: true });
    return () => {
      scrollElement.removeEventListener("scroll", handleScroll);
      cancelAnimationFrame(frame);
    };
  }, [scrollElement, updateScrollState]);

  // The strip's opening position, applied once, and only while the entry
  // chapter is still the strip's FIRST chapter.
  const stripAnchored = chapters[0]?.chapterKey === entryChapterKey;
  useLayoutEffect(() => {
    if (isLoading || error || !chapter || entryPages.length === 0 || !scrollElement) {
      return;
    }
    if (!stripAnchored) return;
    syncChapterScroll(stripScrollKey, scrollElement, initialScrollTop);
  }, [
    chapter,
    entryPages.length,
    error,
    initialScrollTop,
    isLoading,
    scrollElement,
    stripAnchored,
    stripScrollKey,
  ]);

  // ---- Navigation commands ----------------------------------------------------

  /** A chapter already in the strip is a scroll away; anything else is a route. */
  const jumpToChapter = useCallback(
    (chapterKey: string | null, href: string | null, page: number) => {
      if (!chapterKey) return;
      const handle = stripHandleRef.current;
      if (continuous && handle && chapterIndexOf(chapters, chapterKey) >= 0) {
        handle.scrollToPosition(chapterKey, page);
        return;
      }
      if (href) router.push(href);
    },
    [chapters, continuous, router],
  );

  const goPreviousChapter = useCallback(() => {
    const previousKey = chapter?.previousChapterKey ?? null;
    // "Last page" is only knowable for a chapter already loaded.
    const loaded = previousKey ? chapters[chapterIndexOf(chapters, previousKey)] : undefined;
    jumpToChapter(previousKey, previousChapterHref, loaded ? loaded.pages.length : 1);
  }, [chapter, chapters, jumpToChapter, previousChapterHref]);

  const goNextChapter = useCallback(() => {
    jumpToChapter(chapter?.nextChapterKey ?? null, nextChapterHref, 1);
  }, [chapter, jumpToChapter, nextChapterHref]);

  const goToPage = useCallback(
    (pageNumber: number) => {
      if (pages.length === 0 || !chapter) return;
      const target = Math.min(pages.length, Math.max(1, Math.round(pageNumber)));
      setVisiblePage(target);

      if (readingMode !== "continuous") return;

      const handle = stripHandleRef.current;
      if (handle) {
        handle.scrollToPosition(chapter.chapterKey, target);
      } else {
        setReaderScrollTop(
          scrollElement,
          estimateScrollOffsetToPage(
            pages,
            target,
            resolveContainerWidth(scrollElement),
            zoom,
          ),
        );
      }
    },
    [chapter, pages, readingMode, scrollElement, zoom],
  );

  const turnPage = useCallback(
    (turn: PageTurn) => {
      if (pages.length === 0) return;
      const step = turn === "advance" ? 1 : -1;

      if (readingMode === "continuous") {
        intendScroll();
        const target = visiblePage + step;
        if (target < 1) {
          goPreviousChapter();
          return;
        }
        if (target > pages.length) {
          goNextChapter();
          return;
        }
        goToPage(target);
        return;
      }

      // Paged modes have a hard edge, so a turn past it continues into the
      // neighbouring chapter.
      const nextIndex = viewIndex + step;
      if (nextIndex < 0) {
        goPreviousChapter();
        return;
      }
      if (nextIndex >= views.length) {
        goNextChapter();
        return;
      }
      goToPage(viewLeadPage(views[nextIndex]));
    },
    [
      goNextChapter,
      goPreviousChapter,
      goToPage,
      intendScroll,
      pages.length,
      readingMode,
      viewIndex,
      views,
      visiblePage,
    ],
  );

  const scrollScreen = useCallback(
    (turn: PageTurn) => {
      if (readingMode !== "continuous") {
        turnPage(turn);
        return;
      }
      if (!scrollElement) return;
      const delta = Math.max(160, scrollElement.clientHeight * SCREEN_SCROLL_RATIO);
      scrollReaderBy(scrollElement, turn === "advance" ? delta : -delta);
    },
    [readingMode, scrollElement, turnPage],
  );

  const handleTap = useCallback(
    (zone: TapZone) => {
      // A tap always hands control back from auto-scroll.
      autoScroll.pause();
      if (zone === "toggle") {
        // In cinema mode a tap reveals the chrome rather than latching it.
        if (cinemaCtl.enabled) cinemaCtl.notifyActivity();
        else toggleControls();
        return;
      }
      turnPage(zone);
    },
    [autoScroll, cinemaCtl, toggleControls, turnPage],
  );

  const onFrameClick = useCallback(
    (event: { clientX: number; currentTarget: Element }) => {
      const rect = event.currentTarget.getBoundingClientRect();
      handleTap(resolveTapZone(event.clientX, rect, effectiveTapZones));
    },
    [effectiveTapZones, handleTap],
  );

  // ---- Bookmarks --------------------------------------------------------------

  /**
   * The exact spot being read, in one action. A paged mode reports 0.0 and
   * means it: the stage shows one page fitted to the viewport.
   */
  const captureAnchor = useCallback((): CapturedAnchor => {
    const total = pages.length;
    if (!continuous || !scrollElement || !chapter) {
      return { index: visiblePage, fraction: 0, total };
    }
    const extent = stripHandleRef.current?.pageExtent(chapter.chapterKey, visiblePage);
    const fraction = extent
      ? fractionWithin(scrollElement.scrollTop + READING_LINE_PX, extent.start, extent.end)
      : 0;
    return { index: visiblePage, fraction, total };
  }, [chapter, continuous, pages.length, scrollElement, visiblePage]);

  /** The bookmark body for the spot being read, or null when none exists yet. */
  const bookmarkBody = useCallback((): BookmarkCreate | null => {
    const chapterKey = stripActiveKey || entryChapterKey;
    if (!chapterKey) return null;
    const anchor = captureAnchor();
    return {
      source_id: sourceId,
      series_key: seriesKey,
      chapter_key: chapterKey,
      chapter_number: chapters[chapterIndexOf(chapters, chapterKey)]?.chapterNumber ?? null,
      media_type: BOOKMARK_MEDIA_MANGA,
      anchor_index: anchor.index,
      anchor_fraction: anchor.fraction,
      anchor_total: anchor.total,
    };
  }, [captureAnchor, chapters, entryChapterKey, seriesKey, sourceId, stripActiveKey]);

  const { capture: captureBookmark, captureAsync: captureBookmarkAsync } = bookmark;
  const handleBookmark = useCallback(() => {
    const body = bookmarkBody();
    if (body) captureBookmark(body);
  }, [bookmarkBody, captureBookmark]);
  const bookmarkCommand = useCallback(async (): Promise<"saved" | "failed"> => {
    const body = bookmarkBody();
    if (!body) return "failed";
    try {
      await captureBookmarkAsync(body);
      return "saved";
    } catch {
      return "failed";
    }
  }, [bookmarkBody, captureBookmarkAsync]);

  // "Say so quietly": the chapter lost pages since this bookmark was made, so it
  // opened at the nearest page that still exists. Timed, not dismissible.
  const anchorMoved = bookmarkTarget?.stale ?? false;
  const [movedNoticeDismissed, setMovedNoticeDismissed] = useState(false);
  useEffect(() => {
    if (!anchorMoved) return;
    const timer = window.setTimeout(() => setMovedNoticeDismissed(true), MOVED_NOTICE_MS);
    return () => window.clearTimeout(timer);
  }, [anchorMoved]);
  const movedNoticeVisible = anchorMoved && !movedNoticeDismissed;

  // ---- Zoom, mode, wheel ------------------------------------------------------

  const zoomIn = useCallback(
    () => updatePreferences({ zoom: zoomBy(zoom, 1) }),
    [updatePreferences, zoom],
  );
  const zoomOut = useCallback(
    () => updatePreferences({ zoom: zoomBy(zoom, -1) }),
    [updatePreferences, zoom],
  );
  const resetZoom = useCallback(() => updatePreferences({ zoom: 1 }), [updatePreferences]);
  const zoomSteps = useCallback(
    (steps: number) => updatePreferences({ zoom: zoomBy(zoom, steps) }),
    [updatePreferences, zoom],
  );

  // Switching back to the strip lands on the page that was on screen. The target
  // is queued rather than applied: the list has not mounted yet.
  const changeReadingMode = useCallback(
    (mode: ReadingMode) => {
      if (mode === readingMode) return;
      if (mode === "continuous" && pages.length > 0) {
        pendingScrollPageRef.current = visiblePage;
        setAtTop(false);
        setAtBottom(false);
      }
      updatePreferences({ readingMode: mode });
    },
    [pages.length, readingMode, updatePreferences, visiblePage],
  );

  // Same wheel contract as the paged stage: ctrl/cmd+wheel zooms, a plain wheel
  // scrolls. The passive listener does the zoom and ARMS a non-passive one on a
  // modifier (see `installWheelZoomArming`).
  useEffect(() => {
    if (!scrollElement || !continuous) return;
    return installWheelZoomArming({
      scroller: scrollElement,
      keys: window,
      zoom: (event) => {
        const steps = wheelZoomSteps(event);
        if (steps !== 0) zoomSteps(steps);
        return steps !== 0;
      },
    });
  }, [continuous, scrollElement, zoomSteps]);

  // Keep scrolling UP at the top of the strip and the chapter before it is
  // pulled onto the head: a sustained overscroll, not "you touched the top".
  const loadPrevious = strip.loadPrevious;
  const loadPreviousRef = useRef(loadPrevious);
  useEffect(() => {
    loadPreviousRef.current = loadPrevious;
  }, [loadPrevious]);
  useEffect(() => {
    if (!scrollElement || !continuous || !atTop) return;
    let overscroll = 0;
    let resetTimer: number | null = null;
    const handleWheel = (event: WheelEvent) => {
      if (event.ctrlKey || event.metaKey || event.deltaY >= 0) return;
      overscroll -= event.deltaY;
      if (resetTimer) window.clearTimeout(resetTimer);
      resetTimer = window.setTimeout(() => {
        overscroll = 0;
      }, 320);
      if (overscroll >= OVERSCROLL_TRIGGER) {
        overscroll = 0;
        loadPreviousRef.current();
      }
    };
    scrollElement.addEventListener("wheel", handleWheel, { passive: true });
    return () => {
      scrollElement.removeEventListener("wheel", handleWheel);
      if (resetTimer) window.clearTimeout(resetTimer);
    };
  }, [scrollElement, continuous, atTop]);

  const handleEscape = useCallback(() => {
    switch (resolveEscapeTarget({ helpOpen, fullscreen: fullscreen.active })) {
      case "help":
        closeShortcuts();
        return;
      case "fullscreen":
        fullscreen.exit();
        return;
      default:
        // Peel cinema mode before leaving the reader.
        if (cinemaCtl.enabled) {
          toggleCinema();
          return;
        }
        router.push(seriesHref);
    }
  }, [
    cinemaCtl.enabled,
    closeShortcuts,
    fullscreen,
    helpOpen,
    router,
    seriesHref,
    toggleCinema,
  ]);

  // Leave the chapter for its series page. Fullscreen survives a client-side
  // navigation, so it is dropped first.
  const openSeries = useCallback(() => {
    fullscreen.exit();
    router.push(seriesHref);
  }, [fullscreen, router, seriesHref]);

  useReaderShortcuts({
    direction,
    onTurnPage: turnPage,
    onScrollScreen: scrollScreen,
    onFirstPage: () => goToPage(1),
    onLastPage: () => goToPage(pages.length),
    onToggleFullscreen: fullscreen.toggle,
    onToggleCinema: toggleCinema,
    // A no-op outside continuous mode: auto-scroll only ever drives the strip.
    onToggleAutoScroll: () => {
      if (continuous) autoScroll.toggle();
    },
    onEscape: handleEscape,
    onPreviousChapter: () => {
      intendScroll();
      goPreviousChapter();
    },
    onNextChapter: () => {
      intendScroll();
      goNextChapter();
    },
    onOpenSeries: openSeries,
    onBookmark: handleBookmark,
    onZoomIn: zoomIn,
    onZoomOut: zoomOut,
    onZoomReset: resetZoom,
  });

  // The strip pulls the next chapter itself and warms images straight across
  // the seam, so this is only for the paged modes.
  const preloadNextChapter = useCallback(async () => {
    const nextKey = chapter?.nextChapterKey;
    if (!nextKey || kind !== "chapter") return [];
    return ensureChapterPages(queryClient, { sourceId, seriesKey, chapterKey: nextKey });
  }, [chapter?.nextChapterKey, kind, queryClient, seriesKey, sourceId]);
  useChapterPreload({
    chapterKey: activeChapterKey,
    page: visiblePage,
    pageCount: pages.length,
    hasNextChapter: !continuous && chapter?.nextChapterKey != null && kind === "chapter",
    loadNextChapter: kind === "chapter" ? preloadNextChapter : NO_PRELOAD,
  });

  // ---- Next-chapter auto-queue (cinematic §8.14.11) ---------------------------
  // Quiet by design: no toast, no haptic. Off for legacy (`autoQueueNext:
  // false`), which then also never fetches `GET /settings` for it.
  const status: ReaderEngineState["status"] =
    isLoading || !preferencesReady
      ? "loading"
      : error
        ? "error"
        : !chapter || pages.length === 0
          ? "empty"
          : "ready";

  const downloadsScope = useStorageScope();
  const offlineIndex = useOfflineState();
  const capabilities = useContentPreferences({ enabled: autoQueueNext }).data?.capabilities;
  const saver = useMangaChapterSaver({ sourceId, seriesKey, seriesTitle: null });
  const queuedNextRef = useRef<Set<string>>(new Set());
  const nextKeyToQueue = chapter?.nextChapterKey ?? null;
  const offlineEntries = offlineIndex.entries;
  useEffect(() => {
    if (!autoQueueNext || status !== "ready" || !nextKeyToQueue) return;
    const queueKey = `${sourceId}/${seriesKey}/${nextKeyToQueue}`;
    let cancelled = false;
    void (async () => {
      let freeBytes: number | null = null;
      try {
        const estimate = await navigator.storage?.estimate?.();
        if (estimate?.quota != null && estimate.usage != null) {
          freeBytes = estimate.quota - estimate.usage;
        }
      } catch {
        // Unknown storage counts as enough.
      }
      if (cancelled) return;
      const nextKey = chapterCacheKey({ sourceId, seriesKey, chapterKey: nextKeyToQueue });
      if (
        !shouldAutoQueueNext({
          medium: "manga",
          hasProfileScope: downloadsScope !== null,
          serviceWorkerSupported: isServiceWorkerSupported(),
          capabilityOn: capabilities?.client_downloads === true,
          hasNextChapter: true,
          nextSaved: offlineEntries.some((entry) => entry.key === nextKey),
          alreadyQueued: queuedNextRef.current.has(queueKey),
          switchOn: readSaveNext(),
          freeBytes,
        })
      ) {
        return;
      }
      queuedNextRef.current.add(queueKey);
      try {
        const request = await saver.buildRequest(nextKeyToQueue);
        if (request) await saveChapterOffline(request);
      } catch {
        // Speculative: the reader's own Save control still works.
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [
    autoQueueNext,
    capabilities?.client_downloads,
    downloadsScope,
    nextKeyToQueue,
    offlineEntries,
    saver,
    seriesKey,
    sourceId,
    status,
  ]);

  // ---- The published shape ----------------------------------------------------

  // Cached bookmarks of this series, never fetched from here: `[]` until some
  // screen has loaded them.
  const bookmarksQuery = useQuery({
    queryKey: bookmarksQueryKey({ sourceId, seriesKey }),
    queryFn: skipToken,
  });
  const cachedBookmarks = (bookmarksQuery.data as readonly Bookmark[] | undefined) ?? NO_BOOKMARKS;
  const chapterKeyNow = chapter?.chapterKey;
  const stateBookmarks = useMemo(
    () =>
      cachedBookmarks
        .filter((b) => b.chapter_key === chapterKeyNow)
        .map((b) => ({ page: b.anchor_index, fraction: b.anchor_fraction })),
    [cachedBookmarks, chapterKeyNow],
  );

  const refFor = (key: string | null, edgeLabel: string | null, edgeKey: string | null): ChapterRef | null => {
    if (!key) return null;
    const loaded = chapters[chapterIndexOf(chapters, key)];
    return {
      chapterKey: key,
      label: loaded ? stripChapterLabel(loaded) : edgeKey === key ? (edgeLabel ?? "") : "",
      number: loaded?.chapterNumber ?? null,
    };
  };
  const nextKey = chapter?.nextChapterKey ?? null;
  const nextState: NextState = strip.nextError
    ? "failed"
    : nextKey && chapterIndexOf(chapters, nextKey) >= 0
      ? "ready"
      : nextKey || strip.tail.chapterKey
        ? "loading"
        : "none";
  const positionInSeries =
    kind === "readAll" ? orderIndexOf(order, activeChapterKey || entryChapterKey) : -1;

  const state: ReaderEngineState = {
    kind,
    layout: readingMode === "continuous" ? "strip" : readingMode,
    status,
    error: error ?? null,
    chapter: chapter
      ? {
          sourceId: chapter.sourceId,
          seriesKey: chapter.seriesKey,
          chapterKey: chapter.chapterKey,
          label: chapterTitle,
          number: chapter.chapterNumber ?? null,
        }
      : null,
    page: visiblePage,
    pageCount: pages.length,
    progress: percentStore.get() / 100,
    chapterPosition:
      positionInSeries >= 0 ? { index: positionInSeries + 1, total: order.length } : null,
    neighbours: {
      previous: refFor(chapter?.previousChapterKey ?? null, strip.head.label, strip.head.chapterKey),
      next: refFor(nextKey, strip.tail.label, strip.tail.chapterKey),
      loadedKeys: chapters.map((entry) => entry.chapterKey),
    },
    nextState,
    bookmarks: stateBookmarks,
    zoom,
    autoScroll: { playing: autoScroll.playing, speed: autoScrollSpeed },
    chromeVisible,
    cinema: cinemaCtl.enabled,
  };

  const commands = {
    seek: (fraction: number) =>
      goToPage(1 + Math.round(Math.min(1, Math.max(0, fraction)) * Math.max(0, pages.length - 1))),
    // ponytail: glide is accepted for later skins; the strip's own jump is instant today.
    jumpToPage: (page: number) => goToPage(page),
    next: goNextChapter,
    previous: goPreviousChapter,
    toggleAutoScroll: () => {
      if (continuous) autoScroll.toggle();
    },
    setSpeed: (speed: number) => updatePreferences({ autoScrollSpeed: speed }),
    zoom: (scale: number) => updatePreferences({ zoom: clampZoom(scale) }),
    bookmark: bookmarkCommand,
    setChromeVisible: (visible: boolean) =>
      useReaderStore.getState().setControlsVisible(visible),
  };

  return {
    state,
    commands,
    surface: {
      layout: state.layout,
      chapters,
      stripKey: stripScrollKey,
      scrollElement,
      initialScrollTop,
      zoom,
      pageGap,
      onPositionChange: handleStripPosition,
      onImagesReady: handleImagesReady,
      onHandleReady: registerStripHandle,
      head: {
        edge: strip.head,
        href:
          strip.head.chapterKey && chapter
            ? readerChapterHref({
                sourceId: chapter.sourceId,
                seriesKey: chapter.seriesKey,
                chapterKey: strip.head.chapterKey,
              })
            : null,
        visible: atTop && Boolean(strip.head.chapterKey),
        loading: strip.loadingPrevious,
        load: loadPrevious,
      },
      tail: {
        edge: strip.tail,
        hasMore: Boolean(strip.tail.chapterKey),
        href:
          strip.tail.chapterKey && chapter
            ? readerChapterHref({
                sourceId: chapter.sourceId,
                seriesKey: chapter.seriesKey,
                chapterKey: strip.tail.chapterKey,
              })
            : null,
        error: strip.nextError,
        retry: strip.retryNext,
      },
      paged: {
        pages,
        chapterTitle,
        view: currentView ?? FIRST_PAGE_VIEW,
        slotsPerView: readingMode === "double" ? 2 : 1,
        direction,
        fitMode: effectiveFitMode(fitMode, readingMode),
        pageTransition,
      },
      tapZones: effectiveTapZones,
      onTap: handleTap,
      onZoomSteps: zoomSteps,
    },
    extras: {
      progressStore: percentStore,
      activeChapter: chapter ?? null,
      seriesHref,
      prefsSeriesKey,
      previousChapterHref,
      nextChapterHref,
      nextChapterLabel,
      setReadingMode: changeReadingMode,
      openSeries,
      toggleCinema,
      reducedMotion: { cinema: cinemaCtl.reducedMotion, autoScroll: autoScroll.reducedMotion },
      bookmarkPending: bookmark.pending,
      bookmarkSaved: bookmark.justSaved,
      bookmarkFailed: bookmark.failed,
      movedNoticeVisible,
      onFrameClick,
      onRetry,
    },
  };
}
