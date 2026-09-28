# Cinematic DESIGN.md: recheck round 1, web lens

Rechecked 2026-09-28 against `cinematic/verify/judge-web.md` ("Confirmed", 33 findings; WEB-23 and WEB-31 were refuted and are not rechecked) and the fix log `cinematic/verify/fixed-web.md`. For each finding I read the section the final fix names, compared it with the fix text, grepped for the old value, and grepped every other place the changed value is repeated. Other lenses were still writing to DESIGN.md while this ran (it grew from 4,527 to about 4,580 lines), so I ran a final marker pass on the live file just before writing this. Section numbers are used instead of line numbers because the lines kept moving.

**Result: 31 resolved, 2 unresolved (WEB-1, WEB-30).** Neither blocks a build: each is a one-sentence wording conflict.

## Unresolved

### WEB-1: the chapter announcement has two different strings

The applied fix is complete. §8.14.3 Auto-hide reveals the chrome only on `g` `,` `[` `]` `?` or on focus entering the chrome, lists every other reader key as never revealing it, suspends both the scroll hide and the idle hide while the chrome holds focus, and moves focus to the reading surface before a command hides it. §14.4 now focuses the reading surface on reader routes and adds the polite live region. "on any key" is gone. The §14.4 "Hidden chrome" bullet, which for a while still allowed the downward-scroll hide while focus was inside the chrome, now reads "Chrome never auto-hides (idle or scroll) while focus is inside it", which agrees with §8.14.3.

**Contradiction.** §14.4 says the live region announces **"Chapter 142 · Solo Leveling"** (chapter and series title). §14.5, which predates this round, says "The reader announces chapter changes (**"Chapter 143, The Return"**) but not page changes" (chapter and chapter title). That is two formats for the same announcement.

**Fix.** Use one string in both places, for example "Chapter 143, The Return · Solo Leveling" (the chapter title is dropped when there is none), and have §14.5 refer to §14.4.

### WEB-30: "in sidebar order" does not match the list that follows it

§8.30.2 row 12 carries the fix word for word, and §8.33.2 points at it. But the sentence says the groups are "named by its masthead title **in sidebar order**", and then lists Tonight, Library, Updates, **Collections, History, Bookmarks, Discover**, Sources, Catalogue, **Downloads**, Dialogue, and so on. The sidebar (§7.15 Items) runs `01 Tonight`, `02 Library`, `03 Updates`, `04 Discover`, `05 Downloads`, `06 Collections`, `07 History`, `08 Bookmarks`, `09 Dialogue`, `10 The Numbers`, `11 Circle`, `12 Picks`, then the footer items `Profiles`, `Settings`, `Status`. The error comes from the judge's fix text, which was applied faithfully.

**Fix.** Reorder the list to match the sidebar: Tonight, Library, Updates, Discover, Sources, Catalogue, Downloads, Collections, History, Bookmarks, Dialogue, The Numbers, Circle, Picks, Profiles, Settings, System status. Sources and Catalogue sit under Discover, which is where they light up in the §7.15 route table.

## Resolved

