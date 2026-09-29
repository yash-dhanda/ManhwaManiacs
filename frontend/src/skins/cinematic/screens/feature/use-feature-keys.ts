"use client";

import { useEffect, useRef } from "react";

/** Key → action; the FeatureView passes a fresh map, the listener always reads the latest. */
export type KeyMap = Record<string, () => void>;

/** The "Series" group of the `?` sheet (web/03's sheet reads this list). */
export const FEATURE_KEYS: [string, string][] = [
  ["Enter / c", "Continue"], ["a", "Read all"], ["v", "View cover"], ["f", "Favourite"], ["n", "Notify"],
  ["+", "Follow or unfollow"], ["d", "Download"], ["1–n", "Tabs"], ["[ ]", "Previous or next tab"],
  ["j / k", "Next or previous chapter"], ["x", "Select mode"], ["/", "Go to chapter"], ["o", "Newest or oldest"],
  ["m", "Move to another source"],
];

export function typing(target: EventTarget | null): boolean {
  const el = target as HTMLElement | null;
  return Boolean(el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.tagName === "SELECT" || el.isContentEditable));
}

// TODO(web/03): respect the single-key shortcuts setting once the keymap host exists.
export function useFeatureKeys(map: KeyMap) {
  const ref = useRef(map);
  useEffect(() => {
    ref.current = map;
  });
  useEffect(() => {
    const on = (e: KeyboardEvent) => {
      if (e.metaKey || e.ctrlKey || e.altKey || typing(e.target)) return;
      if ((e.target as HTMLElement | null)?.closest?.('[role="dialog"], [role="menu"]')) return;
      const fn = ref.current[e.key];
      if (fn) {
        e.preventDefault();
        fn();
      }
    };
    window.addEventListener("keydown", on);
    return () => window.removeEventListener("keydown", on);
  }, []);
}

/** `j` / `k`: focus the next or previous chapter row link. */
export function focusRow(delta: 1 | -1) {
  const links = [...document.querySelectorAll<HTMLElement>("[data-row] a[href], a[data-row]")];
  const i = links.indexOf(document.activeElement as HTMLElement);
  links[Math.min(links.length - 1, Math.max(0, i + delta))]?.focus();
}
