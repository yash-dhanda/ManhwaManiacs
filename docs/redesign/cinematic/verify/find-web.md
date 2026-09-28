# Cinematic DESIGN.md: web coverage audit (desktop 1440 px and mobile web 390 px)

Lens: every screen, element, state and interaction in `inventory/web.md`, specified for desktop web and mobile web, including keyboard shortcuts, focus behaviour, hover and pointer states. Every "missing" claim below was checked by grepping the whole of `cinematic/DESIGN.md` (4,101 lines). Style preferences are not reported. Line numbers refer to `cinematic/DESIGN.md` as of 2026-09-28.

Summary: 35 findings: 1 high, 16 medium, 18 low.

---

## WEB-1 · high · §8.14.3 Auto-hide, §14.4 Keyboard and focus

**Problem.** The manga reader's chrome rules break keyboard reading on desktop web in two ways. (a) The chrome shows "on any key" and hides after a downward scroll of 24 px or more. Every reading key (`j`, `Space`, `→`, `d`, `End`, PageDown) is a key and also scrolls the strip, so each page turn by keyboard shows the chrome (240 ms in) and then hides it (160 ms out): the bars flash on every key press. (b) §14.4 sends focus to the running head's title on entering the reader, and hidden chrome is `visibility: hidden`. Once the chrome hides, the focused element becomes unfocusable, focus falls to `<body>`, and the next Tab starts again from the top of the document.

**Evidence.** l.2001: "show after a cumulative upward scroll ≥ 56 px, at chapter end, on a centre tap, on pointer movement into the top 72 px or bottom 96 px (desktop), on any key, or on focus entering the chrome." l.2004: "Hidden chrome is `visibility: hidden` / `Offstage` so it leaves the tab order." l.3643: "a reader route focuses its running head's title". The inventory's source rule (web.md §9.3, "any key reveals") comes from a reader with no keyboard-first mandate. The owner decision asks for "keyboard-first navigation".

**Fix.** Replace "on any key" with an explicit reveal list: `Tab`, `Shift+Tab`, `m`, `,`, `g`, `?`, `[`, `]`, `Esc` (when it closes nothing else). Reading and navigation keys (`j` `k` `Space` `Shift+Space` `←` `→` `a` `d` `Home` `End` `PageUp` `PageDown` `h` `l` `=` `+` `-` `0` `p` `<` `>` `b` `c` `f` `u`) never reveal the chrome; only the scroll rule applies to them. Add: "While focus is inside the chrome (`:focus-within` on web, `Focus.of(context).hasFocus` in Flutter), auto-hide is suspended (no scroll hide, no 3000 ms idle hide). When the chrome hides by `m` or `c` while focus is inside it, focus first moves to the reading surface." Change §14.4 so that a reader route focuses the reading surface (`tabIndex={-1}`, `aria-label="Chapter 142, page 1 of 40"`) instead of the running-head title, with the chapter announced through the existing polite live region.

---

## WEB-2 · medium · §7.15 Desktop sidebar vs Conventions (l.12) and §8.0.9

**Problem.** The spine range contradicts itself. At 1024–1279 px (common laptop widths, and the whole `desktop` breakpoint below 1280) one rule says spine and two rules say expanded. Three related behaviours are also missing: what `mod+b` does inside the auto-spine range (does the 248 px sidebar push the content or overlay it?), whether the toggle state persists, and what the footer "collapse toggle" looks like.

**Evidence.** l.1209: "Width | 248 expanded; 72 collapsed (the *spine*). Auto-spine at 768–1279. `mod+b` toggles". l.12: "768–1023 is the desktop frame with the collapsed sidebar, called the *spine*". l.1558: "the desktop frame with the spine at 768–1023 px". l.1213: "Footer: `Profiles`, `Settings`, `Status` (admin), collapse toggle." (no glyph, label or tooltip). Inventory G14/G29e/A23: auto-collapse below 1024; an explicit "Expand sidebar" button; state not persisted.

**Fix.** Choose one range and write it in all three places. Recommended: auto-spine at 768–1279, and edit l.12 and l.1558 to read 768–1279. Then add: "Below 1280, `mod+b` or the toggle opens the 248 px sidebar as an overlay at `z.panel` over `scrim.modal`. It closes on `Esc`, on an outside click and on navigation, and content does not reflow. At 1280 and wider it pushes the content, and the choice is stored per device in `localStorage['mm.sidebar'] = "expanded" | "spine"`. Collapse toggle: a `bare` icon button with `sidebar-simple` 24 Light; tooltip `Collapse sidebar  ⌘B` when expanded and `Expand sidebar  ⌘B` in the spine; `aria-expanded` reflects the state."

---

## WEB-3 · medium · §7.11 Toasts vs §8.33.3 Stop-press banner

**Problem.** On desktop the toast stack and the stop-press banner are declared to be one stack, but they sit in different places, so the "banner keeps the bottom slot, a new toast rises above it" rule cannot be built. Toast placement is also undefined inside the reader frames, which have no content column. That includes the reader's own toasts ("Marked page 7", "You're further ahead on another device").

**Evidence.** l.1143: "Desktop: bottom-left of the content column, 24 px from the bottom." l.1149: "The stop-press banner (§8.33.3) is a member of the same stack, always its oldest entry". l.2789: "a subtitle-style strip bottom-centre (desktop, max 672) … holding the bottom slot of the toast stack so toasts rise above it".

