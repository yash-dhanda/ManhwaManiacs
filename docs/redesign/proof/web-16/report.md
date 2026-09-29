# web/16 report (lane L05)

Built: Discover (/search), Sources (/sources), Catalogue (/sources/:id), Dialogue (/ocr) in Cinematic; the four ids are out of PENDING.

Stand-ins (web/03-06, web/12, web/15 were not integrated): `features/sources/standins/` (limiter, fnv1a32), `skins/cinematic/screens/kit/` (fields, notices, sheet, toast, poster, motion hooks), `skins/cinematic/ai-copy.ts`. Fonts (Bodoni Moda, Newsreader, Archivo, Plex Mono) are referenced with system fallbacks; the loaders belong to web/04.

Not built / deviations: pull to reprint (phones), hover tooltip delay on health marks (native title), the novel book list on the catalogue (poster wall used), the reader-side `takeDialogueJump` call (no Cinematic reader exists; `BubblePulse` and `announceDialogueJump` are ready), grid-overlay and reduced-motion screenshot sets (scripts/proof.mjs absent), idle sections need pinned sources (demo account has none), genre tile duotone uses the fallback colour.
Screenshots: 9 routes x desktop/phone plus state-partial and state-rate-limited.
