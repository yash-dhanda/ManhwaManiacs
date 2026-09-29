# Web Glass novel reader

Track: web · Order 90 · Depends on: `docs/redesign/prompts/web/35-glass-manga-reader.md` · Runs in parallel with: `docs/redesign/prompts/mobile/36-glass-novel-reader.md` · Proof folder: `docs/redesign/proof/web-36/`

## Goal

Build the Glass novel reader on the web client (`frontend/`): a text column laid on one of seven dark papers (Void, Ink, Night Paper, Dusk, Moss, Rosewood and the book's own "Glass" paper), with floating glass capsules tinted by the paper's ink, the chapter header, the body in Literata / Sans / Atkinson with speaker bands, the end matter and the seamless next chapter pulled up in place, scroll and paged reading with the three Glass page turns (Slide, Lift, Fade) on the existing skin-neutral engine command `paginateNovel`, the Aa "Type and page" sheet with the paper orbs and the paper ripple, the Contents sheet, pinch for text size, the long-press text menu (Copy, Bookmark this paragraph, Play from here, React to this chapter, Recommend to…), every state and every key, on desktop web (with the two side panels) and mobile web. When you finish, the ScreenId `novel` leaves the Glass `PENDING` map. Listen mode (the listen row, the full player, the voices) is `web/37`; recaps, Circle and the ambient extras (cruise, soundscape, page-tinted manga chrome) are `web/41`, `web/43` and `web/44`. Cinematic must not change by a single pixel.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all; "Novels: Apple Books / Kindle (paper themes, typography controls, page turns)", dark only, flagship-only effects, OS reduced motion honoured).
2. `docs/redesign/stack-decision.md` §2.2 (web layout, the lint boundary), §2.6 (one data layer), §3 (novel paper themes and typography stay as reader settings), §4 risks 6 and 11.
3. `docs/redesign/glass/DESIGN.md`:
   - "Conventions used everywhere below", §1 Manifesto.
   - §2.1.1, §2.1.2 (text on glass is `onGlass`; the backing disc), §2.1.3, §2.1.5 (the speaker palette, 14 % bands, 1.5 px underline, dashed from the 11th speaker), §2.1.7 (the "Novel reader chrome" row of the `Lb` table), §2.1.8 (the ambient field for the Glass paper), §2.4.1 (layer stack: content is never glass; `materialThick` side panels), §2.4.2 (variants, rule 7 "nothing on glass is glass", rule 8 "one lit object"), §2.4.3, §2.7 (icons: `text-aa`, `list-numbers`, `headphones`, `bookmark-simple`, `skip-back`, `skip-forward`, `caret-left`, `strata`).
   - §3.1 (Literata and Atkinson delivery, `preload: false`), §3.4 (novel type: every range, default and step), §3.5, §3.6.
   - §4.2 (springs), §4.4, §4.5 (rubber band; chapter end commits at 72 displayed px), §4.6 (thresholds: 150 / 450 ms press, chapter-end 48 / 72), §4.7, §4.10 rows Materialise, Dematerialise, Dive, Book open, Novel next, Page slide, Page lift, Paper ripple, Bloom, Sheet present, Toast fall, Rubber band, Error shake, Skeleton shimmer, Reaction bloom and arc; §4.11 (Reduce Motion, Solid glass, Increase Contrast, the screen-reader rules).
   - §5.2 events `page.turn`, `detent.tick`, `detent.limit`, `bookmark.add`, `press.lift`, `longpress.open`, `chapter.arm`, `chapter.next`, `reader.enter`, `select`, `toggle.on`/`toggle.off`, `reaction.bloom`, `reaction.cross`, `reaction.send`, `error`; §6 (cues `tick`, `chapter`, `add`, `dive`).
   - §7.2, §7.6, §7.10 (sheets: `medium` 52 %, `large`; desktop panels), §7.11, §7.12, §7.21 (steppers and sliders), §7.22, §7.23 (menus, `shift+F10`), §7.24, §7.37 (the depth glyph and the back menu), §7.40 (pointer cursors: `text` on the novel column).
   - **§8.14.2** (the go-to popover, "Nothing beneath", hidden chrome is inert), §8.14.5 (the one keep-awake rule), §8.14.11 (desktop panels, the Reader system UI rule, landscape phone "Novel" row).
   - **§8.15 entire** (§8.15.1 to §8.15.8). Read every line; it is the contract for this step.
   - §9.3.2 (React from the page menu) and §9.3.4 (the menu path "Recommend to…"), §9.4.4 (the line "Novel reader: the chrome takes the paper's ink at 12 % as its tint").
   - §11 (gesture matrix rows for the novel reader), §14.1–§14.8, §15.2 (Readers: Glass supplies only chrome and gestures), §15.4 (the `paginateNovel` row), §15.5 (device keys; `mm.reader-preferences`), §15.7 (the novel reader row of the live-surface table: at most 5).