**Fix.** Use one anchor. Recommended: the desktop stack (toasts and banner) sits bottom-left of the content column, 24 px from the bottom, max width 560, and the banner is drawn at that width. Add a reader rule: "In the manga and novel readers the stack is bottom-centre, 16 px above the folio bar (or bottom bar) while it shows and 24 px above the bottom edge while it is hidden. It never covers the ruler. Max width 560. The novel reader uses stock colours, as §8.15.7 says."

---

## WEB-4 · medium · §7.7 Posters (caption modes) vs §8.22 Source catalogue

**Problem.** The desktop source catalogue has two contradictory caption rules. §7.7 puts it in **Wall** mode, where there is no caption and the title appears only in the hover slate. §8.22 gives it captions below and turns hover slates off. Following §7.7 plus §8.22's "slates off" leaves the title visible nowhere.

**Evidence.** l.1059: "**Wall** (Discover genres, source catalogue on desktop, onboarding): no caption; the title appears in the hover slate and in `aria-label`." l.2517: "**Grid**: a poster wall with captions below (title 2 lines)". l.2524: "hover slates are off here (a catalogue is scanned, not browsed poster by poster)". Inventory SB8 has a 2-line title under every card.

**Fix.** In §7.7 remove "source catalogue on desktop" from the Wall list. Also remove "Discover genres", because genre tiles are 16:9 tiles with their own label (l.2464), not posters. Then state in §8.22: "Captions: **Below** mode with the title on 2 lines (`type.title` 14/20) and no folio line."

---

## WEB-5 · medium · §8.8 Scrub the trailer (now-showing strip) + §7.13 running head

**Problem.** The pinned now-showing strip cannot fit in the running head at the widths the contract claims to support, and no collapse rule is given. Desktop at 1024 px has a 72 px spine and a 952 px head. Its contents are breadcrumb (~150) + thumbnail 32 + kicker (~100) + title (min ~160) + split sm `Continue │ CH 143` (~190) + quiet `Previously on` (~110) + 280 px search trigger + 44 px bell + profile chip (~140) + 96 px margins ≈ 1,300 px. Phone at 390 px has 358 px of content width. Its contents are thumbnail 32 + kicker + title + split sm (~190) + `Previously on` (~110), which leaves under 30 px for the title.

**Evidence.** l.1795: "the now-showing strip fades in inside the running head, between the breadcrumb and the search trigger (phone: after the thumbnail, replacing the running title): the thumbnail, kicker `NOW SHOWING` …, the series title (`type.title`, one line), and on the right a `split` primary at size sm (32 px) `Continue │ CH 143` … plus `Previously on` (`quiet`)". l.1187: "Index search trigger (a 280 px `compact` field …)".

**Fix.** Add a width rule. "Desktop frame below 1440: while the strip is pinned, the breadcrumb hides and the search trigger collapses to a 44 px `bare` `magnifying-glass` button (tooltip `Search or jump  ⌘K`). `Previously on` moves into a `dots-three` overflow at the strip's right end. The title truncates with an ellipsis at a 120 px minimum. Phone frame: the strip shows the thumbnail, the title (one line, min 96 px, no kicker) and a split sm reading `▸ CH 143` (play glyph + folio, 44 px hit). `Previously on` is in a trailing `dots-three`."

---

## WEB-6 · medium · §8.0.1 Frames, §8.0.9 Landscape phones

**Problem.** A phone browser in landscape (for example 844 × 390, 932 × 430) is 768 px wide or wider, so it gets the desktop frame. Below 500 px height the desktop frame hides the sidebar "everywhere". The result is no sidebar and no thumb index: the only way to navigate is the running head's search trigger into the command palette's `GO TO` group. §8.0.9 sends landscape phones to "their tablet row", but the web frame at 768 px and up is still the desktop frame with no navigation.

**Evidence.** l.1442: "Sidebar hidden in the readers; below 500 px viewport height the desktop frame hides the sidebar everywhere." l.1437: "**Desktop** (web ≥ 768) | Every app screen | Contents sidebar (248 / 72 spine) + running head 56". l.1585: "every other screen uses its tablet row when the width is ≥ 600 px". Inventory §2.2 hides the sidebar below 500 px height **only in the reader**.

**Fix.** Change l.1442 to: "Sidebar hidden in the readers. Outside the readers the desktop frame keeps the 72 px spine at any height. Below 500 px height the spine's section list scrolls inside it (`overflow-y: auto`) and the footer items fold into a `dots-three` menu at its bottom." This keeps a navigation control in every non-reader desktop-frame state.

---

## WEB-7 · medium · §7.15 Desktop sidebar (Active), §7.13 breadcrumb, §8.0.2 Navigation map

**Problem.** The sidebar lights "only the exact section", but many routes have no sidebar item of their own, and the contract never says which item they light or which section the breadcrumb names. The unmapped routes are `/sources`, `/sources/:id`, the feature and book pages (`/sources/:s/series/:k`, `/library/:followedId`), `/library/browse`, `/profiles/manage`, `/profiles/new`, `/profiles/:id/edit`, `/library/statistics/annual/:year`, `/circle/:profileId`, `/recap/…`, `/more` and `/settings/:section`. The inventory's gap #5 (the double-lit Library) was fixed only for `/library/collections`.

**Evidence.** l.1215: "Only the exact section lights up: `/library/collections` lights `06 Collections`, not `02 Library`." l.1186: breadcrumb "`No. 02 · LIBRARY / SOLO LEVELING` … each segment is a link". Sources is reached through Discover (l.2465 "`All 89 sources →`"). No route-to-item table exists (grep `lights`, `aria-current` returns only l.1215).

**Fix.** Add a table to §7.15:

