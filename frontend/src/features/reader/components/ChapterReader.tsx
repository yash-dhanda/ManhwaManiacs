"use client";

import { useMemo } from "react";
import { cn } from "@/lib/cn";
import { moodReaderMargin, useActiveProfileStore } from "@/features/profiles";
import { DownloadChapterControl } from "@/features/offline";
import { BookmarkNotice } from "@/features/bookmarks";
import { zoomBy } from "../fit";
import { ReaderEngineView } from "../engine/ReaderEngineView";
import type { ReaderEngine } from "../engine/types";
import type { ReadingMode } from "../types";
import { useReaderPreferences } from "../use-reader-preferences";
import { useReaderSettings } from "../use-reader-settings";
import { useFullscreen } from "../use-fullscreen";
import { useUiStore } from "@/stores/ui-store";
import { createLegacySurfaceSlots } from "./legacy-surface-slots";
import { ReaderControls } from "./ReaderControls";

interface ChapterReaderProps {
  engine: ReaderEngine;
}

/**
 * The legacy reader frame. The reader's state and commands live in
 * `useReaderEngine`; this renders today's chrome around `ReaderEngineView`:
 * the frame, the dimmer and warmth washes, the download control, the counter
 * pill, the controls and the bookmark notice. Deleted at the flip, together
 * with `legacy-surface-slots.tsx`.
 */
