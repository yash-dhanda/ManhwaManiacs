# Web 20: Cinematic onboarding, "the first issue"

## Goal

Build the Cinematic skin's onboarding takeover on the web client (`frontend/`) exactly as `docs/redesign/cinematic/DESIGN.md` §8.7 specifies: a new profile, right after the Iris out of the profile picker, lands on `/welcome?step=n` and sets its taste in four steps (Formats, Genres, Art style, Seeds; the Edition step 1 is skipped while `flags.glass_available` is `false`, so the route runs `step=2..5` and the folio reads `1 / 4` … `4 / 4`), every `Next` saves the answers so far with `PUT /profiles/{id}/taste {step, …}`, a killed tab resumes at the saved `onboarding_step`, and `Print my first issue` follows the picks, saves the taste and plays **Cut to home**: the picked posters (at most 12) fly from the wall into Tonight's first section `01 Your first picks` while the rest of the wall fades to black, and the front page then types its first headline. Deliver every state (loading, catalog unreachable, AI unavailable, offline, follow failures, `/home` failure, reduced motion), desktop web (768 px and up), tablet widths and mobile web (below 768 px, with an Embla pager between steps), keyboard access, and the one shared data layer both skins use (`frontend/src/features/onboarding/`). When you finish, the `onboarding` ScreenId leaves the Cinematic `PENDING` set. The mobile session runs `docs/redesign/prompts/mobile/20-cinematic-onboarding.md` in parallel on Flutter; do not touch `mobile/`.

## Read first

DESIGN.md is binding; where this prompt and DESIGN.md disagree, DESIGN.md wins and you note the conflict in your report.

- `docs/redesign/cinematic/DESIGN.md`:
  - **§8.7 Onboarding, entire** (the step table, the 18+ rule, Resume, Finish "Cut to home", Platform deltas, States, Backend).
  - §8.0.1 (the Takeover frame), §8.0.3 (the `onboarding` row and the root navigator), §8.0.4 (takeovers enter and leave by Dip), §8.0.5 ("Back inside modal states" item 4), §8.0.6 (the `g` sequence never reaches page keys), §8.0.7 (`glass_available`: Onboarding row), §8.0.9 (the Onboarding tablet row).
  - §8.5 (the Iris hand-off, step 3: "Tonight, or onboarding for a brand-new profile"), §8.8 ("New profile, nothing read" and "Just onboarded" states; section `first_picks`), §9.1.2 (case 4b), §9.1.7 (`GET /ai/similar?anilist_id=`, `PUT /profiles/{id}/taste`), §9.1.8 (AI state vocabulary and the unavailable copy).
  - §2.1.1–§2.1.4 (paper, ink, spot, `spot.wash`, `proof`, the raised-stock rule, `scrim.foot`), §2.1.5 (duotone matrix, the ambient fallbacks), §2.2 (grid), §2.6 (rules).
  - §3.2 and the "Literal sizes" paragraph of §3.3.
  - §4 entire: durations §4.2, curves §4.3, the motion table §4.5 (rows Set, Page, Dip, Iris, Cut to home, Highlight sweep, Rack focus, Develop, Flicker, Type), stagger §4.6, interruptibility §4.7, reduced motion §4.8 (rows Cut to home, Highlight sweep, Typing reveal, Page and Dip, Flicker).
  - §5 and §6 (events `select`, `tap.primary`; cues `tick`, `set`).
  - §7 intro (hit areas, focus, cursors, semantics), §7.1, §7.2, §7.5 (chip underline, tri-state note), §7.6 (World card), §7.7 (Wall caption mode, badges), §7.17, §7.18, §7.22, §7.23, §7.29 (spoken folios).
  - §10.2 (TypedHeadline: onboarding step headlines are `h1`, "Printing issue No. 1…" is `p`), §11 (rows "Long-press 450 ms / Onboarding genre words" and "Horizontal swipe / onboarding steps"), §13 moments 11 and 18, §14 entire, §15.2 (`FlyToSlots` in `motion.ts`), §15.5 (rows "`PUT /profiles/{id}/taste` accepts `step`" and "`GET /onboarding/catalog`"), §15.6 ("Cut to home flies at most 12 posters").
- `docs/redesign/glass/DESIGN.md` §15.5 row `PUT /profiles/{id}/taste` and §15.6 row **Taste** (the server accepts `step` 1 to 7; a skin resuming a step beyond its own count resumes at its last step; the server's `styles` enum is the union of both skins' ids).
- `docs/redesign/inventory/00-decisions.md` (owner decisions; AI is external-API only).
- `docs/redesign/stack-decision.md` §2.2 (web folder layout, the import boundary), §2.6 (one data layer).
- `docs/redesign/inventory/capabilities.md` §5 (profiles), §9 (recommendations and AI).
- `docs/redesign/00-baseline.md` (health baseline and RAM figures).
- `docs/redesign/prompts-plan.json`, the entry for this file.

## Before you start

1. Work in `/srv/manhwamaniacs/dev/ManhwaManiacs` on branch `feat/vps-slim-source-native` (`git branch --show-current` must print it; otherwise stop and report). Run `git status --porcelain` and note files other sessions have modified; never stage them.
2. This step depends on `docs/redesign/prompts/web/19-cinematic-ai-picks-similar-recap.md` and `docs/redesign/prompts/backend/05-ai-similar-recap-taste-onboarding.md`. Check they landed; if any check fails, stop and report which dependency is missing:
   - `grep -rn "onboarding/catalog" backend/routes` finds `GET /onboarding/catalog`; `grep -rn "/taste" backend/routes/profiles.py` finds `PUT /profiles/{id}/taste`; `grep -rn "anilist_id" backend/routes/*.py | grep -i similar` finds the `anilist_id` form of `GET /ai/similar`.
   - `grep -n "onboarding" frontend/src/skins/cinematic/index.ts` shows `onboarding` still in the `PENDING` set; `ls "frontend/src/app/(app)/welcome/page.tsx"` exists (the thin route from web/00).
   - `grep -rn "similar" frontend/src/features/ai` finds the `GET /ai/similar` client web/19 added (reuse it; add the `anilist_id` form to that same file if it only takes `source` and `series`).