| Route | Lights | Breadcrumb section |
|---|---|---|
| `/` | `01 Tonight` | `No. 01 · TONIGHT` |
| `/library`, `/library/browse` | `02 Library` | `No. 02 · LIBRARY` |
| `/updates` | `03 Updates` | `No. 03 · UPDATES` |
| `/search`, `/sources`, `/sources/:id` | `04 Discover` | `No. 04 · DISCOVER` (`/ SOURCES`, `/ {source}`) |
| `/downloads` | `05 Downloads` | `No. 05` |
| `/library/collections*` | `06 Collections` | `No. 06` |
| `/library/history` | `07 History` | `No. 07` |
| `/library/bookmarks` | `08 Bookmarks` | `No. 08` |
| `/ocr` | `09 Dialogue` | `No. 09` |
| `/library/statistics*` | `10 The Numbers` | `No. 10` |
| `/circle*` | `11 Circle` | `No. 11` |
| `/library/recommendations` | `12 Picks` | `No. 12` |
| `/profiles/manage`, `/profiles/new`, `/profiles/:id/edit` | footer `Profiles` | `PROFILES` |
| `/settings*` | footer `Settings` | `SETTINGS / {section}` |
| `/admin/status` | footer `Status` | `STATUS` |
| `/more` | none | `INDEX` |

Feature and book pages light the item of the section they were entered from, carried in `history.state.from`. Without it, `02 Library` lights when the series is followed and `04 Discover` otherwise. The breadcrumb follows the same rule (`No. 04 · DISCOVER / SOLO LEVELING`).

---

## WEB-8 · medium · §7.15 Folio jump, §8.0.6 Global web keys

**Problem.** `g` then a number is ambiguous for two-digit sections. After `g 1` the implementation cannot know whether to jump to `01` at once or wait for `0`, `1` or `2`. No timeout, pending indicator or cancel rule is given. It is also unstated that digits consumed by the sequence must not reach page handlers, which also bind bare digits: Library `1`–`7`, Discover `1`–`5`, feature page `1`–`4`, The Numbers `1`–`4`, Circle `1`–`5`.

**Evidence.** l.1218: "`g` then a number jumps to that section (`g 1` … `g 12`; `g 0` Settings)". l.1523: "`g` then `1`…`12` / `0`". Page digit keys: l.1862, l.2411, l.2478, l.2980, l.3112.

**Fix.** Add: "`g` arms a sequence for 1500 ms. `g 2`…`g 9` and `g 0` jump at once. `g 1` waits 600 ms for a second digit (`0`, `1` or `2`, giving `10`, `11`, `12`) and otherwise jumps to `01`; `Enter` jumps to `01` at once. Any other key, `Esc` or the timeout cancels. While armed, a keycap chip `G 1_` shows bottom-left of the content column (the toast anchor) and fades 160 ms after the sequence ends. Keys consumed by the sequence are never delivered to page-level bindings."

---

## WEB-9 · medium · §8.11, §8.13, §8.23, §9.1.1, §9.1.3 keys (`Delete`)

**Problem.** Several desktop actions are bound to `Delete`. On Mac keyboards the key labelled delete sends `Backspace`, and forward delete needs `fn`, so these bindings never fire for Mac users.

**Evidence.** l.1927 "`Delete` removes the focused member (dialog)"; l.1955 "`Delete` remove"; l.2566 "`Delete` remove focused chapter"; l.2823 "keyboard `Delete`"; l.2880 "`Delete` = Not for me on the focused card". grep `Backspace` / `⌫` finds nothing.

**Fix.** Define one binding for every one of these: "`Delete` or `Backspace` (no modifier, ignored in fields). The keycap renders `⌫` on Mac and `Del` elsewhere." Add it to the §8.0.6 conventions so later screens inherit it.

---

## WEB-10 · medium · §8.23 Downloads (desktop and mobile web)

**Problem.** Desktop web inherits the phone "Activity" block ("the same order"), which has `Pause all` / `Resume all`, `Cancel all`, `Show queue` with `Retry` and `Remove from queue`, and a `p` key for pause/resume. Chapter `Remove` gets an 8 s Undo. The web's download engine is the service worker, whose protocol has only `save-chapter`, `cancel-save`, `remove-chapter`, `get-state`, `sweep`, `set-retention`, `clear-scope`, `mark-*` and `skip-waiting`. It has no pause, resume or queue, and once `remove-chapter` runs the cached pages are gone, so Undo would mean a full re-download. The mobile-web "absent, not disabled" list does not mention any of these controls, so an implementer has to guess.

**Evidence.** l.2543: "controls: `Pause all` / `Resume all`, `Cancel all` …; `Show queue ⁽⁸⁾` expands queue rows". l.2546: "`Remove` (swipe left or trash; toast with Undo for 8 s)". l.2553: "Desktop web layout. The same order in 12 columns: meter and activity in columns 1–8". l.2566: "`p` pause/resume all". l.2551 lists what the web lacks without naming these. Inventory §12.2 lists the service-worker protocol messages.

**Fix.** Add a web delta to §8.23: "On the web the Activity block lists the saves reported by `mm-offline/state` (series, `CH 12 · 7/40 PAGES`, a determinate rule), each with `Stop` (`cancel-save`), plus `Stop all` (a `cancel-save` for each save). There is no Pause, Resume or queue on the web, and `p` is not bound there. Web chapter `Remove` defers the `remove-chapter` message until its 8000 ms Undo toast expires. Meanwhile the row shows `REMOVING…` in `ink.30`, and Undo cancels the pending message. Leaving the page flushes pending removals."

