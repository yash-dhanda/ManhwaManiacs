# Web Cinematic QA and polish before the flip

Track: web · Order 65 · Depends on: `docs/redesign/prompts/web/23-cinematic-ambient-reader-extras.md` · Runs in parallel with: `docs/redesign/prompts/mobile/24-cinematic-qa-polish.md` · Proof folder: `docs/redesign/proof/web-24/`

## Goal

Every Cinematic web screen now exists (steps `web/04` to `web/23`). This step proves the whole skin against its contract and fixes everything that fails, so `release/00` can make Cinematic the default. You will: make the completeness test strict (no Cinematic `ScreenId` left in `PENDING`); run the accessibility rules of `cinematic/DESIGN.md` §14 and every check of §15.7 across every screen; verify reduced motion against the §4.8 table and §14.1; verify the §15.6 performance guards; run the motion-timings overlay over every named move; capture every `ScreenId` at 1440 × 900, 390 × 844 and 440 × 956 at DPR 3, with and without the grid overlay; produce the five "Front pages" frames of §12.6 and replace the placeholder capture in `frontend/public/og.png` with the real Tonight capture; prove the two signature animations; fix every defect found, each in its own commit; and write `docs/redesign/proof/web-24/qa.md`. You add no features. When a check needs something the contract does not define, the contract wins and the gap goes into `qa.md` as an open issue.

## Read first

Read these completely before planning. Where this file and `cinematic/DESIGN.md` disagree, `cinematic/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it; the two signature animations are binding, "Still honor OS reduced-motion for accessibility").
2. `docs/redesign/stack-decision.md` §2.2 (completeness through `satisfies Record<ScreenId, Screen>`, the lint boundary), §3 "Release model", §4 risk 11 (dev-box memory).
3. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.1 (the neutral ramp; `ink.45` `#7A7770` lives on `paper.0` `#000000` only, and the raised-stock scope), §2.1.4 (scrims and the over-art table: `ink.100` 0.60, `ink.80` 0.68, `spot` 0.66, `set` 0.70, `ink.60` 0.82, `proof` 0.84 minimum black alpha at the text line), §2.2.2 (the grid and the `mod+shift+g` / `mod+shift+m` debug overlays), §2.4 (focus ring and z layers).
   - §4.5 (the motion table: every named move and its planned duration), §4.6, §4.7, §4.8 (the reduced-motion table, authoritative).
   - §5 (the five web `navigator.vibrate` events), §6 (sounds off by default).
   - §7 intro (hit areas, heights are minimums), §7.1 (button loading segment), §7.10 (the 1000 ms destructive arm), §7.18 (leader dial and indeterminate rule), §7.29 (`folioLabel()`).
   - §8.0.3 (the `ScreenId` and route table), §8.0.4, §8.0.6 (global keys), §8.0.7 (the debug row before the flip), §8.0.10.
   - §10.1 (all of it: the Letter set, `SetHeading`, triggers `inView` at 50 %, `mount`, `signal`), §10.2 (all of it: `TypedHeadline`, 50 ms per grapheme, the caret, skip rules, where it plays).
   - §11 (the last column: the alternative for every gesture).
   - §12.6 (the "Front pages" set and the OG image), §12.7.
   - §14.1 to §14.11 (every rule), §15.2 (web file map), §15.6 (performance guards), §15.7 (accessibility checks per cluster), §15.8 (verification), §15.9 (the motion-timings overlay).
4. `docs/redesign/inventory/web.md` §1 (route table), §2 (global chrome), §2.9 (keyboard layer), §2.10 and §2.11 (status screens and shared states), §18 (every user action) as the checklist that no function was lost in the redesign.
5. `docs/redesign/inventory/capabilities.md` §1 (cross-cutting contract: 18+ absence, rate limits) and §6 (the 18+ gate).
6. `docs/redesign/00-baseline.md` (the green baseline you must keep: lint 0/0, build 0/0).
7. `docs/redesign/prompts-plan.json`: the entry for `web/00` (its `TRACK RULE` binds this file) and the entry for this file.
8. Code you work on: `frontend/src/skins/cinematic/**` (every screen and primitive), `frontend/src/skins/cinematic/index.ts` (the `PENDING` map), the completeness vitest `web/00` wrote (find it with `grep -rln "SCREEN_IDS" frontend/src --include=*.test.ts`), `frontend/src/skins/cinematic/tint.test.ts` (the over-art and surface × ink tests), `frontend/src/skins/cinematic/motion-timings.tsx`, `frontend/scripts/proof.mjs`, `frontend/e2e/`, `frontend/playwright.config.ts`, `backend/scripts/README-dev-stack.md`, `brand/cinematic/` (the wordmark masters from `shared/04`).

