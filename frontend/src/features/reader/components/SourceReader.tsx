"use client";

import { ChapterReader } from "./ChapterReader";
import { useReaderEngine } from "../engine/use-reader-engine";

interface SourceReaderProps {
  sourceId: string;
  seriesKey: string;
  chapterKey: string;
  initialPage?: number;
  /** `?at=` — the fraction of `initialPage` a bookmark link is opening at. */
  initialAnchorFraction?: number | null;
}

/**
 * The unified source-native reader (spec §3.3), legacy entry point for one
 * chapter and the strip that grows around it (spec 2026-09-05 R1). The state,
 * the strip, progress and bookmark capture live in `useReaderEngine`;
 * `ChapterReader` is the legacy frame around it. `autoQueueNext` stays off so
 * legacy keeps today's behaviour: nothing is saved while reading.
 */
export function SourceReader({
  sourceId,
  seriesKey,
  chapterKey,
  initialPage = 1,
  initialAnchorFraction = null,
}: SourceReaderProps) {
  const engine = useReaderEngine(
    {
      kind: "chapter",
      sourceId,
      seriesKey,
      chapterKey,
      initialPage,
      at: initialAnchorFraction,
    },
    { autoQueueNext: false },
  );
  return <ChapterReader engine={engine} />;
}