---

## WEB-11 · medium · §8.9 Library (density on phones and compact captions)

**Problem.** Density is offered on phones (in the Filters sheet), but only the WALL column count is given for phone and tablet widths. COMPACT has no phone or tablet column count, and LIST has only a desktop layout (seven columns: title, status badge, progress, new count, last read, favourite star, notify bell). Seven columns cannot fit in 358 px. COMPACT's caption content is not specified at any width (the inventory's LB11 is "title only (xs), no row actions").

**Evidence.** l.1846: "wall 6 per row at desktop (8 at wide), compact 8 (12), list rows 72 px with 48 × 72 covers and columns for title, status badge, progress `CH 12 OF 40`, new count, last read, favourite star, notify bell." l.1852: "toolbar collapses to … a `Filters` quiet button opening a sheet (favourites, new only, sort, density, reading status) … Wall: 3 columns (tablet 5)".

**Fix.** Add: "Phone (< 600): WALL 3 per row, COMPACT 4 per row. LIST rows are 72 px: 48 × 72 cover, then title (`type.title`, 2 lines) over a folio caption `CH 12 OF 40 · 3 NEW`, then the reading-status badge at the trailing edge; favourite, notify and last read live in Quick look. Tablet widths 600–767 (web phone frame): WALL 5, COMPACT 7, LIST as phone. COMPACT at every width: no caption below, the title in `aria-label` and in a 500 ms tooltip on desktop, no hover icons, badges limited to `NEW`."

---

## WEB-12 · medium · §7.7 Posters (select mode), §8.9 Card behaviour

**Problem.** Four Library wall states are missing or collide. (a) An **unselected** poster in select mode has no visual; only "Selected" is specified, so nothing shows what can be selected. (b) On desktop hover, the favourite star and notify bell sit "at the top-right", which is where the select check square sits, and the manual-order drag handle appears "on hover" with no position. (c) A favourited series is invisible at rest: badges are `NEW`, status, `18`, `SAVED`, `TEXT`. The inventory's LB16 keeps the star visible when favourited. (d) The inventory's hover-revealed checkbox (LB14, clicking it enters selection) has no counterpart, and no rule says the hover icons hide in select mode.

**Evidence.** l.1074: "Selected (select mode) | 24 px `ink.100` check square at top-right". l.1854: "Hover (desktop) reveals favourite star and notify bell as `on-art` icon buttons at the top-right." l.1847: "posters show a drag handle on hover". l.1063: badge list. Inventory LB14, LB16.

**Fix.** Add these rows to §7.7. "Select mode, unselected: a 24 px square with a 1 px `ink.100` outline on `rgba(0,0,0,0.64)` at top-right, 4 px inset, on every poster; hover icons are hidden while select mode is on. Hover icons (not in select mode): favourite at top-right (4 px inset), notify 8 px to its left. Desktop hover also reveals the empty select square at top-left under the badge stack; clicking it enters select mode with that poster selected. Manual-order handle: a 40 px `on-art` `dots-six-vertical` at bottom-right. Favourited at rest: a 12 px `star` Fill in `spot` leads the caption folio (`★ CH 142 · 3 NEW`), with `aria-label` "Favourite"."

---

## WEB-13 · medium · §8.10 Updates keys vs §11 Gesture matrix and §7.29

**Problem.** On desktop Updates, `r` means two different things. §8.10 binds `r` to `Check now`, a server-wide check of every followed series. The gesture matrix and §7.29 make `r` the desktop equivalent of pull to reprint, which on Updates only reloads the list. §8.10 itself says the two must differ.

**Evidence.** l.1891: "`r` check now". l.3516: "Pull down past the top (96 px) | Tonight, Library, Updates (reloads the list) … | `r`, overflow `Refresh`". l.1885: "pull to reprint reloads the list (it does not start a server check; `Check now` does)". l.1404: "desktop web: `r` key and a Refresh item in the page's overflow menu".

**Fix.** Updates keys: "`r` reloads the list (reprint); `c` runs `Check now`." This matches System status (l.2748: "`c` runs `Check now`").

---

## WEB-14 · medium · §8.17 Series page, CHAPTERS + At a glance (1024–1439)

**Problem.** Between 1024 and 1439 px, which covers most laptops, the At a glance block (reading-status select, tags, shelves, time spent, OCR coverage) is placed "below the list". The list is the virtualised schedule of every chapter, often more than 200 rows, so the only desktop control for reading status is effectively unreachable. Phones and tablets put At a glance at the top of DETAILS instead.

**Evidence.** l.2385: "**CHAPTERS** (8 columns) + **At a glance** aside (4 columns, ≥ 1440; below the list on smaller screens)". l.2387: "Windowed list (virtualised) for long series." l.1570 (tablet) and l.2401 (phone): "At a glance at the top of DETAILS".

**Fix.** Show the aside from 1024 px: "CHAPTERS spans columns 1–8, At a glance columns 9–12, `position: sticky; top: calc(56px + 48px + 16px)` (running head + contents tabs + 16). Below 1024 the tablet rule applies (top of DETAILS)." At 1024 with the spine the aside is about 269 px wide, which fits the numeral and the slug-line select.

---

## WEB-15 · medium · §8.14.1, §8.14.8, §8.14.12 Reader side panels on desktop

**Problem.** (a) Both side panels at their 320 px minimum do not fit next to the strip's 480 px minimum below about 1216 px. At 1024: 1024 − 96 margins − 640 = 288 px for the strip, below the 480 minimum, and the panels "never overlap the strip on desktop". (b) On desktop, Reading setup is "a right column panel" and the Margins panel (`]`) is also on the right. No rule covers both being open.

