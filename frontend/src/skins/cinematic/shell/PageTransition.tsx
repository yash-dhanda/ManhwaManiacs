"use client";
import { ViewTransition as _v } from "react";
import type { ReactNode } from "react";

const VT = _v as unknown as React.ComponentType<Record<string, unknown> & { children?: ReactNode }>;

/** The page wrapper around `<main>` content (§8.0.4, §15.2). Classes live in `view-transitions.css`. */
export function PageTransition({ children }: { children: ReactNode }) {
  return (
    <VT
      default="none"
      enter={{ "nav-forward": "mm-page-in", "nav-back": "mm-page-back-in", "nav-section": "mm-dip-in", "nav-match": "mm-dissolve-in", default: "none" }}
      exit={{ "nav-forward": "mm-page-out", "nav-back": "mm-page-back-out", "nav-section": "mm-dip-out", "nav-match": "mm-dissolve-out", default: "none" }}
    >
      {children}
    </VT>
  );
}
