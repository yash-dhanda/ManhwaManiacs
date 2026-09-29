import type { ReactNode } from "react";
import type { StripEdge } from "../use-chapter-strip";

/**
 * Everything the reader surfaces paint that a skin decides: the states, the
 * seam marker, the strip's two ends, the page box while it loads and when it
 * breaks. The engine renders NONE of it itself; a skin (or the legacy frame)
 * hands one object of these to `ReaderEngineView`. Legacy markup lives in
 * the legacy frame (legacy-surface-slots) and goes away at the flip.
 */
export interface ReaderSurfaceSlots {
  loading(): ReactNode;
  error(message: string, retry: () => void): ReactNode;
  empty(): ReactNode;
  /** Wraps the strip's head, rows and tail (the legacy column padding). */
  stripFrame(children: ReactNode): ReactNode;
  /** RD7. `height` is the row height the strip declared for the seam. */
  chapterDivider(divider: { chapterKey: string; label: string; height: number }): ReactNode;
  /** RD8. `visible` is false until the reader is at the top of the strip. */
  head(head: {
    edge: StripEdge;
    href: string | null;
    visible: boolean;
    loading: boolean;
    load: () => void;
  }): ReactNode;
  /** RD9. */
  tail(tail: {
    edge: StripEdge;
    hasMore: boolean;
    href: string | null;
    error: string | null;
    retry: () => void;
  }): ReactNode;
  /** RD5. Painted inside the page box until the image has decoded (may be null). */
  pagePlaceholder(page: { width: number | null; height: number | null }): ReactNode;
  /** RD4. Painted over the reserved box, never instead of it. */
  brokenPage(page: { index: number }, retry: () => void): ReactNode;
  /** Class on every page box: the backdrop that also fills a letterbox. */
  pageBoxClass: string;
  /** Class put on the paged view's page wrapper when the page-turn fade is on. */
  pageTurnClass: string;
}
