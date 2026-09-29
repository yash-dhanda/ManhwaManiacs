"use client";

import { Keys } from "../kit/Keys";
import type { DiscoverScope } from "@/features/sources/search-scope";

export function DiscoverKeys({ scopes, onScope, focusField, firstResult }: { scopes: DiscoverScope[]; onScope: (s: DiscoverScope) => void; focusField: () => void; firstResult: () => void }) {
  return (
    <Keys
      group="Discover"
      defs={[
        { id: "discover.focus", keys: "/", description: "Focus the search field", handler: focusField },
        { id: "discover.down", keys: "arrowdown", description: "Move into the results", handler: firstResult, allowInInput: true },
        ...scopes.map((sc, i) => ({ id: `discover.scope.${i + 1}`, keys: String(i + 1), description: `Switch to scope ${i + 1}`, handler: () => onScope(sc) })),
      ]}
    />
  );
}
