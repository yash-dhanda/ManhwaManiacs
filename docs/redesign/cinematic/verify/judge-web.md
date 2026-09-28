# Cinematic DESIGN.md: verdicts on the web coverage audit (`find-web.md`)

Judged 2026-09-28. For each of the 35 findings I tried to refute the claim by grepping `cinematic/DESIGN.md` (4,101 lines) for any other place that already specifies the behaviour, reading the cited lines, and checking the fix against `inventory/00-decisions.md`, `stack-decision.md`, the rest of DESIGN.md and, where a finding cites code, the checkout (`frontend/next.config.ts`, `frontend/src/app/manifest.ts`, `frontend/public/sw.js`, `frontend/src/features/offline/download-queue.ts`, `frontend/node_modules/next` 16.2.9). Line numbers refer to DESIGN.md as of today.

**Result: 33 confirmed, 2 refuted.** Of the confirmed findings, 15 have a rewritten, narrowed or trimmed fix (marked *rewritten* or *narrowed*). Severities are the auditor's unless noted.

## Verdicts

| ID | Verdict | Reason |
|---|---|---|
| WEB-1 | Confirmed, fix rewritten | l.2001 reveals the chrome "on any key", but every reading key also scrolls ≥ 24 px, so the bars show (240 ms) and hide (160 ms) on each press. l.2004 hides chrome with `visibility: hidden`, and l.3643 puts focus on the running head title, so focus is lost when the chrome hides. Nothing suspends auto-hide while the chrome holds focus. The auditor's reveal list left out `w v r s u` and `Ctrl+Shift+←/→`, and it cited a polite live region in the reader that does not exist, so both are corrected. |
| WEB-2 | Confirmed | l.12 and l.1558 put the spine at 768–1023, while l.1209 says auto-spine runs to 1279. Nothing says whether `mod+b` below 1280 pushes or overlays the content, whether the state persists, or what the footer "collapse toggle" looks like. Checked: `z.panel` (l.273), `scrim.modal` (l.111) and `sidebar-simple` (l.1991) all exist. |
| WEB-3 | Confirmed, fix rewritten | Toasts sit bottom-left (l.1143), but the banner that shares their stack sits bottom-centre at max 672 (l.2789), so the shared-stack rule in l.1149 cannot be built. The readers have no content column, yet they raise toasts (l.2166–2168, §8.15.7). The fix is extended so reader toasts clear the Listen mini player and the auto-scroll chip (§8.15.3), not just the bar. |
| WEB-4 | Confirmed | §7.7 (l.1059) puts the desktop catalogue in Wall mode (no caption; title only in the hover slate), but §8.22 (l.2517, l.2524) gives it captions and turns hover slates off. Genre tiles are 16:9 tiles (l.2464), not posters. |
| WEB-5 | Confirmed, fix rewritten | The pinned strip (l.1795) adds about 700 px of content to a running head that already holds a 280 px search trigger, the bell and the profile chip. My estimate: even at 1440 with the 248 px sidebar (a 1,192 px head) it only fits once the breadcrumb is gone. At 390 px the phone head cannot hold it at all. The fix now hides the breadcrumb at every desktop width while the strip is pinned. |
| WEB-6 | Confirmed | A landscape phone at 844 × 390 gets the desktop frame (l.1437), and l.1442 hides its sidebar below 500 px of height, so there is no section navigation. §8.0.9's "tablet row" at ≥ 768 is that same frame. |
| WEB-7 | Confirmed, fix rewritten | The only mapping rule is l.1215. Discover's children, the profile and settings routes, the feature pages and `/more` have no rule for which item lights up or what the breadcrumb names. Two things are corrected: The Annual is a Takeover with no sidebar (l.1436), so it is out of the table, and `history.state` does not work with Next `<Link>` (it cannot carry state), so the fix uses a value held in the shell instead. |
| WEB-8 | Confirmed | `g 1` cannot be told apart from `g 10`/`g 11`/`g 12` (l.1218, l.1523), and no rule covers timeout, cancel or swallowing the digits. Pages bind bare digits: l.1862, l.2411, l.2478, l.2980, l.3112. |
| WEB-9 | Confirmed | `Delete` is bound at l.1927, l.1955, l.2566, l.2823 and l.2880. The Mac delete key sends `Backspace`, and the file never mentions `Backspace`. |
| WEB-10 | Confirmed | The web inherits Pause/Resume, the queue and `p` (l.2543, l.2566), but `sw.js` has no pause, resume or queue messages. The messages are `save-chapter`, `cancel-save`, `remove-chapter`, `get-state`, `sweep`, `set-retention`, `set-scope`, `clear-scope`, `mark-*`, `chapter-closed`, `skip-waiting`, plus the `mm-offline/state` broadcast. `download-queue.ts` is an in-page run that can only be cancelled. `remove-chapter` deletes the cached pages, so an 8 s Undo cannot restore them. |
| WEB-11 | Confirmed, fix rewritten | Density is offered on phones (l.1852), but COMPACT and LIST have no phone layout, and a 7-column LIST row does not fit in 358 px. The auditor put "last read" in Quick look, but Quick look has no such item (l.1854), so that is corrected. |
| WEB-12 | Confirmed, fix rewritten | Four gaps: an unselected poster in select mode has no visual; the hover icons and the select square both sit top-right (l.1074, l.1854); the drag handle has no position (l.1847); a favourite is invisible at rest (l.1063). The auditor's fix put the entry square top-left and the checked square top-right, which moves the control between states. The rewrite gives each control its own corner. |
| WEB-13 | Confirmed | `r` means Check now in §8.10 (l.1891) and reload-the-list in §11 (l.3516) and §7.29 (l.1404). l.1885 itself says the two must differ. `c` is free on Updates and matches System status (l.2748). |
| WEB-14 | Confirmed | At 1024–1439 the At a glance aside sits below a virtualised list of 200+ rows (l.2385, l.2387). I checked the width: at 1024 with the spine, 4 of 12 columns are 269 px (952 − 96 margin − 264 gutter = 592 / 12 × 4 + 72). The tabs row is 48 px (§7.12), so the sticky offset is right. |
| WEB-15 | Confirmed | At 1024: 1024 − 96 − 640 = 288 px, below the strip's 480 px minimum (l.1966, and the l.2082 slider floor), and panels never overlap the strip (l.2179). Reading setup (l.2069) and Margins (l.2175) both claim the right side. |
| WEB-16 | Confirmed | There is no state for "next chapter still loading" in the continuous strip. The only loading states are the first load and the previous-chapter band (l.2031); inventory RD9 covers this state. |
| WEB-17 | Confirmed | §7.10 (l.1132) puts "remove from library" behind the arm-delay dialog, but Quick look (l.1854), Updates FOLLOWING (l.1881) and the feature page `+` (l.2411) all remove at once with Undo. `dur.hold.toast.action` = 8000 ms exists (l.498). |
| WEB-18 | Confirmed | Android Chrome vibrates for five events (l.814), but the only switch is "app" (l.2673), and `haptics.ts` (l.3792) checks no preference. |
| WEB-19 | Confirmed | Fullscreen is desktop-only in the manga folio bar (l.1998). The novel reader binds `f` (l.2281) but has no button anywhere (l.2211). Inventory RD27 and RD41 offer it wherever it is supported, and Android Chrome supports it. |
| WEB-20 | Confirmed | l.1512 applies `-webkit-touch-callout: none` to images only. Thumb-index tabs and rows are links, and iOS Safari's link preview fights their long-press menus (l.1201, l.3498). |
| WEB-21 | Confirmed, fix rewritten | There are no cursor rules (the only "cursor" hits, l.3397 and l.3592, are the typing caret). The auditor proposed `w-resize` / `e-resize` for page-turn zones, but those cursors mean "resize", so they would mislead. The rewrite uses `pointer`. |
| WEB-22 | Confirmed | A click toggles the chrome (l.2033) and a double-click zooms (l.3491). With no click delay on desktop, every double-click also toggles the chrome twice. |
| WEB-23 | **Refuted** | §7.11 names `sonner` 2.0.8 as the toast queue (l.1153). Its `<Toaster>` already has `hotkey` defaulting to `['altKey','KeyT']` and a region label "Notifications alt+T", and it restores focus to the last focused element when the stack loses focus. The keyboard path exists by default, so there is nothing to design. |
| WEB-24 | Confirmed, narrowed | Hover and pressed are missing for genre and hub tiles, dialogue result blocks, Circle dispatch rows and letter cards, breadcrumb segments, and checkbox and radio (l.1318–1319 have no hover; only Switch has one). The focus parts are refuted: the §7 preamble (l.923) gives every primitive the focus ring. |
| WEB-25 | Confirmed | On desktop, the pushed pages `security`, `members` and `backup` (l.2648) have no rendering in the right pane. On the web, sections 13 and 15 are app-only (l.2676, l.2678), and nothing says whether the folios renumber (Tonight does, l.1772) or leave gaps. |
| WEB-26 | Confirmed, fix decided | l.1213 and l.1145 say `type.ui` 15, but the role is 14/20 at desktop (l.571). The chip's 28 px avatar (l.1187) is not one of the listed sizes (l.1364). The fix picks the tabled values instead of offering two options. |
| WEB-27 | Confirmed, fix rewritten | The Picks aside is placed only at ≥ 1440 (l.2858), leaving 1024–1439 undefined. The Updates aside is admin-only (l.1882), and nothing says what columns 9–12 hold for others. The auditor's fix repeats the schedule, but the masthead deck already shows it (l.1877), so the rewrite leaves the columns empty on purpose. |
| WEB-28 | Confirmed | The slate is 2.1 × the poster width and anchored over the poster (l.1091), with no edge clamp. Focus inside the slate after `Space`, and where `Esc` returns it, are unspecified. |
| WEB-29 | Confirmed, fix rewritten | `next.config.ts` redirects `/` to `/library` (checked). Next 16.2.9's `experimental.viewTransition` is off by default (`config-shared.d.ts` l.695, l.1412) and DESIGN never sets it. The PWA manifest is generated from `src/app/manifest.ts` (`start_url: "/library"`, `orientation: "portrait-primary"`), not from a static `manifest.webmanifest`. The auditor's "delete the redirect in the Tonight cluster's first commit" would break `legacy`: stack-decision §2.2 keeps it live until the flip, and it has no Tonight screen. The rewrite gates the redirect on the cookie and also drops the portrait lock, which contradicts §8.0.9. |
| WEB-30 | Confirmed, narrowed | Part (a) is refuted: mouse users already reach the sheet from Settings → Keyboard and from the reader setup footer (l.2785, l.2110). Part (b) stands: the registry's 8 groups (l.2675) have nowhere to put the keys §8 defines for Tonight, Downloads, Dialogue, Picks, The Numbers, Circle, Status, Recap and The Annual. |
| WEB-31 | **Refuted** | Palette rows are "leading visual, title, subtitle" (l.2778), which is the §7.16 Standard row (leading 20 px icon or 40 × 60 cover, `type.title` + `type.caption`, 56 / 72 px), so row height is specified. The GO TO icons are §2.7's section icons (l.312). `max width 720` already makes the panel full-width on narrow screens. What is left is taste. |
| WEB-32 | Confirmed, broadened | The 404 deck hard-codes "⌘K" (l.2756), which is wrong on Windows and Linux and meaningless in the phone frame. §7.26 already sets the Mac glyphs "where the platform is Mac", but only for keycaps, not copy. The running-head trigger's "Search or jump…  ⌘K" (l.1187) has the same fault, so the fix covers every shortcut named in copy. |
| WEB-33 | Confirmed, fix trimmed | The desktop Type popover (l.2226) holds about 20 rows and has no height limit, so it overflows windows 768–900 px tall. On desktop the novel chrome is revealed only by a tap or by scrolling (l.2216), and the click toggle fights text selection. The auditor also wanted the `AMBIENT` group collapsed, which I dropped: the soundscape indicator opens the sheet at `AMBIENT` (l.2211), and scrolling alone fixes the overflow. |
| WEB-34 | Confirmed, fix trimmed | Three gaps: the toolbar has no `Clear filters` (it appears only in the filtered-empty state, l.1864); Continue has no count or overflow rule (l.1845; the API already returns up to 12); and "toolbar open" (l.1462) has no meaning on phones, where the toolbar is collapsed. The legacy query-key mapping is dropped: this is a private 2–3 user instance, and the old `status` key filtered publication status, so mapping it onto the new reading-status `status` would be wrong. |
| WEB-35 | Confirmed | The first-run note shows on Library (l.2793) above Library's own `EMPTY SHELF` notice (l.1864), so the same message appears twice. The "Discover is ambiguous" part is weak (§8.0.2 defines the branch), but naming the routes costs nothing. |

