"use client";

import Link from "next/link";
import { ImageOff } from "lucide-react";
import type { ReactNode } from "react";
import type { ReaderSurfaceSlots } from "../engine/slots";
import { StripHead, StripTail } from "./ReaderControls";

/**
 * The legacy reader's surface decorations, moved verbatim out of the engine
 * surfaces (`ContinuousStrip`, `PagedView`, `PageImage`) and `ChapterReader`.
 * Legacy UI: deleted at the flip.
 */
export function createLegacySurfaceSlots(seriesHref: string): ReaderSurfaceSlots {
  return {
    // RD1
    loading: () => (
      <div
        className="flex min-h-[60vh] flex-col items-center justify-center gap-4 bg-bg p-6"
        aria-busy="true"
        aria-label="Loading chapter"
      >
        <div className="w-full max-w-3xl space-y-3">
          {Array.from({ length: 3 }).map((_, index) => (
            <div
              key={index}
              className="mx-auto aspect-[2/3] w-full max-w-md animate-pulse rounded-lg bg-white/5"
            />
          ))}
        </div>
        <p className="text-sm text-muted">Loading chapter…</p>
      </div>
    ),

    // RD2
    error: (message, retry) => <LegacyError message={message} retry={retry} seriesHref={seriesHref} />,

    // RD3
    empty: () => (
      <div className="flex min-h-[60vh] items-center justify-center bg-bg text-muted">
        This chapter has no pages.
      </div>
    ),

    stripFrame: (children: ReactNode) => <div className="flex-1 py-4 pb-28">{children}</div>,

    // RD7: a hairline, the chapter's name, nothing else.
    chapterDivider: ({ label, height }) => (
      <div
        className="mx-auto flex w-full max-w-3xl items-center gap-4 px-6"
        style={{ height: `${height}px` }}
      >
        <span className="h-px flex-1 bg-border/70" aria-hidden />
        <span className="whitespace-nowrap text-[11px] font-semibold uppercase tracking-[0.22em] text-muted">
          {label}
        </span>
        <span className="h-px flex-1 bg-border/70" aria-hidden />
      </div>
    ),

    // RD8
    head: ({ edge, href, visible, loading, load }) => (
      <StripHead label={edge.label} href={href} visible={visible} loading={loading} onLoad={load} />
    ),

    // RD9
    tail: ({ edge, hasMore, href, error, retry }) => (
      <StripTail hasMore={hasMore} error={error} onRetry={retry} label={edge.label} href={href} />
    ),

    // RD5: the reserved box is filled by `pageBoxClass` (the reader backdrop).
    pagePlaceholder: () => null,
    pageBoxClass: "bg-bg",

    // RD4: overlaid on the reserved box so a dead page never resizes its row.
    brokenPage: (_page, retry) => (
      <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-bg px-6 text-center">
        <ImageOff className="size-6 text-muted" aria-hidden />
        <p className="text-sm text-muted">Failed to load page</p>
        <button
          type="button"
          onClick={retry}
          className="inline-flex h-9 items-center rounded-lg border border-border/60 px-4 text-sm font-medium text-fg transition-colors hover:border-primary/40 hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60"
        >
          Retry
        </button>
      </div>
    ),

    pageTurnClass: "reader-page-transition-enter",
  };
}

function LegacyError({
  message,
  retry,
  seriesHref,
}: {
  message: string;
  retry: () => void;
  seriesHref: string;
}) {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-3 bg-bg p-6 text-center">
      <p className="text-danger">{message}</p>
      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={retry}
          className="inline-flex h-10 items-center justify-center rounded-lg bg-primary px-4 text-sm font-medium text-primary-fg transition-colors hover:bg-primary-hover"
        >
          Try again
        </button>
        <Link
          href={seriesHref}
          className="inline-flex h-10 items-center justify-center rounded-lg border border-border/60 px-4 text-sm font-medium text-fg transition-colors hover:bg-white/5"
        >
          Go to series
        </Link>
      </div>
    </div>
  );
}
