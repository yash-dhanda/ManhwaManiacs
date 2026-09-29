"use client";
// STUB (interface frozen; the icon-button agent replaces the body with the Base UI tooltip).
import type { ReactElement, ReactNode } from "react";

/** level: "default" 600 ms hover, "bar" 150 ms (dock, collapsed sidebar); keyboard focus on an icon-only control opens at 0 ms. */
export function Tooltip({ label, level = "default", disabled = false, children }: { label: ReactNode; level?: "default" | "bar"; disabled?: boolean; children: ReactElement }): ReactElement {
  void label; void level; void disabled;
  return children;
}
