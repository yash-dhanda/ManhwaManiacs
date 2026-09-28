# Cinematic DESIGN.md: recheck round 2, web lens

Rechecked 2026-09-28 against `cinematic/verify/judge-web.md` ("Confirmed", 33 findings; WEB-23 and WEB-31 were refuted and are not rechecked), the fix log `cinematic/verify/fixed-web.md` (rounds 1 and 2) and the round 1 recheck `cinematic/verify/recheck-web-1.md`. For each finding I read the section the final fix names, compared it with the fix text, grepped for the old value, and grepped every other place the changed value is repeated. Other lenses were still writing to DESIGN.md while this ran (4,645 lines at the start, 4,646 at 22:54 UTC), so a final marker pass was run on the live file just before writing this; every marker below was still present. Section numbers are used because line numbers keep moving.

**Result: 33 resolved, 0 unresolved.** Both round 1 leftovers (WEB-1, WEB-30) are now fixed, and the two round 2 follow-ups (WEB-16 in §9.4.1, WEB-22 in §8.14.10 and §11) are in place and agree with their source sections.

## Round 1 leftovers, now resolved

### WEB-1: one chapter announcement string

- §8.14.3 Auto-hide: reveal only on `g` `,` `[` `]` `?` or focus entering the chrome (`Tab` / `Shift+Tab`); every other reader key is listed as never revealing it; `m` and `c` keep their own rules; auto-hide (scroll and 3000 ms idle) is suspended while focus is inside the chrome (web `:focus-within`, Flutter `FocusScopeNode.hasFocus`); focus moves to the reading surface before `m`, `c` or a page click hides the chrome. Cinema mode repeats "never while focus is inside it".
- §14.4 Route changes: a reader route focuses the reading surface (`tabIndex={-1}`, `role="region"`, `aria-label="Chapter 143, page 1 of 40"`), and the polite live region announces "Chapter 143, The Return · Solo Leveling" (title part dropped when there is none: "Chapter 143 · Solo Leveling"), stated as the only chapter announcement string.
- §14.5 now says the reader announces chapter changes "through the §14.4 live region, with the §14.4 string", quoting the same text.
- §14.4 Hidden chrome bullet: "Chrome never auto-hides (idle or scroll) while focus is inside it", which matches §8.14.3.
- Old values gone: "on any key", "running head's title" as the reader focus target, "Chapter 142 · Solo Leveling", "Chapter 142, page 1 of 40", and the old §14.5 "Chapter 143, The Return" format. The remaining "THE RETURN" hits (§8.14.5 seam band, §8.14.6 pull-to-continue caption) are visual labels, not announcements.

### WEB-30: registry groups in sidebar order

§8.30.2 row 12 now reads "named by its masthead title in sidebar order (§7.15 Items; Sources and Catalogue sit under Discover, where they light in the §7.15 route table: Tonight, Library, Updates, Discover, Sources, Catalogue, Downloads, Collections, History, Bookmarks, Dialogue, The Numbers, Circle, Picks, Profiles, Settings, System status), then Series page, Reader, Novel reader, Listen, Recap, The Annual". This matches §7.15 Items (`01 Tonight` … `12 Picks`, then footer `Profiles`, `Settings`, `Status`) and the §7.15 route table (`/sources`, `/sources/:id` light `04 Discover`). §8.33.2 still points at row 12.

## Resolved

