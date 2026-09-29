"use client";
import { useEffect } from "react";
import { create } from "zustand";
import type { IconRole } from "../icons/roles.generated";

export type RunningHeadTrailing = { icon: IconRole; label: string; href?: string; onPress?: () => void };
export type RunningHeadConfig = {
  /** Phone running title, e.g. `LIBRARY · UPDATES`. */
  title?: string;
  /** Pushed screens: a back target (`true` = browser back). */
  back?: { href?: string; label?: string } | true;
  /** Up to two trailing icon buttons on the phone frame. */
  trailing?: RunningHeadTrailing[];
  /** The bar sits over art: transparent with `scrim-head`. */
  overArt?: boolean;
  /** Last breadcrumb segment on the desktop frame (`SOLO LEVELING`). */
  breadcrumbTail?: string;
  /** Library, Discover, Downloads and Index put the content-mode chip in their phone head. */
  contentModeChip?: boolean;
};

export const useRunningHeadStore = create<{ cfg: RunningHeadConfig; set: (c: RunningHeadConfig) => void }>((set) => ({ cfg: {}, set: (cfg) => set({ cfg }) }));

const same = (a: RunningHeadConfig, b: RunningHeadConfig) =>
  a.title === b.title && a.overArt === b.overArt && a.breadcrumbTail === b.breadcrumbTail && a.contentModeChip === b.contentModeChip &&
  JSON.stringify(a.back) === JSON.stringify(b.back) &&
  JSON.stringify((a.trailing ?? []).map((t) => [t.icon, t.label, t.href])) === JSON.stringify((b.trailing ?? []).map((t) => [t.icon, t.label, t.href]));

/**
 * Screens call this to shape the running head. Cleared when the screen unmounts, so a screen that never calls it gets the
 * defaults (no back, no title, no trailing).
 */
export function useRunningHead(cfg: RunningHeadConfig): void {
  useEffect(() => {
    const cur = useRunningHeadStore.getState().cfg;
    if (!same(cur, cfg) || cur.trailing?.some((t, i) => t.onPress !== cfg.trailing?.[i]?.onPress)) useRunningHeadStore.getState().set(cfg);
  });
  useEffect(() => () => useRunningHeadStore.getState().set({}), []);
}