---

## Confirmed

Final fixes. They are written as edits to `cinematic/DESIGN.md` for the main session to apply.

### WEB-1 · high · reader chrome and keyboard reading (§8.14.3, §14.4)

**Defect.** Reading keys flash the chrome on every press, and focus is lost when the chrome hides.

**Fix.** In §8.14.3 Auto-hide, replace "on any key" with the following:

> "on `g`, `,`, `[`, `]` or `?` (keys that open something in or beside the chrome), or on focus entering the chrome (`Tab` / `Shift+Tab`)"

Then add:

> "Every other reader key never reveals the chrome, and only the scroll rules apply to it. That covers page and scroll keys (`j` `k` `Space` `Shift+Space` `←` `→` `a` `d` `Home` `End` `PageUp` `PageDown`), chapter keys (`h` `l` `Ctrl+Shift+←/→`), zoom (`=` `+` `-` `0`), auto-scroll (`p` `<` `>`), and `b`, `u`, `w`, `v`, `r`, `f`, `s`. `m` and `c` keep their own rules.
>
> While focus is inside the chrome (web `:focus-within` on the chrome container; Flutter `hasFocus` on the chrome's `FocusScopeNode`), auto-hide is suspended: no scroll hide and no 3000 ms idle hide. When `m`, `c` or a click on the page hides the chrome while it holds focus, focus moves to the reading surface first."

In §14.4, replace "a reader route focuses its running head's title" with:

> "a reader route focuses the reading surface (web `tabIndex={-1}`, `role="region"`, `aria-label="Chapter 142, page 1 of 40"`; Flutter a `FocusNode` on the strip with the same `Semantics` label). A polite live region (`aria-live="polite"`; Flutter `Semantics(liveRegion: true)`) announces "Chapter 142 · Solo Leveling" on entry and on every chapter change."

### WEB-2 · medium · spine range, `mod+b` and the collapse toggle (§7.15, conventions, §8.0.9)

**Fix.** Make auto-spine 768–1279 everywhere:
- l.12 becomes: "768–1279 uses the collapsed sidebar, the *spine*; 768–1023 also lays out on the 8-column grid".
- l.1558 becomes: "the desktop frame with the spine (768–1279; 8 columns at 768–1023)".

Add to §7.15:

> "Below 1280, `mod+b` or the toggle opens the 248 px sidebar as an overlay at `z.panel` over `scrim.modal`. It closes on `Esc`, an outside click or navigation, and the content does not reflow. At ≥ 1280 the sidebar pushes the content, and the choice is stored per device in `localStorage['mm.sidebar']` (`expanded` | `spine`; not stored below 1280).
>
> Collapse toggle: a `bare` icon button with `sidebar-simple` 24 Light. Its tooltip is `Collapse sidebar` or `Expand sidebar` plus the `mod+b` keycap (§7.26), and `aria-expanded` reflects the state."

### WEB-3 · medium · toast anchor and toasts in the readers (§7.11, §8.33.3)

**Fix.**

In §8.33.3, change "bottom-centre (desktop, max 672)" to "bottom-left of the content column, 24 px from the bottom (desktop, max 560, the toast anchor of §7.11)".

Add a row to §7.11:

> "Reader and Page frames: toasts sit bottom-centre, max 560, 16 px above the highest bottom element that is showing (the folio bar or novel bottom bar, the Listen mini player, the auto-scroll chip). When the chrome is hidden they sit 24 px above the bottom edge. They never cover the ruler. In the novel reader they use the stock colours (§8.15.7)."

### WEB-4 · medium · catalogue captions (§7.7, §8.22)

**Fix.**

In §7.7 Wall mode, delete "Discover genres" (genre tiles are 16:9 tiles with their own label, l.2464) and "source catalogue on desktop". The Wall list becomes "(onboarding)".

In §8.22 Grid, add: "Caption mode **Below**, with the title on 2 lines (`type.title`) and no folio line."

### WEB-5 · medium · now-showing strip width (§8.8)

**Fix.** Add to the Scrub-the-trailer bullets:

> "While the strip is pinned, the desktop breadcrumb hides (the strip names the page).
>
> Below 1440 the search trigger also collapses to a 44 px `bare` `magnifying-glass` button (tooltip "Search or jump" + the platform `mod+k` keycap), `Previously on` moves into a `dots-three` overflow at the strip's right end, and the title truncates with an ellipsis at a 120 px minimum.
>
> Phone frame: the thumbnail, then the title (one line, min 96 px, no kicker), then a `split` sm reading `▸ CH 143` (44 px hit), then `dots-three` holding `Previously on`."

### WEB-6 · medium · sidebar below 500 px height (§8.0.1)

**Fix.** Replace l.1442 with:

> "Sidebar hidden in the readers. Outside the readers the desktop frame keeps at least the 72 px spine at any height. Below 500 px of viewport height the spine's section list scrolls inside it (`overflow-y: auto`) and its footer items fold into a `dots-three` menu at its bottom."

### WEB-7 · medium · which sidebar item lights and what the breadcrumb says (§7.15, §7.13)

**Fix.** Add this table to §7.15.

| Route | Lights | Breadcrumb |
|---|---|---|
| `/` | `01 Tonight` | `No. 01 · TONIGHT` |
| `/library`, `/library/browse` | `02 Library` | `No. 02 · LIBRARY` |
| `/updates` | `03 Updates` | `No. 03 · UPDATES` |
| `/search`, `/sources`, `/sources/:id` | `04 Discover` | `No. 04 · DISCOVER` (`/ SOURCES`, `/ {source}`) |
| `/downloads` | `05 Downloads` | `No. 05 · DOWNLOADS` |
| `/library/collections`, `/library/collections/:id` | `06 Collections` | `No. 06 · COLLECTIONS` (`/ {shelf}`) |
| `/library/history` | `07 History` | `No. 07 · HISTORY` |
| `/library/bookmarks` | `08 Bookmarks` | `No. 08 · BOOKMARKS` |
| `/ocr` | `09 Dialogue` | `No. 09 · DIALOGUE` |
| `/library/statistics` | `10 The Numbers` | `No. 10 · THE NUMBERS` |
| `/circle`, `/circle/:profileId` | `11 Circle` | `No. 11 · CIRCLE` (`/ {member}`) |
| `/library/recommendations` | `12 Picks` | `No. 12 · PICKS` |
| `/profiles/manage`, `/profiles/new`, `/profiles/:id/edit` | footer `Profiles` | `PROFILES` |
| `/settings`, `/settings/:section` | footer `Settings` | `SETTINGS / {section}` |
| `/admin/status` | footer `Status` | `STATUS` |
| `/more` | none | `INDEX` |

Then add:

> "Feature and book pages (`/sources/:s/series/:k`, `/library/:followedId`) and `/recap/…` keep the item that was lit before the navigation, held in the shell's state (the shell survives client navigation; a `<Link>` cannot carry `history.state`). On a cold load, `02 Library` lights when the series is followed and `04 Discover` otherwise. The breadcrumb follows the same rule (`No. 04 · DISCOVER / SOLO LEVELING`). The Annual is a Takeover and has no sidebar."

### WEB-8 · medium · the `g`-number sequence (§7.15, §8.0.6)

**Fix.** Add to §8.0.6:

> "`g` arms a sequence for 1500 ms. `g 2`…`g 9` and `g 0` jump at once. `g 1` waits 600 ms for a second digit (`0`, `1` or `2`, giving 10, 11 or 12) and otherwise jumps to `01`; `Enter` jumps to `01` at once. Any other key, `Esc` or the timeout cancels the sequence.
>
> While armed, a keycap chip `G 1_` shows at the toast anchor (§7.11) and fades 160 ms after the sequence ends. Keys consumed by the sequence are never delivered to page bindings (Library `1`–`7`, Discover `1`–`5`, feature `1`–`4`, The Numbers `1`–`4`, Circle `1`–`5`)."

### WEB-9 · medium · `Delete` on Mac keyboards (§8.11, §8.13, §8.23, §9.1.1, §9.1.3)

**Fix.** Add to §8.0.6:

> "`Delete` in any screen's key list means `Delete` or `Backspace` with no modifier, ignored while typing in a field. The keycap renders `⌫` on Mac and `Del` elsewhere (§7.26)."

l.1927, l.1955, l.2566, l.2823 and l.2880 then inherit it.

### WEB-10 · medium · Downloads controls on the web (§8.23)

**Fix.** Add a web delta after "Mobile web layout":

> "On the web the Activity block lists the saves reported by the worker's `mm-offline/state` broadcast (series, `CH 12 · 7/40 PAGES`, a determinate rule), plus the in-page bulk run's tally (`12 of 40 saved in this series`). Each save has `Stop` (`mm-offline/cancel-save`), and there is `Stop all` (a `cancel-save` for each save, plus cancelling the bulk run). The web has no Pause, Resume or queue rows, and `p` is not bound there.
>
> Web chapter `Remove` defers the `mm-offline/remove-chapter` message until its 8000 ms Undo toast expires. Meanwhile the row reads `REMOVING…` in `ink.30`. Undo drops the pending message, and `pagehide` flushes any pending removals."

### WEB-11 · medium · Library density on phones and tablets (§8.9)

**Fix.** Add to the Phone layout:

> "WALL 3 per row, COMPACT 4 per row (web 600–767 and app tablets: WALL 5, COMPACT 7).
>
> LIST rows on phones are 72 px: a 48 × 72 cover, then the title (`type.title`, 2 lines) over the folio caption `CH 12 OF 40 · 3 NEW`, then the reading-status badge at the trailing edge. The favourite, notify and last-read columns are desktop-only (Favourite and Notify stay in Quick look).
>
> COMPACT at every width has no caption below. The title is in `aria-label` and, on desktop, in a tooltip after 500 ms. There are no hover icons, and only the `NEW` badge shows."

### WEB-12 · medium · Library poster corners in hover, select and manual-order states (§7.7, §8.9)

**Fix.** Add these rows to §7.7 and point §8.9 Card behaviour at them. The corners are: badges top-left, select square top-right, hover icons bottom-right, drag handle bottom-left.
- **Select mode, unselected**: every poster shows a 24 px square at top-right, 4 px inset, with a 1 px `ink.100` outline on `rgba(0,0,0,0.64)`. Hover icons are hidden while select mode is on.
- **Hover (desktop, not in select mode)**: favourite (`star`) and notify (`bell-ringing`) `on-art` icon buttons at bottom-right, 4 px inset, with notify 8 px left of favourite. The same empty select square appears at top-right; clicking it enters select mode with that poster selected (inventory LB14).
- **Manual order**: a 40 px `on-art` `dots-six-vertical` handle at bottom-left on hover.
- **Favourited at rest**: a 12 px `star` (Fill, `spot`) leads the caption folio (`★ CH 142 · 3 NEW`), and "Favourite" is appended to the poster's `aria-label`.

### WEB-13 · medium · `r` on Updates (§8.10)

**Fix.** Updates keys: "`r` reloads the list (reprint, as §11); `c` runs `Check now`; `j`/`k` …". This matches System status (l.2748).

### WEB-14 · medium · At a glance on laptops (§8.17)

**Fix.** Change item 3 to:

> "**CHAPTERS** (columns 1–8) + **At a glance** aside (columns 9–12) from 1024 px, `position: sticky; top: calc(56px + 48px + 16px)` (running head + contents tabs + 16). Below 1024 the tablet rule applies (At a glance at the top of DETAILS)."

### WEB-15 · medium · both reader side panels on narrow desktops (§8.14.12)

**Fix.** Add to §8.14.12:

> "If `viewport − 2 × grid margin − open panels` would leave the strip under 480 px, opening a panel closes the one on the other side (last opened wins, 320 ms `settle`). Reading setup takes the right slot: opening it hides Margins, and closing it restores Margins if Margins was open. `[` / `]` state is still remembered per profile, but where both panels cannot fit, only the most recently opened one is restored."

Also replace "With both open the strip keeps the middle 6 columns" (l.1966) with "With both open the strip takes the remaining width, never less than 480 px".

### WEB-16 · medium · next chapter still loading in the continuous strip (§8.14.11)

**Fix.** Add a row to §8.14.11:

> "Next chapter loading (strip) | Below the seam, a 96 px band of ground reads `CH 143 IS ON ITS WAY` in `type.kicker` `ink.45`, with a 16 px leader dial after 400 ms. After 8 s it adds "This source can take a while." (`type.caption`). The band keeps 128 px of bottom padding so the folio bar never covers it. Auto-scroll pauses at the band and resumes when the pages land."

### WEB-17 · medium · single unfollow has no dialog (§7.10)

**Fix.** In l.1132 delete "remove from library" from the arm-delay list, and add:

> "A single unfollow or remove from library never opens a dialog. It commits at once with the toast "Removed {title}." + `Undo`, held for `dur.hold.toast.action` (8000 ms). Only unfollow in bulk asks first."

### WEB-18 · low · a haptics switch for mobile web (§5, §8.30.2 row 10)

**Fix.** Row 10:

> "Haptic feedback: app, and web when `'vibrate' in navigator` and `matchMedia('(pointer: coarse)').matches`. On the web it is stored per device in `localStorage['mm.haptics']` (`on` by default, or `off`), and `haptics.ts` checks it before calling `navigator.vibrate`. The row is not rendered on iOS Safari or desktop. `Feel it` stays app-only."

### WEB-19 · low · fullscreen at every width (§8.14.8, §8.15.3, §8.15.5)

**Fix.**
- Add a `Fullscreen` switch row to Reading setup → `CONTROLS` and to the Type sheet (session scope). On the web it renders whenever `document.fullscreenEnabled` is true, at every width.
- Add `corners-out` / `corners-in` to the novel reader's desktop top bar, just before `text-aa`.

### WEB-20 · low · iOS link callout on long-press targets (§8.0.5)

**Fix.** Extend l.1512:

> "…and so does every element with a long-press action: thumb-index tabs, rows with row menus, source rows, profile avatars, the Listen mini player and the auto-scroll chip. For those elements only, the phone frame also calls `preventDefault()` on `contextmenu`."

### WEB-21 · low · pointer cursors (§7 preamble)

**Fix.** Add a bullet to the §7 preamble:

> "Cursors (web):
> - `pointer` on every clickable element that is not a native button (posters, cards, rows, tiles, breadcrumb segments); `default` on disabled controls; `text` in fields.
> - Reader paged side zones: `pointer`; centre zone: `default`.
> - Zoomed page and Lightbox: `grab`, and `grabbing` while dragging. Drag handles: the same.
> - Ruler: `pointer` on the track, `grabbing` while scrubbing.
> - In both readers the cursor hides (`cursor: none`) after 3000 ms without pointer movement while the chrome is hidden, and returns on the next move."

### WEB-22 · low · click vs double-click in the desktop strip (§8.14.5)

**Fix.** Add to §8.14.5 Tap behaviour:

> "Desktop strip: the chrome-toggle click commits after 250 ms unless a second click lands within 250 ms and 24 px, which zooms instead. Paged side zones turn on the first click, and a double-click on a side zone turns two pages and never zooms."

### WEB-24 · low · hover and pressed states for the unlisted surfaces (§7, §8)

**Fix.** The focus ring is already global (§7 preamble), so only hover and pressed are added:
- **Genre tiles and Tonight's `Sources` hub tiles**: the §7.6 Feature card states. Hover zooms the image 1.04 inside the frame and underlines the title (200 ms `settle`); pressed is a 1 px impression.
- **Dialogue result blocks**: hover adds a 2 px `ink.100` left bar and zooms the still to 1.04 inside its crop; pressed fills `paper.3`.
- **Circle dispatch rows**: the §7.16 row hover (l.1233).
- **Letter cards**: the Feature card states.
- **Breadcrumb segments**: the §7.12 tab states (hover `ink.100`) plus a 1 px underline at 4 px offset (160 ms).
- **Checkbox and radio**: hover sets the outline to `ink.100` (80 ms).

### WEB-25 · low · Settings pushed pages and numbering on desktop (§8.30.1)

**Fix.** Add:

> "Desktop: pushed pages (`security`, `members`, `backup`) render in the right pane under a `quiet` `← {Parent section}` link above their section header, and the parent stays lit in the table of contents.
>
> Folios are assigned to the sections this client renders, in order, with no gaps (web: 01 Profile & account … 14 About). The slugs, not the numbers, are the stable identifiers."

### WEB-26 · low · desktop values outside the token tables (§7.15, §7.11, §7.13)

**Fix.**
- Delete "15" from "`type.ui` 15" in l.1145 and l.1213, so both use the role as tabled (14/20 at desktop and wide, 15/20 on phones).
- Change the profile chip's avatar in l.1187 to 32 px, an existing §7.25 size.

### WEB-27 · low · Picks aside below 1440 and the Updates aside for non-admins (§9.1.3, §8.10)

**Fix.**
- Picks at 1024–1439: the ask block spans columns 1–12, and the aside renders under it as a full-width `Your genres` slug line (the tablet rule, l.1576).
- Updates: "Non-admins have no aside. The lists keep columns 1–8 at every role, so the row measure does not change, and columns 9–12 stay empty. The schedule is already in the masthead deck."

### WEB-28 · low · preview slate at rail edges and its focus (§7.8)

**Fix.** Add to the Preview slate row:

> "The slate is centred on the poster, then clamped so it stays at least 24 px inside the content columns. At a rail's ends it grows from the poster's outer edge inward.
>
> Opened with `Space`, focus moves to `Read`, and `Tab` cycles `Read → + Library → Details`. `Esc` or `Space` closes it and returns focus to the poster. Opened by hover, it takes no focus."

### WEB-29 · low · web prerequisites in `next.config.ts` and the manifest (§15.2, §12.3)

**Fix.** Add a `next.config.ts` / `manifest.ts` row to §15.2:

> - "Add `experimental: { viewTransition: true }` next to `proxyTimeout`. Next 16.2.9 wires React `<ViewTransition>` and `<Link transitionTypes>` (§8.0.4) only with it.
> - Until the Cinematic flip, give the existing `/` → `/library` redirect `missing: [{ type: "cookie", key: "mm-skin", value: "(cinematic|glass)" }]`. `legacy`, which has no Tonight, still answers 307 to the library, and a Cinematic cookie reaches Tonight at `/`. The flip release deletes the redirect.
> - §12.3's manifest values go into `src/app/manifest.ts`; there is no static `manifest.webmanifest`. Set `start_url: "/"`, `id: "/"`, `short_name: "Maniacs"`, and `#000000` for `background_color` and `theme_color`. Delete `orientation: "portrait-primary"`, which would lock the installed Android PWA out of the landscape layouts of §8.0.9 and §8.14.1."

In §12.3, change "`manifest.webmanifest`" to "the web app manifest (`src/app/manifest.ts`)".

### WEB-30 · low · keyboard registry groups (§8.30.2 row 12, §8.33.2)

**Fix.** Replace the group list in row 12 with:

> "grouped as General, Navigation, then one group per screen that binds keys, named by its masthead title in sidebar order (Tonight, Library, Updates, Collections, History, Bookmarks, Discover, Sources, Catalogue, Downloads, Dialogue, The Numbers, Circle, Picks, Profiles, Settings, System status), then Series page, Reader, Novel reader, Listen, Recap, The Annual. Each screen registers its keys under its own group."

### WEB-32 · low · platform keycaps in copy (§8.32, §7.13, §7.26)

**Fix.** Add to §7.26:

> "Shortcuts named in running copy use the same platform rule: `⌘K` on Mac, `Ctrl K` elsewhere. This applies to the 404 deck and to the running head's "Search or jump…" trigger."

In the phone frame, the 404 sentence becomes "Search everything from Discover.", with `Discover` as a `link`.

### WEB-33 · low · novel reader on desktop (§8.15.3, §8.15.5)

**Fix.**
- §8.15.5: "Desktop popover: max height `min(640px, 100vh − 52px − 24px)`, scrolling inside, with the `TEXT AND PAGE` kicker row sticky."
- §8.15.3: "Desktop chrome also shows on pointer movement into the top 72 px or bottom 96 px. A click toggles the chrome only if, after `mouseup`, the selection is collapsed and the pointer moved ≤ 4 px since `mousedown`."

### WEB-34 · low · Library toolbar, Continue row and `/library/browse` on phones (§8.9, §8.0.3)

**Fix.**
- Toolbar: "A `quiet` `Clear filters` appears at the end of the status slug line whenever a status other than `ALL`, `★ FAVOURITES`, `NEW ONLY`, a tag or a search is active. `Esc` in the search field clears only the search."
- Continue: "A §7.8 rail of up to 12 cuttings (the existing `GET /library/continue-reading?limit=12`): 4 visible at desktop, 5 at wide, paddles on hover."
- Routes: "`/library/browse` on phones opens the Filters sheet once on mount."

### WEB-35 · low · first-run note exclusions (§8.33.4)

**Fix.** Replace the exclusion clause with:

> "on every app-frame screen except Tonight, Library (its own `EMPTY SHELF` notice already says it), `/search`, `/sources`, `/sources/:id`, feature and book pages, the readers and takeovers."

---

## Refuted

- **WEB-23** (toast keyboard access): `sonner` 2.0.8 (l.1153) already provides it by default: `hotkey` `['altKey','KeyT']`, a region label with the hotkey, and focus restored when the stack loses focus.
- **WEB-31** (palette rows): already specified. The rows are §7.16 Standard rows (56 / 72 px, leading 20 px icon or 40 × 60 cover), the section icons come from §2.7, and a `max-width` panel is already full-width on narrow screens.