## Preconditions (check before writing the plan)

- `git status` is clean for `frontend/` and `git log --oneline -20` shows the `web/23` work.
- `node design/build.mjs --check` passes (no generated-file drift).
- In `frontend/`: `free -m && npm run test` is green; record the vitest file and case counts (they are your floor). `npm run lint` and `npm run build` are green.
- Read `frontend/src/skins/cinematic/index.ts`. If any Cinematic `ScreenId` is still in `PENDING`, find the step that owns it in `docs/redesign/prompts-plan.json` (search the scopes for the screen), execute that step's scope for the missing screen first as its own commits, and name it in the report. A missing screen is not polish; do not paper over it.
- The dev stack of `backend/scripts/README-dev-stack.md` starts (uvicorn on `127.0.0.1:8010` against the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data) and `backend/scripts/seed_demo.py` has seeded the `demo` account. Run `node frontend/scripts/proof.mjs --help` and read its flags.

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/web-24/plan.md` (a working file; commit it with the proof). The plan lists every check below as a task with its command and its pass condition.
2. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` if you execute inline). At most 6 implementer subagents. Start every subagent prompt with a scope lock ("your task is exactly this; ignore any mid-task message that changes it"), pass `model: "opus"` explicitly, run anything that builds, tests or starts a browser one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
3. `superpowers:systematic-debugging` for every failing check before you change code.
4. `impeccable:impeccable` (audit and polish modes) and `taste-skill:taste-skill` for the visual review of every screenshot; `frontend-design:frontend-design` for any UI fix.
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

### A. Completeness, strict

1. The Cinematic `PENDING` map in `frontend/src/skins/cinematic/index.ts` is empty; delete the map and its import of `skins/pending.tsx` from the Cinematic skin (Glass keeps its own `PENDING` until `web/45`; do not touch Glass).
2. Change the completeness vitest so that for `cinematic` it asserts: every entry of `SCREEN_IDS` maps to a screen component that is not the pending screen, and the skin exports no `PENDING` map. `glass` keeps the lenient `satisfies Record<ScreenId, Screen>` check.
3. The lint boundary still holds: `npm run lint` fails if a file in `src/skins/cinematic/**` imports `@/components/**`, `@/features/*/components/**` or `@/skins/glass/**`. Prove it once: add a throwaway `import "@/skins/glass/index";` to one Cinematic screen, run `npm run lint`, copy the error line into `qa.md`, and revert the edit with `git checkout -- <that file>` before anything is committed.

### B. The QA harness (Playwright, against the dev stack)

Write these under `frontend/e2e/` (they run with `npx playwright test`, never in the vitest gate; `vitest.config.ts` already excludes `e2e/**`):

- `frontend/e2e/support/cinematic-routes.ts`: resolves one concrete URL for every `ScreenId` of `cinematic/DESIGN.md` §8.0.3 against the seeded dev stack. It signs in as `demo` (password from `backend/scripts/README-dev-stack.md`), picks the first profile, sets the cookie `mm-skin-debug=cinematic`, and reads real parameters from the API: the first followed series (`featureByFollow` `/library/:followedId`, `feature` `/sources/:sourceId/series/:seriesKey`, `reader`, `readAll`, `recap`), the first source (`source`), a novel series and chapter when `novels_enabled` is true (`novel`; when novels are off, record `novel` as "not reachable on this server" and capture the book page state instead), the first collection (`collection`), the current year (`annual`), the second profile (`circleMember`, `profileEdit`), and the static paths for the rest (`setup` must redirect to `/login`; `readerLanding` is `/reader`). Every `ScreenId` in `SCREEN_IDS` appears in the resolved list; the file throws if one is missing.
- `frontend/e2e/support/audit.ts`: one `audit(page, { pointer: "coarse" | "fine" })` function run on every screen, returning a list of violations with a CSS selector, the rule and the measured value:
  1. **Console and network:** no `console.error`, no uncaught exception, no failed request except the ones a state deliberately provokes.
  2. **One `h1`** per page; section heads are `h2`; `document.title` is `{Page} · ManhwaManiacs` (§14.4, §14.5).
  3. **Names:** every `button`, `a[href]`, `[role=button|link|tab|switch|checkbox|radio|slider|menuitem|option]`, `input`, `select`, `textarea` and `[tabindex="0"]` has a non-empty accessible name (computed from `aria-labelledby`, `aria-label`, `<label>`, `alt`, text content, then `title`, in that order).
  4. **Hit targets (§14.6):** on `coarse` (390 × 844 with `hasTouch: true, isMobile: true`) every interactive element's own box is ≥ 44 × 44 CSS px with ≥ 8 px to the nearest other interactive box; on `fine` (1440 × 900) ≥ 32 × 32 with ≥ 24 px target spacing (WCAG 2.5.8). Inline text links inside running text are exempt and listed.
  5. **`ink.45` on the wrong ground (§2.1.1, §14.2):** every element whose computed `color` is `rgb(122, 119, 112)` (`ink.45`) must have `rgb(0, 0, 0)` as the first non-transparent `background-color` found walking up its ancestors (a `background-image` ancestor counts as "over art" and fails unless the element has its own solid ground).
  6. **Text size (§14.7):** no visible text node renders below 11 px computed `font-size`.
  7. **Images:** every `img` has `alt` (empty only when it sits inside an element whose accessible name already carries the title, or when it is decorative and `aria-hidden`).
  8. **Scrims resolve (§15.7):** every element with the `scrim-foot` class, the running head's and folio bar's `::before` and the Listen transport's `::before` have a computed `background-image` that is not `none`.
