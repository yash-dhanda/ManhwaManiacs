"use client";

import { useRouter } from "next/navigation";
import { useCallback } from "react";
import { columnWipe } from "./wipe";

/**
 * TODO(web/06): stand-in for `enterReader(href, { entry: "wipe" })` from
 * `motion.ts`. It is the real Column wipe (12/8/4 blades, reduced-motion
 * cross-fade); web/06's re-export replaces this body.
 */
export function useReaderEntry() {
  const router = useRouter();
  return useCallback(
    (href: string) => {
      const from = window.location.pathname + window.location.search;
      void columnWipe(
        () => router.push(href),
        () => window.location.pathname + window.location.search !== from,
      );
    },
    [router],
  );
}
