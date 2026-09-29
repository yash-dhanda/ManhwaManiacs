"use client";

import { useGridNavigation } from "@/lib/keyboard";

/** Arrow-key movement inside one rail/grid; `id` must be unique per mounted grid. */
export function useGridNavHost(id: string, group = "Discover", enabled = true) {
  return useGridNavigation({ id: `grid.${id}`, group, description: "Move through results", enabled });
}