- `frontend/e2e/cinematic-qa.spec.ts`: for every resolved route, at `fine` 1440 × 900 and at `coarse` 390 × 844, loads the page, waits for network idle and for every `[aria-busy="true"]` region to clear (10 s cap), runs `audit()`, and writes the violations to `docs/redesign/proof/web-24/audit/<screenId>-<viewport>.json`. A second pass at a 720 × 450 viewport with `deviceScaleFactor: 2` (the layout of 200 % browser zoom on 1440 × 900) asserts `document.documentElement.scrollWidth <= innerWidth` on every screen (§14.7; tables scroll inside their own container and are exempt).
- `frontend/e2e/cinematic-focus.spec.ts` (desktop 1440 × 900, keyboard only): on every screen, the first `Tab` lands on the visible **Skip to content** link and `Enter` moves focus to the page `h1`; then `Tab` 60 times, recording each focused element's rect and its computed `outline-style`, `outline-color` and `box-shadow`. Pass: every focused element shows the double ring (`outline: 2px solid` `ink.100` at 2 px offset plus the black halo `0 0 0 6px #000`, §14.4), nothing focused is invisible or covered (the element's centre point returns the element or a descendant from `document.elementFromPoint`), rails take one tab stop each, and the order follows the grid's reading order (a jump backwards in y of more than 8 px outside a landmark change is recorded in `qa.md` and fixed). Also: after an in-app navigation focus is on the new `h1`; opening a sheet, dialog, the command palette or the Lightbox traps focus and returns it to the trigger on close.
- `frontend/e2e/cinematic-motion.spec.ts`: see section D.
- `frontend/e2e/cinematic-signature.spec.ts`: see section G (if `web/04` already wrote a signature spec, extend that file instead and keep its name).

### C. Accessibility rules of §14 and every §15.7 check, on every screen

Work through each bullet of §15.7 and each subsection of §14 and record a pass or a fix in `qa.md`:

