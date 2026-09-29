"use client";

import { Keys } from "../kit/Keys";

export function CatalogueKeys({ focusSearch, mode, refresh }: { focusSearch: () => void; mode: (dir: 1 | -1) => void; refresh: () => void }) {
  return (
    <Keys
      group="Catalogue"
      defs={[
        { id: "catalogue.search", keys: "/", description: "Search this source", handler: focusSearch },
        { id: "catalogue.mode.prev", keys: "[", description: "Previous browse mode", handler: () => mode(-1) },
        { id: "catalogue.mode.next", keys: "]", description: "Next browse mode", handler: () => mode(1) },
        { id: "catalogue.refresh", keys: "r", description: "Refresh from the source", handler: refresh },
      ]}
    />
  );
}