3. Inventory what earlier steps built and reuse it; never re-implement a primitive inside a screen. `ls frontend/src/skins/cinematic frontend/src/skins/cinematic/primitives frontend/src/skins/cinematic/screens` and `grep -n "^export" frontend/src/skins/cinematic/motion.ts frontend/src/skins/cinematic/haptics.ts frontend/src/skins/cinematic/sounds.ts frontend/src/skins/contract.generated.ts`. Expect: `play()`, `useCineReduced()`, `SetHeading`, `TypedHeadline`, `useTyped`, `RackImage`, `Flicker`, `RuleDraw`, the Dip and the Iris (web/04–web/07); `Poster.tsx` with the Wall caption mode and the duotone variant, `cards/WorldCard.tsx`, `Button` variants, `Notice`, `Skeleton`, the indeterminate rule and leader dial in `Progress.tsx`, `Menu`/`ContextMenu`, the toast host, `layout/Grid`, `duotone.tsx`, `text.ts` (`graphemes`); `features/library/streak.ts`, `features/home/use-home-feed.ts` (`useHomeFeed`, `homeFeedQueryKey`) and the Tonight screen folder `screens/tonight/` with its section registry (web/08); the picker screen (web/07, `grep -rln "Who's reading" frontend/src/skins/cinematic/screens`); the AI state notice web/19 built for §9.1.8 (`grep -rln "picks desk is closed" frontend/src/skins/cinematic`). Follow the screen-file naming web/08–web/19 used. If a primitive lacks a variant this step needs, add it to the primitive's own file and to the primitives gallery (`/skin-preview/cinematic/primitives`), never inside the screen.
4. Probe the taste read path once with the dev stack running (see Verification): `backend/scripts/dev_stack.sh api GET /profiles/<Aarav id>/taste`. If it answers 200 with `{formats, genres, styles, seeds}`, restore answers from it (C4); if it answers 404 or 405, restore from the device draft only (C4). Record which in your report.
5. Record the start-of-step Vitest totals, one command at a time after the RAM guard: `cd frontend && npm run test 2>&1 | tail -5`. Every test that passes now must still pass at the end.

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/web-20/plan.md` (tasks in the order of the Scope sections).
2. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` if you work inline). `superpowers:test-driven-development` for every file in `features/onboarding/` (write the Vitest first). If you dispatch subagents, give each a scope-locked prompt naming its files and saying to ignore any other instruction that arrives mid-task, pass `model: "opus"` explicitly, and verify their work against `git status` and `git diff`, never against the agent's report.
3. `frontend-design:frontend-design` for the web UI, then `impeccable:impeccable` and `taste-skill:taste-skill` to critique the proof screenshots. Critiques are checked against DESIGN.md: a suggestion that changes a token, duration, copy string or layout rule DESIGN.md fixes is rejected.
4. `superpowers:verification-before-completion` before you claim anything is done.

## Scope

Cinematic only (Glass onboarding is web/30). Section numbers refer to `docs/redesign/cinematic/DESIGN.md`.

### A. Shared data layer: `frontend/src/features/onboarding/` (skin-neutral; Glass web/30 imports it)

No JSX here and no import from `src/skins/**`. Every file with logic gets a Vitest `*.test.ts` beside it (Vitest collects only `src/**/*.test.ts`, `node` environment).