1. **Contrast (§14.2, §15.7 first two bullets):** the `tint` tests pass, including the surface × ink loop and the over-art table composited over `#FFFFFF` and `#F5F547` (≥ 4.5:1; ≥ 3:1 for large text and icons). Add any over-art row the table is missing: walk every screenshot of section E and every place where text or an icon sits over a cover, a page, a duotone field or a blurred copy, and make sure each such (component, ink, ground alpha) has a row. Check each on a white page and a white cover with the focus ring on an on-art control (the black halo must show). The audit rule B5 finds `ink.45` on any ground but `paper.0`.
2. **Colour is never the only signal (§14.3):** health states carry a label and a square mark, cautions the `NOTE` kicker, errors the `CORRECTION` kicker and the `‸` margin mark, download states distinct shapes, reactions a glyph and a name, charts a text summary and a label on every mark. Check each screen that shows them.
3. **Keyboard and focus (§14.4):** the `cinematic-focus.spec.ts` results; forced colours (`page.emulateMedia({ forcedColors: "active" })`) and more contrast (`page.emulateMedia({ contrast: "more" })`) screenshots of every screen at 1440 × 900 into `docs/redesign/proof/web-24/forced-colors/` and `.../more-contrast/`, checked by eye: rules, hairlines, notches, focus rings and outlines use `CanvasText`; `spot` fills become `Highlight`; duotone, grain, scrims and blur are gone under forced colours; `ink.45` renders `ink.80` and `rule.1` renders `rule.2` under more contrast. Single-key shortcuts turn off in Settings → Keyboard and stop firing.
4. **Screen readers (§14.5):** from the accessibility tree (`page.locator("body").ariaSnapshot()`): each page has one `h1`; `SetHeading` and `TypedHeadline` expose their full text from the first frame (take the snapshot 100 ms after navigation, while the animation still runs); toasts are `role="status"`, errors `role="alert"`; the reader's polite live region announces exactly "Chapter 143, The Return · Solo Leveling" (or "Chapter 143 · Solo Leveling" without a chapter title) on entry and on a chapter change, and nothing on page changes; the ruler is a range with `aria-valuetext="Page 18 of 40"`; folios read in full through `folioLabel()`; the Lightbox is labelled "Cover of {title}". Timers pause while keyboard focus is inside the element they time (toast holds, chrome idle hide, mini-player linger).
5. **Touch targets (§14.6):** audit rule B4 on every screen; the reader's tap zones are at least 25 % of the width, and a full-width band at least 12 % of the height.
6. **Text size (§14.7):** the 200 % pass of section B; every screen again with Hyperlegible text on (Settings → Appearance), captured at 1440 × 900 and 390 × 844 into `docs/redesign/proof/web-24/hyperlegible/`; nothing clips or truncates that the contract does not truncate.
7. **Every gesture has an alternative (§14.8):** for every row of §11 whose platform includes the web, press the alternative named in its last column (button, menu item or key) and confirm it does the same thing; long-press menus are mirrored by a visible `dots-three` button, the Lightbox by `View cover`, swipe actions by row menus.
8. **Haptics and sound (§14.9):** haptics accompany a visible change and turn off in Settings → Feedback (`localStorage['mm.haptics'] = "off"` stops every `navigator.vibrate` call; stub `navigator.vibrate` in the page and count calls); UI sounds are off by default for a new profile and silent while narration or a soundscape plays.
9. **Flashing (§14.10):** nothing flashes more than three times a second: measure the caret blink (0.94 Hz), skeleton flicker (0.36 Hz) and sparks (once a second) from their CSS or Motion timings and record them.
10. **Content safety (§14.11) and the 18+ on-device checklist (§15.7):** on the dev stack only, with the demo profile whose gate is open, follow one mature series from a working 18+ source, download one chapter, add a bookmark, read two pages; then close the gate and check that Downloads, Library (online and offline), Tonight's offline edition, Bookmarks, History, Discover search, every badge and every count show none of it and say nothing about it; with the gate open again, check it all returns untouched. A World card shows the 16 px certificate when `is_adult` is true or any `available[]` source is mature, and is absent with the gate closed. Share cards draw only the `shareable` block. Afterwards unfollow the series and delete the download so the seed is as it was.
11. **Destructive confirms (§7.10, §15.7):** every destructive confirm in the app keeps the 1000 ms arm: a double click on its trigger must not confirm (Playwright `dblclick` then assert nothing was deleted). List each confirm you tested.
12. **Spoiler guard (§15.7):** reactions checked on an unread, a half-read and a finished chapter.

### D. Reduced motion (§4.8, §14.1) and the motion-timings pass (§15.9)