| ID | Where it lives | Checks |
|---|---|---|
| WEB-1 | §8.14.3 Auto-hide, §14.4, §14.5 | See above. |
| WEB-2 | §1 Breakpoints, §7.15 Width / `Below 1280` / `Collapse toggle`, §8.0.1 Desktop row, §8.0.9 intro | Every spine range reads 768–1279 (§1, §7.15, §8.0.1, §8.0.9). The remaining `768–1023` hits are the 8-column grid (§1, §8.0.1, §8.0.9, §8.8 Tablet, §8.14.1 Tablet row), never the spine. `localStorage['mm.sidebar']` defined once. `z.panel`, `scrim.modal`, `sidebar-simple` exist. |
| WEB-3 | §8.33.3, §7.11 Position and `Reader and Page frames` | Banner at bottom-left of the content column, 24 px from the bottom, max 560, "the toast anchor of §7.11", which matches §7.11 Position. "max 672" is gone. The reader row (bottom-centre, max 560, 16 px above the highest bottom element, 24 px when chrome hidden, stock colours in the novel reader) agrees with §8.15.7. |
| WEB-4 | §7.7 Caption modes, §8.22 Grid | Wall is "(onboarding)" only; "Discover genres" and "source catalogue on desktop" are gone. §8.22 Grid is caption mode **Below**, title on 2 lines (`type.title`), no folio line. |
| WEB-5 | §8.8 trailer scrub bullets | Breadcrumb hides while the strip is pinned; below 1440 the search trigger collapses to a 44 px `bare` `magnifying-glass` with the platform `mod+k` keycap, `Previously on` moves into `dots-three`, title truncates at 120 px; phone strip layout present with a 44 (48 Android) hit. |
| WEB-6 | §8.0.1 line under the frames table | Spine kept at any height; below 500 px of height the section list scrolls (`overflow-y: auto`) and footer items fold into `dots-three`. No "hidden below 500 px" rule left. |
| WEB-7 | §7.15 route table and the feature/book/recap rule; §7.13 breadcrumb | All 16 rows as written. Shell state instead of `history.state`; cold-load rule; The Annual excluded as a Takeover. §7.13's `No. 02 · LIBRARY / SOLO LEVELING` fits the rule. |
| WEB-8 | §8.0.6 "The `g` sequence"; §7.15 Folio jump | 1500 ms arm, 600 ms second-digit wait, `Enter`, cancel keys, `G 1_` chip at the toast anchor, swallowed digits. Every bare-digit binding it names still exists: Library `1`–`7` (§8.9), Discover `1`–`5` (§8.20), feature `1`–`4` (§8.17), The Numbers `1`–`4` (§9.2.1), Circle `1`–`5` (§9.3.2). |
| WEB-9 | §8.0.6 "`Delete`" | `Delete` or `Backspace`, no modifier, ignored in fields, `⌫` / `Del` keycap. |
| WEB-10 | §8.23 "Web activity and removal"; §8.23 Keys | `mm-offline/state`, `Stop` / `Stop all`, no Pause, Resume or queue on the web, deferred `remove-chapter` with 8000 ms Undo, `REMOVING…` in `ink.30`, `pagehide` flush. `p` is app-only in Keys. |
| WEB-11 | §8.9 Phone layout | WALL 3 / COMPACT 4 (web 600–767 and app tablets 5 / 7), 72 px phone LIST row, COMPACT without captions at every width. Agrees with "Wall: 3 columns (tablet 5)". |
| WEB-12 | §7.7 corner rule and four state rows; §8.9 Card behaviour and Manual order | Each control has its own corner. The select square outline sits on `color.onart`, which §2.8.1 defines as `rgba(0,0,0,0.64)`, the fix's value. `Selected` keeps the check square top-right. |
| WEB-13 | §8.10 Keys | `r` reloads the list (as §11 and §7.29), `c` runs `Check now` (as §8.31 Keys). |
| WEB-14 | §8.17 item 3 | Aside from 1024 px, `top: calc(56px + 48px + 16px)`; below 1024 it points at §8.0.9, whose Feature page row puts At a glance at the top of DETAILS. |
| WEB-15 | §8.14.12 "Narrow desktops"; §8.14.1 Desktop web | "middle 6 columns" is gone; "never less than 480 px" matches `clamp(480px, 46vw, 860px)` and the 480–860 slider in §8.14.8. |
| WEB-16 | §8.14.11 row; §9.4.1 Chapter boundaries | Row present as written. §9.4.1 now pauses auto-scroll at the unloaded next chapter band and resumes when its pages land, matching the row. |
| WEB-17 | §7.10 arm-delay list and `Single unfollow` row | "remove from library" is out of the arm-delay list; only "unfollow in bulk" remains. Toast held for `dur.hold.toast.action` = 8000 ms (§2.8.4). Updates FOLLOWING and the feature `+` key both say toast with Undo. |
| WEB-18 | §8.30.2 row 10, §5 intro, §15.2 `haptics.ts` | All three `localStorage['mm.haptics']` mentions agree. `Feel it` is app-only in row 10 and "absent on the web" in §5. |
| WEB-19 | §8.14.8 `CONTROLS`, §8.15.5 row, §8.15.3 Top | Gated on `document.fullscreenEnabled` at every width in both sheets; `corners-out` / `corners-in` before `text-aa` in the novel desktop top bar. |
| WEB-20 | §8.0.5 Long-press on images | Callout suppression for every long-press target listed; `contextmenu` `preventDefault()` in the phone frame. |
| WEB-21 | §7 preamble "Cursors (web)" | All five rules present in one bullet. No `w-resize` / `e-resize`. |
| WEB-22 | §8.14.5; §8.14.10 Double tap row; §11 Double tap / Reader row | 250 ms / 24 px rule and the side-zone exception in §8.14.5 and §8.14.10. §11 carries the side-zone exception and points at §8.14.5. |
| WEB-24 | §7.6 Letter; §8.20 genre tiles; §8.8 `Sources` tiles; §8.24 Block states; §9.3.2 dispatches; §7.21 Checkbox, Radio; §7.13 breadcrumb | Hover and pressed present on all seven surfaces. |
| WEB-25 | §8.30.1 "Pushed pages on desktop", "Folios" | Present; web runs 01…14 because Server (13) and Diagnostics (15) are app sections in §8.30.2. |
| WEB-26 | §7.13 profile chip; §7.11, §7.15 | 32 px avatar (a §7.25 size). No "`type.ui` 15" anywhere. |
| WEB-27 | §9.1.3 Aside; §8.10 Aside | Picks at 1024–1439 follows the §8.0.9 Picks row (aside under the ask block). Updates non-admins leave columns 9–12 empty. |
| WEB-28 | §7.8 Preview slate and `Slate focus` rows | 24 px clamp, grow inward at rail ends; focus rules in the `Slate focus` row agree with the fix. |
| WEB-29 | §15.2 View transitions, Home route, Web app manifest; §8.0.3 `tonight`; §12.3 Web | `experimental: { viewTransition: true }`; manifest values in `manifest.ts`, `orientation` deleted; §12.3 says "no `orientation` key". The redirect gate is the same two-cookie `missing` list (`mm-skin`, `mm-skin-debug`) in §8.0.3 and §15.2, a superset of the fix's one-cookie gate that also lets the pre-flip debug row reach Tonight. The only `manifest.webmanifest` left is the sentence saying there is none. |
| WEB-30 | §8.30.2 row 12, §8.33.2 | See above. |
| WEB-32 | §7.26, §7.13 search trigger, §8.32 404 | Platform rule for shortcuts in copy; `Ctrl K` off Mac; phone-frame sentence. The remaining `⌘` hits are `Ctrl`/`⌘` + wheel, which is correct. |
| WEB-33 | §8.15.5 popover, §8.15.3 | `min(640px, 100vh − 52px − 24px)` with a sticky kicker; pointer reveal zones and the click-versus-selection rule. |
| WEB-34 | §8.9 toolbar and Continue; §8.0.3 `library` | `Clear filters` in the toolbar; 12-cutting rail (4 / 5 visible); `/library/browse` opens the Filters sheet once on mount on phones. |
| WEB-35 | §8.33.4 | Exclusion list names Library, `/search`, `/sources`, `/sources/:id`, feature and book pages, the readers and takeovers. |

