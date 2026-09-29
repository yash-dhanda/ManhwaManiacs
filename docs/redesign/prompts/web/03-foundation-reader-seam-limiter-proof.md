# Web foundation 03: reader engine seam, request limiter and the proof harness

## Goal

This step is shared data-layer work that every later cluster needs, and none of it adds a pixel. On the web client (`frontend/`) you will:

- **Reader engine.** Extract the manga reader's state and commands out of today's reader components into a skin-neutral engine in `features/reader/engine/`: a `useReaderEngine()` hook plus a `ReaderEngineView` that renders today's strip and paged surfaces and hands all chrome to a `renderChrome(state, commands)` slot. The engine also owns the next-chapter auto-queue. The legacy reader then runs on the engine, looks and behaves exactly as today, and keeps every existing reader test green.
- **Request limiter.** Add the sources request limiter of cinematic §15.6: a sliding window of 50 request starts per 60 s, four priorities, a 150 ms hover dwell, and `Retry-After` pauses.
- **Cover transition name.** Add `coverTransitionName()` (FNV-1a) to the data layer.
- **Proof harness.** Write `frontend/scripts/proof.mjs`, the headless Playwright screenshot harness every later step uses for its visual proof.

## Read first

1. `docs/redesign/stack-decision.md` §2.2 (the data layer stays in `features/`), §2.3 (the engine seam on mobile; the web mirrors it), §4 risk 6 (engine extraction first, no pixel changes), risk 11 (memory).
2. `docs/redesign/cinematic/DESIGN.md`:
   - §8.0.4 "Web" bullets (`coverTransitionName`: `cover-` + the 8-hex-digit 32-bit FNV-1a of `sourceId + "\u0000" + seriesKey`, synchronous, about 6 lines),
   - §8.14.11 (reader states, and "Saving the next chapter (auto-queue)"),
   - §15.4 (reader engine seam: the base state fields and commands; the engine owns the next-chapter auto-queue),
   - §15.6 (performance guards; the "One request limiter for the sources bucket" bullet, which is binding word for word),
   - §15.8 (verification: Playwright screenshots of phone and desktop layouts, with the grid overlay on and off).