1. `frontend/e2e/cinematic-motion.spec.ts` runs every screen twice with `reducedMotion: "reduce"`: once from the OS query alone, and once with the OS query off and the in-app switch Settings → Appearance → "Reduce motion in the app" on (which stamps `html[data-motion="reduced"]`). On each screen: `document.getAnimations()` returns only the allowed running animations (the leader dial, the indeterminate rule and the button loading segment of §7.1 and §7.18); no element under a `SetHeading` has a per-letter transform or blur (the whole string fades over 200 ms); every `TypedHeadline` shows its full text at once with no caret; Drift shows a still frame at scale 1.03; programmatic scrolls jump (`behavior: "auto"`). Then walk every row of the §4.8 table by hand and tick it in `qa.md`: Column wipe, Iris, match cut and Stop the press become a 200 ms cross-fade; Page, Dip, Rise and Insert a 150 ms fade; skeletons static at 0.8; rules present at rest; Folio flip instant; poster hover outline only; auto-scroll never auto-starts; guided view cuts; streak loops static; the trailer scrub scrolls away normally and the now-showing strip fades in over 150 ms; Cut to home cross-fades; Lightbox fades and still drags to dismiss; the arm rule appears full at 1000 ms; the recap and Listen countdowns update a label once per second; the voice pulse is a static band; the colophon is a still page; page-tint and ambient swaps are instant and page tint changes at most once every 2 s; gestures still track the finger and finish with a 150 ms fade.
2. **Motion-timings overlay pass.** In `next dev` (the overlay exists in development builds only), open the overlay with `mod+shift+m` and trigger every named move of §4.5 at least once at 1440 × 900 and every phone-specific move at 390 × 844. After each screen, use the overlay's `Copy log` and append the JSON to `docs/redesign/proof/web-24/motion-log.json`. Pass: no row is `proof` (no dropped frame, no overrun of more than one frame over the planned duration). The VPS has no GPU, so headless Chromium rasterises in software: for every failing row, record a Performance trace (`page.tracing` or Chrome DevTools Protocol `Tracing.start` with the `devtools.timeline` category) and read where the frame time goes. Script, style or layout cost is yours to fix now (typical causes: animating layout properties instead of `transform` and `opacity`, a filter animated on a large layer, a React re-render per frame). Raster-only cost is a software-rendering artefact: list those moves in `qa.md` under "Owner check on real hardware" with the exact steps to reproduce them in desktop Chrome with the overlay on.
3. The `SKIN RESTART` entry: switch LEGACY → CINEMATIC and back through the debug row (`/settings/diagnostics?debug=1`) with the overlay on; the entry is under 1,500 ms.

### E. Screenshots of every `ScreenId`

Using `frontend/scripts/proof.mjs` (add any flag it lacks: `--jpeg` with quality 80, `--dpr`, `--grid`), with the skin forced through the `mm-skin-debug=cinematic` cookie, headless Chromium in the named session `web-24`, capture every resolved route of section B at:

- 1440 × 900 (DPR 1), 390 × 844 (DPR 3, touch), 440 × 956 (DPR 3, touch);
- each once with the grid overlay off and once on (`mod+shift+g`);
- as JPEG quality 80 (the set is large; PNG is kept for the Front pages and `og.png` only),

into `docs/redesign/proof/web-24/screens/<screenId>-<width>x<height>[-grid].jpg`. Also capture each screen's loading, empty, error and offline states that the contract defines (use Playwright `page.route` to delay or fail the relevant request, and `context.setOffline(true)` for offline) at 1440 × 900 and 390 × 844 into `.../states/`. Review every image with `impeccable` and `taste-skill` against the contract and fix what is wrong (misaligned to the grid, text off the baseline, wrong ink on a ground, a clipped focus ring, a scrim that does not reach the text).

### F. "Front pages" and the real `og.png` (§12.6)

Write `frontend/scripts/front-pages.mjs` (Node 22 + the installed `playwright`, no new dependency). It captures and composes by rendering a small HTML composition page in Playwright and screenshotting it, so no image library is needed. The composition page loads its faces from Google Fonts (`https://fonts.googleapis.com/css2?family=Bodoni+Moda:ital,opsz,wght@1,6..96,400&family=IBM+Plex+Mono:wght@500&display=block`) and waits for `document.fonts.ready` before each screenshot; the UI captures are taken first from the running dev server and embedded as `data:` URLs.

1. **Five phone frames**, each 1320 × 2868 (a 440 × 956 CSS viewport at DPR 3), no 18+ content, the seeded demo profile:
   - `front-1-tonight.png`: caption "Every source. One shelf.", folio `No. 1 · TONIGHT`, the UI capture from the edition preview route `/skin-preview/cinematic` (it renders Tonight from `frontend/src/skins/preview-feed.generated.json` with the demo covers, which satisfies "placeholder covers in the hero frame").
   - `front-2-reader.png`: "Built for the long scroll.", folio `No. 2 · THE STRIP`, the manga reader mid-chapter with the chrome shown (a chapter from the seeded library).
   - `front-3-listen.png`: "Novels, read aloud." with the sub "Thirty-one voices", folio `No. 3 · THE READING`, the Listen full player (when novels are off on the dev server, turn `novels_enabled` on for the dev stack only).
   - `front-4-annual.png`: "Your year in chapters.", folio `No. 4 · THE ANNUAL`, the first Annual page.
   - `front-5-circle.png`: "Read together.", folio `No. 5 · CIRCLE`, the Circle screen with the second demo profile's activity.
   Layout per §12.6: a 640 px black top band with the caption as a magazine cover line in Bodoni Moda Italic 120 px, `ink.100` bone, with one keyword in `spot` `#F4D03F` via a highlighter band (the keyword per frame: "One shelf.", "long scroll.", "read aloud.", "chapters.", "together."), the folio line above it, then a bone Oxford rule at DPR 3 (9 + 6 + 3 px, `rule.oxford`) between band and capture, then the UI capture, square-cornered, bleeding off the bottom edge.