**Evidence.** l.1966: "The strip column is `clamp(480px, 46vw, 860px)` … Two optional side panels …, each 3 columns (min 320 px) … With both open the strip keeps the middle 6 columns." l.2179: "never overlap the strip on desktop". l.2069: "a right column panel on desktop". l.2175: "Right, "Margins" (`]`)".

**Fix.** Add to §8.14.12: "If `viewport − 2 × grid margin − open panels` would drop below 480 px, opening a panel closes the panel on the other side (last opened wins, 320 ms Panel motion). Reading setup takes the right slot: opening it hides Margins, and closing it restores Margins if Margins was open. `[` / `]` state is still remembered per profile, but on screens where both panels cannot fit, only the most recently opened one is restored."

---

## WEB-16 · medium · §8.14.5, §8.14.6, §8.14.11 Continuous strip: next chapter loading

**Problem.** In the default continuous strip the next chapter "is already stitched below", but the time while it is still loading (its manifest has not arrived) has no state. The inventory's RD9 has "pulsing dot + '{Ch N} is on its way…'". The contract covers the previous chapter loading (top band), next failed, and end of series, but not next loading.

**Evidence.** l.2031: top-of-strip loading `Loading CH 141…` only. l.2048: "Continuous strip (default): the next chapter is already stitched below, so step 4–5 are replaced by the chapter seam". l.2052: next failed. The §8.14.11 states table has no next-loading row. Inventory RD9.

**Fix.** Add a row to §8.14.11: "Next chapter loading (strip) | Below the seam, a 96 px band of ground: `CH 143 IS ON ITS WAY` in `type.kicker` `ink.45` with a 16 px leader dial after 400 ms. After 8 s the caption adds "This source can take a while." The band keeps 128 px of bottom padding so the folio bar never covers it. Auto-scroll pauses at the band and resumes when the pages land."

---

## WEB-17 · medium · §7.10 Dialogs (arm-delay list) vs §8.9, §8.10, §8.17

**Problem.** The contract contradicts itself on whether removing a single series from the library is confirmed. §7.10 lists "remove from library" among the destructive confirms that open with the 1000 ms arm. The Library Quick look, the Updates FOLLOWING tab and the feature page `+` key all remove at once, with a toast and Undo.

**Evidence.** l.1132: "(delete profile, remove from library, delete shelf, … unfollow in bulk, …)". l.1854: "Remove from library ("Your reading progress is kept", toast with Undo …)". l.1881: "`Unfollow` (quiet `proof`, toast with Undo)". l.2411: "`+` follow / unfollow toggle (asks nothing, toast with Undo)".

**Fix.** Remove "remove from library" from the §7.10 list and add: "A single unfollow or remove from library never opens a dialog. It commits at once with the toast "Removed {title}." + `Undo` held for `dur.hold.toast.action` (8000 ms). Only `Unfollow` in bulk asks first."

---

## WEB-18 · low · §5 Haptics, §8.30.2 row 10 Feedback (mobile web)

**Problem.** Android Chrome mobile web vibrates for five events, but the only "Haptic feedback" switch is marked "app", so mobile-web users cannot turn vibration off.

**Evidence.** l.814: "Mobile web: Android Chrome gets `navigator.vibrate` for the five events". l.2673: "Haptic feedback (K13, app; default on; **per device**)".

**Fix.** Row 10: "Haptic feedback: app, and web when `'vibrate' in navigator` and `(pointer: coarse)`. On the web it is stored per device in `localStorage['mm.haptics']` (`on` default, `off`), and `haptics.ts` checks it before calling `navigator.vibrate`. Hidden on iOS Safari and desktop. `Feel it` stays app-only."

---

## WEB-19 · low · §8.14.3, §8.14.8, §8.15.3 Fullscreen on mobile web and in the novel reader

**Problem.** The manga reader's fullscreen control exists only on desktop, although the inventory offers it at every width "when supported" (RD27, and RD41 in the sheet), and Android Chrome supports it. The novel reader binds `f` to fullscreen, but its chrome has no fullscreen button, so on phones there is no path at all.

**Evidence.** l.1998: "and on desktop fullscreen (`corners-out`)". l.2281: novel "`f` | Fullscreen". l.2211: the novel top bar has no fullscreen item. Inventory RD27, RD41.

**Fix.** Add a `Fullscreen` / `Exit fullscreen` switch row to Reading setup → CONTROLS and to the Type sheet, shown on the web whenever `document.fullscreenEnabled` is true, at every width. Add `corners-out` / `corners-in` to the novel top bar on desktop, just before `text-aa`.

---

## WEB-20 · low · §7.14 Thumb index long-press, §8.0.5 mobile web

**Problem.** Long-press on thumb-index tabs, source rows, chapter rows and picker avatars opens app menus, but `-webkit-touch-callout: none` is specified only for images. On iOS Safari a long-press on a link (the tabs are links) opens Safari's link preview, which fights the app menus.

**Evidence.** l.1201: "Long-press | Library → Updates; Downloads → the queue; Index → Switch profile." l.1512: "Posters, covers, cuttings and reader pages set `-webkit-touch-callout: none; user-select: none; -webkit-user-drag: none`".

**Fix.** Extend l.1512: "every element with a long-press action (thumb-index tabs, rows with row menus, source rows, profile avatars, the Listen mini player, the auto-scroll chip) sets the same three properties, and the phone frame calls `preventDefault()` on `contextmenu` for those elements only."

