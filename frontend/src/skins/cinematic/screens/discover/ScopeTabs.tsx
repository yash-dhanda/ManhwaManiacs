"use client";

import type { DiscoverScope } from "@/features/sources/search-scope";
import { kit as s } from "../kit/Kit";

const LABEL: Record<DiscoverScope, string> = { all: "ALL", library: "LIBRARY", sources: "SOURCES", dialogue: "DIALOGUE", ask: "ASK" };

export function visibleScopes(caps: { aiAvailable: boolean; dialogueAvailable: boolean }): DiscoverScope[] {
  return ["all", "library", "sources", ...(caps.dialogueAvailable ? (["dialogue"] as const) : []), ...(caps.aiAvailable ? (["ask"] as const) : [])];
}

export function ScopeTabs({ scopes, value, onChange }: { scopes: DiscoverScope[]; value: DiscoverScope; onChange: (s: DiscoverScope) => void }) {
  return (
    <div className={s.tabs} role="tablist" aria-label="Search scope">
      {scopes.map((sc, i) => (
        <button key={sc} type="button" role="tab" aria-selected={sc === value} className={s.tab} onClick={() => onChange(sc)}>
          <span className={s.folioNum}>{String(i + 1).padStart(2, "0")}</span>
          {LABEL[sc]}
        </button>
      ))}
    </div>
  );
}