2. **Desktop set**, 2880 × 1800 (1440 × 900 at DPR 2), the same five captions in the spread layout: `front-desktop-{1..5}-….png`.
3. **`frontend/public/og.png`**, 1200 × 630, replacing the `shared/04` placeholder capture: `#000000`; a 12-column grid with 48 px margins; the wordmark lockup (from `brand/cinematic/`, the stacked masthead lockup SVG) at 72 px cap height with its Oxford rule in columns 1–5, vertically centred; "Every source. One shelf." in Bodoni Moda Italic 40 under it; columns 6–12 hold the Tonight capture from frame 1's source route at 1440 × 900, square-cornered, bleeding off the right and bottom edges under `scrim.gutter` (the eased 13-stop scrim of §2.1.4, end `#000` at the text side); no 18+ content, no real profile names (the demo profile names only).
4. Output: the phone and desktop frames in `docs/redesign/proof/web-24/front-pages/` (PNG), `og.png` in `frontend/public/`. `release/00` publishes the frames with the SideStore source; name them in the report.

### G. Signature animations actually play

`frontend/e2e/cinematic-signature.spec.ts`, desktop 1440 × 900, a fresh browser context per test:

1. **Typing reveal (§10.2) on Tonight.** Navigate to `/`. 200 ms after navigation, the cover-story headline's 10th grapheme is still unrevealed (computed `color` alpha 0; §10.2.1 lays the full string out from frame 0 with the tail `transparent`) even though route focus has moved to the page `h1` (§14.4): focus must not skip it. The caret is present. After `n × 50 ms + 3,180 ms + 160 ms` (`n` = the headline's grapheme count, spaces included; the caret blinks for 3,180 ms and then fades over 160 ms, §10.2.1) plus 200 ms of slack, every grapheme is revealed and the caret is gone. Clicking the headline or pressing `Enter` or `Space` while it is focused completes it at once and the count does not advance again afterwards (§10.2.3 "skip must stop the clock").
2. **Once per day per profile.** Reload in the same context: the headline shows at rest immediately.
3. **Letter set (§10.1) on an H3 below the fold.** On `/`, an H3 `SetHeading` below the fold keeps its letters at opacity 0 until it is 50 % in view; scroll it in; within 1,420 ms (the 120 ms rule lead, at most 560 ms of stagger and the 640 ms letter move, plus 100 ms of slack) every letter is at opacity 1, translate 0 and blur 0. A second visit in the same session shows it at rest (the seen set). A masthead (`trigger: "mount"`) plays once per session; a `signal` title (a feature page title) plays on every visit.
4. **Reduced motion:** with `reducedMotion: "reduce"` both render their full text immediately; the Letter set is a single 200 ms fade and the typed headline has no caret.
5. **Long words (§10.1.1):** "Transmigration" in `type.cover` at 200 % text in a 358 px column falls back to the plain string with the 200 ms fade and does not overflow.

### H. Performance guards (§15.6)

Check each and record the evidence in `qa.md`:

1. Grain and Drift run only on the one visible hero or spread art and pause off screen (scroll the hero away; `getAnimations()` on it is empty or paused).
2. At most one animated blur layer per screen outside letter reveals and Rack focus; Rack focus runs on at most 12 images at once (load a Discover results page and a desktop Library wall and count running blur animations).
3. Duotone filters are cached per colour (one `<filter>` per distinct duo in the DOM); spreads request covers at `w=720` (network log) and never upscale sharp art.
4. The reader runs no grain, blur, drift or `backdrop-filter` over pages (computed styles of every element over the strip).
5. Page-tint sampling runs at most every 600 ms off the main thread (count `postMessage` calls to `page-tint.worker.ts` during a 10 s scroll: ≤ 17); panel detection shares the worker at 360 px, one page ahead.
6. The trailer scrub animates `transform` and `opacity` only (read the animated properties in a Performance trace; no layout per frame).
7. Edition preview iframes mount only on Settings → Appearance and onboarding step 1, and unmount on leave.
8. The Lightbox decodes the full cover only on open; Cut to home flies at most 12 posters.
9. The sources request limiter: its vitest is green; on the dev stack, a burst of navigation never sends more than 50 request starts to `/sources/*`, covers and page images in any 60 s window (count from the network log over a 3-minute browse session); P3 prefetch pauses under 20 free slots; a forced 429 (`page.route` returning 429 with `Retry-After: 5`) pauses P2 and P3 for 5 s.
10. Rails virtualise beyond 30 items; walls use `@tanstack/react-virtual`.