export function ChapterReader({ engine }: ChapterReaderProps) {
  const { state, commands, extras } = engine;
  const { seriesHref } = extras;
  const slots = useMemo(() => createLegacySurfaceSlots(seriesHref), [seriesHref]);

  const { fitMode, direction, autoScrollSpeed, update: updatePreferences } =
    useReaderPreferences(extras.prefsSeriesKey);
  const {
    pageGap,
    dimmer,
    warmth,
    pageTransition,
    togglePageGap,
    togglePageTransition,
    setDimmer,
    setWarmth,
    setTapZones,
  } = useReaderSettings();
  const fullscreen = useFullscreen();
  const toggleShortcuts = useUiStore((s) => s.toggleShortcuts);

  const continuous = state.layout === "strip";
  const readingMode: ReadingMode = state.layout === "strip" ? "continuous" : state.layout;
  const zoom = state.zoom;
  const effectiveTapZones = engine.surface.tapZones;

  // Ambient mood tint, but only in the gutters beside the page column — the page
  // itself stays pure obsidian. `default` mood → "transparent" → no wash.
  const mood = useActiveProfileStore((s) => s.activeProfile?.mood ?? "default");
  const marginWash = moodReaderMargin(mood);
  const gutterBackground =
    marginWash === "transparent"
      ? undefined
      : `linear-gradient(90deg, ${marginWash} 0%, transparent calc((100% - 48rem) / 2), transparent calc(100% - (100% - 48rem) / 2), ${marginWash} 100%)`;

  const bookmarkNotice = extras.bookmarkFailed
    ? { tone: "failed" as const, text: "Couldn't save that spot." }
    : extras.bookmarkSaved
      ? { tone: "saved" as const, text: "Saved this spot." }
      : extras.movedNoticeVisible
        ? {
            tone: "moved" as const,
            text: "That page is gone from this chapter — opened at the nearest one.",
          }
        : null;

  return (
    <ReaderEngineView
      engine={engine}
      slots={slots}
      renderFrame={(children) => (
        <div
          className={cn(
            "relative flex flex-col bg-bg",
            continuous ? "min-h-full scroll-smooth" : "h-full overflow-hidden",
          )}
          style={gutterBackground ? { background: gutterBackground } : undefined}
          // The paged view owns its own clicks (edge zones turn the page), so the
          // tap-anywhere-by-default toggle is wired only for the strip. Goes
          // through the same `resolveTapZone` + `handleTap` as the paged stage,
          // so a customised tap-zone config applies here too.
          onClick={continuous ? extras.onFrameClick : undefined}
          role="presentation"
        >
          {children}
        </div>
      )}
      renderUnderlay={() => (
        <>
          {/* Night-reading dimmer + warmth overlays. Pure CSS opacity over the
              pages, `pointer-events-none` so they never intercept a tap or the
              scrub bar, and z-10 keeps them beneath every piece of chrome
              (including the page counter) so the controls stay reachable no
              matter how far either slider is pushed. Persist per profile; see
              `reader-settings.ts`. */}
          {dimmer > 0 ? (
            <div
              aria-hidden
              className="pointer-events-none fixed inset-0 z-10 bg-bg"
              style={{ opacity: dimmer }}
            />
          ) : null}
          {warmth > 0 ? (
            <div
              aria-hidden
              // A flat wash, NOT mix-blend-multiply: a blend mode over a
              // viewport-sized fixed layer re-blends the whole viewport on every
              // scroll frame. Warmth is a low-opacity tint either way.
              className="pointer-events-none fixed inset-0 z-10 bg-primary"
              style={{ opacity: warmth * 0.55 }}
            />
          ) : null}

          {/*
            Saves this chapter's pages to the device, using the very URLs resolved
            above — the reader's own page loading is untouched, the service worker
            just answers those requests from the cache when the network is gone.
          */}
          {/* `data-reader-chrome` here and on the controls below: resting the
              pointer or Tab-reached focus in either holds the chrome up, and Tab
              reaching either brings it back (`chrome-autohide.ts`). */}
          <div onClick={(event) => event.stopPropagation()} role="presentation" data-reader-chrome="">
            <DownloadChapterControl
              // Only drawn once the engine is ready, which has a chapter.
              chapter={extras.activeChapter!}
              visiblePage={state.page}
              visible={state.chromeVisible}
            />
          </div>

          <div
            className={cn(
              "pointer-events-none fixed left-1/2 top-4 z-20 -translate-x-1/2",
              extras.reducedMotion.cinema ? "" : "transition-opacity duration-300",
              // Cinema mode hides even this: revealed activity brings the full
              // control bar (which carries the page count) back instead.
              !state.chromeVisible && !state.cinema ? "opacity-100" : "opacity-0",
            )}
          >
            {/* Flat glass: this pill stays up for the whole read with the page
                strip moving under it, and a backdrop blur there is re-sampled on
                every scroll frame. `!` because the glass rule is unlayered. */}
            <div className="glass-panel glass-flat rounded-full bg-[color-mix(in_srgb,var(--shape-panel-fill)_35%,var(--color-surface))]! px-4 py-1.5 font-mono text-xs tabular-nums text-primary">
              {state.page} <span className="text-muted">/ {state.pageCount}</span>
            </div>
          </div>
        </>
      )}
      renderChrome={() => (
        <>
          <div onClick={(event) => event.stopPropagation()} role="presentation" data-reader-chrome="">
            <ReaderControls
              chapterTitle={state.chapter?.label ?? "Chapter"}
              chapterPosition={
                state.chapterPosition
                  ? `${state.chapterPosition.index} of ${state.chapterPosition.total}`
                  : null
              }
              progress={extras.progressStore}
              visiblePage={state.page}
              pageCount={state.pageCount}
              zoom={zoom}
              onZoomIn={() => commands.zoom(zoomBy(zoom, 1))}
              onZoomOut={() => commands.zoom(zoomBy(zoom, -1))}
              onZoomReset={() => commands.zoom(1)}
              readingMode={readingMode}
              onReadingModeChange={extras.setReadingMode}
              readingModeLocked={state.kind === "readAll"}
              fitMode={fitMode}
              onFitModeChange={(mode) => updatePreferences({ fitMode: mode })}
              direction={direction}
              onDirectionChange={(next) => updatePreferences({ direction: next })}
              onSeekPage={commands.jumpToPage}
              fullscreen={fullscreen.active}
              fullscreenSupported={fullscreen.supported}
              onToggleFullscreen={fullscreen.toggle}
              onShowShortcuts={toggleShortcuts}
              pageGap={pageGap}
              onTogglePageGap={continuous ? togglePageGap : undefined}
              cinema={state.cinema}
              onToggleCinema={extras.toggleCinema}
              pageTransition={pageTransition}
              onTogglePageTransition={!continuous ? togglePageTransition : undefined}
              autoScrollAvailable={continuous}
              autoScrollPlaying={state.autoScroll.playing}
              onToggleAutoScroll={commands.toggleAutoScroll}
              autoScrollSpeed={autoScrollSpeed}
              onAutoScrollSpeedChange={commands.setSpeed}
              autoScrollReducedMotion={extras.reducedMotion.autoScroll}
              dimmer={dimmer}
              onDimmerChange={setDimmer}
              warmth={warmth}
              onWarmthChange={setWarmth}
              tapZones={effectiveTapZones}
              onTapZonesChange={setTapZones}
              onBookmark={() => void commands.bookmark()}
              previousChapterHref={extras.previousChapterHref}
              nextChapterHref={extras.nextChapterHref}
              nextChapterLabel={extras.nextChapterLabel}
              seriesHref={seriesHref}
              onOpenSeries={extras.openSeries}
              onPreviousChapter={commands.previous}
              onNextChapter={commands.next}
              bookmarkPending={extras.bookmarkPending}
              showBookmark
              visible={state.chromeVisible}
            />
          </div>

          {bookmarkNotice ? (
            <BookmarkNotice tone={bookmarkNotice.tone}>{bookmarkNotice.text}</BookmarkNotice>
          ) : null}
        </>
      )}
    />
  );
}
