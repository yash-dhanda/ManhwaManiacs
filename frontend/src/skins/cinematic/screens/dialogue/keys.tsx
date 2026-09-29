"use client";

import { Keys } from "../kit/Keys";

export function DialogueKeys({ focusField }: { focusField: () => void }) {
  const blocks = () => Array.from(document.querySelectorAll<HTMLElement>("[data-block]"));
  const step = (dir: number) => {
    const all = blocks();
    const i = all.findIndex((b) => b === document.activeElement || b.contains(document.activeElement));
    all[Math.min(all.length - 1, Math.max(0, i + dir))]?.focus();
  };
  return (
    <Keys
      group="Dialogue"
      defs={[
        { id: "dialogue.focus", keys: "/", description: "Focus the search field", handler: focusField },
        { id: "dialogue.next", keys: "j", description: "Next hit", handler: () => step(1) },
        { id: "dialogue.prev", keys: "k", description: "Previous hit", handler: () => step(-1) },
      ]}
    />
  );
}