---

## WEB-21 · low · §7 (pointer states), §8.14.7, §7.30

**Problem.** There are no pointer-cursor rules anywhere (grep `cursor` finds only the text caret). On desktop web this matters where the pointer is the only cue: the paged-mode click zones (back / menu / next), a zoomed page or the Lightbox (pan), drag handles, the ruler, and an idle cursor sitting over pages in cinema mode.

**Evidence.** l.2060: "Tap zones: 30 / 40 / 30 …". l.3487: "Click zones, same". l.1419: "pan when zoomed". No `cursor` rule in the file.

**Fix.** Add to §7: "Cursors (web): `pointer` on every clickable non-button (posters, rows, tiles, breadcrumb segments); `default` on disabled controls; `text` in fields. Reader paged click zones: `w-resize` on the back zone and `e-resize` on the next zone (mirrored for RTL), `default` in the centre. Zoomed page and Lightbox: `grab`, and `grabbing` while dragging. Drag handles: `grab` / `grabbing`. Ruler: `pointer` on the track and `grabbing` while scrubbing. In both readers the cursor hides (`cursor: none`) after 3000 ms without pointer movement while the chrome is hidden, and returns on the next move."

---

## WEB-22 · low · §8.14.5, §8.14.10, §11 (desktop click vs double-click in the reader)

**Problem.** In strip mode a click toggles the chrome, and a double-click zooms 1× ⇄ 2×. Without a click delay, every double-click also toggles the chrome twice (a flash) before zooming. Mobile web has a 300 ms / 24 px detector; desktop does not.

**Evidence.** l.2033: "Tap behaviour: the whole screen toggles chrome (default)." l.3491: "Double tap | Reader … | 300 ms / 24 px detector | Double-click".

**Fix.** "Desktop strip: the chrome-toggle click commits after 250 ms unless a second click lands within 250 ms and 24 px, which zooms instead. Paged side zones turn immediately, and a double-click on a side zone does nothing (no zoom)."

---

## WEB-23 · low · §7.11 Toasts (keyboard access)

**Problem.** Toasts with actions (Undo 8 s, "Jump", "Reload", "Open") hold indefinitely while focused, but nothing says how a keyboard user reaches a toast. The stack is not in the tab order near the trigger, and no shortcut is defined.

**Evidence.** l.1147: "indefinite while hovered or focused". l.1150: "Dismiss | … `Esc` (focused)". grep `hotkey` / `Alt+T` finds nothing. `sonner` 2.0.8 is the queue (l.1153).

**Fix.** "`Alt+T` focuses the newest toast; the region is `aria-label="Notifications (Alt+T)"` (sonner `hotkey={["altKey","KeyT"]}`). `Tab` moves between toast actions and `Esc` returns focus to where it was. List `Alt+T` under General in the keyboard sheet."

---

## WEB-24 · low · §7 and §8: hover, pressed and focus states for desktop-only clickable surfaces

**Problem.** Several clickable surfaces have no hover, pressed or focus spec, although every primitive in §7 has one: Discover genre tiles (16:9), Tonight `Sources` hub tiles (16:9 duotone), dialogue-search result blocks (the whole two-column block is clickable), Circle dispatch rows and letter cards, running-head breadcrumb segments, and checkbox and radio (only Switch has a hover row).

**Evidence.** l.2464 (genre tiles, no states); l.1785 ("16:9 duotone tiles, source name in `type.subhead`"); l.2579 ("Click (either column) → the reader"); l.3088 (dispatch rows); l.1186 ("each segment is a link"); l.1318–1319 (checkbox and radio: no hover).

**Fix.** Genre and hub tiles: hover zooms the image 1.04 inside the frame, a 2 px `ink.100` inside outline, the title underlined (200 ms `settle`); pressed scales 0.98; focus ring. Dialogue blocks: hover shows a 2 px `ink.100` left bar and the still's image at 1.04; pressed fills `paper.3`. Dispatch rows: the §7.16 row hover. Letter cards: the Feature card hover. Breadcrumb segments: `ink.100` plus a 1 px underline at 4 px offset (160 ms). Checkbox and radio: hover sets the outline to `ink.100` (80 ms); focus ring on the 20 px box.

---

## WEB-25 · low · §8.30.1 Settings structure (desktop pushed pages, numbering)

**Problem.** (a) Desktop Settings shows one section in the right pane, but `security`, `members` and `backup` are "pushed pages", and there is no desktop rendering for them: no back link, and no rule for which table-of-contents item stays lit. (b) Sections are "numbered", but on the web the app-only sections (13 Server, 15 Diagnostics) and capability-hidden rows disappear. It is unstated whether the folios renumber (as Tonight does, l.1772) or keep gaps.

**Evidence.** l.2646: "the right pane … shows one section at a time (route `/settings/:section`)". l.2648: "and the pushed pages `security`, `members`, `backup`". Rows 13 and 15 are "(app)" at l.2676 and l.2678.

**Fix.** "Desktop: pushed pages render in the right pane under a `quiet` `← {Parent section}` link above their section header, and the parent stays lit in the table of contents. Folios are assigned to the sections rendered on this client, in order, with no gaps (web: 01 Profile & account … 14 About). The slugs, not the numbers, are the stable identifiers."

---

## WEB-26 · low · §7.15, §7.11, §7.13, §7.25 (desktop values outside the token tables)

**Problem.** Desktop chrome uses sizes that contradict the role and size tables, so an implementer has to choose between the local value and the token. The sidebar label and the toast text say `type.ui` 15, but `type.ui` is 14/20 on desktop and wide. The desktop profile chip uses a 28 px avatar, which is not one of the avatar sizes.