### I. Fix everything, then `qa.md`

Every failure found in A to H is fixed in the Cinematic skin (or in the shared data layer when that is where the fault is), one commit per fix, with the check re-run after the fix. Then write `docs/redesign/proof/web-24/qa.md`:

- a table with one row per check (section and item, command or method, result, the commit SHA of the fix when there was one);
- the audit summary per screen (0 violations is the target; any accepted exception is listed with its reason and the contract section that allows it);
- the motion log summary (moves checked, moves passing, raster-only moves under "Owner check on real hardware" with reproduction steps);
- the screenshot, Front pages and `og.png` inventory;
- open issues, each with the contract section it concerns.

## Out of scope here (do not build)

- The flip itself (`release/00`): the default skin, deleting `legacy`, the version bump and the ship.
- Any Glass work; any new feature; any change in `mobile/` or `backend/`.
- Device passes on the owner's iPhone and Android flagship (that is `mobile/24`'s checklist).

## File layout

```
frontend/src/skins/cinematic/index.ts                 PENDING map removed (A1)
frontend/src/skins/**/completeness*.test.ts           strict for cinematic (A2; keep the file web/00 made)
frontend/e2e/support/cinematic-routes.ts              B
frontend/e2e/support/audit.ts                         B
frontend/e2e/cinematic-qa.spec.ts                     B, C
frontend/e2e/cinematic-focus.spec.ts                  B, C3
frontend/e2e/cinematic-motion.spec.ts                 D
frontend/e2e/cinematic-signature.spec.ts              G (or the web/04 file, extended)
frontend/scripts/proof.mjs                            new flags only if missing (--jpeg, --dpr, --grid)
frontend/scripts/front-pages.mjs                      F
frontend/public/og.png                                F3
frontend/src/skins/cinematic/**                       fixes (I)
frontend/src/skins/cinematic/tint.test.ts             new over-art rows (C1)
docs/redesign/proof/web-24/                           plan.md, qa.md, audit/, screens/, states/, forced-colors/,
                                                      more-contrast/, hyperlegible/, front-pages/, motion-log.json
```

