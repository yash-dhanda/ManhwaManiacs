"use client";

import { Keys } from "../kit/Keys";

const rows = () => Array.from(document.querySelectorAll<HTMLElement>("[data-row-link]"));

export function SourcesKeys({ focusFilter, togglePin, move }: { focusFilter: () => void; togglePin: (id: string) => void; move: (id: string, dir: "up" | "down") => void }) {
  const current = () => document.activeElement?.closest<HTMLElement>("[data-source-id]")?.dataset.sourceId ?? null;
  const step = (dir: number) => {
    const all = rows();
    const i = all.findIndex((r) => r === document.activeElement || r.contains(document.activeElement));
    all[Math.min(all.length - 1, Math.max(0, i + dir))]?.focus();
  };
  return (
    <Keys
      group="Sources"
      defs={[
        { id: "sources.filter", keys: "/", description: "Filter sources", handler: focusFilter },
        { id: "sources.next", keys: "j", description: "Next source", handler: () => step(1) },
        { id: "sources.prev", keys: "k", description: "Previous source", handler: () => step(-1) },
        { id: "sources.pin", keys: "p", description: "Pin or unpin the focused source", handler: () => { const id = current(); if (id) togglePin(id); } },
        { id: "sources.up", keys: "alt+arrowup", description: "Move the focused pin up", handler: () => { const id = current(); if (id) move(id, "up"); }, allowInInput: true },
        { id: "sources.down", keys: "alt+arrowdown", description: "Move the focused pin down", handler: () => { const id = current(); if (id) move(id, "down"); }, allowInInput: true },
      ]}
    />
  );
}