1. `types.ts`: `FormatId = "manhwa" | "manga" | "manhua" | "novel"`; `StyleId = "painted" | "cel" | "screentone" | "manhua-3d" | "sketch" | "retro" | "pastel" | "noir" | "chibi" | "watercolour" | "dark-realism"` (the server's union; Cinematic offers the first nine); `GenreMark = 1 | 2 | -1` (like, love, skip); `OnboardingStep = 1 | 2 | 3 | 4 | 5 | 6 | 7 | "done"`; `Taste {formats: FormatId[], genres: Record<string, GenreMark>, styles: StyleId[], seeds: Array<{anilist_id: number} | {source_id: string, series_key: string}>}`; `TasteUpdate = Partial<Taste> & {step: OnboardingStep}`; `OnboardingCatalog {formats: [{format: FormatId, covers: string[]}], genres: [{name: string, weight: number}], seeds: WorldItem[]}` (`WorldItem` from `@/features/library/types`).
2. `api.ts` through the existing HTTP client (`services/http.ts`, which adds `X-Profile-Id`): `onboardingApi.catalog({formats, genres, styles})` → `GET /onboarding/catalog` with comma-joined query values, omitted when empty; `onboardingApi.saveTaste(profileId, body: TasteUpdate)` → `PUT /profiles/{id}/taste`; `onboardingApi.getTaste(profileId)` → `GET /profiles/{id}/taste`, called only when the Before-you-start probe answered 200 (a constant `TASTE_READABLE` in this file records the probe result).
3. `hooks.ts`: `useOnboardingCatalog(params, {enabled})` on React Query 5 (key `["onboarding", "catalog", profileId, matureEnabled, formats, genres, styles]`, `staleTime` 24 h, `retry: 1`, `refetchOnWindowFocus: false`; the profile's gate is part of the key so a gate change refetches); `useSaveTaste()` (mutation, no optimistic cache); `useSimilarSeeds(anilistId)` calling the web/19 AI client with `anilist_id` (key `["ai", "similar", "anilist", anilistId]`, `staleTime` 7 days).
4. `steps.ts`: `ONBOARDING_STEPS` = `[1, 2, 3, 4, 5]` with ids `edition | formats | genres | styles | seeds`; `shownSteps(glassAvailable)` → `[2, 3, 4, 5]` while `FLAGS.glassAvailable` is false, else `[1, 2, 3, 4, 5]`; `folioFor(step, glassAvailable)` → `{index, total}` (step 2 → `1 / 4` while false); `resumeStep(onboarding_step, glassAvailable)` → `"done"` stays `"done"`; `null` → the first shown step; `1` while the flag is false → `2`; `6` or `7` (a Glass profile) → `5`; `nextStep`, `prevStep` (the first shown step's previous is `null`: back leaves to the picker). Test: every mapping above.
5. `genres.ts`: `genreParagraph(catalog.genres)` → the names sorted by `weight` descending, then name A–Z, capped at 40 (all of them when fewer than 30); `tapGenre(mark)` cycles `undefined → 1 → 2 → undefined` and `-1 → undefined`; `holdGenre()` → `-1`; `menuGenre(action)` for `like | love | skip | clear`; `genreLabel(name, mark)` → "Romance, liked" / "Romance, loved" / "Romance, skipped" / "Romance, not chosen"; `likedGenres(map)` → the names with 1 or 2, loved first (the catalog's `genres=` parameter). Test: the cycle, the cap at 29, 30, 40 and 45 names, the labels, the ordering.
6. `styles.ts`: `ART_STYLES`, the nine Cinematic crops in this order with their file names under `frontend/public/onboarding/styles/`, their typographic plate names and their descriptions (the description is also the crop's `aria-label` once art exists):

   | # | `StyleId` | File | Plate name | Description |
   |---|---|---|---|---|
   | 1 | `painted` | `01-painted.webp` | Painted | Full-colour painted webtoon art. |
   | 2 | `cel` | `02-cel.webp` | Cel | Crisp cel shading and clean lines. |
   | 3 | `screentone` | `03-screentone.webp` | Screentone | Black-and-white ink with tone dots. |
   | 4 | `manhua-3d` | `04-manhua-3d.webp` | Manhua 3D | Rendered, three-dimensional colour. |
   | 5 | `sketch` | `05-sketch.webp` | Sketch | Loose, sketchy indie linework. |
   | 6 | `retro` | `06-retro.webp` | Retro | The look of 1990s manga. |
   | 7 | `pastel` | `07-pastel.webp` | Pastel | Soft, light pastel colour. |
   | 8 | `noir` | `08-noir.webp` | Noir | High-contrast black and shadow. |
   | 9 | `chibi` | `09-chibi.webp` | Chibi | Small, round, comic proportions. |

   `STYLE_ART_BUNDLED = false`: the nine commissioned CC0 crops (600 × 600 WebP, quality 80, ≤ 60 KB each, §8.7) do not exist yet, so the step ships the typographic plates. `styles.test.ts` asserts that when the constant is `true`, all nine files exist in `frontend/public/onboarding/styles/` and each is ≤ 61,440 bytes (the commit that adds the art flips the constant).
7. `draft.ts`: the device draft in scoped `localStorage` (`lib/scoped-storage.ts`, so each profile has its own) under `mm.onboarding.draft` = `{taste: Taste, touched: Array<keyof Taste>, picks: number[] /* anilist ids in pick order */}`; `readDraft()`, `writeDraft()`, `clearDraft()`; `tasteBody(draft, step)` → a `TasteUpdate` holding `step` plus only the touched fields (answers never re-sent from an untouched default, so a resume on another device never overwrites the server's answers with empty ones); `mm.onboarding.pending` holds a `TasteUpdate` with `step: "done"` that failed to save (C6), with `readPending()` and `clearPending()`. Test: touched-only bodies, isolation between two scopes, pending round trip.
8. `print.ts`: `runFollows(picks, follow, concurrency = 4)` → `{followed: Pick[], failed: Pick[]}` in pick order, calling `libraryApi.follow({sourceId, seriesKey})` for each pick with `available.length > 0` (its first `available[]` entry); information-only picks are not followed and count as neither; `followedToast(ok, total)` → `null` when all succeeded, else "Followed {ok} of {total}. {Count} couldn't be added." where Count is "One" … "Nine" spelled with a capital for 1–9 and a numeral from 10 ("Followed 4 of 5. One couldn't be added.", "Followed 3 of 5. Two couldn't be added."); `flightList(followed)` → the first 12 followed picks in pick order (§15.6). Test: concurrency never exceeds 4, order kept, the toast copy for 0, 1, 2, 9, 10 and 12 failures, the 12 cap.

### B. The frame and the chrome: `frontend/src/skins/cinematic/screens/onboarding/`

Wire `screens.onboarding` in `frontend/src/skins/cinematic/index.ts` to `OnboardingScreen` and remove `onboarding` from `PENDING`. `document.title` is "Your first issue · ManhwaManiacs". The Shell renders this route in the **Takeover** frame (§8.0.1: full screen on `#000000`, no sidebar, no running head, no thumb index, no first-run note, no stop-press banner); if web/06's frame map does not list `onboarding` as a Takeover yet, add it there.

1. **Top bar** (`OnboardingTopBar.tsx`), 56 px desktop, 44 px phone (+ `env(safe-area-inset-top)`), `#000000`, no rule:
   - Left (phones only): back, a `bare` icon button `arrow-left` 24 Light, tooltip and `aria-label` "Back", 44 px hit. Desktop has `Back` in the footer instead.
   - Centre (desktop: left-aligned in the grid margin): the folio `1 / 4` in `type.folio` `ink.60`, then 12 px, then four rules 24 × 2 px, 4 px apart: done steps filled `spot` `#F4D03F`, the current step `ink.100` `#F3F0E8`, later steps `rule.2` `#3D3C38`. When a step completes, its rule fills `spot` from the left over 240 ms `ease.settle` (the chip underline draw). The group is one `role="img"` with `aria-label` "Step 1 of 4" (§7.29 spoken folios).
   - Right: `Skip`, a `quiet` button (`type.label` `ink.60`, 1 px underline at 4 px offset on hover), 44 px hit.
2. **Step body layout** on the grid (§2.2; the `Grid` primitive): desktop 12 columns (margin 48 at 1024–1439, 72 at 1440–1919, 96 at ≥ 1920; gutter 24, 32 from 1920), tablet 8 columns, phone 4 columns (margin 16, gutter 12). Vertical: top bar, 48 px (phone 24), kicker in `type.kicker` `ink.45` (`#7A7770`, 4.7:1 on black), 12 px, the step headline as `TypedHeadline` with `as="h1"` in `type.masthead` (Bodoni Moda Roman opsz 96 wght 800; 40/40 phone, 56/56 tablet, 72/68 desktop, 88/84 wide; fluid `clamp(2.5rem, 1.582rem + 3.92vw, 5.5rem)`; tracking −0.035em; sentence case; `text-wrap: balance`) across columns 1–8 (tablet 1–8, phone 1–4), 40 px (phone 24), the step content, then the footer.
3. **Footer**: desktop, a row at the bottom of the content: `Back` (`quiet`) at the left (on the first shown step it returns to the picker), `Next` (`primary` md, 44 px, `type.label`) at the right; on step 5 the primary reads `Print my first issue`. Phones: a sticky bottom bar (`#000000`, 16 px padding, `padding-bottom: calc(16px + env(safe-area-inset-bottom))`) with the primary full width at 48 px.
4. **Step headlines** (typed at one grapheme per 50 ms, `spot` caret 0.12em × 0.86em, blink off/on in 530 ms halves for 3180 ms then a 160 ms fade; tap, click, `Enter` or `Space` on it completes it; each type once per step entry):

   | Step | Kicker | Headline |
   |---|---|---|
   | 2 Formats | `FORMATS` | "What do you read?" |
   | 3 Genres | `GENRES` | "Tap once to like, twice to love, hold to skip." |
   | 4 Art style | `ART STYLE` | "Which of these do you like the look of?" |
   | 5 Seeds | `YOUR FIRST ISSUE` | "Choose three or more to start." |

   Step 1 (`YOUR EDITION` / "Pick how the app looks.") is not rendered while `FLAGS.glassAvailable` is false: `/welcome?step=1` replaces itself with `?step=2`. It ships with the Glass flip (list it as open in your report).
5. **Step change.** Desktop and tablet: `Next` plays **Page** forward (incoming x +24 px → 0 and opacity 0 → 1 over 320 ms `ease.settle`; outgoing x 0 → −24 px, fade out over 224 ms `ease.lift`), `Back` plays it reversed. Phones: an Embla pager (`embla-carousel-react` 8.6.0, `{ align: "start", containScroll: "trimSnaps", duration: 25 }`; Embla's own settle stands in for the §8.0.5 320 ms `ease.settle`, do not hand-roll a pager) whose slides are only the steps up to the current one, so a forward swipe has nothing to reach and a step is committed only by `Next`; a backward swipe past the snap threshold goes back one step. Reduced motion: every step change is a 150 ms (`dur.reduced`) opacity cross-fade and Embla scrolls with `duration: 0` equivalents (`scrollTo(index, true)`).
6. **History and URL.** The URL is the source of truth. `Next` does `router.push("/welcome?step=" + next, { scroll: false })`; `Back`, the phone back arrow and a backward swipe call `router.back()`; browser and Android back therefore step back one step, and back from the first shown step leaves to the picker. When onboarding opens at a resumed step n above the first shown step, rebuild the history first: `router.replace("/welcome?step=2")`, then `router.push` for each step up to n, so back walks the steps. A `?step=` above the resumed step (a hand-typed URL) replaces itself with the resumed step.
7. **Focus and announcements.** On every step entry focus moves to the step's `h1` (`tabIndex={-1}` once typed, `0` while typing, §10.2.3), and a polite live region says "Step 2 of 4: Genres". Keyboard (desktop and hardware keyboards), registered through `useShortcut` from `@/lib/keyboard` in the group "Onboarding" (single-key bindings respect the "Single-key shortcuts" setting, never fire while typing in a field): `→` = `Next` (only when `Next` is enabled), `←` = `Back`, but only while focus is not inside a roving group (the genre paragraph, the style grid or the seed wall), where the arrows move focus instead. Every binding appears in the `?` sheet.

### C. The four steps

1. **Formats** (`FormatsStep.tsx`, step 2). Tiles `Manhwa`, `Manga`, `Manhua`, and `Novels` only when `useNovelsEnabled()` is true. Each tile is a 2:3 plate with square corners: a duotone mosaic of the format's three `covers` from the catalog, drawn as three vertical strips each a third of the plate wide and full height (`object-fit: cover`, `referrerPolicy="no-referrer"` because they are AniList CDN URLs), duotoned through `duotone.tsx` to the ambient fallback duo `#B8B2A4` (black → duo, the §2.1.5 matrix, `color-interpolation-filters="sRGB"`), grain at 0.06; `scrim.foot` ending in the ambient fallback tint `#0E0D0B` (the 13 eased stops of §2.1.4, reaching alpha 1 24 px above the word's line box); the word in Bodoni Moda Italic 32 (opsz 32, wght 600, line 36, tracking −0.015em) `ink.100`, 16 px from the left and bottom, sitting on the solid end colour. Layout: desktop four tiles across 3 columns each (three across 4 when Novels is absent), tablet 2 × 2 across 4 columns each, phone 2 × 2 across 2 columns each. Multi-select: a selected tile shows a 2 px `spot` inset frame (`box-shadow: inset 0 0 0 2px var(--mm-color-spot)`); each tile is a `button` with `aria-pressed` and the accessible name "Manhwa" (§7 semantics: multi-select toggles). Hover (fine pointer): the mosaic zooms 1.04 inside the fixed frame, 200 ms `dur.clip` `ease.settle`; pressed: 1 px impression (80 ms `ease.set` down, 160 ms `ease.settle` up); focus: the double ring (2 px `ink.100` at 2 px offset plus the 6 px `#000` halo) around the tile. Haptic `select` and sound `tick` (if on) per toggle. Rack focus on each cover's first decode (blur 14 px, brightness 0.6, scale 1.03 → sharp over 520 ms `ease.settle`), at most 12 racking at once, the rest Develop. `Next` is always enabled (answers are optional); it saves `formats` when touched.
2. **Genres** (`GenresStep.tsx`, step 3): **the genre paragraph** (§13 moment 11). The names from `genreParagraph()` set as one justified paragraph (`text-align: justify; text-align-last: left; hyphens: none`) in Bodoni Moda Italic (opsz 28, wght 500) at 28 px desktop, 26 px tablet, 22 px phone (the Bodoni literal cap of 1.30 applies at large browser text sizes, §3.3), line height 40 px on a fine pointer and 44 px on a coarse pointer, across columns 1–10 desktop (1–8 tablet, 1–4 phone), max 72ch. Each name is an inline `button` with `white-space: nowrap` (multi-word genres never break), separated by an ordinary space with `word-spacing: -0.05em` so the resting gap reads as a thin space and justification can still stretch it; on a coarse pointer each button is `inline-block` with `min-width: 44px` and `text-align: center`. States:
   - neutral: `ink.60` `#9A978F`;
   - like (one tap): `ink.100` and a 2 px `spot` underline 4 px below the baseline, drawn left → right over 240 ms `ease.settle`;
   - love (second tap): `ink.100`, the underline stays, and a `spot.wash` band `rgba(244,208,63,0.16)` sweeps left → right behind the word (Highlight sweep, 200 ms `dur.clip` `ease.set`); inside the band the word stays `ink.100`;
   - skip (hold 450 ms, or the menu): `ink.45` `#7A7770` with a 1 px `proof` `#FF5B4A` strike-through (`text-decoration: line-through 1px`);
   - a third tap on a loved word clears it; a tap on a skipped word clears it.
   Hold: `pointerdown` starts a 450 ms timer, cancelled by more than 8 px of movement or an early `pointerup`; when it fires the word is skipped (haptic `select`) and the following click is swallowed. Words set `-webkit-touch-callout: none; user-select: none` and the phone frame calls `preventDefault()` on `contextmenu` for them (§8.0.5). The menu (Base UI `ContextMenu` on right-click; `Menu` on `Shift+F10` or the context-menu key on the focused word): `Like`, `Love`, `Skip`, `Clear`, the current state checked (§7.22 surface: `paper.2`, 1 px `rule.2`, items 40 px desktop / 48 px phone). Semantics: the paragraph is `role="group"` with `aria-label` "Genres" and roving focus (one tab stop; `←`/`↑` previous word, `→`/`↓` next word, `Home`/`End`); each word's accessible name is `genreLabel()`; `Enter`/`Space` taps; a polite live region announces "Romance: loved" on change. Haptic `select` and sound `tick` per change. Mature genres are simply absent unless the gate is open (the server filters them; nothing says they are hidden).
3. **Art style** (`ArtStyleStep.tsx`, step 4): a 3 × 3 grid of square plates, 12 px gaps: desktop across columns 4–9, tablet 2–7, phone 1–4. While `STYLE_ART_BUNDLED` is false each plate is `paper.1` `#0B0B0A` with a 1 px `rule.2` inner frame, the plate name in Bodoni Moda Italic 24 (opsz 24, wght 600, line 28) `ink.100` and, under it, the description in `type.caption` rendered `ink.60` (the plate is a raised ground: its root carries `data-stock="raised"`, §2.1.1), left-aligned with 16 px padding, bottom-anchored. With the art bundled, each plate is the 600 × 600 crop (`object-fit: cover`) with `aria-label` = its description and no visible text. Multi-select with the 2 px `spot` inset frame, `aria-pressed`, hover zoom and pressed impression as the format tiles. Roving focus across the grid (arrow keys by row and column, `Home`/`End`). `Next` is always enabled; it saves `styles` when touched.
4. **Seeds** (`SeedsStep.tsx`, step 5): a poster wall of the catalog's `seeds` (24 World items, available items first), fetched for this step with `formats`, `genres` (`likedGenres()`) and `styles` from the answers. Wall: 2:3 posters (§7.7 Wall caption mode: no caption; the title in the desktop preview slate after a 600 ms dwell and in the `aria-label`), 6 per row desktop (2 columns each), 5 per row tablet, 3 per row phone, 12 px gaps (8 on phones), the first paint running **Set** (fade 0 → 1 and rise 8 px → 0 over 320 ms `ease.settle`, +32 ms per item in a row, +64 ms per row, capped at 480 ms). Available items render in full colour; information-only items (`available` empty) render in duotone to their `ambient.duo` (fallback `#B8B2A4`); with the gate open, the 16 px `18` certificate sits top-left on its `#000000` fill when `is_adult` is true or any `available[]` source is mature.
   - **Pick**: a tap (or `Enter`/`Space` in the roving grid) toggles the pick: the 2 px `spot` inset frame, `aria-pressed`, the accessible name "Solo Leveling, picked". Haptic `select`, sound `tick`.
   - **Similar inserts**: the first time a poster is picked, `useSimilarSeeds(anilist_id)` asks for 3 similar World items; those not already on the wall (by `anilist_id`) are inserted right after the picked poster and run Set (320 ms per item, 32 ms apart). Layout holds for everything before the pick. Unpicking keeps the inserted posters; re-picking never inserts again.
   - **AI unavailable** (the similar answer has `available: false`, or the request fails): no posters are inserted, and once per step entry a `NOTE` line appears under the counter with the §9.1.8 copy for its `reason`, in `type.caption` `ink.60` with the `NOTE` kicker in `spot`: `not_configured` "The editors' desk isn't set up on this server.", `budget_exhausted` "The picks desk is closed tonight. Asks reset at midnight UTC.", `rate_limited` `SLOW DOWN` "Too many asks at once. Try again in {n} s." with a live `Retry-After` countdown folio. Use the web/19 AI notice component for it.
   - **Counter**: a folio under the headline, `type.folio`: `{n} / 3 PICKED` in `ink.60` below three picks, `{n} PICKED` in `set` `#57D68D` from three (the colour change is a 160 ms `dur.beat` cross-fade). `Print my first issue` is disabled below three picks (fill `paper.3`, text `ink.30`, `aria-disabled`, tooltip "Pick three or more first.").
   - Loading: twelve flicker plates (galley proofs, §7.17: `paper.1` with the inner hairline, opacity 0.55 ↔ 1 over a 1400 ms half-period `ease.drift`, 60 ms phase offsets in reading order, shown only after 120 ms of waiting) replaced by posters with a 160 ms dissolve as they arrive (no Set after a skeleton, §4.6).

### D. Save and resume (§8.7 "Resume")

1. Every `Next` sends `tasteBody(draft, next)` with `PUT /profiles/{id}/taste` in the background and moves on without waiting; the draft is written first, so a failed save never loses an answer. A failed save is retried with the next `Next` and at Print.
2. `Skip` (any step) sends `tasteBody(draft, "done")`, clears the draft on success, and leaves by **Dip** (out 160 ms `ease.lift`, hold 40 ms, in 240 ms `ease.settle`) to `/` with `router.replace`, where Tonight shows its "New profile, nothing read" state (web/08). A failed Skip save goes to `mm.onboarding.pending` (D5).
3. **Where onboarding opens.** Change the picker (web/07's screen): after the Iris closes on a profile whose `onboarding_step` is not `"done"` and that has no `mm.onboarding.pending` entry with `step: "done"`, the Iris out opens `/welcome?step={resumeStep(...)}` instead of `/` (the step headline starts typing as the iris opens, §8.5 step 3). A profile whose pending entry says done is treated as done: send the pending `PUT` in the background (clear it on success) and open Tonight. Add `onboarding_step: number | "done" | null` to `Profile` in `features/profiles/types.ts` if web/07 did not.
4. **Restoring answers.** With the taste readable (Before you start, item 4), `getTaste()` fills the answers on entry and the draft fills anything the server lacks; without it, the draft alone restores them (answers chosen on another device stay on the server and are never overwritten, because only touched fields are sent, A7).
5. **Pending done.** When the final `step: "done"` save fails after three attempts 2 s apart, store it in `mm.onboarding.pending` and finish the flow anyway. After Skip this is silent; after Print, show the toast "Your picks are followed. Your taste will save when the server answers." (no action, so the default 3600 ms `dur.hold.toast`).
6. The 18+ gate: every list here comes from `GET /onboarding/catalog`, already gated by the server for this profile (§8.7). Nothing on screen mentions hidden content.

### E. Finish: "Print my first issue" and Cut to home (§8.7 Finish, §4.5 Cut to home, §13 moment 18)

1. On press (haptic `tap.primary`, sound `set` if on): the wall dims to 30 % brightness (`filter: brightness(0.3)`, 240 ms `ease.lift`), a 2 px `spot` indeterminate rule runs across the content width under the headline (the §7.18 indeterminate rule, 1200 ms `dur.loop.rule` linear loop), and "Printing issue No. 1…" types in `type.masthead` `ink.100` (a `TypedHeadline` with `as="p"`) over the dimmed wall, centred in columns 1–8. At the same time: `runFollows()` (4 at a time), the `step: "done"` save with the full taste (`formats`, `genres`, `styles`, and `seeds` as `{anilist_id}` for every pick in pick order), and a prefetch of `GET /home` into the Tonight query key (`queryClient.fetchQuery({ queryKey: homeFeedQueryKey(...), queryFn })` from `features/home`).
2. When the follows have settled and `/home` has answered, the flight starts (skipped entirely under reduced motion, E5):
   1. The unpicked posters and the typed line fade to black: 240 ms `ease.lift`.
   2. Before the route swap, read the source rect (`getBoundingClientRect()`) and the decoded `currentSrc` of each poster in `flightList()` and hand them to the flight store; hide those posters on the wall (`visibility: hidden`) the frame the layer shows its copies.
   3. `router.replace("/", { scroll: false })` (no transition type, so no view transition plays). Tonight mounts underneath at rest with section `01 Your first picks` whose slots for the flying posters are empty (`visibility: hidden`).
   4. After Tonight's first layout with data, it reports the target rects of those slots (`data-fly-slot="{source_id}:{series_key}"` on each poster in the `first_picks` rail) to the flight store. Each copy flies from its wall rect to its slot rect: a FLIP transform (translate and scale from the source rect to the target rect, `transform-origin: 0 0`) of 480 ms `ease.turn` `cubic-bezier(0.65, 0, 0.35, 1)`, staggered 60 ms in pick order (`scalar.stagger.fly`), on the flight layer at `z.shutter`. A slot outside the rail's visible scroll area (its rect right edge beyond the rail's right edge) flies to the rail's right edge (same top, the slot's size) and fades to 0 over its last 160 ms. As each copy lands, its slot becomes visible and the copy is removed. The total is 480 + 60 × (n − 1) ms.
   5. After the last poster lands, Tonight plays its Front page moment for case 4b (web/08): the masthead kicker sets, the cover story racks into focus and its headline types ("Tonight: start Omniscient Reader."), and the deck "Chapter 1 is waiting. The rest of your picks are below." sets.
   Picks beyond 12 appear in the rail with its normal Set. The move is reported to the motion-timings overlay as `play("cutToHome")` with its planned duration.
3. **Flight plumbing.** `frontend/src/skins/cinematic/flight.ts`: a small zustand store (`zustand` is installed) with `status: "idle" | "armed" | "flying" | "landed"`, `items: [{key, src, rect}]`, `arm(items)`, `land(targets: Record<key, DOMRect>)`, `done()`, `reset()`. `frontend/src/skins/cinematic/FlightLayer.tsx`: a fixed, pointer-transparent overlay mounted once by `skins/cinematic/Shell.tsx` outside the frame switch (so it survives the `/welcome` → `/` swap), rendering one `<img>` per item at its source rect and animating it with Motion `animate()` through a `FlyToSlots(items, targets)` helper added to `skins/cinematic/motion.ts` (§15.2). Tonight (web/08's `screens/tonight/`): the `first_picks` rail puts `data-fly-slot` on its posters, hides the keys in `flight.items` while `status` is `armed` or `flying`, calls `land()` from a layout effect once its items render, and holds its Front page moment until `status` is `landed` (render the headline as an invisible placeholder with the same text and classes until then, then mount the `TypedHeadline`). Fail-safe: if `land()` has not been called 3000 ms after `arm()`, the layer fades its copies out over 240 ms `ease.lift`, resets, and Tonight plays normally.
4. **Failures.**
   - Some follows fail: those picks are dropped from the flight, and after the flight the toast `followedToast(ok, total)` shows ("Followed 4 of 5. One couldn't be added.", 6000 ms error hold, `role="alert"`).
   - Every follow fails (and at least one pick was available): no flight; the toast "Couldn't follow any of them. Try again from Discover." and a Dip to Tonight's new-profile state.
   - Only information-only picks: no follows and no flight; the taste is saved and Tonight opens by Dip.
   - `GET /home` fails: no flight; Tonight's error state appears after a Dip (web/08).
5. **Reduced motion** (§4.8 row Cut to home): no dimming animation and no flight; the typed line is shown whole; when the follows and `/home` settle, a 200 ms (`dur.clip`) cross-fade into Tonight, which then shows at rest.
6. Glass chosen in step 1 is out of scope (step 1 does not exist until the Glass flip).

### F. States (§8.7 States; every state in both frames)

| State | Presentation |
|---|---|
| Loading, step 2 | Four 2:3 galley plates flickering, with the format words already set on them |
| Loading, step 3 | A greeked paragraph: six justified lines of `paper.1` bars at the paragraph's line height (the last line 60 % wide), flickering |
| Loading, step 5 | Twelve flicker plates in the wall, replaced by posters with a 160 ms dissolve as they arrive |
| Catalog unreachable (the server answered an error), step 2 | The tiles become typographic plates: `paper.1`, 1 px `rule.2` inner frame, the format word in Bodoni Moda Italic 32 `ink.100` bottom-left; still selectable |
| Catalog unreachable, step 3 | The §7.23 notice in the paragraph's place: 3 px `rule.heavy` drawn on entrance, kicker `CORRECTION` in `proof`, typed headline (`h2`) "The genre list didn't come through.", deck "You can set genres later from Discover." (`type.deck` `ink.60`, max 48ch), primary `Try again`; `Next` stays enabled |
| Catalog unreachable, step 5 | The wall is replaced by the notice: kicker `NOTE`, headline "Follow series later from Discover.", and the footer primary becomes `Finish` (saves `step: "done"` and opens Tonight by Dip) |
| AI unavailable | C4 above: the wall still comes from the catalog; picks insert nothing; the one `NOTE` line |
| Fully offline (`navigator.onLine` is false, or the catalog request fails with a network error while offline) | Steps 2–5 show the notice: kicker `OFFLINE EDITION`, typed headline "Finish when you're back online.", primary `Skip for now` (to Tonight's offline edition by Dip, **without** saving `done`: the saved step is kept, so the next online pick of this profile resumes at the saved step, or at step 2 if none was saved) |
| Follow failures, `/home` failure | E4 |
| 18+ | Mature genres, formats' covers and seeds are absent unless the profile's gate is open; nothing mentions them |

### G. Accessibility and platform rules (§14)

- Hit targets: every interactive element is at least 44 × 44 px on a coarse pointer, with at least 8 px between adjacent targets (the wall's 8 px phone gap meets it); at least 32 × 32 px on a fine pointer.
- The double focus ring on keyboard focus only, never clipped (walls and grids pad 8 px for the halo).
- Headlines are `h1` (one per step); the typed line in E1 is a `p`; the live regions of B7 and A5.
- Reduced motion (§4.8, §14.1): typed headlines and "Printing issue No. 1…" appear whole with no caret; step changes are 150 ms cross-fades; the chip underline and the progress rule fill appear at their end state; the Highlight sweep shows the band at once; skeletons are static at 0.8 opacity; Rack focus becomes a 160 ms opacity fade; Set becomes a single 160 ms fade; Cut to home is the 200 ms cross-fade.
- Every gesture has a non-gesture alternative (§14.8): hold-to-skip has the menu; the pager swipe has `Next` and `Back`.
- Haptics and sounds through `skins/cinematic/haptics.ts` and `sounds.ts`: `select` → sound `tick`, `tap.primary` → sound `set`; none of these vibrate on the web (the web maps only five events, §5).

### H. Out of scope here

Step 1 Edition and the deferred Glass restart (the Glass flip); the nine art-style crops (the owner's art intake; flip `STYLE_ART_BUNDLED` when they land); Glass onboarding (web/30); any change under `mobile/`, `backend/` or `design/`.

## File layout

Create or change only these paths (stage them explicitly):

```
frontend/src/features/onboarding/{types,api,hooks,steps,genres,styles,draft,print}.ts
frontend/src/features/onboarding/{steps,genres,styles,draft,print}.test.ts
frontend/src/features/ai/<web/19's similar client file>          (the anilist_id form, only if missing)
frontend/src/features/profiles/types.ts                           (onboarding_step, only if missing)
frontend/src/skins/cinematic/index.ts                             (onboarding out of PENDING)
frontend/src/skins/cinematic/Shell.tsx                            (mount FlightLayer; Takeover frame for onboarding if missing)
frontend/src/skins/cinematic/motion.ts                            (FlyToSlots)
frontend/src/skins/cinematic/flight.ts
frontend/src/skins/cinematic/FlightLayer.tsx
frontend/src/skins/cinematic/screens/onboarding/OnboardingScreen.tsx
frontend/src/skins/cinematic/screens/onboarding/{OnboardingTopBar,OnboardingFooter,FormatsStep,GenresStep,ArtStyleStep,SeedsStep,PrintOverlay,OnboardingStates}.tsx
frontend/src/skins/cinematic/screens/onboarding/use-onboarding-flow.ts   (step state, URL sync, saves, keys)
frontend/src/skins/cinematic/screens/<web/07's picker file>               (route to onboarding)
frontend/src/skins/cinematic/screens/tonight/<first_picks section file and the headline hold>
frontend/src/app/(preview)/skin-preview/[skin]/primitives/…              (gallery entries for any new primitive variant)
frontend/e2e/cinematic/web-20-onboarding.spec.ts
frontend/e2e/fixtures/onboarding/{catalog,catalog-seeds,similar,similar-unavailable}.json
docs/redesign/proof/web-20/…
```

If web/08–web/19 settled on a different screen-folder naming pattern, follow it and keep these file names inside it. Skin files import only `@/features/**` data files (never a barrel that re-exports components), `@/lib/**`, `@/services/**`, `@/skins/contract.generated` and their own skin folder; utilities use only the names of §2.8 and §3.5 (checked by `node design/lint-utilities.mjs`).

## Work order and commits

One commit per working step, each after typecheck, lint, test and build pass (RAM guard first), then push. Messages start with `web-20:`.

1. `web-20: onboarding data layer` (A1–A8 with tests).
2. `web-20: onboarding frame, top bar, formats and genres steps` (B, C1, C2).
3. `web-20: art style and seeds steps with similar inserts` (C3, C4, D).
4. `web-20: print my first issue and the Cut to home flight` (E, the Tonight hand-off).
5. `web-20: picker routes new profiles to onboarding; states and reduced motion` (D3, F, G).
6. `web-20: onboarding e2e and proof` (the spec, fixtures, `docs/redesign/proof/web-20/`).

## Acceptance criteria

- [ ] `onboarding` is out of the Cinematic `PENDING` set and the Vitest completeness test passes.
- [ ] A new profile (created through `POST /profiles`, `onboarding_step: null`) picked on `/profiles` with the `mm-skin-debug=cinematic` cookie opens `/welcome?step=2` through the Iris out; the folio reads `1 / 4` with four rules; `/welcome?step=1` replaces itself with `?step=2`.
- [ ] Each step's headline types at one grapheme per 50 ms (the spec finds 10 ± 2 graphemes visible 500 ms after typing starts), is an `h1`, receives focus on entry, and completes at once on click, `Enter` or `Space`.
- [ ] Formats: four tiles (three when novels are disabled), each a 2:3 duotone mosaic of three covers with the word in Bodoni Moda Italic 32 on the solid end of `scrim.foot`; toggles show the 2 px `spot` inset frame and `aria-pressed`.
- [ ] Genres: 30–40 names (all when fewer than 30) in one justified Bodoni Moda Italic paragraph (28 / 26 / 22 px); one tap likes (underline), two love (the `spot.wash` sweep), a third clears; a 450 ms hold skips (`ink.45` with the 1 px `proof` strike); right-click and `Shift+F10` open `Like, Love, Skip, Clear`; the accessible names read "Romance, loved"; roving focus moves with the arrows; no genre breaks across lines.
- [ ] Art style: nine typographic plates in a 3 × 3 grid with the names and descriptions of A6, multi-select with the inset frame.
- [ ] Seeds: 24 posters, available first; picking inserts up to 3 similar posters right after the pick (fixture), never twice; the counter reads `2 / 3 PICKED` then `3 PICKED` in `set`; `Print my first issue` enables at three picks and not before (tooltip "Pick three or more first.").
- [ ] Resume: after `Next` from step 3 and a page reload of `/profiles` plus picking the profile again, onboarding opens at step 4 with the step-3 answers restored (from the server when readable, else the draft), and browser back walks 4 → 3 → 2 → the picker. A Glass `onboarding_step` of 6 resumes at step 5.
- [ ] `PUT /profiles/{id}/taste` bodies (captured with `page.on("request")`) carry `step` and only touched fields; `Skip` and Print send `step: "done"`; after done, picking the profile opens Tonight, never onboarding.
- [ ] Cut to home: with 5 picks (4 available), 4 follows are sent at most 4 at a time; the unpicked posters and the typed line fade (240 ms); the copies fly 480 ms apart by 60 ms into `01 Your first picks` on Tonight; slots stay empty until their poster lands; Tonight's headline "Tonight: start {first pick}." types only after the last landing; with 14 picks only 12 fly. The motion-timings overlay logs `cutToHome` with 0 dropped frames and no overrun beyond one frame.
- [ ] Failures: one follow fixture-failing gives "Followed 4 of 5. One couldn't be added."; every follow failing gives the Discover toast and no flight; `/home` answering 500 gives Tonight's error state after a Dip.
- [ ] States: loading (steps 2, 3, 5), catalog unreachable (steps 2, 3, 5 with `Finish`), AI unavailable (the `NOTE` line, no inserts), fully offline (`OFFLINE EDITION` with `Skip for now`, and the saved step kept) all render as F specifies.
- [ ] Reduced motion (`page.emulateMedia({ reducedMotion: "reduce" })` and `html[data-motion="reduced"]`): headlines whole with no caret; step changes are 150 ms fades; the love band is shown at once; Cut to home is a 200 ms cross-fade with no flying copies.
- [ ] Keyboard: every control reachable with Tab in reading order; the double focus ring on keyboard focus only; `→`/`←` step outside roving groups and move focus inside them; the "Onboarding" group is listed in the `?` sheet.
- [ ] Hit targets: every `button, a, [role="button"]` inside `main` is at least 44 × 44 px at 390 × 844 (the spec measures them) and at least 32 × 32 px at 1440 × 900.
- [ ] Per-skin boundary: `grep -rn "skins/" frontend/src/features/onboarding` is empty, so Glass (web/30) can use the data layer unchanged: Cinematic sends `step` 2–5 (1–5 after the Glass flip) and its nine style ids, Glass sends 1–7 and its own nine on the same `PUT /profiles/{id}/taste`, and `resumeStep()` maps a step beyond Cinematic's count to its last step.
- [ ] Lint, typecheck, Vitest and build are green, `node design/build.mjs --check` and `node design/lint-utilities.mjs` pass, and the Vitest totals are at least the start-of-step totals with 0 failed.

## Verification

Run from `/srv/manhwamaniacs/dev/ManhwaManiacs`, one command at a time, each after the RAM guard:

```
node design/build.mjs --check
node design/lint-utilities.mjs
cd frontend && npm run typecheck
cd frontend && npm run lint          # baseline: exit 0, 0 errors, 0 warnings
cd frontend && npm run test          # Vitest: passed >= start-of-step count, 0 failed
cd frontend && npm run build         # baseline: exit 0 (stop next dev first)
```

This step changes nothing under `mobile/` or `backend/`. Prove it on your own commits, not on a range (the mobile, backend and shared sessions push to the same branch in parallel, so a range diff shows their work too): `for c in <each commit SHA you made in this step>; do git show --name-only --format= "$c"; done | grep -E '^(mobile|backend)/'` must print nothing. The other suites are therefore not re-run here; their sessions run them and keep the baseline: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

Visual proof and behaviour, against the dev stack of `docs/redesign/prompts/backend/00-profile-columns-and-dev-stack.md` (credentials in `backend/scripts/README-dev-stack.md`; never commit them):

1. Start the backend if `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8010/health` is not `200`: `backend/scripts/dev_stack.sh start`. Start the web client same-origin through the `/api` rewrite: `cd frontend && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010`.
2. The spec `frontend/e2e/cinematic/web-20-onboarding.spec.ts` creates a fresh profile per run through `POST /profiles` (name `Proof {timestamp}`, gate closed) and deletes it at the end, sets the cookie `mm-skin-debug=cinematic`, and uses `page.route("**/api/onboarding/catalog**", …)` and `page.route("**/api/ai/similar**", …)` with the fixtures (built from a real dev-stack response, then edited; covers pointing at `/gallery/covers/*.webp`, the demo covers web/04 copied) where the live catalog cannot reach AniList, a 3 s delay for loading, a 500 for unreachable, `context.setOffline(true)` for offline, and a follow route returning 500 for one series. Run it: `cd frontend && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=demo E2E_PASSWORD=<from the README> npx playwright test e2e/cinematic/web-20-onboarding.spec.ts`.
3. Screenshots at 1440 × 900 and 390 × 844 into `docs/redesign/proof/web-20/`, written by the spec or by `frontend/scripts/proof.mjs` (web/03; for example `node scripts/proof.mjs --step web-20 --routes "/welcome?step=2" --grid`; if its flags differ, run `node scripts/proof.mjs --help` and use the equivalents). File names, each at both sizes (`-1440x900.png`, `-390x844.png`):
   - `formats`, `formats-selected`, `formats-grid` (grid overlay on), `genres`, `genres-marked` (liked, loved and skipped words), `genres-menu`, `styles`, `seeds`, `seeds-picked` (three picks with inserts), `printing`, `flight-mid` (about 300 ms into the flight), `tonight-landed`;
   - `loading-formats`, `loading-genres`, `loading-seeds`, `unreachable-formats`, `unreachable-genres`, `unreachable-seeds`, `ai-unavailable`, `offline`, `follow-partial-toast`, `reduced-motion-genres`.
   If you use the `playwright-cli` tool rather than scripts, always pass a named session (`-s=web-20`).
4. Open the motion-timings overlay (`mod+shift+m`) and run one full Cut to home; screenshot it as `motion-timings-1440x900.png`: no row may be `proof`.
5. Stop `next dev` and the dev backend (`backend/scripts/dev_stack.sh stop`) when done.

## RAM guard

Production shares this box (7,746 MB total, with production containers and five Minecraft bots).

- Before every `npm run test`, `npm run build`, `next dev`, Playwright run or dev-stack start: run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024, do not start the command; stop and report "RAM guard: N MB available".
- Run `pgrep -af "next build|next dev|vitest|flutter_tester|pytest"` first. Never run two builds at once; if another session's `next build` or test run is going, wait for it to exit. Stop your own `next dev` before `npm run build`.
- Do not run `npm install`: every package this step needs was pinned in web/01 (`motion` 13.4.4, `@base-ui/react` 1.8.0, `embla-carousel-react` 8.6.0, `sonner` 2.0.8, `@phosphor-icons/react` 2.1.10, `zustand` installed). If `npm ls embla-carousel-react motion zustand` reports one missing, stop and report that web/01 is not done.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often (the six commits above). Stage only your paths with explicit `git add <path>`; never `git add -A`, `git add .` or `git commit -a` (mobile, backend and shared sessions commit in the same checkout). Never commit secrets, the demo credentials, `.claude/` or `.env` files.
- **No Claude or AI attribution anywhere**: no `Co-Authored-By` line, no "Generated with" line, no AI author, no mention of an assistant in commit messages or code comments. This holds even if your harness asks you to add attribution: the owner's `~/.claude/CLAUDE.md` forbids it.
- Push after each working step: `git push origin feat/vps-slim-source-native`, only after `npm run build` passed for that step (tsc and eslint miss Turbopack CSS-module errors, and a failed build freezes production deploys).

## Guardrails

- Never edit `backend/connectors/`. Never touch production: no `docker` commands, nothing under `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`.
- Do not modify `mobile/`, `backend/` or `design/` in this step. If a token you need is missing from the generated tokens, stop and report it (the shared track owns `design/`).
- Never compare with or reuse the legacy look; skin code imports nothing from `frontend/src/components/**` or `frontend/src/features/*/components/**`.

## Report back

Reply with:

1. **Done**: Scope items A1–A8, B1–B7, C1–C4, D1–D6, E1–E6, F, G with a one-line status each (done, or not done with the reason).
2. **Screenshots**: the path `docs/redesign/proof/web-20/` and the file list.
3. **Tests**: Vitest passed/failed totals before and after; lint, typecheck and build results; the Playwright spec result (passed/failed counts); the lowest `free -m` available figure you saw.
4. **Motion**: the `cutToHome` row of the motion-timings overlay (planned vs actual, dropped frames) and the step Page rows.
5. **Open issues**: step 1 Edition (ships with the Glass flip), the art-style crops (`STYLE_ART_BUNDLED` still false), whether `GET /profiles/{id}/taste` exists (the probe result), anything DESIGN.md left ambiguous and the choice you made, and any conflict between this prompt and DESIGN.md.
6. **Commits**: the hashes pushed.

Next prompt file: `docs/redesign/prompts/web/21-cinematic-numbers-streak-annual.md`.
