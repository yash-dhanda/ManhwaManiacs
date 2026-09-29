import type { ReadingPercentStore } from "@/features/novels/reading-percent";
import type { TapZone, TapZoneConfig } from "../keymap";
import type { StripChapter, StripPosition } from "../strip";
import type { StripEdge } from "../use-chapter-strip";
import type { FitMode, ReaderPage, ReadingDirection } from "../types";
import type { StripHandle } from "./ContinuousStrip";

/**
 * The skin-neutral reader engine's contract (cinematic §15.4). State and
 * commands only; every pixel is a skin's. Fields later steps add (`pageTint`,
 * `panels`, words on screen, `chapterCompleted`, and Glass's
 * `currentPageSample`, `scrollVelocity`, `seamProgress`, `overscrollExtent`,
 * `panelBoxes`) arrive with web/12, web/23 and web/34, not here.
 */
export type NextState = "loading" | "ready" | "failed" | "none";

export interface ChapterRef {
  chapterKey: string;
  label: string;
  number: number | null;
}

export interface ReaderEngineState {
  kind: "chapter" | "readAll";
  layout: "strip" | "single" | "double";
  status: "loading" | "ready" | "error" | "empty";
  error: string | null;
  chapter: {
    sourceId: string;
    seriesKey: string;
    chapterKey: string;
    label: string;
    number: number | null;
  } | null;
  /** 1-based page in the current chapter. */
  page: number;
  pageCount: number;
  /**
   * 0-1 through the current chapter. A snapshot taken when the engine last
   * rendered: in the strip it moves with every scroll frame, and re-rendering
   * the reader for it was the cost `reading-percent.ts` exists to avoid. A
   * chrome that shows it live subscribes to `engine.progressStore` instead.
   */
  progress: number;
  /** Read-all "n of total"; `index` is the 1-based n. */
  chapterPosition: { index: number; total: number } | null;
  neighbours: {
    previous: ChapterRef | null;
    next: ChapterRef | null;
    loadedKeys: readonly string[];
  };
  nextState: NextState;
  /** Current chapter, for the ruler. */
  bookmarks: readonly { page: number; fraction: number }[];
  /** 1 = fit. */
  zoom: number;
  /** Today's 1-10 steps (20-220 px/s). */
  autoScroll: { playing: boolean; speed: number };
  chromeVisible: boolean;
  cinema: boolean;
}

export interface ReaderEngineCommands {
  seek(fraction: number): void;
  jumpToPage(page: number, opts?: { glide?: boolean }): void;
  next(): void;
  previous(): void;
  toggleAutoScroll(): void;
  setSpeed(speed: number): void;
  zoom(scale: number): void;
  bookmark(): Promise<"saved" | "failed">;
  setChromeVisible(visible: boolean): void;
}

/** Everything `ContinuousStrip` or `PagedView` needs, and the strip's two ends. */
export interface SurfaceBindings {
  layout: ReaderEngineState["layout"];
  chapters: readonly StripChapter[];
  /** Remounts the strip when the entry chapter changes. */
  stripKey: string;
  scrollElement: HTMLElement | null;
  initialScrollTop: number;
  zoom: number;
  pageGap: boolean;
  onPositionChange(position: StripPosition): void;
  onImagesReady(): void;
  onHandleReady(handle: StripHandle | null): void;
  head: {
    edge: StripEdge;
    href: string | null;
    /** At the top of the strip and something is waiting above. */
    visible: boolean;
    loading: boolean;
    load(): void;
  };
  tail: {
    edge: StripEdge;
    hasMore: boolean;
    href: string | null;
    error: string | null;
    retry(): void;
  };
  paged: {
    pages: ReaderPage[];
    chapterTitle: string;
    /** Page numbers on screen, in reading order. */
    view: number[];
    slotsPerView: number;
    direction: ReadingDirection;
    fitMode: FitMode;
    pageTransition: boolean;
  };
  tapZones: TapZoneConfig;
  onTap(zone: TapZone): void;
  onZoomSteps(steps: number): void;
}

/**
 * What the legacy chrome needs beyond state and commands. A new skin builds
 * from `state` and `commands`; these are conveniences that exist because the
 * legacy frame reads more of the reader's internals than a skin should.
 */
export interface ReaderEngineExtras {
  /** Live percent read-out, 0-100. */
  progressStore: ReadingPercentStore;
  /** The active chapter with its pages: what the download control saves. */
  activeChapter: StripChapter | null;
  seriesHref: string;
  previousChapterHref: string | null;
  nextChapterHref: string | null;
  nextChapterLabel: string | null;
  setReadingMode(mode: "continuous" | "single" | "double"): void;
  openSeries(): void;
  toggleCinema(): void;
  reducedMotion: { cinema: boolean; autoScroll: boolean };
  bookmarkPending: boolean;
  bookmarkSaved: boolean;
  bookmarkFailed: boolean;
  /** "That page is gone from this chapter", while it should still be shown. */
  movedNoticeVisible: boolean;
  /** The frame's own click target: tap anywhere in the strip. */
  onFrameClick(event: { clientX: number; currentTarget: Element }): void;
  /** Retry the entry chapter (or the series chapter list). */
  onRetry(): void;
}

export interface ReaderEngine {
  state: ReaderEngineState;
  commands: ReaderEngineCommands;
  surface: SurfaceBindings;
  extras: ReaderEngineExtras;
}

export type ReaderEngineInput =
  | {
      kind: "chapter";
      sourceId: string;
      seriesKey: string;
      chapterKey: string;
      initialPage?: number;
      at?: number | null;
    }
  | {
      kind: "readAll";
      sourceId: string;
      seriesKey: string;
      from?: string | null;
      initialPage?: number;
      at?: number | null;
    };
