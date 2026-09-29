# web/16 report (lane L05)

Built: Discover (/search), Sources (/sources), Catalogue (/sources/:id), Dialogue (/ocr), and the Cinematic reader host that performs the dialogue jump (seek, 2 px bubble pulse, toast). Discover, Sources, Catalogue and Dialogue are out of PENDING. `reader` stays PENDING (web/12); `screens/reader/BubblePulse.tsx` and `features/ocr/dialogue-jump.ts` are ready for web/12 to call `takeDialogueJump()`.

Fix pass 1 closed: reader jump (`skins/cinematic/screens/reader/JumpingReader.tsx`), pull to reprint on Sources and Catalogue (`kit/use-pull.tsx`), health tooltip with 500 ms hover delay and 0 ms on focus, novel book list on the catalogue (`kit/BookList.tsx`), genre tile duotone from the cover (`kit/use-duo.ts`), the proof harness (`frontend/scripts/proof.mjs`, `--grid`, `--reduced`), the extended e2e spec, pinned sources seeded on the dev stack, and the state screenshots. Also fixed: the 32 px white band above every kit page (margin collapse), and the phone Sources row grid (link collapsed to 14 px).

Stand-ins that remain (their steps are not in this lane's waitFor and not integrated; per lane rule 12 each is marked TODO(step-id)):
- web/03: `features/sources/standins/` (limiter, fnv1a32), `scripts/proof.mjs`.
- web/04-06: `skins/cinematic/screens/kit/` (fields, notices, sheet, toast, poster, motion hooks). Fonts load through the existing core/reading loaders.
- web/09: `kit/BookList.tsx`. web/12: `JumpingReader` hosts the shared source reader inside a skin (eslint-disabled import). web/23: `kit/use-duo.ts` samples the cover colour where `ambient.duo` will come from.
- web/15: `skins/cinematic/ai-copy.ts`.

Screenshots: 11 routes x desktop/phone x plain/-grid/-reduced, plus state-*.png (idle, failed-group, no-results, error, offline, opening, partial, rate-limited, dialogue-results, dialogue-nothing-found, dialogue-error, reader-jump-found, reader-jump-chapter-start).


Fix pass 2: removed the legacy-reader host (`JumpingReader`, eslint-disable) and the reader-jump e2e (owned by web/12); every P1 source call in `features/sources/hooks.ts` and `features/ocr/hooks.ts` now goes through `sourcesLimiter.run('P1', ...)` (stand-in limiter, TODO(web/03)); appearance-boot test updated for `data-glass-renderer`.
