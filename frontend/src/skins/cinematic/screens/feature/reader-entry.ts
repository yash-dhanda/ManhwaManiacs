"use client";

import { useRouter } from "next/navigation";
import { useCallback } from "react";

/**
 * TODO(web/06): stand-in for `enterReader(href, { entry: "wipe" })`. Plays a
 * 200 ms cross-fade through black (the reduced-motion form of the Column
 * wipe) then navigates; web/06's re-export replaces this file's body.
 */
export function useReaderEntry() {
  const router = useRouter();
  return useCallback(
    (href: string) => {
      const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      const go = () => router.push(href);
      const doc = document as Document & { startViewTransition?: (cb: () => void) => unknown };
      if (!reduce && doc.startViewTransition) doc.startViewTransition(go);
      else go();
    },
    [router],
  );
}
