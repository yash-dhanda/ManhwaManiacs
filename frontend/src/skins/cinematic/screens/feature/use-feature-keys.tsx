"use client";

import { useShortcut } from "@/lib/keyboard";

/** One "Series" key (§8.17 D10, §8.18 E6): registered with the app keyboard registry, so the `?` sheet lists it. */
export interface FeatureKey {
  id: string;
  keys: string | string[];
  label: string;
  run: () => void;
  enabled?: boolean;
}

// TODO(web/03): respect the single-key shortcuts setting once the keymap host exposes it.
function Bind({ k }: { k: FeatureKey }) {
  useShortcut({
    id: `series.${k.id}`,
    keys: k.keys,
    description: k.label,
    group: "Series",
    enabled: k.enabled,
    preventDefault: false,
    handler: (e) => {
      const el = e.target as HTMLElement | null;
      if (el?.closest?.('[role="dialog"], [role="menu"]')) return;
      const enter = e.key === "Enter";
      if (enter && el?.closest?.("a, button, summary")) return;
      e.preventDefault();
      k.run();
    },
  });
  return null;
}

export function FeatureKeys({ keys }: { keys: FeatureKey[] }) {
  return (
    <>
      {keys.map((k) => (
        <Bind key={k.id} k={k} />
      ))}
    </>
  );
}

/** `j` / `k`: focus the next or previous chapter row link. */
export function focusRow(delta: 1 | -1) {
  const links = [...document.querySelectorAll<HTMLElement>("[data-row] a[href], a[data-row]")];
  const i = links.indexOf(document.activeElement as HTMLElement);
  links[Math.min(links.length - 1, Math.max(0, i + delta))]?.focus();
}
