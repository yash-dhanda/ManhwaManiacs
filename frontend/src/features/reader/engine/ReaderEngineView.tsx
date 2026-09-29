"use client";

import type { ReactNode } from "react";
import { ContinuousStrip } from "./ContinuousStrip";
import { PagedView } from "./PagedView";
import type { ReaderSurfaceSlots } from "./slots";
import type { ReaderEngine, ReaderEngineCommands, ReaderEngineState } from "./types";

interface ReaderEngineViewProps {
  engine: ReaderEngine;
  slots: ReaderSurfaceSlots;
  /** Everything a skin paints after the surface: controls, pills, notices. */
  renderChrome: (state: ReaderEngineState, commands: ReaderEngineCommands) => ReactNode;
  /**
   * Elements that sit BEFORE the surface in DOM order. Legacy paints its night
   * dimmer, warmth wash, download control and page counter here; keeping them
   * ahead of the surface is what keeps the stacking exactly as it was.
   */
  renderUnderlay?: (state: ReaderEngineState) => ReactNode;
  /**
   * Wraps the ready reader (underlay, surface, chrome) in the skin's own frame.
   * The loading, error and empty states are drawn without it.
   */
  renderFrame?: (children: ReactNode, state: ReaderEngineState) => ReactNode;
}

/**
 * Renders the reader surface for `state.layout` and hands all chrome to the
 * caller. It draws no legacy UI itself: every decoration is a slot.
 */
export function ReaderEngineView({
  engine,
  slots,
  renderChrome,
  renderUnderlay,
  renderFrame,
}: ReaderEngineViewProps) {
  const { state, surface, commands, extras } = engine;

  if (state.status === "loading") return <>{slots.loading()}</>;
  if (state.status === "error") return <>{slots.error(state.error ?? "", extras.onRetry)}</>;
  if (state.status === "empty") return <>{slots.empty()}</>;

  const body = (
    <>
      {renderUnderlay?.(state)}
      {surface.layout === "strip" ? (
        slots.stripFrame(
          <>
            {slots.head(surface.head)}
            {surface.scrollElement ? (
              <ContinuousStrip
                key={surface.stripKey}
                chapters={surface.chapters}
                zoom={surface.zoom}
                pageGap={surface.pageGap}
                slots={slots}
                scrollElement={surface.scrollElement}
                initialScrollTop={surface.initialScrollTop}
                onPositionChange={surface.onPositionChange}
                onImagesReady={surface.onImagesReady}
                onHandleReady={surface.onHandleReady}
              />
            ) : null}
            {slots.tail(surface.tail)}
          </>,
        )
      ) : (
        <PagedView
          pages={surface.paged.pages}
          chapterTitle={surface.paged.chapterTitle}
          view={surface.paged.view}
          slotsPerView={surface.paged.slotsPerView}
          direction={surface.paged.direction}
          fitMode={surface.paged.fitMode}
          zoom={surface.zoom}
          tapZoneConfig={surface.tapZones}
          onTap={surface.onTap}
          onZoom={surface.onZoomSteps}
          pageTransition={surface.paged.pageTransition}
          slots={slots}
        />
      )}
      {renderChrome(state, commands)}
    </>
  );

  return <>{renderFrame ? renderFrame(body, state) : body}</>;
}