**Evidence.** l.1213: "label (`type.ui` 15 `ink.60`)". l.1145: "`type.ui` 15 `ink.100`". l.571: "`type.ui` | … | 15/20 | 15/20 | 14/20 | 14/20". l.1187: "profile chip (28 px avatar + name". l.1364: "Circles (sizes 20, 24, 32, 44, 96, 144)".

**Fix.** Either use the role as tabled (`type.ui` 14/20 on desktop for sidebar labels and toasts) and delete the "15", or add a role `type.ui.lg` (Archivo `wdth` 100, `wght` 500, 15/20 at every breakpoint) to §3.2 and §3.5 and cite it. Change the chip avatar to 32 px (an existing size), or add 28 to the §7.25 size list.

---

## WEB-27 · low · §9.1.3 Picks aside, §8.10 Updates aside (desktop below 1440 and non-admins)

**Problem.** The Picks aside ("Your genres") is specified only at 1440 px and wider. At 1024–1439 its place is undefined: phones move it under the ask block, but desktop leaves columns 9–12 empty or unset. On Updates, desktop "uses 8 of 12 columns plus a 4-column aside" that is admin-only, and nothing says what non-admins see in columns 9–12.

**Evidence.** l.2858: "Aside (columns 9–12, ≥ 1440)". l.2860 (phone moves it). l.1876: "desktop uses 8 of 12 columns plus a 4-column aside". l.1882: "Aside (desktop, admin)".

**Fix.** Picks at 1024–1439: the ask block spans columns 1–12 and the aside renders under it as a full-width slug line. Updates for non-admins: columns 9–12 carry the schedule as credits (`LAST CHECK 21:04 · NEXT ≈ 21:34 · EVERY 30 MIN`, sticky under the tabs), so the NEW list keeps columns 1–8 at every role.

---

## WEB-28 · low · §7.8 Rails (preview slate at edges and its focus)

**Problem.** The desktop preview slate is 2.1 × the poster width and "anchored over the poster", but no edge rule exists. On the last visible poster of a rail at 1440 (7.25 visible) it overflows the right margin or the viewport. Keyboard focus while the slate is open (after `Space`) is also unspecified: can Tab reach `Read`, `+ Library` and `Details`, and where does `Esc` return focus?

**Evidence.** l.1091: "A portal overlay …, 2.1 × poster width, anchored over the poster … `Esc` closes."

**Fix.** "The slate is centred on the poster, then clamped so it stays at least 24 px inside the content columns (at the rail's ends it grows from the poster's outer edge inward). Opened with `Space`, focus moves to `Read`, `Tab` cycles `Read → + Library → Details`, and `Esc` or `Space` closes it and returns focus to the poster. Opened by hover, it takes no focus."

---

## WEB-29 · low · §8.0.3 Route contract, §8.0.4 web transitions, §12.3 (web prerequisites)

**Problem.** Three prerequisites the contract depends on are not stated, so a first web cluster would build the wrong thing. (a) `frontend/next.config.ts` currently redirects `/` to `/library` (inventory R0), which makes Tonight at `/` unreachable until it is removed. (b) React `<ViewTransition>` and `<Link transitionTypes>` are wired in Next 16.2.9 only with `experimental.viewTransition: true`, which neither DESIGN.md nor `next.config.ts` sets. (c) §12.3 names `manifest.webmanifest`, but the app generates its manifest from `src/app/manifest.ts` (currently `start_url: "/library"`).

**Evidence.** `frontend/next.config.ts` l.28–29: `redirects() { return [{ source: "/", destination: "/library", permanent: false }]; }`. DESIGN l.1461 "`tonight` | `/` | Home". l.1499 "in-app links use React `<ViewTransition>` with `transitionTypes`". grep `viewTransition` finds nothing in DESIGN.md. l.3556 "`manifest.webmanifest`: … `start_url` "/"". `frontend/src/app/manifest.ts` l.38 `start_url: "/library"`.

**Fix.** Add to §15.2: "`next.config.ts`: delete the `/` → `/library` redirect in the Tonight cluster's first commit; add `experimental: { viewTransition: true }` next to `proxyTimeout`. The manifest values of §12.3 go into `src/app/manifest.ts` (`start_url: "/"`, `id: "/"`, `short_name: "Maniacs"`, `background_color` and `theme_color` `#000000`)."

---

## WEB-30 · low · §8.33.2 Keyboard sheet, §8.30.2 row 12 (discoverability and group names)

**Problem.** (a) The inventory's topbar Keyboard button (G30c) is gone. Outside the reader, the `?` sheet can be opened with a mouse only from Settings → Keyboard, and the command palette has no "Keyboard shortcuts" action. (b) The registry's group list has 8 groups, but §8 defines keys for about 17 more screens (Tonight, Updates, Collections, History, Bookmarks, Series page, Discover, Downloads, Dialogue, Picks, The Numbers, Circle, System status, Settings, Profile picker, Recap, The Annual), so their group names and their order in the sheet are left to guesswork.

**Evidence.** l.2785: "Also reachable from the reader's setup sheet and Settings → Keyboard." l.2777: ACTIONS "(Continue {series}, Check for updates, Open settings, Toggle reading mode, Sign out)". l.2675: "grouped (General, Navigation, Library, Search, Sources, Reader, Novel reader, Listen)". Inventory G30c.

