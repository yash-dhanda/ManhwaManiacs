# mobile/16 plan (lane L09)

Order of work, one commit each:

1. A1-A14 skin-neutral data layer with unit tests (discover scope, source health, genre index, trending, wash hue, freshness, text fold, still crop, engine label, dialogue jump, recent-search clear, genre weights).
2. Repository and provider additions (genres, health, summary, tiers, genre/refresh browse, chapter pages, fetchChapterText) and the request-limiter stand-in with the P3 test.
3. Discover: index field, scopes, idle page, tiered results, group jump, ASK.
4. Sources directory: health, pins, reorder, Move items, row menu, Health details, tablet table.
5. Source catalogue: modes, genre sheet, search, wall, infinite scroll, opening state, notices, TOP.
6. Dialogue search: subtitled stills, transcript blocks, jump, bubble pulse and landing helper, scan widgets.
7. Router wiring (four ids leave PENDING) and widget tests.

Stand-ins for steps that are not integrated yet (mobile/03-06, 08, 12): see TODO(mobile/..) markers under `lib/skins/cinematic/screens/discover/`.