| ID | Where it now lives | Checks |
|---|---|---|
| WEB-2 | §1 Breakpoints, §7.15 Width / `Below 1280` / `Collapse toggle`, §8.0.1 Desktop row, §8.0.9 intro | Every spine mention reads 768–1279, with 8 columns at 768–1023. No `768–1023` spine range is left anywhere. `z.panel` (30) and `scrim.modal` exist. `localStorage['mm.sidebar']` is defined once. |
| WEB-3 | §8.33.3, §7.11 `Reader and Page frames` row | "max 672" and the bottom-centre banner are gone. The banner and §7.11 Position agree on bottom-left of the content column, 24 px from the bottom, max 560. |
| WEB-4 | §7.7 Wall (onboarding only), §8.22 Grid | Wall is now used only in onboarding. §8.22 is caption mode Below, with 2-line `type.title` and no folio line. |
| WEB-5 | §8.8 trailer-scrub bullets | The breadcrumb hides while the strip is pinned. The 1440 collapse of the search trigger and `Previously on` into `dots-three` is present. The phone strip layout is present (hit area written as 44 (48 Android), consistent with §7.2). |
| WEB-6 | §8.0.1 line under the frames table | The spine is kept at any height. Below 500 px of height the section list scrolls and the footer items fold into `dots-three`. No leftover "hidden below 500 px" rule. |
| WEB-7 | §7.15 route table and the feature/book/recap rule | All 16 rows are present. The rule uses the shell's state, not `history.state`. The Annual is excluded as a Takeover. The §7.13 breadcrumb example matches. |
| WEB-8 | §8.0.6 "The `g` sequence"; §7.15 Folio jump points at it | 1500 ms arm, 600 ms second-digit wait, `Enter`, cancel keys, the `G 1_` chip at the toast anchor, swallowed digits. Checked every bare-digit page binding: Library `1`–`7`, Discover `1`–`5`, feature `1`–`4`, The Numbers `1`–`4`, Circle `1`–`5`. None is missing. |
| WEB-9 | §8.0.6 "`Delete`" | `Delete` or `Backspace`, the `⌫` / `Del` keycap. The five `Delete` key lists (Collections, Bookmarks, Downloads, Picks, AI cards) inherit it. |
| WEB-10 | §8.23 "Web activity and removal"; §8.23 Keys | `mm-offline/state`, `Stop` / `Stop all`, no Pause, Resume or queue on the web, deferred `remove-chapter` with an 8000 ms Undo, `REMOVING…` in `ink.30`, a `pagehide` flush. `p` is app-only. |
| WEB-11 | §8.9 Phone layout | Density counts per row (web 600–767 and app tablets: WALL 5, COMPACT 7). 72 px phone LIST row. COMPACT without captions at every width. |
| WEB-12 | §7.7 corner rule and 4 new state rows; §8.9 Card behaviour and Manual order | Each control has its own corner. `Selected` keeps the check square top-right. `on-art`, `bell-ringing` and `dots-six-vertical` all exist in §7.2 and §2.7. |
| WEB-13 | §8.10 Keys | `r` reloads, `c` runs Check now, matching §8.31 and §7.29. |
| WEB-14 | §8.17 item 3 | The aside starts at 1024 px with `top: calc(56px + 48px + 16px)`. Below 1024 it points at the §8.0.9 tablet row, which agrees. |
| WEB-15 | §8.14.12 "Narrow desktops"; §8.14.1 Desktop web | "middle 6 columns" is gone. The strip is never below 480 px, which matches the `clamp(480px, …)` column and the 480–860 slider floor in §8.14.8. |
| WEB-16 | §8.14.11 `Next chapter loading (strip)` | Row present as written. |
| WEB-17 | §7.10 arm-delay list and `Single unfollow` row | "remove from library" is out of the arm-delay list, and only "unfollow in bulk" is left in it. The Updates FOLLOWING, feature `+` and Quick look paths all say toast with Undo. `dur.hold.toast.action` = 8000 ms. |
| WEB-18 | §8.30.2 row 10, §5 intro, §15.2 `haptics.ts` | The three `localStorage['mm.haptics']` mentions agree. `Feel it` is app-only in §5 and in row 10. |
| WEB-19 | §8.14.8 `CONTROLS` row, §8.15.5 row, §8.15.3 Top | Gated on `document.fullscreenEnabled` at every width. The novel desktop top bar has `corners-out` / `corners-in` just before `text-aa`. |
| WEB-20 | §8.0.5 Long-press on images | Callout suppression covers every long-press target, plus `contextmenu` `preventDefault()` in the phone frame. |
| WEB-21 | §7 preamble "Cursors (web)" | All five rules are present, merged into one bullet. |
| WEB-22 | §8.14.5 | 250 ms / 24 px click-versus-double-click rule. Side zones never zoom. |
| WEB-24 | §7.6 Letter card; §8.20 genre tiles; §8.8 `Sources` tiles; §8.24 Block states; §9.3.2 dispatches; §7.21 Checkbox and Radio; §7.13 breadcrumb | Hover and pressed states present on all seven surfaces. |
| WEB-25 | §8.30.1 "Pushed pages on desktop", "Folios" | Present. The web runs 01…14 because Server (13) and Diagnostics (15) are app-only in §8.30.2. |
| WEB-26 | §7.13 profile chip, §7.11 Text | 32 px avatar. `type.ui` has no "15" anywhere. |
| WEB-27 | §9.1.3 Aside; §8.10 Aside | Picks at 1024–1439 follows the §8.0.9 tablet row. On Updates, non-admins get empty columns 9–12. |
| WEB-28 | §7.8 Preview slate and `Slate focus` rows | 24 px clamp and grow-inward at a rail's ends. The focus half is in the separate `Slate focus` row, which agrees. |
| WEB-29 | §15.2 View transitions, Home route and Web app manifest; §12.3 Web | `experimental: { viewTransition: true }`, `manifest.ts` values, `orientation` deleted. §12.3 says "no `orientation` key". The redirect gate in §8.0.3 and §15.2 is the same two-cookie `missing` list in both places. The only remaining `manifest.webmanifest` is the sentence saying there is none. |
| WEB-32 | §7.26, §7.13 search trigger, §8.32 404 | Platform rule for shortcuts in copy. `Ctrl K` off Mac. Phone-frame sentence. The remaining `⌘` hits are `Ctrl`/`⌘` + wheel, which is correct. |
| WEB-33 | §8.15.5 popover, §8.15.3 | `min(640px, 100vh − 52px − 24px)` with a sticky kicker. Pointer reveal zones and the click-versus-selection rule are present. |
| WEB-34 | §8.9 toolbar and Continue; §8.0.3 `library` | `Clear filters` in the toolbar, a 12-cutting rail (4 / 5 visible), and the Filters sheet opening on mount for `/library/browse` on phones. |
| WEB-35 | §8.33.4 | The exclusion list names Library, `/search`, `/sources`, `/sources/:id`, feature and book pages, the readers and takeovers. |

## Observations outside this recheck (not caused by the web fixes)

- §8.33.3 still opens with "the user is not on Updates or in a reader" and ends with "In the novel reader it appears in the stock colours at the top edge". This contradiction was already in the committed text. The WEB-3 rewrite of the anchor did not touch it.
- §8.23 keeps the web chapter status "Paused — this browser is out of room" next to the new "The web has no Pause, Resume" rule. This is a worker quota state, not a control, but nothing says how such a save continues. Suggest wording it as "Stopped — this browser is out of room".
- §9.4.1 says continuous auto-scroll "rolls straight through seams". §8.14.11 (WEB-16) now pauses it at an unloaded next-chapter band. The two are compatible, but §9.4.1 could point at §8.14.11.
- The §11 gesture matrix row "Double tap | Reader (strip and paged) | … | Double-click" does not mention the WEB-22 exception that a double-click on a paged side zone turns two pages instead of zooming.
- The 1280 px sidebar threshold (§1, §7.15) has no entry in the §2.8.2 breakpoint tokens. Media queries use literals, so this is documentation only.
