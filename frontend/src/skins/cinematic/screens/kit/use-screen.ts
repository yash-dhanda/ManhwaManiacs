"use client";

import { useEffect, useRef } from "react";

/** Sets `document.title`, focuses the h1 on mount, and routes the `mm:focus-search` event to `focusSearch`. */
export function useScreenChrome(title: string, focusSearch?: () => void) {
  const h1 = useRef<HTMLHeadingElement>(null);
  useEffect(() => {
    document.title = `${title} · ManhwaManiacs`;
  }, [title]);
  useEffect(() => {
    h1.current?.focus({ preventScroll: true });
  }, []);
  const focusRef = useRef(focusSearch);
  useEffect(() => {
    focusRef.current = focusSearch;
  });
  useEffect(() => {
    const on = () => focusRef.current?.();
    window.addEventListener("mm:focus-search", on);
    return () => window.removeEventListener("mm:focus-search", on);
  }, []);
  return h1;
}

/** Retry-After seconds off an ApiError-like value (headers are not surfaced, so default 12). */
export function retryAfterSeconds(error: unknown): number {
  const v = (error as { retryAfter?: number } | null)?.retryAfter;
  return typeof v === "number" && v > 0 ? v : 12;
}

export function isStatus(error: unknown, status: number): boolean {
  return (error as { status?: number } | null)?.status === status;
}
export function errorCode(error: unknown): string | null {
  const e = error as { code?: unknown; body?: { code?: unknown; detail?: { code?: unknown } } } | null;
  const c = e?.code ?? e?.body?.code ?? e?.body?.detail?.code;
  return typeof c === "string" ? c : null;
}
