# Web Cinematic novel reader "The page"

Track: web · Order 45 · Depends on: `docs/redesign/prompts/web/13-cinematic-manga-reader-paged-readall-panels.md` · Proof folder: `docs/redesign/proof/web-14/`

## Goal

Build the Cinematic novel reader, "The page", on the web client: a text column painted edge to edge in one of seven dark paper stocks (including the book's own "Issue" colour), with an in-page running head, the chapter opener, a body set in one of five reading faces with a Bodoni drop cap, scene-break rules and speaker-tinted dialogue, the end matter and seamless next chapter, solid stock-coloured chrome that fades (never slides), scroll and paged reading with Cut / Slide / Fade turns on a new skin-neutral engine command `paginateNovel` (CSS multi-column), the "Text and page" Type sheet, the Contents sheet, bookmarks, keys, gestures and every state. The three extra reading faces (`skins/cinematic/reading-fonts.ts`) load only on this screen. Before any pixels, the novel reader's logic that still lives in legacy components moves into a skin-neutral hook in a no-pixel commit (stack-decision §2.3). When you finish, the ScreenId `novel` leaves the Cinematic `PENDING` set. Listen mode is the next step (`web/15`); the ambient extras are `web/23`.

## Read first

Read these completely before planning. Where this file and `cinematic/DESIGN.md` disagree, `cinematic/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all; "Novels: Apple Books / Kindle (paper themes, typography controls, page turns)").
2. `docs/redesign/stack-decision.md` §2.2, §2.3 ("logic that lives in a widget moves first", same rule on the web), §2.6, §3 (the novel paper themes and typography stay as reader settings), §4 risk 11.
3. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.1 (the stock-painted panel rule: `ink.45` roles render the stock's `muted`), §2.1.5 (the Issue stock is derived in `tint.ts`, and its contrast test), §2.1.6 (speaker tints and paper stocks, both tables), §2.7 (icons, including `voice-31` and `text-aa`).
   - §3.1 (global type rules: `onum` in running text), §3.2 (`type.dropcap`), §3.4 (the five reading faces, their defaults and web delivery, Hyperlegible text), §3.5 (`type-dropcap` with `--para-lh`).
   - §4.2–§4.8 (the chrome fade 240 / 160 ms, `dur.pageturn`, `spring.release`, the Letter set, Folio flip, reduced motion rows "Reader chrome in / out" and "Gestures").
   - §5 (`bookmark.add`, `page.turn`, `chapter.complete`, `chapter.next`, `select`) and §6 (`set`, `turn`, `done`).
   - §7.9, §7.11 (toasts in the Page frame use the stock), §7.16 (the novel contents row), §7.17, §7.18, §7.19, §7.20, §7.21, §7.23, §7.24 (rating card), §7.29 (`folioLabel()`).
   - §8.0.1 (the Page frame), §8.0.3 (row `novel`: `/novels/:sourceId/:seriesKey/:chapterKey` with `?page&para&at&listen=1`), §8.0.4, §8.0.10.
   - §8.14.2 (Column wipe and Dip entries, back target), §8.14.6 ("The end" block), §8.14.12 (the Margins panel the novel reuses).
   - §8.15 entire (§8.15.1 to §8.15.9).
   - §10.1.2 (`End of chapter 12` is a Letter set), §11 (rows: tap zones 25 / 50 / 25, horizontal swipe in novel paged and novel scroll, over-scroll 140 px at the novel scroll bottom, left-edge vertical swipe), §14.1, §14.3 (speaker tints are never the only signal), §14.4, §14.5, §14.6, §14.7 (the novel body's absolute size range), §15.2 (`fonts.ts`, `reading-fonts.ts`), §15.6, §15.7.
4. `docs/redesign/glass/DESIGN.md` §15.4 (the `paginateNovel(measure, type)`, `pageIndex`, `pageCount` row: "Paged novels: web CSS multi-column pagination"; Glass's novel reader, `web/36`, will call the command you add).
5. `docs/redesign/inventory/web.md` §1 (R21), §2.9 (the "Novel reader" bindings), §10.3 (NR1–NR19, NT1–NT7), §18.7 (A74–A86), §19.3 (K40–K44).
6. `docs/redesign/inventory/capabilities.md` §1 (`cache.stale`, rate limits, 18+ absence), §13 (novel progress uses paragraph buckets), §15 (bookmarks: `media_type: "novel"`, `snippet`, `anchor_stale`), §19.1 and §19.2 (chapter text, attribution, `text_fingerprint`), §24.
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/proof/web-12/report.md` and `docs/redesign/proof/web-13/report.md` (the reader components and engine API you reuse: `openReader`, `SidePanelLayout`, `EdgeHud`, `EndStates`, `UpNextRail`, `CircleReaders`, `SpeedRuler`).
9. Code: `frontend/src/features/novels/` (all `.ts` files, and read `components/NovelReader.tsx`, `NovelChapterView.tsx`, `NovelTypePanel.tsx` to find the logic you must extract), `frontend/src/skins/cinematic/reading-fonts.ts` and `fonts.ts` (from `web/01`), `frontend/src/skins/cinematic/tint.ts` (Issue stock derivation from `web/04`), `frontend/src/skins/cinematic/screens/reader/`, `frontend/src/features/bookmarks/`, `frontend/src/features/offline/`, `frontend/scripts/proof.mjs`.

## Preconditions

- `git log --oneline -20` shows the `web/13` commits; `npm run test` in `frontend/` is green (record the file and case counts as your floor).
- `frontend/src/skins/cinematic/index.ts` lists `novel` in `PENDING` and no longer lists `reader` or `readAll`.
- `tint.ts` exports the Issue-stock derivation (`grep -n "issue" -i frontend/src/skins/cinematic/tint.ts`); if it does not, add it in this step with its test (§2.1.6: page = `ambient.tint`; ink = `ink.100` mixed 10 % toward `ambient.ink` in OKLab, then lightened in 0.01 L steps until ≥ 13:1 on the page; muted = `ambient.ink` darkened in 0.01 L steps until 5.5:1 on the page).

## Skills to invoke

1. `superpowers:writing-plans` before any code; plan at `docs/redesign/proof/web-14/plan.md`.
2. `superpowers:test-driven-development` for the extraction, `paginate.ts`, the preference migration and the pure helpers.
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). At most 6 implementer subagents, one heavy command at a time, their work verified against `git status` and `git diff`.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for the page typography (this screen is the skin's best argument for Newsreader and Bodoni Moda: measure, leading, the drop cap, hanging nothing, no ornament beyond the rules).
5. `superpowers:verification-before-completion` before claiming done.

## Scope: deliver every item below

### A. Skin-neutral data and engine work (no pixels, first commits)

A1. **Extract the novel reader logic** from `features/novels/components/NovelReader.tsx` and `NovelChapterView.tsx` into `frontend/src/features/novels/use-novel-reader.ts` (the novel engine): the chapter window and seamless next (swap the next chapter in at the top and replace the URL), prefetch of the next chapter, the paragraph-bucket progress save (debounced 500 ms, flushed on leave, `is_completed` on seamless next) with `furtherElsewhere` when a save answers `advanced: false`, the reading line (38 % from the top in scroll mode), bookmark capture (paragraph anchor + fraction + a 180-character snippet), stale-anchor resolution, attribution loading and the fingerprint check, `?page=&para=&at=` restore. The legacy components switch to the hook in the same commit and keep their pixels; every existing novel test stays green. The hook exposes state (`chapter`, `paragraphs`, `attribution`, `readingBucket`, `bookPercent`, `nextState`, `furtherElsewhere`, `saved`, `stale`) and commands (`next`, `previous`, `jumpToBucket`, `bookmark`, `markComplete`).
A2. **`paginateNovel(measure, type)`** (glass §15.4) with state `pageIndex` and `pageCount`: web CSS multi-column in a fixed-height container. Pure math in `frontend/src/features/novels/paginate.ts` with `paginate.test.ts`: `pageCount(scrollWidth, columnWidth, gap)`, `pageForOffset(offsetLeft, columnWidth, gap)`, the first paragraph on a page (for the bucket), page ↔ bucket mapping, clamping. The DOM hook `use-novel-pagination.ts` measures after `document.fonts.ready`, on resize (a `ResizeObserver` on the container) and on every Type change, and keeps the first paragraph of the current page on screen across re-pagination.
A3. **Preferences, extended not replaced** (`features/novels/preferences.ts`, `typography.ts`, `settings.ts`), keeping the legacy constants and fields so the legacy reader still works:
   - per book, the profile-scoped `mm.novel-preferences[{source}:{series}]`: `face` (`newsreader | literata | source-serif | atkinson | archivo`) with the read-time fallback from web K44 `fontFamily` (`serif` → `newsreader`, `sans` → `archivo`); `fontSize` now 14–40 (web K41; the legacy reader still clamps to its own 15–26 on read); `lineHeight` 1.30–2.10 step 0.05 (K42); `measure` 48–88ch step 2, default 64 (K43); new `paragraphSpacing` 0–1.2em step 0.1 (default 0), `letterSpacing` −0.02 to +0.08em step 0.01 (default 0).
   - per profile, the scoped `mm.novel-settings`: `stock` (`nitrate | ink | sepia-night | dusk | moss | rosewood | issue`) with the read-time fallback from web K40 `palette` (§2.1.6: `black`, `site`, `app`, null → Nitrate; `paper`, `soft-grey` → Ink; `sepia`, `cream`, `dusk` → Sepia Night; `midnight`, `solarized-dark`, `solarized-light` → Dusk; `forest` → Moss; `rose-pine`, `dawn` → Rosewood); new `margins` (`NARROW | STANDARD | WIDE`, default `STANDARD`), `bold` (false), `justify` (false), `layout` (`SCROLL | PAGED`, default `SCROLL`), `pageTurn` (`CUT | SLIDE | FADE`, default `CUT`), `tapZones` (`STANDARD | BOTH_MARGINS | ONE_HAND`, default `STANDARD`), `swipeChapter` (false), `brightness` (−75…0, default 0).
   - Normalisers keep unknown fields. Tests: every migration mapping, range clamps, unknown-field preservation through a legacy write, per-profile isolation.
A4. Face defaults (§3.4): size 19 desktop / 18 phone for Newsreader, Literata, Source Serif and Atkinson, 18 / 17 for Archivo; line spacing 1.60 (Newsreader, Literata, Source Serif, Archivo) and 1.70 (Atkinson). A book with no stored face uses Newsreader, or Atkinson when Hyperlegible text is on (`html[data-legible="on"]`). Put `faceDefaults(face, isPhone)` in `typography.ts` with a test.

### B. Route, frame and fonts

B1. ScreenId `novel` at `/novels/:sourceId/:seriesKey/:chapterKey` with `?page&para&at&listen=1` (keep the existing catch-all folder; decode once; encoded route builders only). `listen=1` is read by `web/15`; ignore it here.
B2. The Page frame (§8.0.1): no app chrome; everything painted in the stock. Toasts use the stock's page colour for the band and its ink for the text (§8.15.7), placed per §7.11 above the bottom bar.
B3. **Reading faces.** `skins/cinematic/reading-fonts.ts` (`Literata`, `Source_Serif_4`, `Atkinson_Hyperlegible_Next`, all `preload: false`, variables `--mm-font-literata`, `--mm-font-source-serif`, `--mm-font-atkinson`) is imported only by the novel screen (or by the novel route's layout if `web/01` already wired it there; keep that wiring). The `newsreader` face always uses `var(--mm-font-newsreader)`, never `--mm-font-text`, so Hyperlegible text never changes it; `archivo` uses `var(--mm-font-grotesk)` at `wdth` 100, `wght` 400. Check in the network log that no reading-face file loads on Tonight or Library (with Hyperlegible text off) and that each face's file loads only after it is chosen.
B4. Entry and exit reuse `web/12`'s `openReader()`: Column wipe from Tonight, the book page (`Start reading`, `Continue`, a contents row) or a recap opened from them; Dip from History, Bookmarks, Updates, Downloads, Library cuttings, Circle, the command palette and deep links; exit always by Dip; the back target is the in-app previous entry when there is one, otherwise the book page (`/sources/:sourceId/series/:seriesKey`) by Dip. Browser back gets no transition type.
B5. The reading region is focusable (`tabIndex={-1}`, `role="region"`, `aria-label="Chapter 12, 42 percent"`) and takes focus on entry; a polite live region announces "Chapter 12, The Tower · Omniscient Reader's Viewpoint" on entry and on every chapter change (drop the middle part when there is no title).

### C. Stocks (§2.1.6) — the page, painted edge to edge

| Stock | Page | Ink | Muted |
|---|---|---|---|
| Nitrate (default) | `#000000` | `#D9D6D0` | `#8A877F` |
| Ink | `#0B0B0C` | `#E6E3DD` | `#8F8C86` |
| Sepia Night | `#15110C` | `#E8D8BE` | `#9C8E78` |
| Dusk | `#0D1117` | `#D3DAE3` | `#8590A0` |
| Moss | `#0E130F` | `#D5DECF` | `#879384` |
| Rosewood | `#160E10` | `#EBD5D8` | `#A08A8E` |
| Issue | the series' `ambient.tint` | derived in `tint.ts` (≥ 13:1) | derived in `tint.ts` (≥ 5.5:1) |

C1. Use the generated tokens (`--mm-color-stock-<name>-{page,ink,muted}`); the frame sets three local custom properties (`--stock-page`, `--stock-ink`, `--stock-muted`) on its root and every part of the page, chrome, sheets and panels paints from them. Issue resolves per book at render time and falls back to Nitrate when the series has no `ambient`.
C2. Stock-painted parts (margins panel, contents sheet in the reader, the next card, the rating card, toasts) render every `ink.45` role in the stock's muted colour (§2.1.1). Add the stock pages to the surface × ink loop in `tint.test.ts` if `web/04` did not.
C3. The profile's mood grade never reaches the page.

### D. Layout (§8.15.1)

D1. Desktop: a single text column at the chosen measure (default 64ch, range 48–88ch) centred in the viewport; the stock colour runs to the window edges.
D2. Phone (< 768): the column fills the width minus the margin preset (`NARROW` 16, `STANDARD` 24, `WIDE` 48 px).
D3. Landscape phone and tablet: the measure-limited column centred inside the safe rectangle; no chrome control inside a horizontal inset (§2.2.2).
D4. **In-page running head** inside the page at the top of the chapter: the series title and the chapter kicker on the left in `type-kicker` (stock muted), the `42%` folio on the right in `type-folio`; it fades out as it scrolls away (opacity follows its distance from the top over 120 px; a plain scroll-away under reduced motion).

### E. The chapter (§8.15.2)

E1. **Opener**: kicker `CHAPTER 12` in `type-kicker` (stock muted); the title in Bodoni Moda Roman at 1.9 × the body size (stock ink, `opsz` = min(size, 96), sentence case, `text-wrap: balance`) as the page's `h1`; a 48 px rule (1 px stock muted); a line of facts in `type-folio` (`3.4K WORDS · 14 MIN`). The `Listen │ 14 MIN` button is added by `web/15`.
E2. **Body**: the chosen face at the chosen size (absolute px, 14–40) and leading; `font-feature-settings: "onum"` in Newsreader, Literata and Source Serif; paragraphs indented 1.3em except the first and any paragraph after a scene break; `paragraphSpacing` adds space between paragraphs and removes the indent when > 0; `letterSpacing` applies to the body only; `bold` sets `wght` 520 (400 → 520, §8.15.5); `justify` sets `text-align: justify; hyphens: auto` (otherwise ragged right and `hyphens: manual`); `text-wrap: pretty`; `lang` from the chapter when known, else `en`.
E3. **Drop cap**: the first paragraph, only when it is ≥ 80 characters, gets a Bodoni Moda `wght` 800 drop cap three lines tall through `::first-letter` (`initial-letter: 3` where `CSS.supports("initial-letter", "3")`, otherwise `float: left` at `calc(var(--para-lh) * 3)` with `opsz` min(size, 96) and `margin-right: 0.08em`), in the stock ink, so the word stays intact for screen readers and text selection. The host sets `--para-lh` on the paragraph.
E4. **Scene breaks**: a paragraph of ≤ 12 ornament characters (`*`, `#`, `~`, `•`, `·`, `-`, `—`, `=`, `◇`, `❖`, `⁂`, spaces) renders as a centred 32 px rule (1 px stock muted) with 24 px above and below, `role="separator"`.
E5. **Speaker tints** (§2.1.6, §8.15.2): only when `attribution.attributed` is true and its `text_fingerprint` matches the text on screen. The cast order (by line count, busiest first) assigns slots 1–10:

| Slot | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Hue | `#7CC4FF` | `#FF8A7A` | `#9BE08A` | `#D6A3FF` | `#FFC266` | `#6FE3D6` | `#FF9FCB` | `#C9B38A` | `#A6B4FF` | `#E0E0A0` |

   Slots 11+ reuse 1–10 with a dotted underline. Each attributed run gets its slot colour as a 2 px underline at 70 % (`text-decoration: underline 2px color-mix(in srgb, var(--mm-color-speaker-N) 70%, transparent)`, `text-underline-offset: 0.18em`, `dotted` for 11+) and a 12 % background; the text keeps the stock ink; narration is never tinted. Hover shows the speaker's name after 500 ms in a §7.2-style tooltip (`KIM DOKJA` in `type-kicker`); on touch a 450 ms press on a tinted run shows the same name in a small popover (tinted runs set `-webkit-touch-callout: none`; untinted text keeps native selection); screen readers hear a visually hidden "Kim Dokja:" span before the run. Put the slot assignment in `speaker-slots.ts` with a test (ordering, the 11th speaker, stale fingerprint returns no tints).
E6. **End matter**: 96 px of space, a 96 px rule, `End of chapter 12` in `type-section` through `SetHeading` (the Letter set), the facts line (`READ IN 14 MIN`), the reactions slot (an optional node, filled by `web/22`), then the **next card** in stock colours: kicker `NEXT`, `Chapter 13` in Bodoni Moda (`type-subhead` size), the chapter title, `→`, the whole card one link (Enter or click advances seamlessly). Without a next chapter: "You've reached the last chapter this source has published."; for a Completed book whose last chapter completes, `web/12`'s **The end** block in stock colours (`THE END`, "You finished {title}.", the `Up next` rail, `Mark as done`). Then the links `Previous chapter` and `Back to the book`.
E7. **Seamless next**: over-scrolling 140 px at the bottom (wheel and touch; `scrub.boundary`), `l`, or the next card marks the chapter complete (`chapter.complete`, sound `done`) and swaps the next chapter in at the top with the URL replaced (no navigation, no wipe); the live region announces the new chapter.

### F. Chrome (§8.15.3)

F1. Tap or click anywhere toggles the chrome; it fades in 240 ms (`dur.line`) `ease.settle` and out 160 ms (`dur.beat`) `ease.lift`, never slides (the bars are solid); hidden chrome is `visibility: hidden`. A click toggles only if, after `mouseup`, the selection is collapsed and the pointer moved ≤ 4 px since `mousedown`.
F2. Solid stock-coloured bars with a 1 px rule in the stock muted colour at 30 %:
   - **Top** (52 px, plus `env(safe-area-inset-top)` on phones): back (`arrow-left`, "Back to the book"), the running title (`type-nav`, stock muted, `{SERIES} · CHAPTER 12`), the offline mark (`wifi-slash`) when reading a saved copy, then contents (`list-numbers`, `o`), bookmark (`bookmark-simple`; Fill when saved), on desktop fullscreen (`corners-out` / `corners-in` while fullscreen; `f`; rendered only when `document.fullscreenEnabled`), type (`text-aa`, `t`), on desktop the margins toggle (`note-pencil`, `m`). The voices button (`voice-31`) is inserted by `web/15` and the soundscape indicator by `web/23`: keep the buttons in an ordered array.
   - **Bottom** (52 px + `env(safe-area-inset-bottom)`): previous chapter; the progress folio `42% · 6 MIN LEFT` in `type-folio` (a tap cycles chapter %, book %, time left; `g` or a 450 ms press turns it into a number field `42 %` where Enter jumps to that paragraph bucket and Esc cancels); next chapter; a 1 px progress hairline along the top edge of the bar in the stock ink. The auto-scroll button is added by `web/23`. Time left uses `features/novels/reading-time.ts` (250 wpm until `web/23` adds the measured pace).
F3. Auto-hide: hides on downward scroll ≥ 24 px, shows on upward ≥ 56 px, at chapter end, or on tap; desktop also shows on pointer movement into the top 72 px or bottom 96 px; while focus is inside the chrome it never auto-hides; when a command hides it while it holds focus, focus moves to the reading region.
F4. **Margins panel** (desktop and tablet, `m` and `note-pencil`): `web/12`/`web/13`'s right side panel in the stock colours (page background, 1 px stock-muted rule at 30 %), contents tabs `NOTES · CIRCLE · VOICES`: NOTES lists this chapter's bookmarks and notes with `Add a note to this paragraph`; CIRCLE reuses `CircleReaders` from `web/13` with the spoiler guard (unsealed on chapter complete); VOICES is added by `web/15` (render the tab list so `web/15` appends it). The text column recentres in the remaining width in 320 ms `ease.turn`; reduced motion fades in place and recentres at once.
F5. Hit areas: every chrome button is `bare` with a 44 × 44 px hit on coarse pointers and ≥ 32 × 32 px on desktop; tooltips and `aria-label`s on every icon-only button.

### G. Reading modes and page turns (§8.15.4)

G1. **Scroll** (default): one continuous column with seamless next (E7).
G2. **Paged** (Type sheet → Layout): the chapter paginated by `paginateNovel` into viewport-height columns at the chosen measure; page folio `p. 7 of 22` (this chapter) at the bottom centre in `type-folio` stock muted, spoken "page 7 of 22".
G3. Page turns: `CUT` (default, 0 ms), `SLIDE` (280 ms `dur.pageturn` `ease.settle`, finger-tracked on touch through the same `shouldCommitTurn` rule as `web/13`: 72 px or 600 px/s; releases with `spring.release`), `FADE` (160 ms). No curl in this skin. Sound `turn` if on. Reduced motion: every turn is a 150 ms opacity cross-fade.
G4. Tap zones: `STANDARD` 25 / 50 / 25 % (back / menu / forward); `BOTH_MARGINS` ("Both margins advance": both 25 % side zones go forward, the centre is menu); `ONE_HAND` (left 25 % back, the top 12 % across the full width menu, the rest forward). In scroll mode a tap only toggles the chrome. Pure mapping in `tap-zones.ts` with a test.
G5. Progress is always saved as the paragraph bucket (1–100) at the reading line: 38 % from the top in scroll mode, the first paragraph on the page in paged mode.
G6. Keys and wheel in paged mode: `j`/`Space`/`→` forward, `k`/`Shift+Space`/`←` back, one page per wheel gesture with a 200 ms idle reset, `Home`/`End` chapter start and end.

### H. Type sheet "Text and page" (§8.15.5)

H1. Opened by `text-aa`, `t` and `,`. Phones: a `[0.5, 0.92]` sheet; desktop: a 352 px popover under the `text-aa` button (max height `min(640px, 100vh − 52px − 24px)`, scrolling inside, the `TEXT AND PAGE` kicker row sticky, `Esc` or an outside click closes). Painted in the current stock so the preview is honest. Every change applies live under it; steppers roll their digits (Folio flip).
H2. Rows, exactly:

| Control | Range | Default | Scope |
|---|---|---|---|
| Face | Five tiles, each label set in its own face: `Newsreader`, `Literata`, `Source Serif`, `Atkinson Hyperlegible`, `Archivo`; a caption under Atkinson reads "Designed for low vision"; the chosen tile has a 2 px `spot` frame | Newsreader (Atkinson when Hyperlegible text is on) | per book |
| Size | 14–40 px, stepper step 1 (`=`, `-`) | the face default (A4) | per book |
| Line spacing | 1.30–2.10, stepper step 0.05 | the face default (A4) | per book |
| Measure | 48–88ch, stepper step 2 | 64 | per book |
| Margins (phones only) | `NARROW · STANDARD · WIDE` (16 / 24 / 48 px) | Standard | per profile |
| Paragraph spacing | 0–1.2em, stepper step 0.1 | 0 (indents) | per book |
| Character spacing | −0.02 to +0.08em, stepper step 0.01 | 0 | per book |
| Bold text | switch (wght 400 → 520) | off | per profile |
| Justify and hyphenate | switch | off (ragged) | per profile |
| Layout | `SCROLL │ PAGED` | Scroll | per profile |
| Page turn | `CUT │ SLIDE │ FADE` (paged only) | Cut | per profile |
| Tap zones | `STANDARD │ BOTH MARGINS ADVANCE │ ONE HAND` (paged only) | Standard | per profile |
| Swipe sideways to change chapter | switch (scroll layout, coarse pointers only) | off | per profile |
| Fullscreen | switch, rendered whenever `document.fullscreenEnabled` is true, at every width | off | session |
| Stock | Seven 48 × 48 swatches, each showing "Aa" in its own ink on its page, the chosen one with a 2 px `spot` frame: Nitrate, Ink, Sepia Night, Dusk, Moss, Rosewood, Issue (drawn in this book's `ambient` colours; hidden when the series has no `ambient`) | Nitrate | per profile (Issue resolves per book) |
| Reset | a `quiet` `Reset text and page`, which restores every row above to its default at once | — | — |

   The `AMBIENT` group (auto-scroll, speed, resume, soundscape, volume) is appended by `web/23`: keep the rows as an ordered array. Each row states its scope in a `type-caption` line (stock muted): "Saved for this book", "Saved for this profile", "For this reading only".
H3. Semantics: face tiles and stock swatches are `role="radiogroup"` with `aria-checked`; swatches are named ("Sepia Night"); steppers are buttons with `aria-label` ("Larger text", "Smaller text") and a polite live value; everything reachable by `Tab`, arrows within groups.

### I. Contents sheet (§8.15.6)

I1. Opened by `list-numbers` and `o`. Phones: a `[0.5, 0.92]` sheet pre-scrolled to the current chapter; desktop and tablet: the left column panel (`web/12`'s `SidePanelLayout` left slot) in the stock colours. Build it with a `stock | null` prop: with `null` it is a standard §7.9 sheet (`paper.2`, `rule.2` top edge, `spot.wash` current row) so the book page (`web/11`) can reuse it for its go-to (do not change `web/11`'s screen in this step).
I2. Kicker `CONTENTS`; a compact go-to field ("Chapter number", `inputMode="decimal"`; Enter jumps to the first match; typing shows up to 30 matches and "and 12 more"; no match reads "No chapter 480 in this book."); then contents rows (§7.16 novel variant: ordinal `type-folio` right-aligned → title in Newsreader 16 → dot leaders → length `12 MIN` → state mark: `42%` in `spot`, `READ`, the headphones glyph when narrated from `GET /novels/audio/series`, the §7.18 download mark), virtualised with `@tanstack/react-virtual`, pre-scrolled to the current chapter on its `spot.wash` band (`aria-current="location"`). A tap opens that chapter by Dip.
I3. States as notices: loading (10 greeked rows), offline ("The contents need a connection to load."), error (`CORRECTION` + `Try again`).

### J. Bookmarks and notices (§8.15.7)

`b` or the bookmark button saves the paragraph at the reading line plus its fraction and a 180-character snippet through `POST /reader/bookmark` (`media_type: "novel"`), with no dialog (sound `set`); the toast offers `Add a note` (a note field inline in the toast's place, Enter saves). Stale anchors open at the nearest paragraph with the toast "The text here changed. Opened at the nearest paragraph." Failure: "Couldn't save that spot." with the `proof` edge.

### K. Keys (§8.15.8) — register a "Novel reader" group in `lib/keyboard`

| Key | Action |
|---|---|
| `h` / `l` | Previous / next chapter |
| `j` / `k`, `Space` / `Shift+Space` | Scroll or page forward / back |
| `Home` / `End` | Chapter start / end |
| `=` `+` / `-` / `0` | Text size up / down / reset to the face default |
| `t`, `,` | Type sheet |
| `o` | Contents |
| `b` | Bookmark |
| `m` | Margins panel (desktop and tablet) |
| `g` | Go to %: turns the bottom bar's folio into a number field |
| `f` | Fullscreen |
| `Esc` | Close sheet or panel → back to the book |

`p`, `[`, `]`, `Shift+[`, `Shift+]` and the Listen meaning of `<` / `>` are `web/15`; `a` and the auto-scroll meaning of `<` / `>` are `web/23`. The escape order gains "collapse the full player" in `web/15`: write it as a pure reducer (`keys.ts` + test) that `web/15` extends. The "Single-key shortcuts" setting disables every unmodified binding; the global `g`-then-number sequence is disabled here.

### L. Gestures (§8.15.8, §11)

Tap toggles the chrome (scroll) or acts by zone (paged); a 450 ms press on a speaker-tinted run shows the speaker's name (E5); horizontal swipe turns pages in paged mode and, when `swipeChapter` is on, changes chapter in scroll mode (≥ 72 px or 600 px/s, within 30° of horizontal, starting ≥ 24 px from both edges; Dip-free: the next chapter swaps in as in E7); a left-edge (12 %) vertical swipe changes `brightness` (−75 … 0) with `web/12`'s `EdgeHud` over a pointer-transparent `#000000` overlay at alpha `|v|/100`; over-scroll 140 px at the bottom opens the next chapter; browser back is the back gesture.

### M. States (§8.15.9) — every one

| State | Presentation |
|---|---|
| Loading | The page in the stock colour with 12 greeked lines at the body's line height (`color.galley` bars at the §7.17 ragged widths, Flicker at half strength: opacity 0.775 ↔ 1, 1400 ms half-period; static at 0.8 under reduced motion, §4.8) |
| Offline | Reads the saved copy; the top bar shows `wifi-slash`; at the end of the last saved chapter the end matter reads "End of the downloaded copy." with `Back to Downloads` in place of the next card |
| Error | Notice "Couldn't load this chapter." + `Back to the book` |
| Not available (removed source or series, or hidden by the gate) | The §8.0.10 `NOT IN THIS ISSUE` notice in the stock colours, identical for every cause |
| 18+ book | The rating card (§7.24) at the top-left of the page for its 3000 ms hold, in the stock colours |
| Empty | "This chapter came through empty — usually a page that was pulled or is still being published." |
| Stale text | Speaker tints (and, in `web/15`, follow-along) are withheld when the fingerprint does not match |
| Rate limited | The `SLOW DOWN` band with the live `Retry-After` countdown |
| Further on another device | Toast in stock colours "You're further ahead on another device (CH 214, 38%). Jump there?" with `Jump` (8000 ms) |
| Saved copy (`cache.stale` true) | A `SAVED COPY · 3 H` micro badge in the top bar (1 px stock-muted outline, stock-muted text) with the tooltip "The source is down; this is the last copy we saved." |

## Out of scope here (owned by later steps)

- `web/15`: the opener's `Listen │ 14 MIN` button, `p`, the voices button and `VOICES IN THIS CHAPTER (5)` line, the VOICES tab, the mini player and full player, `[` `]` `Shift+[` `Shift+]`, `?listen=1`, the follow-along highlight.
- `web/19`: the `PREVIOUSLY ON` chip on the first page.
- `web/22`: reactions in the end matter, `Recommend this series…`.
- `web/23`: the Type sheet `AMBIENT` group, auto-scroll (`a`, the bottom-bar button, the chip, pace), the soundscape and its `waveform` indicator.
- App-only: "Auto next chapter" advancing after 900 ms, system bars, iOS edge swipe, Android back.

## File layout

```
frontend/src/skins/cinematic/screens/novel.tsx                 ScreenId novel
frontend/src/skins/cinematic/screens/novel/
  NovelReader.tsx         composition: engine hook, frame, chrome, sheets, panels, keys
  PageFrame.tsx           stock custom properties, data-stock handling, brightness overlay
  stocks.ts               the stock table, K40 fallback, Issue resolution (+ stocks.test.ts)
  InPageHead.tsx          D4
  ChapterOpener.tsx       E1
  ChapterBody.tsx         E2–E5 (paragraphs, drop cap, scene breaks, tints, tooltips, SR spans)
  speaker-slots.ts        E5 (+ speaker-slots.test.ts)
  EndMatter.tsx           E6
  TopBar.tsx, BottomBar.tsx, ProgressFolio.tsx     F1–F3
  NovelMarginsPanel.tsx   F4
  PagedColumns.tsx        G2–G3
  tap-zones.ts            G4 (+ tap-zones.test.ts)
  TypeSheet.tsx, type-rows.ts                      H
  NovelContents.tsx       I (stock | null)
  keys.ts                 K (+ keys.test.ts)
frontend/src/features/novels/use-novel-reader.ts               A1 (+ tests of its pure parts)
frontend/src/features/novels/paginate.ts (+ paginate.test.ts), use-novel-pagination.ts   A2
frontend/src/features/novels/preferences.ts, settings.ts, typography.ts (extended, + tests)   A3, A4
frontend/src/features/novels/components/NovelReader.tsx, NovelChapterView.tsx          switched to the hook (legacy pixels unchanged)
frontend/src/skins/cinematic/tint.ts (+ tint.test.ts)          Issue stock, only if missing
frontend/src/skins/cinematic/index.ts                          remove novel from PENDING
docs/redesign/proof/web-14/                                     plan.md, screenshots, report.md
```

## Acceptance criteria

- [ ] The extraction commit changes no legacy pixels (legacy screenshots before and after match) and every existing novel test passes.
- [ ] `novel` is removed from the Cinematic `PENDING` set; the completeness test passes.
- [ ] All seven stocks paint the page, chrome, sheets, panels and toasts from the stock properties; Issue follows the book's `ambient` and is hidden without it; K40 values migrate per the table; `tint.test.ts` asserts the Issue ink ≥ 13:1 and muted ≥ 5.5:1 over the 1,440-case loop.
- [ ] The five faces render in their own face on the tiles and in the body; the three extra faces load only on this screen and only when chosen (network log in the report); Hyperlegible text makes Atkinson the default for books with no stored face and never changes a book stored as `newsreader`.
- [ ] Opener, drop cap (only for a first paragraph ≥ 80 characters, intact word for screen readers), indents, scene-break rules, speaker tints with hover names (500 ms), touch popovers and hidden SR prefixes, end matter with the Letter set, and the next card all match §8.15.2.
- [ ] Seamless next swaps the next chapter in at the top with the URL replaced, by over-scroll 140 px, `l` and the next card; the live region announces it.
- [ ] Chrome fades in 240 ms and out 160 ms with no slide, in both motion settings; a click inside a text selection or after a drag of more than 4 px does not toggle it; auto-hide follows 24 / 56 px; focus inside the chrome prevents hiding.
- [ ] Paged mode paginates with `paginateNovel` (no clipped lines, re-paginates on resize and Type changes keeping the current paragraph), shows `p. 7 of 22`, turns with Cut, Slide (finger-tracked) and Fade, and honours the three tap-zone presets.
- [ ] The Type sheet has every row of H2 with its range, default and scope caption; the popover is 352 px on desktop with a sticky kicker row; a `[0.5, 0.92]` sheet on phones.
- [ ] Contents: the go-to field matches up to 30 with "and 12 more" and "No chapter 480 in this book."; rows show narrated and saved marks; the current chapter sits on its `spot.wash` band; offline and error notices render.
- [ ] Bookmark by `b` with no dialog, `Add a note` in the toast, stale-anchor toast copy exact; progress saves the paragraph bucket at the reading line in both modes.
- [ ] Every state of M renders in the stock colours (screenshots).
- [ ] Keyboard: every key of K works with no mouse; the escape order is exact; the reading region takes focus on entry.
- [ ] Hit targets: every control in the bars, sheets and panels is ≥ 44 × 44 px on a coarse pointer and ≥ 32 × 32 px on desktop (Playwright `getBoundingClientRect()` check).
- [ ] Reduced motion: chrome fades only (it never slides anyway), page turns are 150 ms fades, the Letter set is a 200 ms fade, the panel fades in place; leader dials keep running.
- [ ] Per-skin difference: with `mm-skin-debug=legacy` the legacy novel reader and its type panel still work at the same URLs and still read their legacy fields.
- [ ] `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build` in `frontend/` are green, with counts at or above the precondition floor plus the new tests.

## Verification

**RAM guard.** Before every heavy command run `free -m`; if the `available` figure of the `Mem:` row is under 1024 MB, stop and report. Never run two builds at once, never `next build` while `next dev` runs, one heavy command at a time.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
```

Lint and build stay at 0 errors and 0 warnings (`00-baseline.md`). This step changes nothing in `mobile/` or `backend/` (`git diff --stat -- mobile backend` is empty), so `flutter analyze`, `flutter test` (Flutter at `/srv/manhwamaniacs/dev/flutter/bin`) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header`) are not rerun.

**Visual proof.** Start the dev stack from `backend/scripts/README-dev-stack.md` with `MM_NOVELS_ENABLED=1` in its environment (127.0.0.1:8010, dev SQLite only) and `free -m && npm run dev -- -p 3010`. Open a chapter from a healthy novel source (find one with `GET /sources` where `content_kind` is `novel`). If no novel source answers from this box, register Playwright route fixtures for `GET /novels/chapter`, `GET /novels/attribution` and `GET /sources/{s}/series/{k}` from `frontend/e2e/fixtures/novel/` (`chapter.json` holding a public-domain chapter, the first chapter of Lewis Carroll's *Alice's Adventures in Wonderland*, split into paragraphs, and `attribution.json` tinting three speakers with the matching `text_fingerprint`), and add a `--fixtures <dir>` option to `frontend/scripts/proof.mjs` that installs them. Capture in the named session `web-14`, skin `cinematic` via the `mm-skin-debug` cookie, at 1440 × 900 and 390 × 844, into `docs/redesign/proof/web-14/`:

- `novel-{nitrate,ink,sepia-night,dusk,moss,rosewood,issue}-desktop.png` (chrome shown on one of them, hidden on the rest) and `novel-nitrate-phone.png`, `novel-issue-phone.png`.
- `novel-opener-dropcap-desktop.png`, `novel-scene-break-desktop.png`, `novel-speaker-tooltip-desktop.png`, `novel-speaker-popover-phone.png`, `novel-end-matter-desktop.png`, `novel-the-end-desktop.png`.
- `novel-faces-{newsreader,literata,source-serif,atkinson,archivo}-desktop.png`.
- `novel-paged-{desktop,phone}.png`, `novel-paged-slide-midturn-phone.png`, `novel-paged-one-hand-bands-phone.png`.
- `novel-type-popover-desktop.png`, `novel-type-sheet-phone.png`, `novel-contents-{desktop,phone}.png`, `novel-contents-no-match-phone.png`, `novel-margins-desktop.png`, `novel-progress-field-desktop.png`, `novel-brightness-hud-phone.png`.
- `novel-{loading,offline-end,error,not-available,empty,rate-limited,saved-copy,rating-card}-desktop.png` (use route fixtures, a 500, a 429 with `Retry-After: 12`, and `cache.stale: true` as needed).
- `novel-reduced-motion-desktop.png`, `novel-legacy-desktop.png`, and `network-log.txt` (the font files requested on Tonight, on the novel screen, and after choosing Literata).
- `docs/redesign/proof/web-14/report.md`: each screenshot with the acceptance item it proves.

Stop `next dev` and the dev stack afterwards.

## Git

- Branch `feat/vps-slim-source-native`; the extraction first as its own no-pixel commit, then pagination with tests, preferences with tests, then each screen part, then the proof. Stage paths explicitly, never `git add -A` or `git add .`.
- No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with"); never commit secrets or `.claude/`.
- `npm run build` (after `free -m`) before every push; `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`; do not deploy.

## Report back

1. Done items by scope letter A–M, and anything not done with the reason.
2. Screenshot folder `docs/redesign/proof/web-14/` and its file list; whether live novel data or fixtures were used.
3. Test counts (vitest files and cases before and after), lint and build results, `free -m` before each build.
4. The exact API of `useNovelReader()` and `paginateNovel` (names, arguments, state fields) for `web/15`, `web/23` and the Glass novel reader (`web/36`).
5. The network-log summary for the reading faces.
6. Open issues and any place where `cinematic/DESIGN.md` overrode this file (for example the tap-zone preset row and the novel swipe switch placed in the Type sheet).

Next prompt: `docs/redesign/prompts/web/15-cinematic-listen-mode.md`.