3. `docs/redesign/glass/DESIGN.md` §15.2 "Routes" bullet (the helper lives at `frontend/src/features/sources/cover-transition-name.ts`) and "Readers" bullet; §15.4 (Glass's extra engine fields and commands arrive later, in web/34; read the commit order so your shape leaves room for them).
4. `docs/redesign/inventory/web.md` §9 (the manga reader today: RD1–RD42, chrome auto-hide, cinema, auto-scroll 1–10 = 20–220 px/s, the bottom bar) and §12 (downloads).
5. `docs/redesign/inventory/00-decisions.md` and `docs/redesign/00-baseline.md`.
6. Upstream: `backend/scripts/README-dev-stack.md` (backend/00: uvicorn on 127.0.0.1:8010, the dev SQLite under `/srv/manhwamaniacs/dev/data/`, the demo account); `frontend/src/skins/types.ts` (web/00; `SKIN_DEBUG_COOKIE`).
7. Today's code you restructure (read in full): `frontend/src/features/reader/components/{ChapterReader,SourceReader,ReadAllReader,ContinuousStrip,PagedView,PageImage,ReaderControls,ScrubBar}.tsx`; `frontend/src/features/reader/{use-chapter-strip,use-strip-progress,use-chapter-preload,use-auto-scroll,use-cinema,use-reader-settings,use-reader-preferences,use-reader-shortcuts,hooks,strip,strip-source,read-all,chrome-controller,chrome-autohide,preload,scrub}.ts`; `frontend/src/features/offline/{save-request.ts,chapter-savers.ts,client.ts,hooks.ts}`; `frontend/src/features/sources/api.ts`; `frontend/src/lib/hover-intent.ts`; `frontend/src/services/http.ts`; `frontend/src/types/api.ts`; `frontend/e2e/smoke.spec.ts`; `frontend/playwright.config.ts`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                              # feat/vps-slim-source-native
ls frontend/src/skins/server.ts frontend/src/app/\(app\)/layout.tsx   # web/00 done
ls backend/scripts/dev_stack.sh backend/scripts/README-dev-stack.md  # backend/00 done
wc -l frontend/src/features/reader/components/*.tsx
```

## Skills to invoke

- `superpowers:writing-plans` first. Save the plan at `docs/redesign/proof/web-03/plan.md`. The engine extraction is the most regression-prone change in the web track (stack risk 6), so the plan must list the commits of section A one by one, each with the tests that gate it.
- `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). The engine extraction (A) runs in one session, not split across parallel subagents. B, C and D may run as parallel subagents. Check each against `git diff`, never against its report.
- `superpowers:test-driven-development` for the limiter, the auto-queue predicate and `coverTransitionName`.
- `superpowers:verification-before-completion` before claiming done.
- `impeccable`, `taste-skill:taste-skill` and `frontend-design` are not needed: this step changes no pixels.

## Scope, item by item

### A. Reader engine (cinematic §15.4; glass §15.4 commit step 0)

Commit A1–A7 separately, in this order, with `npm run test` green after each.

1. **A1, a pure move.** `git mv` `features/reader/components/{ContinuousStrip,PagedView,PageImage}.tsx` to `features/reader/engine/`. Fix only import paths (and tests that import them). No code change.
2. **A2, surface slots.** The surfaces paint legacy decorations inside the strip: the chapter divider RD7, the head card RD8, the tail RD9, the page placeholder RD5, the broken page RD4, the loading RD1, error RD2 and no-pages RD3 states, and the paged view's page-turn class. Make each one a prop on the surfaces, as one `slots` object:

   ```ts
   interface ReaderSurfaceSlots {
     loading(): ReactNode;
     error(message: string, retry: () => void): ReactNode;
     empty(): ReactNode;
     chapterDivider(chapter: StripChapter): ReactNode;
     head(edge: StripEdge, loadPrevious: () => void): ReactNode;
     tail(edge: StripEdge, retryNext: () => void): ReactNode;
     pagePlaceholder(page: { width: number | null; height: number | null }): ReactNode;
     brokenPage(page: { index: number }, retry: () => void): ReactNode;
   }
   ```

   Move today's markup for each one, verbatim, into `features/reader/components/legacy-surface-slots.tsx` (legacy UI; deleted at the flip). The engine folder then holds no legacy visuals. If a decoration takes arguments this interface lacks, extend the interface; never move markup back into `engine/`.
3. **A3, types.** `features/reader/engine/types.ts`:

   ```ts
   export type NextState = "loading" | "ready" | "failed" | "none";
   export interface ReaderEngineState {
     kind: "chapter" | "readAll";
     layout: "strip" | "single" | "double";
     status: "loading" | "ready" | "error" | "empty";
     error: string | null;
     chapter: { sourceId: string; seriesKey: string; chapterKey: string; label: string; number: number | null } | null;
     page: number;                      // 1-based page in the current chapter
     pageCount: number;
     progress: number;                  // 0–1 through the current chapter
     chapterPosition: { index: number; total: number } | null;   // read-all "n of total"
     neighbours: { previous: ChapterRef | null; next: ChapterRef | null; loadedKeys: readonly string[] };
     nextState: NextState;
     bookmarks: readonly { page: number; fraction: number }[];     // current chapter, for the ruler
     zoom: number;                      // 1 = fit
     autoScroll: { playing: boolean; speed: number };             // today's 1–10 steps (20–220 px/s)
     chromeVisible: boolean;
     cinema: boolean;
   }
   export interface ReaderEngineCommands {
     seek(fraction: number): void;
     jumpToPage(page: number, opts?: { glide?: boolean }): void;
     next(): void; previous(): void;
     toggleAutoScroll(): void; setSpeed(speed: number): void;
     zoom(scale: number): void;
     bookmark(): Promise<"saved" | "failed">;
     setChromeVisible(visible: boolean): void;
   }
   ```

   `ChapterRef` is `{ chapterKey: string; label: string; number: number | null }`. Take `bookmarks` from the existing bookmarks data (`features/bookmarks`), filtered to the current chapter, or `[]` when not loaded. `nextState` maps from the strip tail: loading → `loading`, tail error → `failed`, a next chapter whose manifest is loaded → `ready`, end of series → `none`. The fields later steps add (`pageTint`, `panels`, words on screen, `chapterCompleted`, and Glass's `currentPageSample`, `scrollVelocity`, `seamProgress`, `overscrollExtent`, `panelBoxes`) are **not** added now. Their steps add them (web/12, web/23, web/34).
4. **A4, the hook.** `features/reader/engine/use-reader-engine.ts`:

   ```ts
   export function useReaderEngine(input:
     | { kind: "chapter"; sourceId: string; seriesKey: string; chapterKey: string; initialPage?: number; at?: number }
     | { kind: "readAll"; sourceId: string; seriesKey: string; from?: string; initialPage?: number; at?: number },
     options?: { autoQueueNext?: boolean },
   ): ReaderEngine   // { state: ReaderEngineState; commands: ReaderEngineCommands; surface: SurfaceBindings }
   ```

   It composes the logic that lives today in `SourceReader` (the linked chapter source) and `ReadAllReader` (the bulk source and reading order): `useChapterStrip`, `useStripProgress` (progress POSTs debounced 500 ms and mirrored to `mm.source-progress`, unchanged), bookmark capture, next-chapter preload. It also takes the non-visual state `ChapterReader` holds today: visible page and chapter, zoom (50–300 %), auto-scroll through `use-auto-scroll`, chrome visibility and cinema through `chrome-controller` / `use-cinema`, reader settings through `use-reader-settings`, the jump-to-page and scrub handlers, and the keyboard map through `use-reader-shortcuts` (its bindings call engine commands). `SurfaceBindings` is everything `ContinuousStrip` or `PagedView` needs (the windowed chapters, refs, scroll handlers, preload state). No threshold or timing changes: hide 24 px, the 3000 ms cinema idle, preload windows and the 140 px over-scroll stay exactly as they are.
5. **A5, the view.** `features/reader/engine/ReaderEngineView.tsx`: `({ engine, slots, renderChrome, renderUnderlay? }) => …`. It renders the surface for `state.layout` with `slots`, then `renderChrome(engine.state, engine.commands)`. `renderUnderlay(state)` exists only if today's `ChapterReader` puts any element before the surface in DOM order (for example the night dimmer RD14 or the warmth overlay RD15). Keep today's DOM order and nesting exactly, so stacking cannot change. The view imports nothing from `features/reader/components/`.
6. **A6, legacy onto the engine.** `SourceReader` and `ReadAllReader` each call `useReaderEngine(...)` with `{ autoQueueNext: false }`, so legacy keeps today's behaviour. They render `ChapterReader`, which becomes the legacy frame: `<ReaderEngineView engine={engine} slots={legacySurfaceSlots} renderChrome={(state, commands) => <today's controls, counter pill, download control, bookmark notice, settings sheet, dimmer and warmth, fed from state and commands>} />`. Its markup, classes and ARIA stay byte-for-byte what they render today. Both entry points move in the same commit.
7. **A7, the auto-queue** (cinematic §8.14.11, "an existing engine duty, extended here").
   - `features/reader/engine/auto-queue.ts` exports a pure `shouldAutoQueueNext(i)`: true only when the chapter is manga, a downloads scope exists (active profile and a supported service worker), the `client_downloads` capability from `GET /settings` is on (find where the app reads `capabilities` with `grep -rn "client_downloads" frontend/src`), a next chapter exists, the next chapter is not saved in the offline index, it has not been queued already during this open, the profile's `mm.downloads.save-next` switch is on, and free storage from `navigator.storage.estimate()` (quota − usage) is at least 1,500,000,000 bytes. Unknown storage counts as enough.
   - The switch lives in `features/offline/save-next.ts`: scoped per profile, default `true`; `readSaveNext()` and `writeSaveNext(on)`. The Settings row arrives with each skin's downloads step.
   - When the engine's `autoQueueNext` option is true and the predicate passes, it builds the request with the same builder the download control uses (`features/offline/save-request.ts`) and calls `saveChapterOffline()` once per open (a ref keyed `sourceId/seriesKey/chapterKey`). No toast, no haptic.
   - `auto-queue.test.ts` covers every false branch and the true case.
8. **Lint.** Add a `no-restricted-imports` block to `frontend/eslint.config.mjs` for `files: ["src/features/reader/engine/**"]`, banning `../components`, `../components/**`, `@/features/*/components/**`, `@/components/**` and `@/skins/**`, so the engine can never lean on UI that the flip deletes.

### B. Sources request limiter (cinematic §15.6)

9. `frontend/src/features/sources/request-limiter.ts`:

   ```ts
   export type Priority = "P0" | "P1" | "P2" | "P3";
   export function createRequestLimiter(opts?: {
     capacity?: number;      // 50 starts
     windowMs?: number;      // 60_000
     p3MinFree?: number;     // 20
     p3MaxInFlight?: number; // 2
     now?: () => number; setTimer?: (fn: () => void, ms: number) => unknown;   // injectable for tests
   }): RequestLimiter;
   interface RequestLimiter {
     acquire(p: Priority, signal?: AbortSignal): Promise<Ticket>;   // resolves when the request may start
     run<T>(p: Priority, task: (signal?: AbortSignal) => Promise<T>, signal?: AbortSignal): Promise<T>;
     refund(t: Ticket): void;          // a response served from a local cache costs nothing
     pause(ms: number): void;          // after a 429: P2 and P3 wait until now + ms
     free(): number;                   // capacity − starts in the last windowMs, floor 0
   }
   export const sourcesLimiter = createRequestLimiter();
   export const HOVER_DWELL_MS = 150;
   ```

   The rules, exactly:
   - A **sliding window**: a log of start times, and each slot frees 60 s after the request that took it. It is not a refilling bucket (a bucket of 50 would admit up to 99 starts in one window).
   - **P0** (the visible reader page and the next) and **P1** (user-initiated lists: browse, search, series, chapters) never wait. They start at once and record a start.
   - **P2** (covers in view) waits until `free() >= 1` and no pause is active.
   - **P3** (prefetch: hover or focus manifests and pages, first rows, the next chapter's manifest, novel chapters, dialogue crops, preview slates) waits until `free() >= 20`, fewer than 2 P3 requests are in flight, and no pause is active.
   - Waiting requests are served P2 before P3, first come first served within a priority. An aborted `signal` removes a waiter.
   - `run()` calls `acquire`, runs the task, and releases the P3 in-flight count in `finally`. When the task throws an `ApiError` with status 429, it calls `pause(retryAfterMs ?? 12_000)`, and for P0 it waits that long and retries **once**.
   - `refund` removes that ticket's start from the log. A response is considered served from a local cache when the matching `PerformanceResourceTiming` has `transferSize === 0`.
10. Wiring:
    - `frontend/src/types/api.ts` `ApiError` gains `retryAfterMs: number | null`. `frontend/src/services/http.ts` parses the `Retry-After` header (delta seconds or an HTTP date) when it builds the error.
    - Every function in `frontend/src/features/sources/api.ts` goes through `sourcesLimiter.run("P1", …)`.
    - `lib/hover-intent.ts` `HOVER_PREFETCH_DELAY_MS` changes from 120 to 150 (the §15.6 dwell). Existing hover prefetch call sites keep working through it.
    - Covers (P2), gated `<img src>` and prefetch (P3) callers arrive with the skin primitives (web/04, web/26) and use `acquire()`.
11. `request-limiter.test.ts` (fake clock and timers):
    - 50 starts inside 60 s leave `free() === 0`, and the 51st P2 waits until the first start is 60 s old;
    - P0 and P1 never wait, even at 0 free;
    - a P3 waits while `free() < 20` and while 2 P3 are in flight;
    - a pause of 12 s holds P2 and P3 but not P0 or P1;
    - a P0 that hits 429 with `Retry-After: 5` retries once after 5 s;
    - `refund` frees the slot;
    - an aborted waiter never starts;
    - a refilling-bucket regression case: 99 starts must never fit in any 60 s window.

### C. `coverTransitionName()` (cinematic §8.0.4; glass §15.2)

12. `frontend/src/features/sources/cover-transition-name.ts`:
    - `export function fnv1a32(text: string): number` is the 32-bit FNV-1a over the UTF-8 bytes of `text` (`new TextEncoder().encode`), with offset basis `0x811c9dc5` and prime `0x01000193` (`Math.imul`, `>>> 0`). web/16 reuses it for `sourceWashHue`.
    - `export function coverTransitionName(sourceId: string, seriesKey: string): string` returns `"cover-" + fnv1a32(sourceId + "\u0000" + seriesKey).toString(16).padStart(8, "0")`.
    - It is synchronous (`crypto.subtle` is async and cannot run during render).
13. `cover-transition-name.test.ts`, with these exact vectors:
    - `fnv1a32("") === 0x811c9dc5`, `fnv1a32("a") === 0xe40c292c`, `fnv1a32("foobar") === 0xbf9cf968`;
    - `coverTransitionName("", "") === "cover-050c5d1f"`;
    - `coverTransitionName("asura", "solo-leveling") === "cover-a07012e1"`;
    - `coverTransitionName("mangadex", "a/b c%d") === "cover-a34e56be"`;
    - `coverTransitionName("src", "한국") === "cover-7f4c64fd"`;
    - every output matches `/^cover-[0-9a-f]{8}$/`, a valid `view-transition-name`.

### D. The proof harness (`frontend/scripts/proof.mjs`)

14. An ES module run with Node 22, using the installed `playwright` package and headless Chromium only. It starts with a usage comment that documents the dev stack:

    ```
    # backend: see backend/scripts/README-dev-stack.md (uvicorn 127.0.0.1:8010, dev SQLite, never production data)
    # frontend: free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010
    # then:     MM_PROOF_USER=… MM_PROOF_PASSWORD=… node scripts/proof.mjs --step web-08 --skin cinematic --routes /,/library
    ```

    Flags:

    | Flag | Meaning | Default |
    |---|---|---|
    | `--step <name>` | Output folder `docs/redesign/proof/<name>/` (resolved from the repo root, whatever the cwd) | required |
    | `--routes <list or file>` | Comma-separated routes, or a path to a `.txt` file with one route per line (`#` starts a comment) | required |
    | `--skin <legacy\|cinematic\|glass>` | Sets the `mm-skin-debug` cookie before the first navigation | no cookie |
    | `--base <url>` | Dev server | `http://127.0.0.1:3010` |
    | `--session <name>` | Named session: the signed-in storage state is kept at `$TMPDIR/mm-proof-<name>.json` and reused while `GET /api/auth/me` answers 200 | the step name with `/` replaced by `-` |
    | `--profile <name>` | Profile to activate | the first profile in `GET /api/profiles` |
    | `--no-auth` | Skip sign-in (for `/login`, `/register`) | off |
    | `--dpr3` | Also capture 440 × 956 at `deviceScaleFactor: 3` | off |
    | `--grid` | For each shot, also press `Control+Shift+KeyG` (the grid overlay of web/04 and web/26) and save a `-grid` copy | off |
    | `--reduced` | `reducedMotion: "reduce"` on the context; files get `-reduced` | off |
    | `--viewport-only` | Viewport screenshots instead of full page | full page |
    | `--settle <ms>` | Wait after `networkidle` and `document.fonts.ready` | 1500 |
    | `--help` | Print the usage | |

    - **Viewports**: 1440 × 900 and 390 × 844, both at `deviceScaleFactor: 1`.
    - **File names**: `<skin or "default">-<slug>-<w>x<h>[@3x][-reduced][-grid].png`. The slug is the route with `/` → `home`, the leading `/` dropped, and `/ ? = & %` replaced by `-` (repeats collapsed).
    - **Credentials** come only from `MM_PROOF_USER` and `MM_PROOF_PASSWORD`. When they are unset, exit 2 with "Set MM_PROOF_USER and MM_PROOF_PASSWORD (the demo account in backend/scripts/README-dev-stack.md)". Never hard-code them.
    - **Sign-in** is exported for reuse by e2e specs: `export async function signIn(context, { base, user, password, profile })`:
      - `POST /api/auth/login` through `context.request`;
      - `GET /api/auth/me` for the user id;
      - `GET /api/profiles` and pick the profile;
      - `context.addInitScript` to write `localStorage["mm.active-profile"] = JSON.stringify({ state: { activeProfile: { id, name, avatar_key, mood }, ownerUserId }, version: 0 })`, matching `features/profiles/store.ts`'s persist options (check its `version`) before any page script runs.
    - **Status**: each route's HTTP status is printed. A 5xx or a navigation error fails the run (exit 1); a 404 is allowed, because 404 pages are proof too.
    - **Main guard**: `main()` runs only when the file is executed directly (`import.meta.url === pathToFileURL(process.argv[1]).href`).
    - If Chromium is missing, the script prints `npx playwright install chromium` and exits 2.

## File layout

```
frontend/src/features/reader/engine/{ContinuousStrip,PagedView,PageImage}.tsx   git mv from components/, then slots
frontend/src/features/reader/engine/{types.ts,use-reader-engine.ts,ReaderEngineView.tsx,auto-queue.ts,auto-queue.test.ts}   new
frontend/src/features/reader/components/{ChapterReader,SourceReader,ReadAllReader}.tsx   change (onto the engine)
frontend/src/features/reader/components/legacy-surface-slots.tsx                  new (legacy markup, verbatim)
frontend/src/features/offline/save-next.ts                                         new
frontend/src/features/sources/{request-limiter.ts,request-limiter.test.ts,cover-transition-name.ts,cover-transition-name.test.ts}   new
frontend/src/features/sources/api.ts                                               change (P1 wrap)
frontend/src/services/http.ts, frontend/src/types/api.ts                           change (retryAfterMs)
frontend/src/lib/hover-intent.ts                                                   change (150 ms)
frontend/eslint.config.mjs                                                         change (engine boundary)
frontend/scripts/proof.mjs                                                         new
docs/redesign/proof/web-03/plan.md, docs/redesign/proof/web-03/*                        new
```

No file under `frontend/src/skins/` changes in this step, and no ScreenId leaves `PENDING`.

## Acceptance criteria

- [ ] `npm run typecheck`, `lint`, `test` and `build` pass. Every Vitest file and case that passed before your first change still passes, including every test under `src/features/reader/` (list them in the report), and the counts are at least the recorded ones.
- [ ] `npm run verify:reader` exits 0 (today `scripts/verify-reader.mjs` is a stub that prints that it is superseded by `npm run test:e2e` and exits 0; leave it as it is). `npm run test:e2e` against the dev stack passes, and it is the real reader check (`E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=<demo> E2E_PASSWORD=<demo>`).
- [ ] Legacy reader pixel parity: before and after screenshots of the chapter reader and read-all reader are identical apart from live data. Take them at 1440 × 900 and 390 × 844 with the chrome shown, the chrome hidden, the settings sheet open, paged Single mode, and the broken-page state (block one image URL with `page.route`).
- [ ] Legacy reader behaviour, checked in the dev stack with Playwright, both entry points (`/reader/…` and `/read-all/…`):
  - scrolling a chapter to the end appends the next chapter;
  - `POST /reader/progress` fires (network log) with the same payload fields as before;
  - `b` saves a bookmark;
  - `p` toggles auto-scroll;
  - `c` enters cinema and the chrome hides after 3 s;
  - the scrubber and the jump-to-page field move to the right page;
  - `?page=7` and `?at=` restore the position;
  - no console errors.
- [ ] `grep -rn "components/" frontend/src/features/reader/engine` is empty, and the engine lint block rejects a probe import of `../components/ReaderControls` (delete the probe; do not commit it).
- [ ] Auto-queue: legacy readers pass `autoQueueNext: false`, and no save request is sent while reading in legacy. `auto-queue.test.ts` passes every branch.
- [ ] `request-limiter.test.ts` and `cover-transition-name.test.ts` pass with the exact vectors above. Browsing a source in legacy still loads, and its `/api/sources/*` calls pass through `sourcesLimiter` (a temporary `console.debug` in `run`, removed before commit, or a unit test on `api.ts`).
- [ ] `proof.mjs`:
  - `node scripts/proof.mjs --help` prints the table;
  - a run with `--step web-03 --routes /library,/reader --skin legacy` writes 4 PNGs into `docs/redesign/proof/web-03/`;
  - `--skin cinematic` gives the pending screens;
  - `--dpr3`, `--reduced` and `--grid` produce the extra files with the right suffixes;
  - a second run reuses the named session without a new `POST /api/auth/login` (check the backend log);
  - missing credentials exit 2 with the message above.
- [ ] Keyboard (web): every reader key binding works exactly as before (inventory §9 and the keymap tests).
- [ ] Hit targets: unchanged; this step adds no control.
- [ ] Reduced motion: unchanged. Auto-scroll still never auto-starts under `prefers-reduced-motion: reduce` (checked with `--reduced`), and the paged fade still follows the setting.
- [ ] Per-skin differences: none by design. The engine, limiter, name helper and harness are skin-neutral. `grep -rn "skins/" frontend/src/features/reader frontend/src/features/sources` is empty.

## Verification

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/frontend
free -m                                   # stop under 1024 MB available
npm run test 2>&1 | tail -5               # BEFORE changes: record counts; also save `npx vitest run src/features/reader --reporter=verbose` output
# … each A-commit: free -m && npm run test …
free -m && npm run typecheck
free -m && npm run lint                   # baseline: 0 errors, 0 warnings
free -m && npm run test
free -m && npm run build                  # never alongside next dev or another build
npm run verify:reader
```

Mobile and backend: this step changes neither. Judge that by your own commits, never by the branch diff (mobile, backend and shared sessions commit on the same branch): `git show --stat --format= <hash>` for each of your commits must list no `mobile/` or `backend/` path. Only if one does, revert that part and prove the baseline still holds with its own commands, one at a time after the RAM guard: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Dev stack and proof.**

1. Start the backend dev stack exactly as `backend/scripts/README-dev-stack.md` says (uvicorn 127.0.0.1:8010, the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data). Export `MM_PROOF_USER` and `MM_PROOF_PASSWORD` from that README's demo account.
2. `free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010` in the background.
3. **Before** section A starts: find one seeded chapter URL and one read-all URL (for example from `GET /api/library/continue-reading`). Take the reader screenshots listed in the acceptance criteria into `docs/redesign/proof/web-03/before/`, with a one-off Playwright script. `proof.mjs` does not exist yet at that point; write it first, and it becomes that script.
4. **After**: `node scripts/proof.mjs --step web-03/after --skin legacy --routes <reader URL>,<read-all URL>`, plus the chrome, sheet, paged and broken-page states (drive those with small additions to the same run, or a scratch script under `/tmp` that imports `signIn` from `scripts/proof.mjs`).
5. Harness self-check: `node scripts/proof.mjs --step web-03/harness --skin cinematic --routes /,/library --dpr3 --reduced --grid`.
6. e2e: `E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=$MM_PROOF_USER E2E_PASSWORD=$MM_PROOF_PASSWORD npm run test:e2e`.
7. Stop `next dev` before any `npm run build`. If Chromium is missing, run `npx playwright install chromium` once.

## Git

- Branch `feat/vps-slim-source-native`. Commits: plan; A1 to A7 as separate commits (A1 a pure move); engine lint block; limiter; the limiter wiring and `retryAfterMs`; hover dwell; `coverTransitionName`; `proof.mjs`; proof images. Push after each working step: `git push origin feat/vps-slim-source-native`.
- Stage explicit paths only, never `git add -A`: mobile, backend and shared sessions commit in this checkout.
- No Claude or AI attribution (no `Co-Authored-By`, no "Generated with" line). Never commit real credentials or secrets (the dev-stack demo password is committed only in `backend/scripts/README-dev-stack.md` by `backend/00`; never copy it into a spec, script or proof file), `.env*` or `.claude/`.
- `npm run build` must pass before every push.

## Guardrails

- Work in `frontend/` (plus `docs/redesign/proof/`). Never edit `backend/` (and never `backend/connectors/`), `mobile/`, `design/` or generated files.
- Never touch production containers or `/srv/manhwamaniacs/{app,data}`. The dev stack uses only the dev SQLite.
- RAM guard: `free -m` before every build, test run, e2e run and dev server start. Stop under 1024 MB available. One heavy command at a time.

## Report back

1. Done items A1–A7, B, C and D, each with its commit hash.
2. The engine: final `ReaderEngineState` and `ReaderEngineCommands` (paste the two interfaces), whether `renderUnderlay` was needed and why, and any slot you added beyond the list.
3. The reader test list (every file under `src/features/reader/` with its case count) before and after.
4. The e2e result and the manual behaviour checks, each ticked.
5. Screenshot folders `docs/redesign/proof/web-03/{before,after,harness}/`.
6. Test counts, lint and build results, and the lowest `free -m` available figure.
7. Open issues.

Next prompt in the web track: `docs/redesign/prompts/web/04-cinematic-primitives-core-and-reveals.md` (it needs web/02 and web/03). Next in the global order: `docs/redesign/prompts/mobile/03-foundation-fonts-icons-harness-glass-gate.md`.