Skin files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**` and their own `skins/cinematic/**`.

## Acceptance criteria

- [ ] `frontend/src/skins/cinematic/index.ts` has no `PENDING` map, and the completeness vitest asserts every `ScreenId` has a real Cinematic screen (a test that fails if the pending screen is referenced).
- [ ] `cinematic-routes.ts` resolves a URL for every `ScreenId` in `SCREEN_IDS`; `setup` redirects to `/login`.
- [ ] The audit reports 0 violations on every screen at 1440 × 900 and 390 × 844, or each remaining one is listed in `qa.md` with the contract section that allows it.
- [ ] No horizontal page scroll at 200 % zoom on any screen (tables scroll inside their own container).
- [ ] Keyboard: the Skip link is the first stop on desktop, every focused element shows the double ring with its black halo, nothing focused is covered, rails are one tab stop, route changes focus the `h1`, overlays trap and return focus.
- [ ] Every coarse-pointer target is ≥ 44 × 44 px with ≥ 8 px spacing; every fine-pointer target ≥ 32 × 32 px with ≥ 24 px spacing.
- [ ] The `tint` tests pass with the over-art table complete for every text or icon run over art found in the screenshots.
- [ ] Forced colours, more contrast and Hyperlegible text screenshots exist for every screen and show the §14.4 and §14.7 remaps.
- [ ] Reduced motion (OS query, and the in-app switch alone) matches every row of §4.8: only the leader dial, the indeterminate rule and the button loading segment keep running.
- [ ] The motion-timings log covers every named move of §4.5; no move shows a dropped frame or an overrun of more than one frame, except raster-only moves listed for the owner's hardware check with evidence from a trace; `SKIN RESTART` is under 1,500 ms.
- [ ] Screenshots of every `ScreenId` at 1440 × 900, 390 × 844 and 440 × 956 @3, each with and without the grid overlay, are in `docs/redesign/proof/web-24/screens/`, plus the state captures in `states/`.
- [ ] The five phone "Front pages" frames are 1320 × 2868 PNG and the desktop set 2880 × 1800 PNG, with the §12.6 band, caption, folio, Oxford rule and bleed; `frontend/public/og.png` is 1200 × 630 with the real Tonight capture and no 18+ content.
- [ ] `cinematic-signature.spec.ts` passes: the Tonight headline is still typing 200 ms after navigation despite route focus, skips on click, `Enter` and `Space` and stays skipped, types once per day per profile; an H3 below the fold waits for 50 % visibility; reduced motion shows both at once; "Transmigration" falls back at 200 %.
- [ ] Every §15.6 guard has evidence in `qa.md`, including the limiter never exceeding 50 starts per 60 s.
- [ ] The 18+ on-device checklist passes on the web and the dev seed is restored afterwards.
- [ ] Every destructive confirm resists a double click (the 1000 ms arm), each listed.
- [ ] Legacy users see no change (the flip is `release/00`): with `mm-skin-debug=legacy`, `/library` and a reader still render as before.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (file and case counts at or above the floor) and `npm run build` (0 errors, 0 warnings) are green in `frontend/`; `node design/build.mjs --check` passes.
- [ ] `docs/redesign/proof/web-24/qa.md` exists with every section of item I.

## Verification

**RAM guard (production shares this box).** Before every heavy command (a build, the vitest suite, the dev stack, `next dev`, a Playwright run) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two builds at once. Never run `next build` while `next dev` or a Playwright browser is running: stop them first. Run the Playwright specs one file at a time with `--workers=1`.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
cd .. && node design/build.mjs --check && cd frontend
```

For the Playwright work, start the dev stack of `backend/scripts/README-dev-stack.md`, then in `frontend/`:

```bash
free -m && npm run dev -- -p 3010
# in a second shell, one spec at a time:
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=demo E2E_PASSWORD='<from README-dev-stack.md>' npx playwright test e2e/cinematic-qa.spec.ts --workers=1
# then cinematic-focus, cinematic-motion, cinematic-signature the same way
free -m && node scripts/front-pages.mjs --base http://127.0.0.1:3010
```

If you use `playwright-cli` for ad-hoc inspection, always pass a named session (`-s=web-24`): the default session is shared with other Claude sessions on this box.

`00-baseline.md` records lint and build at 0 errors and 0 warnings; they must stay there. This step changes nothing in `mobile/` or `backend/`: confirm `git diff --stat origin/feat/vps-slim-source-native -- mobile backend` is empty, so `flutter analyze`, `flutter test` (Flutter at `/srv/manhwamaniacs/dev/flutter/bin`) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header`) are not rerun.

**Visual proof.** Everything in sections E and F lands under `docs/redesign/proof/web-24/`, captured headless at the exact sizes above. Stop `next dev` and the dev stack when the captures are done.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the strict completeness change, the harness, then one commit per fix (`fix(web-cinematic): ink.45 on paper.2 in the filters sheet`), then the Front pages and `og.png`, then the proof and `qa.md`. Stage your paths explicitly (`git add frontend/e2e/cinematic-qa.spec.ts …`, `git add docs/redesign/proof/web-24`), never `git add -A` or `git add .`, because the mobile, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets (the demo password stays in `README-dev-stack.md`, never in a spec; read it from the environment) or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: the flip is `release/00`.

## Report back

Reply with:

1. Done items by section (A to I), and anything not done with the reason.
2. Any `ScreenId` that was still pending at the start and which step's scope you executed for it.
3. Paths: `docs/redesign/proof/web-24/qa.md`, the screenshot folders, the Front pages file names (for `release/00`) and `frontend/public/og.png`.
4. Test counts: vitest files and cases before and after; each Playwright spec's pass count; lint and build results; the `free -m` available figure before each build.
5. Audit totals (violations found, fixed, accepted with reason); the number of fix commits.
6. The motion-log summary and the list of moves for the owner's hardware check, with steps.
7. Open issues, each with its contract section.

Next prompt file: `docs/redesign/prompts/release/00-cinematic-flip-release.md` (it also waits for `docs/redesign/prompts/mobile/24-cinematic-qa-polish.md`). After the flip, the web track continues with `docs/redesign/prompts/web/25-glass-foundation-material-physics.md`.
