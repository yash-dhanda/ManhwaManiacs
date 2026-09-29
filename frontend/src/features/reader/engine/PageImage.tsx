"use client";

import Image from "next/image";
import { memo, useCallback, useEffect, useState } from "react";
import { cn } from "@/lib/cn";
import { readerDebug } from "../debug";
import { pageContainerStyle, UNKNOWN_PAGE_ASPECT } from "../page-layout";
import type { ReaderSurfaceSlots } from "./slots";

export interface PageFrame {
  width: number;
  height: number;
}

/** Only ever a denominator: `next/image` wants a number, the layout wants a ratio. */
const DEFAULT_INTRINSIC_WIDTH = 800;

interface PageImageProps {
  imageUrl: string;
  /** 1-based page number, handed to the broken-page slot. */
  pageIndex: number;
  slots: Pick<ReaderSurfaceSlots, "pagePlaceholder" | "brokenPage" | "pageBoxClass">;
  alt: string;
  width?: number | null;
  height?: number | null;
  priority?: boolean;
  seamless?: boolean;
  /**
   * Exact rendered box, in CSS pixels. The paged modes resolve their own layout
   * (fit width / height / original + zoom) and need the space reserved before
   * the image decodes so a page turn never reflows under the reader. Continuous
   * scrolling leaves this unset and stays fluid.
   */
  frame?: PageFrame | null;
  /**
   * Fired once the image has decoded, carrying its INTRINSIC size — `null` when
   * the browser resolved none. That size is the only trustworthy shape a page
   * has when its connector reports no dimensions: the row's own box is still
   * the placeholder at this point in the commit, so a caller that measured the
   * DOM here would sample the guess it is trying to replace.
   */
  onLoad?: (natural: PageFrame | null) => void;
}

export const PageImage = memo(function PageImage({
  imageUrl,
  pageIndex,
  slots,
  alt,
  width,
  height,
  priority,
  seamless = true,
  frame = null,
  onLoad,
}: PageImageProps) {
  /**
   * WHICH url decoded, and which one failed — not `loaded`/`failed` booleans.
   *
   * Both are derived rather than mirrored, so a change of `imageUrl` resets
   * them in the same render that reads them. Mirroring meant an effect that
   * called setState synchronously — a cascading render, and the one thing
   * `react-hooks/set-state-in-effect` exists to stop — and it also left one
   * frame in which the new page was laid out under the old page's `loaded`,
   * i.e. with no reserved box at all, which is a measurement the virtualizer
   * would then have to correct.
   */
  const [loadedUrl, setLoadedUrl] = useState<string | null>(null);
  const [failedUrl, setFailedUrl] = useState<string | null>(null);
  const loaded = loadedUrl === imageUrl;
  const failed = failedUrl === imageUrl;
  /**
   * Bumped by Retry, and only ever part of the ELEMENT's key — never of the
   * URL. A cache-busting query parameter would change the string Cache Storage
   * matches on, so retrying a page of a downloaded chapter would miss its saved
   * copy and go to a network that is not there. Remounting the element makes
   * the browser ask again for the same URL instead of re-serving its cached
   * failure.
   */
  const [attempt, setAttempt] = useState(0);
  // `next/image` requires an intrinsic size, and with an unknown page the only
  // honest one is the same prior the container's placeholder box uses — a
  // second guess here would make the image and its box disagree before decode.
  const imageWidth = width && width > 0 ? width : DEFAULT_INTRINSIC_WIDTH;
  const imageHeight =
    height && height > 0 ? height : Math.round(DEFAULT_INTRINSIC_WIDTH * UNKNOWN_PAGE_ASPECT);

  const retry = useCallback(() => {
    setFailedUrl(null);
    setAttempt((previous) => previous + 1);
  }, []);

  useEffect(() => {
    readerDebug("page-image-mounted", { alt, imageUrl });
  }, [alt, imageUrl]);

  return (
    <div
      className={cn(
        "relative overflow-hidden",
        slots.pageBoxClass,
        frame ? "shrink-0" : "w-full",
        seamless ? "block" : "rounded-sm shadow-lg shadow-black/40",
      )}
      style={
        frame
          ? { width: `${frame.width}px`, height: `${frame.height}px` }
          : pageContainerStyle(loaded, width, height)
      }
    >
      <Image
        key={attempt}
        src={imageUrl}
        alt={alt}
        width={imageWidth}
        height={imageHeight}
        className={cn("block object-contain", frame ? "h-full w-full" : "h-auto w-full")}
        style={
          frame
            ? { width: "100%", height: "100%", display: "block" }
            : { width: "100%", height: "auto", display: "block" }
        }
        priority={priority}
        loading={priority ? undefined : "lazy"}
        unoptimized
        onLoad={(event) => {
          setLoadedUrl(imageUrl);
          const img = event.currentTarget;
          onLoad?.(
            img.naturalWidth > 0 && img.naturalHeight > 0
              ? { width: img.naturalWidth, height: img.naturalHeight }
              : null,
          );
        }}
        onError={() => {
          readerDebug("page-image-failed", { alt, imageUrl });
          setFailedUrl(imageUrl);
        }}
      />
      {!loaded && !failed ? slots.pagePlaceholder({ width: width ?? null, height: height ?? null }) : null}
      {failed ? slots.brokenPage({ index: pageIndex }, retry) : null}
    </div>
  );
});