**Fix.** Add `Keyboard shortcuts  ?` to the palette's ACTIONS and to the desktop account menu (above Sign out). Replace the group list with this order: General, Navigation, Tonight, Library, Updates, Collections, History, Bookmarks, Series page, Discover, Sources, Catalogue, Downloads, Dialogue, Picks, The Numbers, Circle, Profiles, Settings, Status, Reader, Novel reader, Listen, Recap, The Annual. Each screen registers its keys under its own group name.

---

## WEB-31 · low · §8.33.1 Command palette (rows and narrow widths)

**Problem.** Only the LIBRARY group (40 × 60 covers) and SOURCES (logos) have leading visuals. GO TO, ACTIONS, EDITION and SETTINGS rows have none, and row height is unspecified (the inventory's CP6 had a 32 px visual per kind). The panel is max 720 px at 12 vh, with no rule below 768 px (mobile web with an external keyboard, or iPad split view).

**Evidence.** l.2778: "Row: leading visual, title, subtitle (`type.caption`), the `↵` glyph on the active row". l.2775: "max width 720, max height 70 vh, placed 12 vh from the top".

**Fix.** "Rows are 56 px, or 72 px for LIBRARY rows with a 40 × 60 cover. The leading slot is a 40 px box: GO TO shows the section's §2.7 icon (24 Light) with its folio as the subtitle; ACTIONS `arrow-right`; SETTINGS `gear-six`; EDITION `mm-mark`; SOURCES the 24 px logo. Below 768 px the panel is full width minus 16 px margins at 8 vh, with max height 80 vh."

---

## WEB-32 · low · §8.32 404

**Problem.** The 404 deck hard-codes the Mac glyph, and it shows even in the phone frame, where no keyboard shortcut applies.

**Evidence.** l.2756: "deck "It may have been renamed, or the series it pointed to left your library. Press ⌘K to search everything."". Inventory S1: "Press Ctrl K".

**Fix.** "Render the shortcut as a platform keycap (`⌘K` on Mac, `Ctrl K` elsewhere) through the §7.26 formatter. In the phone frame the sentence becomes "Search everything from Discover." with `Discover` as a `link`."

---

## WEB-33 · low · §8.15.3, §8.15.5 Novel reader on desktop

**Problem.** (a) The Type controls are a "352 px popover" on desktop, but the control set has grown to about 20 rows (five face tiles, size, spacing, measure, paragraph spacing, character spacing, bold, justify, layout, page turn, seven stock swatches, and an AMBIENT group with auto-scroll, speed ruler, resume, soundscape and volume). No max height, scrolling or grouping is given, so it overflows a 768–900 px tall window. (b) Desktop chrome reveal is only "on tap" or on scroll direction. The manga reader's pointer bands (top 72 / bottom 96) are missing, and click-to-toggle over prose conflicts with selecting text.

**Evidence.** l.2226: "a 352 px popover under the `text-aa` button on desktop". l.2228–2248: the control table. l.2216: "Chrome hides on downward scroll ≥ 24 px, shows on upward ≥ 56 px, at chapter end, or on tap." Compare l.2001 (manga pointer bands).

**Fix.** "Desktop Type popover: max height `min(640px, 100vh − 52px − 24px)` with internal scroll, the kicker row sticky, and the `AMBIENT` group collapsed behind a `quiet` `Ambient ▸` row. Desktop chrome also shows on pointer movement into the top 72 px or bottom 96 px. A click toggles the chrome only when the selection is collapsed after `mouseup` and the pointer moved ≤ 4 px."

---

## WEB-34 · low · §8.9 Library desktop toolbar and Continue row

**Problem.** (a) The desktop toolbar has no `Clear filters` while filters are active (inventory LB8). Clearing appears only in the filtered-empty state. (b) The Continue row is "4 across on desktop", with no total count or overflow behaviour (the inventory's LB9 is a rail of up to 12). (c) `/library/browse` "renders the same screen with the toolbar open", but the phone toolbar is collapsed, and nothing says whether "open" means the Filters sheet. Old bookmarked URLs (`?search=&status=&reading_status=&is_favorite=`) have no mapping to the new keys (`?q&status&fav`).

**Evidence.** l.1843 (toolbar, no clear control); l.1864 (`Clear filters` only in filtered empty); l.1845: "a row of cuttings (3:2), 4 across on desktop"; l.1462: "`/library/browse` renders the same screen with the toolbar open".

**Fix.** "A `quiet` `Clear filters` appears at the end of the slug line whenever a status, `★ FAVOURITES`, `NEW ONLY`, a tag or a search is active; `Esc` in the search field clears only the search. Continue is a §7.8 rail of up to 12 cuttings (4 visible at desktop, 5 at wide, paddles on hover). `/library/browse` on phones opens the Filters sheet once on mount. Legacy query keys map `search → q`, `is_favorite → fav`, `reading_status → status` through a `router.replace` on first render."

---

## WEB-35 · low · §8.33.4 First-run note

**Problem.** The exclusions changed from the inventory's (`/library`, `/sources*`, readers) to "Tonight, Discover and the readers". Library now shows the banner above its own `EMPTY SHELF` notice, so the same message appears twice. "Discover" is also ambiguous: does it include `/sources` and `/sources/:id`, which belong to the Discover branch but are separate routes?

**Evidence.** l.2793: "on every screen except Tonight, Discover and the readers". l.1864: Library empty `EMPTY SHELF`. Inventory G38.

**Fix.** "Shown on every app-frame screen except Tonight, Library (its own `EMPTY SHELF` notice says it), `/search`, `/sources`, `/sources/:id`, feature and book pages, the readers and takeovers."
