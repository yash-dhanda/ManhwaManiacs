# web/03 plan: reader engine seam, limiter, proof harness

Baseline before any change: 162 test files / 2885 tests; `src/features/reader`: 29 files / 436 tests.
Gate after every A commit: `npm run test` (via heavy.sh web) plus `tsc --noEmit`.

## A. Reader engine (one session, sequential)
1. A1 pure `git mv` of ContinuousStrip, PagedView, PageImage to `features/reader/engine/`; import paths and the cover-image census path only. Gate: test, tsc.
2. A2 `ReaderSurfaceSlots` (loading, error, empty, stripFrame, chapterDivider, head, tail, pagePlaceholder, brokenPage, pageTurnClass); surfaces take `slots`; legacy markup moves verbatim to `components/legacy-surface-slots.tsx`. Gate: test, tsc, lint.
3. A3 `engine/types.ts` (state, commands, NextState, surface bindings). Gate: tsc.
4. A4 `engine/use-reader-engine.ts`: SourceReader + ReadAllReader composition and ChapterReader's non-visual state. Gate: tsc (not yet wired).
5. A5 `engine/ReaderEngineView.tsx` with `renderFrame`, `renderUnderlay`, `renderChrome`. Gate: tsc.
6. A6 ChapterReader becomes the legacy frame; SourceReader/ReadAllReader call the engine with `autoQueueNext: false`, both in one commit. Gate: test, tsc, lint, e2e/manual parity.
7. A7 `save-next.ts`, `auto-queue.ts` (+ test), engine wiring. Gate: test.
8. Lint block for `src/features/reader/engine/**`.

## B, C, D (independent)
B request limiter (+ wiring, Retry-After, 150 ms dwell), C coverTransitionName, D `scripts/proof.mjs`. Committed first.
