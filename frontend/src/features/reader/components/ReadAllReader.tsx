"use client";

import { ChapterReader } from "./ChapterReader";
import { useReaderEngine } from "../engine/use-reader-engine";

interface ReadAllReaderProps {
  sourceId: string;
  seriesKey: string;
  /** Where to start the run. Absent means the first chapter of the series. */
  fromChapterKey?: string | null;
  initialPage?: number;
  /** `?at=` — the fraction of `initialPage` a bookmark link is opening at. */
  initialAnchorFraction?: number | null;
}

/**
 * The whole series as one scroll (spec 2026-09-05 R2), legacy entry point. The
 * reading order, the bulk strip source and progress live in `useReaderEngine`
 * (`kind: "readAll"`, which pins the layout to the strip); `ChapterReader` is
 * the legacy frame. `autoQueueNext` stays off so legacy keeps today's behaviour.
 */
export function ReadAllReader({
  sourceId,
  seriesKey,
  fromChapterKey = null,
  initialPage = 1,
  initialAnchorFraction = null,
}: ReadAllReaderProps) {
  const engine = useReaderEngine(
    {
      kind: "readAll",
      sourceId,
      seriesKey,
      from: fromChapterKey,
      initialPage,
      at: initialAnchorFraction,
    },
    { autoQueueNext: false },
  );
  return <ChapterReader engine={engine} />;
}
