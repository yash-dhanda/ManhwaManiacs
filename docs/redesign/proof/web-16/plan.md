# web/16 plan (lane L05)

Tasks, in commit order. Parts B to E each own a disjoint folder under `frontend/src/skins/cinematic/screens/`.

A. Shared data layer (skin-neutral, Vitest): search-scope, genre-index, trending, health, source-wash, genre-weights, still-crop, engine-label, dialogue-jump (+ findMatchPage), still-source, pin-order, discover-requests (limiter priorities), clearRecentSearches, useSourceHealthSummary, OCR types (page, box), useOcrCapability, useInfiniteOcrSearch.
B. Discover: index field, scope tabs, idle page (recent, ask block, genre tiles + panel, pinned credits, dialogue entry, trending), results (status line, filters, groups, group jump, retry, collapsed empties, IN DIALOGUE), ASK scope, keys.
C. Sources: directory table, health marks, pins with Reorder, Move items, Alt+Up/Down, row menu with long-press, health details sheet, states.
D. Catalogue: browse modes, genre select, search, poster wall, infinite scroll, opening state with tips and source wash, TOP button, not-browsable and not-available notices.
E. Dialogue: subtitled stills (stillCrop, lazy P1 manifest then P3 image), transcript with highlighter, jump hand-off, BubblePulse.
F. Cross-cutting: reduced motion, focus ring, 18+ absence, content mode.
G. AI copy: `skins/cinematic/ai-copy.ts` (web/08 module absent).

Stand-ins for missing steps (all marked TODO(web/NN)): limiter and fnv1a32 (web/03), the `kit/` primitives (web/04, web/05), plain screen chrome (web/06).