4. `docs/redesign/cinematic/DESIGN.md` §2.1.6 (the paper stocks and speaker tints Cinematic stores) and §8.15.5 (its Type sheet fields), only to know which shared novel fields the other skin writes into the same stores; never copy its look.
5. `docs/redesign/inventory/web.md` §10.3 (NR1–NR19, NT1–NT7), §18.7 (A74–A81), §19.3 (K40–K44).
6. `docs/redesign/inventory/capabilities.md` §1 (`cache.stale`, rate limits), §13 (paragraph buckets), §15 (bookmarks, `media_type: "novel"`, `anchor_stale`), §19.1, §19.2.
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/proof/web-14/report.md` (the exact API of `useNovelReader()`, `paginateNovel`, `use-novel-pagination.ts` and the novel preference stores), `docs/redesign/proof/web-15/report.md` (the API of `useNarration()`), `docs/redesign/proof/web-35/report.md` (the Glass reader chrome pieces you reuse: the go-to popover, the side-panel layout, the dive entry, the reader settings store and its field names).
9. Code you build on: `frontend/src/features/novels/` (`use-novel-reader.ts`, `paginate.ts`, `use-novel-pagination.ts`, `preferences.ts`, `settings.ts`, `typography.ts`, `book-defaults.ts`, `reading-time.ts`, `use-narration.ts`), `frontend/src/features/reader/` (`ambient-settings.ts`, the Glass reader settings store from `web/35`), `frontend/src/features/circle/` (the reactions mutation from `web/22`), `frontend/src/skins/glass/` (`glass/GlassSurface.tsx`, `glass/useLb.ts`, `glass/AmbientField.tsx`, `motion.ts`, `physics/`, `primitives/*`, `Shell.tsx` with the `SheetHost` and its sheet registry, `screens/reader/*` from `web/35`, `screens/series/*` book page from `web/33`), `frontend/src/skins/cinematic/screens/novel/` (read only, to find shared logic that must move to `features/`), `frontend/e2e/fixtures/novel/` (from `web/14`), `frontend/scripts/proof.mjs`.

## Preconditions (check before writing the plan)

- `git log --oneline -30` shows the `web/35` commits; `frontend/src/skins/glass/index.ts` lists `novel` in `PENDING` and no longer lists `reader` or `readAll`.
- `grep -n "paginateNovel\|pageCount" frontend/src/features/novels/*.ts` finds the command from `web/14`; `grep -rn "useNarration" frontend/src/features/novels` finds `web/15`'s hook. If either is missing, stop and report which step has not run.
- `npm ls @use-gesture/react @tanstack/react-virtual motion @base-ui/react` lists all four.
- In `frontend/`: `free -m && npm run test` is green; record the vitest file and case counts (your floor).

## Skills to invoke

1. `superpowers:writing-plans` before any code; write the plan to `docs/redesign/proof/web-36/plan.md`, one task per scope letter.
2. `superpowers:test-driven-development` for every pure module (preference mapping, papers, page-turn maths, pinch steps, chapter-end pull, keys reducer, speaker bands, reading pace).
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 6 implementer subagents; start each subagent prompt with a scope lock, pass `model: "opus"` explicitly, run builds, tests and browsers one at a time, and verify every subagent's work against `git status` and `git diff`, never against its report.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for the page itself: measure, leading, the drop cap, the calm chrome. The page must feel like dark paper under a pane of water, never like a web article with floating buttons.
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Use the generated custom properties and TypeScript tokens (`--mm-…`, `tokens.generated.ts`, `motion.generated.ts`), never literals, except the paper colours and the formula constants below, which you put in `papers.ts` with a comment citing the section. Every animated move goes through `play(name, …)` from `skins/glass/motion.ts` with its `MotionName` from the §4.10 table. Sections cited are `glass/DESIGN.md` unless named otherwise.

### A. Shared data layer (skin-neutral, `frontend/src/features/novels/`, first commits, no pixels)

A1. **`glass-novel-prefs.ts`** (+ `glass-novel-prefs.test.ts`): Glass reads and writes the stores `web/14` and `web/18` created, and adds only its own fields (their normalisers keep unknown fields; if one does not, fix that normaliser in this commit with a test). Never rewrite a legacy key's value.
   - **Per book**, `mm.novel-preferences[{source}:{series}]` (profile-scoped through `lib/scoped-storage.ts`): shared fields `fontSize`, `lineHeight`, `measure`, `paragraphSpacing`, `letterSpacing`, clamped **on read** to Glass's ranges (§3.4): size 15–30 px step 1, line height 1.40–2.10 step 0.05, measure 48–88 ch step 2, paragraph spacing 0–1.2 em step 0.1, character spacing −0.02 to +0.10 em step 0.01. New field `glassFace: "literata" | "sans" | "atkinson"`; read-time fallback from Cinematic's `face` (`atkinson` → `atkinson`; `archivo` → `sans`; anything else → `literata`) and then from web K44 `fontFamily` (`sans` → `sans`, `serif` → `literata`).
   - **Profile defaults**, `mm.novel-defaults` (from `web/18`): shared `size`, `lineHeight`, `measure`, plus the new field `glassFace`. A book with no own value falls back to these, then to the Glass defaults of §3.4: Literata (Atkinson when `html[data-legible="on"]`), size 19 on a coarse pointer or below 1024 px and 20 on desktop, line height 1.75, measure 68, paragraph spacing 0.6 em, character spacing 0.
   - **Per profile**, `mm.novel-settings`: shared `layout` (`SCROLL | PAGED`, default `SCROLL`), `bold` (false), `justify` (false), `tapZones` (`STANDARD | BOTH_MARGINS | ONE_HAND`, default `STANDARD`); new fields `paper` (`void | ink | night-paper | dusk | moss | rosewood | glass`), `glassPageTurn` (`slide | lift | fade`, default `slide`), `lineGuide` (false). `paper` falls back at read time from web K40 `palette` per §8.15.1: `paper`, `sepia`, `cream` → `night-paper`; `solarized-light` → `dusk`; `soft-grey` → `ink`; `dawn` → `rosewood`; `solarized-dark` → `dusk`; `forest` → `moss`; `rose-pine` → `rosewood`; `black` → `void`; `midnight` → `dusk`; `site` → `glass`; `null` or absent → `void`. §8.15.1 does not map the old dark `dusk` swatch (`#1E1B18`, warm); map it to `night-paper`, the warm dark paper, as Cinematic maps it to its warm Sepia Night, and name this in the report.
   - Hooks `useGlassNovelPrefs(sourceId, seriesKey)` → `{ values, setBook(patch), setProfile(patch), resetBook() }` (`resetBook` removes the Glass-visible per-book fields only).
   - Tests: every K40 and K44 mapping, every clamp at both ends, the fallback order book → profile default → Glass default, the Legible-text default face, unknown-field preservation through a Glass write, per-profile isolation.
A2. **Reading pace** (`reading-pace.ts` + test): if `grep -rn "wpm\|reading-pace" frontend/src/features` finds a pace module from `web/23`, use it; otherwise create it. A profile-scoped `mm.novel-pace` = the last 30 samples `{ words, ms }`. A sample is a stretch of reading of at least 20 s in which the reading line advanced, ended by 5 s without scroll or input, a chapter change or leaving the reader; stretches containing an idle gap over 60 s are dropped. `pace()` = Σwords / Σminutes; `ready` when Σms ≥ 120,000. `minutesLeft(wordsRemaining)` rounds up and returns `null` while not ready. Test: the 20 s floor, the idle drop, readiness at exactly 120,000 ms.
A3. **Scene breaks**: if `web/14` put the ornament-paragraph detector inside `skins/cinematic/`, move it to `features/novels/scene-break.ts` in a no-behaviour-change commit (Cinematic imports it from there; its tests stay green), then use it here. Rule unchanged: a paragraph of at most 12 ornament characters (`*`, `#`, `~`, `•`, `·`, `-`, `—`, `=`, `◇`, `❖`, `⁂`, spaces).
A4. No new engine command: paged mode uses `paginateNovel(measure, type)`, `pageIndex`, `pageCount` from `web/14`. If its API cannot report a turn in progress, keep the turn animation in the skin; never change what a page is.

### B. Route, entry and exit

1. ScreenId `novel` at `/novels/:sourceId/:seriesKey/:chapterKey` with `?page&para&at&listen=1` (the thin route file `web/00` wrote stays thin). Decode once; build every URL with `ROUTES` from `contract.generated.ts`. `listen=1` is read by `web/37`; ignore it here. `para` opens at that paragraph and flashes it with the **Row pulse** move (the `iris600` fill at 14 % fading to 0 over 900 ms; reduced motion: shown 900 ms, removed without a fade).
2. Frame: immersive. No dock, no sidebar, no bottom accessory (`web/29` hides them in both readers); `html` background stays `#000000`; the paper paints edge to edge under the safe areas.
3. **Entry.** From the book page's "Start reading" / "Continue" (`web/33`): **Book open** (settle 615 ms on `page`, k 146.0, c 24.17): the plate rotates open on its spine (`rotateY` 0 → −78°, `perspective: 900px`, `transform-origin: left center`) while the paper expands from the plate's rectangle. Build it with React `<ViewTransition>` and a shared `view-transition-name` on the plate and on the paper frame, keyframes in `glass.css` eased by the generated `page` `linear()` string, `reader.enter` (`ahap:dive`) and the `dive` sound on landing. From contents rows, History, Bookmarks, Updates, Downloads, dialogue and novel-text search results and the command palette: `web/35`'s **Dive** (settle 558 ms on `zoom`). Reduced motion: 200 ms cross-fade for both.
4. **Exit.** Back returns to the entry beneath (the book sheet recessed under the reader returns on history back). **Nothing beneath** (a cold deep link, the skin-switch return route): back goes to `ROUTES.feature(sourceId, seriesKey)` in its full-page form with a 200 ms cross-fade (§8.15.3). The back button shows the `strata` depth glyph and a long-press (500 ms on touch, the web rule) opens `web/29`'s back menu.
5. Semantics: the reading region is `role="region"` with `aria-label="Chapter 12, 42 percent"` (updated at most every 5 %), `tabIndex={-1}`, focused on entry; a polite live region announces "Chapter 12, The Tower · Omniscient Reader's Viewpoint" on entry and on every chapter change. `document.title` = "Ch 12 · {series} · ManhwaManiacs".

### C. Papers (§8.15.1) and the chrome tint

1. `screens/novel/papers.ts` (+ test) holds the table:

   | Paper | Background | Ink | Muted |
   |---|---|---|---|
   | Void (default) | `#000000` | `#D9D6D0` | `#8A877F` |
   | Ink | `#0B0B0C` | `#E6E3DD` | `#8F8C86` |
   | Night Paper | `#15110C` | `#E8D8BE` | `#9C8E78` |
   | Dusk | `#0D1117` | `#D3DAE3` | `#8590A0` |
   | Moss | `#0E130F` | `#D5DECF` | `#879384` |
   | Rosewood | `#160E10` | `#EBD5D8` | `#A08A8E` |
   | Glass | `#000000` + the book cover's ambient field at 10 % in the top 30 % of the screen | `#ECECF1` | `#8F8F99` |

   The test asserts ink ≥ 13:1 and muted ≥ 5.8:1 on each background (the §8.15.1 figures: lowest ink 13.42, lowest muted 5.84).
2. `PaperFrame.tsx` sets `--paper-bg`, `--paper-ink`, `--paper-muted` on the reader root; the page, the contents sheet, the loading skeleton, toasts shown in the reader and every state paint from them.
3. **Glass paper:** `useAmbient({ palette: coverPalette(book), opacity: 0.10 })` (`web/25`) with a novel mask: opaque to 20 % of the viewport height, transparent at 30 %, so only the top 30 % carries colour. A book without a palette uses the profile mood colour at 10 %.
4. **Legibility and tint:** every novel chrome surface passes `useLb({ kind: "paper", luminance })` with the paper's relative luminance (Glass paper: the field term `l × 0.10 + 0.02`), so the dim sits near its 0.22 floor. When the shared `mm.ambient-settings.pageTint` is on (default true), every novel glass surface carries a tint layer of the paper's ink at 12 % inside the glass (§9.4.4); off, no tint. The tint cross-fades over `tintShift` (900 ms `cubic-bezier(0.2, 0, 0, 1)`; 200 ms under reduced motion) when the paper changes.

### D. Layout (§8.15.2)

1. **Column:** centred; width = measure in `ch` of the body face at the body size; phone side margins at least 20 px (`max(20px, env(safe-area-inset-left))`); `lang` from the chapter when known, else `en`.
2. **Desktop panels (≥ 1024 px):** content-layer surfaces, `materialThick` fill (`rgba(19,19,23,0.84)`, blur 36) mixed 70 / 30 with the paper colour (`color-mix(in oklab, var(--paper-bg) 70%, #131317)` under the blur), radius 26, inset 12, never Liquid Glass. **Left panel 300 wide, Contents** (`t`): the contents list of item J with the current chapter centred. **Right panel 360 wide, tabs "Aa · Voices · Listen"** as an in-page tab strip (§7.13); this step delivers the **Aa** tab (item I inline); `web/37` appends Voices and Listen (build the tabs from an ordered array). `,` opens Aa. Opening a panel re-centres the column on `sheet` (k 171.3, c 24.09); panels hide with the chrome and never cover the text.
3. **Fit:** the column renders at `min(measure, viewport − Σ(open panel width + 24) − 40)` and re-flows around the current paragraph anchor; the stored measure never changes. If the column would fall below 48 ch at the current size, opening the second panel closes the first with the same `sheet` spring and the toast "One panel at a time at this window size".
4. **Semantics and focus:** each panel is a non-modal `<aside role="complementary">` labelled "Contents" or "Type, voices and listen"; opening by key moves focus to the current row or the first control, opening by pointer leaves focus where it was; `F6` / `shift+F6` cycle column → left panel → right panel; Esc inside a panel closes it and returns focus to the column. Tablets (768–1023 px) open the same content as sheets.
5. **Chapter header:** "CHAPTER 12" in `caption1` +0.22 em in muted; the title in Literata `opsz` 36, `wght` 560 at 1.55 × the body size in ink (the page's `h1`); a 56 px rule (1 px muted); "3.4k words · 14 min" in muted `mono` 12/16 (a §3.7 size override; minutes from `reading-pace.ts`, 250 wpm until ready). Leave a slot after the rule for `web/37`'s "Listen · 14 min" capsule and its "Audio plays without follow-along" line.
6. **Body (§3.4):** the chosen face (`var(--mm-font-serif)` Literata with `opsz` = size and `wght` 400; Sans = Google Sans Flex at `ROND 0`, `opsz` = size; Atkinson = `var(--mm-font-legible)`), size, line height, paragraph spacing and character spacing from A1; first paragraph with a drop cap only when it has at least 80 characters (Literata `wght` 620 at 3.1 em, 3 lines, through `::first-letter` with `initial-letter: 3` where `CSS.supports("initial-letter", "3")`, otherwise `float: left` sized from the line height), so the word stays whole for selection and screen readers; indents 1.3 em after the first paragraph (none when paragraph spacing > 0); scene breaks (A3) render "✦ ✦ ✦" centred in muted with 0.5 em tracking and 1.6 em above and below, `role="separator"`; Justify: `text-align: justify; hyphens: auto; text-wrap: pretty`, else ragged with `hyphens: manual`; Bold: `wght` 400 → 520.
7. **Reading faces load only here:** Literata comes from `skins/glass/fonts.ts` (`preload: false`) and Atkinson from the same file; neither may load on Home or Library (network log in the proof).
8. **Speaker bands (§2.1.5):** only when `attribution.attributed` is true and its `text_fingerprint` matches the text on screen. `speaker-bands.ts` (+ test) assigns slots in cast order (busiest first): `spk1` `#7CC4FF`, `spk2` `#FFB27A`, `spk3` `#9BE58A`, `spk4` `#D7A4FF`, `spk5` `#FF8FA3`, `spk6` `#6FE3D4`, `spk7` `#FFD86B`, `spk8` `#A7B4FF`, `spk9` `#F59BD6`, `spk10` `#C8D98A`; from the 11th speaker the list repeats with a dashed underline. Each attributed run: background band at 14 % of its hue, a 1.5 px underline at 60 % (`text-underline-offset: 0.18em`), the text in the paper ink; narration is never tinted. A visually hidden "Mira:" precedes each run for screen readers. Test: ordering, the 11th speaker, a stale fingerprint returns no bands.
9. **Tap a tinted run:** a `glassThin` chip "Mira · voiced by Ada" (or "Mira" with no assigned voice) materialises 8 px above the run for 2 s and dematerialises; it does not toggle the chrome; the chip's text is also the run's `aria-describedby` hint.
10. **End matter:** 96 px rule, "END OF CHAPTER 12" (`caption1` +0.22 em muted), the length line, then the **Next card** (`surface1` `#131317` on the paper, radius 20, padding 16: "NEXT" `caption1`, "Chapter 13 · The Tower" in Literata 20, a chevron; one link) or "You've reached the last chapter this source has published", then plain links "Previous chapter" and "Back to the book". Leave an ordered slot after the length line for `web/43`'s reaction strip.
11. **Seamless next (`chapter-end-pull.ts` + test):** at the chapter end, over-scroll rubber-bands with `rubberband(x, viewportHeight, 0.35)` (the reader constant); at 48 displayed px it arms (`chapter.arm`, `soft(0.5)`), at 72 it locks the Next card (`chapter.next`, `rigid(0.8)`, the `chapter` sound); crossing back below 72 un-locks (`threshold.back`); releasing while locked plays **Novel next**: the next chapter slides up in place on `page` (615 ms; reduced motion 200 ms cross-fade), the URL is replaced (no navigation), the old chapter is marked complete through `useNovelReader().next()`. `l` and the Next card do the same. **Desktop wheel:** delta past the end accumulates: 140 px arms, 210 px commits, reset after 400 ms without wheel input. **Auto next** (the Glass reader settings store's `autoNext`, default on): reaching the end opens the next chapter after 900 ms unless narration is playing or the reader scrolls back up. Reduced motion: the rubber band is a hard stop; the card locks at the threshold with a 150 ms fade. Tests: the arm and commit thresholds, the wheel accumulator with its 400 ms reset, the auto-next cancel on scroll-back.
12. **Further ahead elsewhere:** when a progress save answers `advanced: false`, the toast "You're further ahead on another device: Ch 146, 38 %" with "Jump there" (the same toast as the manga reader, in the paper palette).

### E. Chrome (§8.15.3)

All chrome is `glassRegular` / `glassThin` with the paper `Lb` and tint of C4; soft edges under the top and bottom groups fade with the chrome.

1. **Toggle:** a tap or click on the column (outside a link or a tinted run) toggles the chrome; a click toggles only when, after `mouseup`, the selection is collapsed and the pointer moved ≤ 4 px. The chrome **materialises** in (250 ms lensing, opacity over the first 120 ms, blur 8 → 0) and **dematerialises** out (350 ms); no minimise pill. Engine thresholds still apply: 24 px of downward scroll hides, 56 px upward shows, 3000 ms idle hides after a tap opened it; never hides in the first 800 ms of a chapter, while a sheet, menu, popover or selection is open, while focus is inside the chrome, with Screen reader mode on (`data-sr="on"`), or within 30 s of a `keydown`. **Hidden chrome is inert** (`inert` on the groups); any non-reader key, a Tab, or pointer movement into the top or bottom 72 px (desktop) restores it and the first control takes focus.
2. **Top-left group:** back (44, depth glyph) + title capsule "Tower of God · Ch 12" (`glassThin`, 36 tall, `subhead` 600 `onGlass`, truncating at 60 % of the width; tap → Contents, `t`). The "Saved copy" capsule joins this group when reading a downloaded copy; the `warning` "Saved copy · 2 h" capsule when `cache.stale` is true (age from `cache.fetched_at`).
3. **Top-right glass group** (one `GlassGroup` masked element with the top-left group, §2.4.1): bookmark (toggle; saved = Fill `iris400` on the backing disc), then the ordered slots `web/37` fills (listen `headphones`, voices `voice-31`), then **Aa** (`text-aa`). Never more than four icons. Leave the Aa button a `badge` prop for `web/44`'s 6 px `iris400` soundscape dot.
4. **Bottom capsule** (`glassRegular`, 56 tall, max 520 wide, its bottom edge at `max(env(safe-area-inset-bottom), 0px) + 16 px`): previous chapter (`skip-back`; 30 % and disabled when there is none), the readout "42 % · 6 min left" in `mono` 13 (minutes only once `reading-pace` is ready; before that just "42 %"; paged mode "p. 7 of 22 · 42 %"), an ordered slot for `web/44`'s cruise button (scroll mode only), next chapter (`skip-forward`, tooltip with the next chapter's label).
5. **Progress hairline:** 2 px at `top: env(safe-area-inset-top)`, full width, the muted ink at 100 % for the read part and 25 % for the rest, always visible (also with the chrome hidden).
6. **Go to a percentage** (§8.15.4): the readout is a button ("42 percent, go to a percentage"); it blooms (`morph`) `web/35`'s go-to popover (`glassThick`, 280 wide) above the capsule with a slider 0–100 % (`detent.tick` every 5 %) and a number field (`inputmode="decimal"`, "%" after it); Enter or "Go" jumps through `jumpToBucket`; in paged mode the slider steps by page and the field takes a page number. `g` opens it. It is an anchored picker (no `?sheet=` entry).
7. **Landscape phone** (`(orientation: landscape) and (max-height: 500px)`): the column at its measure; top-left back + title (≤ 40 % width); top-right bookmark, the listen slot, Aa and ⋯ (voices and the soundscape row live in the ⋯ menu, filled by `web/37` and `web/44`); the bottom capsule stays.
8. **Keep screen awake** (phones, §8.14.5): while the reader is visible and the Glass reader store's `keepAwake` is on, hold `navigator.wakeLock.request("screen")`, re-acquired on `visibilitychange`, released on leave. Render the Aa sheet row only when `"wakeLock" in navigator` and `(pointer: coarse)`. Export `useKeepAwake({ force })` so `web/44` holds the same lock while cruise runs (its `force` overrides the switch) instead of adding a second wake-lock hook.
9. **Top-centre slot:** one ordered, one-at-a-time slot under the top groups for the transient capsules: the rate-limit capsule (J), the pinch capsule (G9) and `web/41`'s "Previously · 20 s" pill (§8.15.3, 6 s after 3 or more days away). Whichever shows takes the chip / popover line of the L budget, so opening one closes the other.

### F. Touching the text (§8.15.3)

1. **Touch (mobile web):** the column is the only `user-select: text` region. The platform's long-press starts native selection; when a non-collapsed selection inside the column appears after a touch, fire `longpress.open` (the Android web vibrate `[18]`) and replace the bottom capsule with a `glassThick` **action capsule** (Bookmark this paragraph · Play from here · React · Recommend, 44 px targets), so nothing covers the native selection toolbar or the handles; it dematerialises when the selection clears.
2. **Desktop:** after a mouse selection ends inside the column (non-collapsed, 200 ms after `mouseup`), on a right-click inside the column (at the pointer; the browser menu is suppressed only there) and on `shift+F10` with a selection, a `glassThick` menu blooms above the selection on `morph` (min width 220, rows 44, radius 20 inside 26): **Copy**, **Bookmark this paragraph**, **Play from here**, **React to this chapter**, **Recommend to…**. Dragging the selection keeps it attached (repositioned on `selectionchange`, at most once per frame); a click outside clears the selection and closes it. Keyboard per §7.23.
3. **Copy:** `navigator.clipboard.writeText(selection)`; toast "Copied".
4. **Bookmark this paragraph:** the paragraph under the selection start; `POST /reader/bookmark` (`media_type: "novel"`, paragraph anchor, fraction, 180-character snippet) through `useNovelReader().bookmark`; `bookmark.add` haptic and the `add` sound; toast "Saved this spot · Add note" in the paper palette ("Add note" opens a one-line note sheet `?sheet=note` that saves through the same upsert); failure toast "Couldn't save that spot".
5. **Play from here:** rendered only when the chapter's audio exists (`useNarration()`'s availability). It calls `playFrom(paragraphIndex)` on a `GlassListenBridge` React context that this step creates in `screens/novel/listen-bridge.tsx`; its default implementation seeks `useNarration()` to the first segment of that paragraph and plays, and `p` toggles play and pause. `web/37` replaces the bridge's provider with the full Glass narration host (listen row, player, highlight); keep the context's shape `{ available, playing, playFrom(para), toggle() }`.
6. **React to this chapter:** the row morphs into `web/28`'s `ReactionPicker` at the same anchor (six bubbles: Hype `fire`, Love `heart`, Wrecked `smiley-melting`, Tears `drop`, Twist `lightning`, Masterpiece `hands-clapping`; `reaction.bloom`, `reaction.cross` per bubble); choosing one sends `POST /circle/reactions {source_id, series_key, chapter_key, kind}` through the shared reactions mutation (`hype`, `loved`, `wrecked`, `tears`, `shook`, `chefs_kiss`); the glyph flies on a ballistic arc (gravity 2,400 px/s²) to the end-matter reaction strip when it is mounted and on screen, otherwise to the title capsule, and lands with a `tick` pop and a 6-particle `bloom` burst (`reaction.send`, `ahap:pop`, the `pop` sound). Failure: the glyph falls back with the error shake and the toast "Couldn't send your reaction"; offline: queued by the shared mutation and drawn at once; sharing off: the send still works and the toast adds "Only you see this. Turn on Circle sharing to show others." Reduced motion: no arc, the glyph appears at its target with a 150 ms fade.
7. **Recommend to…:** pushes `?sheet=recommend&series={sourceId}:{seriesKey}` through the `SheetHost`. Render the row only when the Glass sheet registry has a `recommend` entry (`web/43` registers it); until then the row is absent. When present and nobody accepts recommendations, the row reads "Recommend to… (no one is taking recommendations yet)" and is disabled with that reason (§9.3.4).
8. **Double-tap** does nothing (single taps are never delayed). `b` bookmarks the paragraph at the reading line; Shift + arrows select text; `shift+F10` opens the menu on a selection.
9. **Cursor (§7.40):** the column opts into `web/26`'s cursor contract with `data-cursor="text"` (the I-beam over the text); tinted runs, links and every chrome control keep `pointer`, disabled controls `not-allowed`.

### G. Reading modes and page turns (§8.15.4)

1. **Scroll** (default): one scrolling column with native momentum; the reading line is 38 % from the top.
2. **Paged:** `paginateNovel` pages the chapter with CSS multi-column (§8.15.4, the foliate-js approach): the paged box is page-sized (the viewport width minus the open side panels, and the viewport height minus the chrome insets), `column-width` = that box's width, `column-gap: 0`, and every block child carries `max-inline-size: <measure>ch; margin-inline: auto`, so each page is one viewport wide while the text keeps the measure of D1; re-paginates on resize and every Type change, keeping the first paragraph of the current page on screen. The progress bucket is `round(pageIndex / pageCount × 100)` clamped 1–100; paragraph bookmarks anchor to the first paragraph that starts on the page (`at = 0`).
3. **Tap bands** (`page-turn.ts` + test): `STANDARD` 25 / 50 / 25 % (back / menu / forward; novels always read left to right, so the bands are never mirrored); `BOTH_MARGINS` ("Both margins go forward"); `ONE_HAND` (left 20 % back, top 12 % across the full width menu, the rest forward). Test each preset at its band edges.
4. **Slide** (default): the page follows the finger 1:1 (`touch-action: pan-y` on the paged box, horizontal drags owned after 10 px); the turning page carries `box-shadow: 0 0 8px rgba(0,0,0,a)` on its moving edge, with `a` scaled linearly from 0 to 0.45 by turn progress (§8.15.4); release projects `x + 0.499 × vx` and turns when the projection passes 50 % of the width; settles on `page` with the release velocity; `page.turn` (`selection`) and the `tick` sound on commit. Taps, keys and wheel turn with the same spring from rest.
5. **Lift** (Glass's own, §8.15.4 *Web Lift turn*): on pointer-down on a turn, mount one `cloneNode(true)` of the multi-column container with `inert` and `aria-hidden="true"` inside a page-sized wrapper (`overflow: hidden; transform-style: preserve-3d; backface-visibility: hidden; perspective: 1600px`) above the live container. Forward: the clone shows page n and rotates away `rotateY` 0 → −100° around the spine (the left edge) while the live container moves to page n + 1 beneath it; backward: the clone shows page n − 1 and rotates in from −100° over the live page n, and the live container moves to n − 1 on settle. Progress = drag distance / page width (release velocity included); a 40 px `rgba(255,255,255,0.18)` specular band crosses the turning page with progress; the page beneath un-dims from `brightness(0.85)` to 1; the back of the lifted page is the paper colour at 92 %. On settle or cancel the clone is removed and a cancel returns the live container to page n. Pure transforms only: no bitmap capture, no canvas, no shader. Selection, find and search stay on the single live container.
6. **Fade:** a 160 ms cross-fade.
7. **Reduce Motion:** Fade regardless of the choice.
8. **Wheel and keys in paged mode:** one page per wheel gesture with a 200 ms idle reset; `j`, Space, `→` forward; `k`, Shift+Space, `←` back; Home / End chapter start and end.
9. **Pinch for text size** (`pinch-steps.ts` + test): `@use-gesture/react` `usePinch` on the column with `touch-action: pan-x pan-y`, ignored while `visualViewport.scale > 1` (§8.0.8); on desktop the same handler takes trackpad pinch (`ctrlKey` wheel). One size step per ×1.15 of pinch scale from the gesture's start (`steps = trunc(log(scale) / log(1.15))`), clamped 15–30, `detent.tick` per step and `detent.limit` at an end; the text is never visually scaled: a `glassThin` capsule "Text size 21" shows top-centre during the pinch (it takes the chip slot of the budget), and the column reflows once on release around the paragraph anchor. `=`, `+`, `-`, `0` step and reset the same value.
10. **Line guide** (option): two frosted bands (`backdrop-filter: blur(6px)`, fill = the paper colour at 55 %) above and below the current line band (2 lines tall at the body's line height); drag the band or tap above or below it to move it one band; it registers in the glass budget as a scrim, not glass.

### H. Type and page sheet "Aa" (§8.15.5)

`?sheet=type`, a `medium` sheet (52 %) so the page updates live above it; desktop: the right panel's Aa tab; tablets: the sheet. Build the rows as an ordered array so `web/37` and `web/44` can append. On T4 glass all body text is `onGlass`; wells, tracks and steppers use `wellOnGlass`.

1. **Face tiles** "Literata", "Sans", "Atkinson", each set in its own face; selected: `fill2` twin + the selected ring; `role="radiogroup"`.
2. **Steppers** (`web/27`'s `Stepper`, detents with `detent.tick`, `detent.limit` at the ends, the page reflowing live): Size 15–30 px, Line height 1.40–2.10, Measure 48–88 ch, Paragraph spacing 0–1.2 em, Character spacing −0.02 to +0.10 em; the value in `mono`; buttons named "Larger text" / "Smaller text", "More line height" / "Less line height", "Wider column" / "Narrower column", "More paragraph space" / "Less paragraph space", "More letter space" / "Less letter space".
3. **Switches:** Justify and hyphenate, Bold text, Line guide.
4. **Mode** segmented Scroll · Paged; **Page turn** segmented Slide · Lift · Fade (paged only); **Taps** segmented Standard · Both margins · One hand (paged only). §8.15.5 lists no taps row; §8.15.4 defines the presets, so they live here; say so in the report.
5. **Ambient** group: the Page-tinted chrome switch (shared `mm.ambient-settings.pageTint`); `web/44` appends the Soundscape row and the cruise default.
6. **Screen** (phones): Keep screen awake (E8).
7. **Papers** as seven orbs (44 px circles in the paper colour with "Aa" in its ink and a specular highlight at the light angle; the Glass orb shows the book's palette), a radio group named by paper. Choosing one plays **Paper ripple**: `document.startViewTransition(() => setPaper(next))` with `::view-transition-new(root)` animated by `clip-path: circle(r at x y)` from 0 to the farthest-corner distance from the orb's centre on the `page` spring (settle 615 ms, the generated `linear()` string), `select` haptic. It is the only sprung colour change. Reduced motion or no `startViewTransition`: a 200 ms cross-fade.
8. **Reset** plain button (per-book typography back to defaults, `resetBook()`); toast "Type reset for this book".
9. **Scope captions** in `caption1` `onGlass`: typography rows "This book"; paper, mode, page turn, taps, switches "All books".

### I. Contents sheet (§8.15.6)

`?sheet=contents`, a `large` sheet in the paper colours (tablets and phones); desktop: the left panel. "Contents" in Literata 22; an ordered first-row slot for `web/41`'s "Previously on" row; a go-to field ("Chapter number", `inputmode="decimal"`, autofocus when opened from `t` with a keyboard or from a search affordance; Enter jumps to the first match; no match reads "No chapter 480 in this book."); the list windowed with `@tanstack/react-virtual` (reuse `web/33`'s book-page contents row if it is exported), pre-scrolled to the current chapter (its row ink at 7 % fill, `wght` 600, `aria-current="location"`); each row: number in `mono`, title, and the state marks the book page shows (read check, percent, downloaded `droplet`, narrated `headphones`). A tap opens that chapter by Dive. States: loading (a 20 px liquid spinner), offline "The contents need a connection to load" (downloaded chapters stay listed), error + Try again.

### J. States (§8.15.7), all in the paper colours

| State | Presentation |
|---|---|
| Loading | Paper-coloured skeleton lines at varied widths (12 lines at the body line height) with the sheen tinted to the ink at 5 % (1400 ms loop; static under reduced motion) |
| Offline | A downloaded copy opens with the "Saved copy" capsule; otherwise the offline object lens in the paper colours with "Back to the book" |
| Error | "Couldn't load this chapter" + "Back to the book" |
| Empty | "This chapter came through empty. The source answered with no text; the page may have been pulled or is still being published." |
| Stale bookmark | Toast "The text here changed. Opened at the nearest paragraph." |
| Saved copy | The `warning` capsule "Saved copy · 2 h" in the top-left group (`cache.stale`) |
| End of book | The last-chapter line of D10 |
| End of the downloaded copy | Offline with the next chapter not downloaded: "End of the downloaded copy" + "Download next 10 when online" (queues the next 10 through the shared download queue) |
| Bookmark saved / failed | Toasts in the paper palette (F4) |
| Rate limited | The `warning` capsule "The source is busy; the next chapter will load in {n} s" with its live `Retry-After` countdown, top-centre, while the current chapter stays readable |
| Unavailable | §8.0.8 object lens ("This source was removed from the server." and siblings) and, on a gated profile, "This isn't available on this profile" with "Back home" and no title |

### K. Keys (§8.15.8): register a "Novel reader" group in `lib/keyboard`

`keys.ts` is a pure reducer (+ `keys.test.ts`) that `web/37` and `web/44` extend. Bindings: `h` / `l` previous / next chapter; `j` / `k`, Space / Shift+Space page or screen; Home / End chapter start / end; `=`, `+` / `-` / `0` text size; `,` Aa; `t` contents; `b` bookmark the paragraph at the reading line; `p` play / pause through the listen bridge (F5); `g` go to a percentage; `?` shortcuts; `shift+F10` selection menu; `F6` / `shift+F6` panel cycle. `c` does nothing here. `[`, `]`, `v`, the narration meaning of `<` / `>` are `web/37`; `a`, the cruise meaning of `<` / `>` and `shift+s` are `web/44`. **Esc order:** menu or popover → sheet or side panel → return to the book. The global `g` chords are off inside the reader; the Single-key shortcuts switch disables every printable binding (§8.0.6).

### L. Budget and materials (§15.7)

At most five live `backdrop-filter` elements: top chrome (both groups, one masked element) 1, bottom capsule (or the action capsule) 1, the listen row slot 1 (`web/37`), the tinted-run chip or go-to popover or pinch capsule or selection menu 1 (one closes when another opens), a sheet 1. Content (the page, the Next card, side panels) is never glass. Check it with `useGlassCount()` in the e2e spec.

## Out of scope here (owned by later steps; do not build)

- `web/37`: the listen and voices buttons, the "Listen · 14 min" capsule, the listen row, the full player, the right panel's Voices and Listen tabs, highlight-as-read, narration-driven page turns, `[`, `]`, `v`, narration `<` / `>`, `?listen=1`.
- `web/41`: the "Previously" pill and the Contents "Previously on" row. `web/43`: the end-matter reaction strip and the recommend sheet. `web/44`: cruise, the soundscape, the Aa badge, `a`, `shift+s`.
- Any change to `design/`, `mobile/`, `backend/` or the Cinematic skin (except the A3 move, which changes no Cinematic behaviour).

## File layout

```
frontend/src/features/novels/glass-novel-prefs.ts (+ .test.ts)      A1
frontend/src/features/novels/reading-pace.ts (+ .test.ts)           A2 (only if missing)
frontend/src/features/novels/scene-break.ts (+ .test.ts)            A3 (only if it still lives in the Cinematic skin)
frontend/src/skins/glass/screens/novel.tsx                          ScreenId novel
frontend/src/skins/glass/screens/novel/
  NovelReader.tsx          composition: useNovelReader, pagination, frame, chrome, panels, sheets, keys
  papers.ts (+ papers.test.ts), PaperFrame.tsx                      C
  ChapterHeader.tsx, ChapterBody.tsx, speaker-bands.ts (+ test), TintedRunChip.tsx   D5–D9
  EndMatter.tsx, chapter-end-pull.ts (+ test)                       D10–D12
  SidePanels.tsx                                                    D2–D4
  ChromeTop.tsx, BottomCapsule.tsx, ProgressHairline.tsx, GoToPercent.tsx, useKeepAwake.ts   E
  SelectionMenu.tsx, ActionCapsule.tsx, listen-bridge.tsx           F
  PagedColumns.tsx, page-turn.ts (+ test), LiftTurn.tsx, PinchSize.tsx, pinch-steps.ts (+ test), LineGuide.tsx   G
  TypeSheet.tsx, type-rows.ts, PaperOrbs.tsx                        H
  ContentsSheet.tsx                                                 I
  NovelStates.tsx                                                   J
  keys.ts (+ keys.test.ts)                                          K
frontend/src/skins/glass/glass.css                                  Book open keyframes, paper ripple, lift turn, bands (global stylesheet; no CSS modules)
frontend/src/skins/glass/index.ts                                   novel removed from PENDING
frontend/e2e/glass-novel.spec.ts
docs/redesign/proof/web-36/                                         plan.md, screenshots, network-log.txt, report.md
```

Skin files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, `@/config/**`, the generated contract and `skins/glass/**`; the lint rule bans `@/skins/cinematic/**`.

## Acceptance criteria

- [ ] `novel` is gone from the Glass `PENDING` map; the completeness test passes.
- [ ] `glass-novel-prefs.test.ts`, `papers.test.ts`, `page-turn.test.ts`, `pinch-steps.test.ts`, `chapter-end-pull.test.ts`, `speaker-bands.test.ts`, `keys.test.ts` (and `reading-pace.test.ts` if created) pass; a stored K40 `palette` of each of the 14 values opens the mapped paper and the old key is unchanged afterwards.
- [ ] All seven papers paint the page, the contents sheet, toasts and states from `--paper-*`; the Glass paper shows the book's field only in the top 30 %; paper ink ≥ 13:1 and muted ≥ 5.8:1 (test).
- [ ] Novel chrome dims from the paper's `Lb` (near 0.22) and carries the paper-ink tint at 12 % when Page-tinted chrome is on, none when off.
- [ ] Header, drop cap (only for a first paragraph ≥ 80 characters, word intact for selection), indents, "✦ ✦ ✦" breaks, speaker bands at 14 % with the 1.5 px underline (dashed from the 11th), the 2 s run chip, the end matter and the Next card match §8.15.2.
- [ ] Seamless next: arm at 48, lock at 72 displayed px with the `c = 0.35` rubber band; wheel 140 / 210 px with the 400 ms reset; `l` and the Next card; the URL is replaced, the old chapter is complete, the live region announces the new chapter; Auto next waits 900 ms and cancels on scroll-back.
- [ ] Chrome materialises (250 ms) and dematerialises (350 ms) with no minimise pill; hidden chrome is `inert`; it never hides with focus inside, a sheet open, `data-sr="on"`, or within 30 s of a key press.
- [ ] The novel column shows the `text` cursor and every chrome control `pointer` (§7.40).
- [ ] Paged mode paginates with `paginateNovel` (one page = the page-sized box, text at the measure), re-paginates without losing the paragraph, and turns with Slide (1:1, 50 % projection, the `0 0 8px rgba(0,0,0,0.45)` edge shadow scaled by progress), Lift (clone, `rotateY` to −100° at 1600 px perspective, specular band, un-dimming page beneath, no bitmap) and Fade (160 ms); the three tap presets work at their band edges; Reduce Motion forces Fade.
- [ ] Pinch steps once per ×1.15 with `detent.tick`, never scales the text visually, shows "Text size N", reflows once on release, and is ignored while the page is browser-zoomed.
- [ ] The Aa sheet has every row of H with its range, default, step and scope caption; the paper ripple spreads from the chosen orb on the `page` spring (a 200 ms cross-fade under reduced motion).
- [ ] Contents: pre-scrolled to the current chapter, go-to with the "No chapter 480 in this book." line, windowed rows, offline and error states; desktop left panel, tablet and phone sheet.
- [ ] Desktop: both panels re-centre the column on `sheet`, the column never goes below 48 ch (the second panel closes the first with the toast), `F6` cycles, Esc closes a panel and returns focus.
- [ ] Text menu: desktop menu (selection end, right-click, `shift+F10`) and the mobile-web action capsule; Copy, Bookmark this paragraph (toast with "Add note"), Play from here (only when audio exists; `p` toggles), React (six bubbles, arc, `reaction.send`, failure and offline states), Recommend (absent until `web/43`'s sheet exists).
- [ ] Every state of J renders in the paper colours (screenshots).
- [ ] Keyboard: every binding of K works with no mouse; the Esc order is exact; the reading region takes focus on entry.
- [ ] Hit targets: every control in the chrome, the action capsule, the sheets and the panels is at least 44 × 44 CSS px (Playwright `getBoundingClientRect()` walk at 390 × 844 and 1440 × 900).
- [ ] Reduced motion (`emulateMedia({ reducedMotion: "reduce" })` and `data-motion="reduced"`): chrome 150 ms fades, Book open and Dive 200 ms cross-fades, Novel next 200 ms, Fade turns only, paper change 200 ms, rubber band as a hard stop, no reaction arc; pinch and drags still track 1:1.
- [ ] Solid glass (`data-solid="on"`) and Increase contrast (`data-contrast="more"`) snapshots show `solid1` chrome with the 1 px rim and the `hcBorder` respectively.
- [ ] Budget: `useGlassCount().glass` never exceeds 5 on the novel reader in the e2e walk.
- [ ] Literata and Atkinson load only on the novel screen (network log: none on `/` and `/library`).
- [ ] Per-skin difference: with `mm-skin-debug=cinematic` the Cinematic novel reader at the same URL is unchanged (screenshot before and after) and its tests pass; nothing under `frontend/src/skins/cinematic/**` changed except import paths from the A3 move.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (at or above the floor plus the new tests) and `npm run build` (0 errors, 0 warnings) are green.

## Verification

**RAM guard (production shares this box).** Before every heavy command (build, the vitest suite, `next dev`, a Playwright run) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
```

`00-baseline.md` records lint and build at 0 errors and 0 warnings; keep them there. This step changes nothing in `mobile/` or `backend/`: check each of your commits with `git show --stat --format= <hash>` (the parallel `mobile/36` session and the backend and shared sessions commit `mobile/` and `backend/` on the same branch, so never judge by the branch diff). If one of your commits touched them, revert that part and prove the baseline with `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 tests pass, or the current higher count) and `cd backend && .venv/bin/python -m pytest -q --no-header`, one at a time after the RAM guard.

**Visual proof.** Start the dev stack from `backend/scripts/README-dev-stack.md` with `MM_NOVELS_ENABLED=1` (uvicorn 127.0.0.1:8010, dev SQLite only), then `free -m && npm run dev -- -p 3010`. Use a live novel chapter when a novel source answers from this box; otherwise install `web/14`'s fixtures with `node scripts/proof.mjs --fixtures e2e/fixtures/novel` (run `node scripts/proof.mjs --help` first; its real flags win). Capture in the named session `web-36`, skin forced with the `mm-skin-debug=glass` cookie, headless Chromium at 1440 × 900 and 390 × 844 (touch emulation on the phone size), into `docs/redesign/proof/web-36/`:

- `paper-{void,ink,night-paper,dusk,moss,rosewood,glass}-desktop.png` (chrome shown on two, hidden on the rest), `paper-void-phone.png`, `paper-glass-phone.png`.
- `header-dropcap-desktop.png`, `scene-break-desktop.png`, `speaker-bands-desktop.png`, `run-chip-phone.png`, `end-matter-desktop.png`, `next-locked-phone.png` (mid-pull at the 72 px lock).
- `faces-{literata,sans,atkinson}-desktop.png`, `paged-{desktop,phone}.png`, `slide-midturn-phone.png`, `lift-midturn-desktop.png`, `lift-midturn-phone.png`, `taps-one-hand-phone.png`, `pinch-capsule-phone.png`, `line-guide-phone.png`.
- `type-sheet-phone.png`, `type-panel-desktop.png`, `paper-ripple-mid-phone.png`, `contents-{desktop,phone}.png`, `contents-no-match-phone.png`, `panels-both-desktop.png`, `panels-toast-desktop.png` (at 1100 px wide), `go-to-percent-phone.png`.
- `menu-desktop.png`, `action-capsule-phone.png`, `reaction-picker-desktop.png`.
- `state-{loading,offline,error,empty,saved-copy,end-of-download,rate-limited,unavailable}-desktop.png` (a `page.route` fixture per state: a 3 s delayed chapter for loading, `context.setOffline(true)`, a 500, an empty `paragraphs` array, `cache.stale: true`, the offline end with the next chapter not saved, a 429 with `Retry-After: 12`, a 404 `source_not_found`).
- `reduced-motion-desktop.png`, `solid-desktop.png`, `contrast-desktop.png`, `landscape-phone.png` (844 × 390), `cinematic-{before,after}-desktop.png`, and `network-log.txt` (font requests on `/`, `/library` and the novel screen).

`frontend/e2e/glass-novel.spec.ts` (run with `free -m && E2E_BASE_URL=http://127.0.0.1:3010 npx playwright test e2e/glass-novel.spec.ts --workers=1`) asserts the hit targets, the Esc order, focus on entry, the reduced-motion checks, the budget and the 48 / 72 px pull thresholds. Write `docs/redesign/proof/web-36/report.md` mapping every screenshot to its acceptance item. Stop `next dev` and the dev stack afterwards.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the A3 move alone (only when A3 applies); preferences with tests; pace; papers; frame and body; end matter and pull; chrome; paged mode and turns; pinch and line guide; the Aa sheet; contents; the text menu; states and keys; the spec and proof. Stage your paths explicitly (`git add frontend/src/skins/glass/screens/novel …`), never `git add -A` or `git add .`; the mobile, backend and shared sessions commit in the same checkout.
- Conventional messages (`feat(web-glass): novel reader lift turn`). No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. Done items by scope letter (A to L), and anything not done with the reason.
2. The screenshot folder `docs/redesign/proof/web-36/` and its file list; whether live novel data or fixtures were used.
3. Test counts: vitest files and cases before and after; the Playwright spec result; lint and build results; the `free -m` available figure before each build.
4. The exact API you leave for `web/37`, `web/41`, `web/43` and `web/44`: the `GlassListenBridge` shape, the chrome slot arrays, the top-centre slot, the end-matter slot, the right-panel tab array, the Aa row array, `useKeepAwake`, the keys reducer entry points.
5. Decisions made where the contract was silent (the `dusk` paper mapping, the Taps row in the Aa sheet, the pinch capsule, the reaction flight target before `web/43`), and any place where `glass/DESIGN.md` overrode this file.
6. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/web/37-glass-listen-mode.md` (`docs/redesign/prompts/mobile/36-glass-novel-reader.md` runs in parallel).