## Observations outside this recheck (not caused by the web fixes)

- **§8.8 strip tab order contradicts itself.** The "Focus during the scrub" bullet (and §14.4) say the now-showing strip's controls join the tab order at `p` ≥ 0.8, but the implementation paragraph right after it says "The strip's controls enter the tab order only when `p` = 1." This comes from the accessibility lens, not a web fix. Suggest deleting the "only when `p` = 1" sentence or changing it to `p` ≥ 0.8.
- **§8.33.3 reader wording** (still open from round 1): it opens with "the user is not on Updates or in a reader" and ends with "In the novel reader it appears in the stock colours at the top edge". One of the two has to go.
- **§8.23 "Paused — this browser is out of room"** is still listed as a web chapter status next to "The web has no Pause, Resume". The fixer kept it as an inventory quota state; "Stopped — this browser is out of room" would avoid implying a resume control.
- **§14.4 reading-surface label is manga-shaped.** `aria-label="Chapter 143, page 1 of 40"` applies to "a reader route", which includes the novel reader in scroll mode, where there are no pages. A novel form such as "Chapter 143, 42 percent" would close it.
- **§8.30.1 Folios wording.** "since Server and Diagnostics are app-only" sits next to the slug list's "`diagnostics` (app; web only with `?debug=1`, §8.0.7)". The no-gaps rule still numbers correctly when the debug row shows (About becomes 15), so this is wording only.
- **1280 px has no breakpoint token.** §7.15 and §1 switch the sidebar at 1280, but §2.8.2 has no `bp.*` entry for it, so Tailwind has no named variant. Media queries use literals, so this is documentation only.
