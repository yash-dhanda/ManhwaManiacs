# Glass DESIGN.md audit: web coverage (desktop 1440 px and mobile web 390 px)

Lens: every screen, element, state and interaction of `inventory/web.md`, specified for desktop web and mobile web, including keyboard shortcuts, focus behaviour, hover and pointer states. Every "missing" claim below was checked by grepping the whole of `glass/DESIGN.md` (4,184 lines). Line numbers refer to `glass/DESIGN.md` unless another file is named. Widths at 1440 px assume the content column starts at 304 px (§7.16) with the `s10` 40 px wide-screen margin on both sides, so the usable content width is 1440 − 304 − 80 = 1056 px.

---

## WEB-1 · high · §8.0.3, §8.12, §7.37, §15.2 (routes presented as sheets and windows)

**Problem.** Series detail (`feature`, `featureByFollow`), the recap (`recap`), a friend (`circleMember`) and the profile form are routes that must render as a sheet (phone, mobile web) or a window (desktop) *over the still-visible page they came from*, which recedes by sheet position. The document never says how the web keeps the covered page mounted, and it says elsewhere that the App Router cannot. An implementation session will either render these as full-page navigations (losing the sheet, the recession and the "cover flies back to its origin" dismissal) or invent a mechanism.

**Evidence.**
- Line 1886: "The App Router cannot keep covered pages mounted, so the web never fans live screens (no plane stack)."
- Line 1981: `feature` is "Sheet (medium → large) / 960 px window over the recessed page; a deep link without a parent renders it as a full page".
- Line 2296: "desktop and tablet: a **window** 960 wide … over the recessed page (scale 0.97, blur 8, dim 50 %)".
- Line 2020: "The recap itself is a route (`recap`) presented as a sheet, and so is a friend (`circleMember`)."
- Line 3806 (§15.2 Routes) only says "thin `app/` route files render `skins.glass.screens[id]`"; no parallel or intercepting routes anywhere (grep for "intercept", "parallel route", "@modal": no hits). `research/web-motion-libs.md` line 202 already names the fix ("intercepting plus parallel routes (`@modal/(.)series/[id]`) keep the grid mounted").

**Fix.** Add to §15.2 Routes: the `(app)` layout gets a parallel slot `@sheet` (default `null` from `@sheet/default.tsx`). Intercepting routes render the sheet or window into it on soft navigation: `@sheet/(.)sources/[sourceId]/series/[seriesKey]/page.tsx`, `@sheet/(.)library/[followedId]/page.tsx` (resolves the follow row, then the same screen), `@sheet/(...)recap/[sourceId]/[seriesKey]/page.tsx`, `@sheet/(...)circle/[profileId]/page.tsx`; the profile form intercepts `(.)profiles/new` and `(.)profiles/[id]/edit` inside the picker's layout. A hard load of the same URL renders the full page (the existing "deep link without a parent" rule). Closing calls `router.back()`; the underlying page's recession (scale 0.97, blur 8, dim 50 % on desktop; §7.10 recession on phones) is driven by a CSS variable the sheet writes on the `(app)` layout root. The poster zoom keeps `ViewTransition name="cover-{sourceId}-{seriesKey}"` because both elements are now in the DOM. State in §7.37 that the back menu limitation applies to stacked pushes only, not to these sheet routes.

---

## WEB-2 · high · §7.16 Desktop sidebar, §8.0.1 Frames, §3.2

**Problem.** The collapsed 76 px sidebar is the only navigation for every web width from 768 to 1179 px (the whole tablet frame, and desktop 1024–1179 px because it auto-collapses below 1180), yet only the desktop accessory's collapsed form is specified. The collapsed rendering of the wordmark, the search capsule, the content-mode segmented control, the Library item and its five children, Home's For you child, the pinned sources, the Updates count badge and the profile capsule are all undefined, as is how the user re-expands it (inventory G29e), whether `mod+b` expansion below 1180 px pushes or overlays the content, and whether the manual choice persists. §8.0.1 also contradicts §7.16 for 1024–1179 px, and the tooltip type is contradictory.

**Evidence.**
- Line 1658: "Collapsed: 76 wide (icons only), auto-collapsing below 1180 px; `mod+b` toggles".
- Line 1942: Desktop app (1024 px and wider) is "280 px inset glass sidebar".
- Line 1941: Tablet app is "Collapsed 76 px glass sidebar … floating nav row on the right".
- Line 858: `tabLabel` "(dock, sidebar collapsed tooltips)" is "n/a" at Desktop and Wide, while line 1793 says tooltips are `footnote`.
- `inventory/web.md` G16: content-mode switch "Collapsed: stacked icon-only buttons with `title`"; G29e: "Expand-sidebar button … `aria-label="Expand sidebar"`"; §19.5: sidebar collapsed state is not persisted today.
- Line 1661 "Exactly one item is active" does not say which item lights on `/sources/:id` when that source is also a pinned sidebar entry.

**Fix.** Add a "Collapsed (76 px)" block to §7.16: `mm-mark` 32 px centred at top (tooltip "ManhwaManiacs"); below it the expand button (44 px plain icon, `caret-right`, `aria-label="Expand sidebar"`, `aria-expanded="false"`); search as a 44 px `magnifying-glass` icon button (tooltip "Search · ⌘K" / "Ctrl K", opens the palette); the content-mode control as two stacked 44 px icon buttons (`strip-scroll`, `book-open`) sharing one droplet that travels vertically on `tab`; each item a 44 × 44 icon cell, radius 12, active droplet 52 × 44; Library opens a `glassThick` flyout menu of its five children on hover (150 ms delay) or Enter/→; For you appears in the same flyout under Home; pinned sources as 32 px favicon cells; the Updates count as the §7.20 count badge at the icon's top-right (−4, −4); the profile capsule becomes the 44 px orb. Tooltips use `footnote` 13/18 `onGlass` everywhere (drop the `tabLabel` tooltip mention). Rule: at 1180 px and wider the sidebar starts expanded, below 1180 it starts collapsed; `mod+b` or the expand button below 1180 opens the 280 px panel as an **overlay** over the content (`dimSheet` behind it, Esc or an outside click collapses it, focus moves to its first item), at 1180 and wider it pushes the content; the manual choice is kept for the session in `sessionStorage['mm.glass.sidebar']` only. Correct §8.0.1's Desktop row to "280 px sidebar at ≥ 1180 px, collapsed 76 px from 1024 to 1179 px". On `/sources/:id` of a pinned source, the pinned entry is the active one and Sources is not.

---

## WEB-3 · medium · §2.2 Scroll insets, §7.14 Desktop toolbar row

**Problem.** The desktop top scroll inset (24 px) is smaller than the desktop toolbar row (48 px tall), so at rest the large title and the first focusable element sit under the toolbar's glass group, and `scroll-padding-block` (set equal to the inset) lets keyboard focus land under the toolbar, the exact WCAG 2.4.11 failure the paragraph claims to prevent. The toolbar row's vertical position and its height have no token, and where the desktop large title sits relative to the toolbar is not stated.

**Evidence.**
- Line 295: "Top inset = safe area + 60 (floating nav row) on phone, 24 on desktop … `scroll-padding-block` on web equals these insets so keyboard focus never lands under a bar (WCAG 2.4.11)."
- Line 1631: "a slim **toolbar row** (48 tall, transparent, `edgeSoft` 48 px) … trailing actions as a glass group that always ends with a keyboard-shortcuts button".
- §2.8.2 (lines 638–682) has no toolbar key.

**Fix.** Add `layout.toolbarHeight` 48 and `layout.toolbarTop` 12 (aligned with `sidebarInset`) to §2.2 and §2.8.2; the toolbar row is `position: sticky; top: 12px` inside the content column with 0 px horizontal inset beyond the screen margin. Desktop top inset = 12 + 48 + 16 = **76 px**; the large title (40/46 desktop, 44/50 wide) starts at 76 px; `scroll-padding-top: 76px`, `scroll-padding-bottom: 24px` on desktop. The `edgeSoft` plateau under the toolbar runs from 0 to 60 px, then the 24 px fade. When the toolbar's controls do not fit (Library at content widths under 900 px: search, five chips, sort, density), the status chips collapse into the "Filters" menu and the search well shrinks to a 44 px icon button that expands on focus.

---

## WEB-4 · medium · §7.8 Posters, §7.9 Rails, §8.8, §8.11, §8.17, §8.19, §8.9, §8.0.8 (grid and rail sizing at 1440 px)

**Problem.** Poster widths and column or visible counts contradict each other and are only given at 1024 and 1920 px, so the 1440 px layout is a guess. At 1440 px (1056 px content): Home's "7 posters" gives 137 px posters, not the 184 px `wide` poster of §7.8; the Library grid "6 (1024) to 10 (1920)" interpolates to 7 or 8 columns of 115–134 px; the tablet frame's minimum poster (148 px) is larger than every desktop grid poster. Catalogue (5 to 8), History (6 to 10) and Search (6 to 8 per row) each use a different rule.

**Evidence.**
- Line 1569: "Widths: phone 124 (rail) / grid by columns; tablet 148; desktop 168; wide 184."
- Line 2243: "Rails show 7 (1440 px) to 9 (1920 px) posters".
- Line 2586: "a 6 (1024) to 10 (1920) column grid"; line 2282: "5 (1024) to 8 (1920) columns"; line 2619: "6 columns at 1024 px to 10 at 1920 px"; line 2260: "6 to 8 posters per row".
- Line 2100: tablets "grids take as many columns as fit at a 148 px minimum poster width".

**Fix.** One rule in §7.8: grids are `grid-template-columns: repeat(auto-fill, minmax(var(--grid-min), 1fr))` with gap 20 (`s7`) on tablet and desktop, 12 on phone; `--grid-min` = 148 px (tablet), 152 px (desktop and wide) for Comfortable, 112 px for Compact; the Search section grid uses the 112 px result card (§7.7). Resulting Comfortable columns: 5 at 1024 (156 px), 6 at 1440 (159 px), 8 at 1920 (153 px); Library, History and the catalogue all follow it, and the per-screen counts are replaced by a pointer to §7.8. Rails keep §7.8's 168 px (desktop) and 184 px (wide) posters with a 16 px gap, so Home shows 4.8 posters at 1024, 5.4 at 1440 and 6.9 at 1920; replace line 2243's "7 (1440 px) to 9 (1920 px)" with those values (or, if 7 at 1440 is the intent, change `wide` to 136 px and say so). State the content-width formula once: `W = min(viewport − sidebarOffset, contentMax) − 2 × margin`, sidebarOffset 304 (expanded) or 100 (collapsed), margin 32 (desktop) or 40 (wide).

---

## WEB-5 · medium · §7.10 Sheets (desktop panel or window), §8.0.3 sheet ids

**Problem.** §7.10 says a sheet becomes either a 440 px right panel or a 560 px centred window on desktop, but most sheet ids never say which, the 440 px panel is assigned to no sheet at all, and no desktop window has a maximum height or vertical position (the palette lost the inventory's 70 vh cap). Unassigned: `filters`, `tags`, `manage-tags`, `add-series`, `collection-share`, `recommend`, `letter-note`, `note` (bookmark note), `audiobook`, `whats-new`, and `voices`/`cast`/`soundscape` when opened outside a reader (book page ⋯ "Voices for this book", the listen player's ⋯, Settings).

**Evidence.**
- Line 1594: "the same content renders as (a) a right-side **panel**, 440 wide … or (b) a centred **window**, 560 wide"; line 1587: "Detents a given sheet uses are listed per screen" (detents are, desktop forms are not).
- Line 2581 (Filters "opening a sheet"), line 2300 (`?sheet=tags` `medium` sheet), line 2609 (Add series "a `large` sheet"), line 3092 (`collection-share` `medium`), line 3100 (Recommend "a `medium` sheet"), line 2562 (Audiobook "`large` sheet"), line 2403 ("a one-line note sheet"), line 2852 (What's New "a `large` sheet"), line 3131 (soundscape: "desktop the right panel's Settings tab", reader only): none names a desktop form.
- `inventory/web.md` CP2: palette "max-height 70 vh"; C5: dialogs "max-height `100dvh-2rem`". DESIGN.md gives the palette and windows no height rule.

**Fix.** Add a table to §7.10: 440 px right panel for `filters`, `manage-tags`, `audiobook`, and `voices`, `cast`, `soundscape` outside a reader; 560 px window for `tags`, `add-series`, `collection-share`, `recommend`, `letter-note`, `note`, `whats-new` (plus those already stated). Panels: full height minus 12 px insets, body scrolls, header sticky. Windows: centred horizontally on the content column, top at `max(12vh, 48px)`, `max-height: min(80dvh, 880px)`, body scrolls with a sticky 56 px header. The 960 px series window: top 24 px, `height: calc(100dvh − 48px)`, the window itself scrolls (so the left column's `position: sticky; top: 24px` works). Palette: results list `max-height: calc(70vh − 88px)` scrolling under the field and footer. A panel or window opened from inside the series window stacks over it (the two-sheet limit of §7.10).

---

## WEB-6 · medium · §7.12, §7.30, §7.35, §8.25.6, §15.7 (desktop placement of floating layers)

**Problem.** Several floating layers are placed only for phones, so desktop and the desktop readers have no position for them, and the desktop glass budget omits one of them.

**Evidence.**
- Line 1828: the global new-chapters capsule "drops in at the top"; the top-band priority (line 1609) is "one slot under the nav row on phones". No desktop position.
- Line 1827: the "Offline" / "Saved copy" / "Syncing" status capsule lives in the "(top nav row)"; desktop has a toolbar row with no title capsule to replace.
- Line 1864: the bulk-selection toolbar "replaces the bottom accessory slot"; desktop has no bottom accessory (it lives in the sidebar, line 1660). The same holds for Settings → Notifications' "floating glass bar 'Unsaved changes'" (line 2747).
- Line 1608: desktop toasts sit "bottom-left, 24 px from the sidebar's edge"; the readers have no sidebar, and the manga reader's 300 px left panel occupies that corner.
- Line 3960: the desktop budget counts "sidebar 1, toolbar group 1, toast 1, app-update capsule 1, palette or window or panel 1, menu 1 = **6**"; the new-chapters capsule makes 7.

**Fix.** Desktop and tablet: the new-chapters capsule is top-centre of the content column, 12 px below the toolbar row (top 72 px), max width 480, and shares one queue with toasts (a toast waits while the capsule shows, keeping the budget at 6). The status capsule sits in the toolbar row immediately after the page title (32 tall, 12 px gap). The bulk toolbar and the "Unsaved changes" bar sit fixed at bottom 24 px, centred on the content column, max width 720, 52 tall; the app-update capsule moves up by 64 px while either shows. Inside the readers on desktop, toasts are top-centre at 72 px from the top (between the two top groups), never bottom-left.

---

## WEB-7 · medium · §8.0.6 Global keys versus per-screen keys

**Problem.** Several per-screen bindings collide with global bindings or browser bindings, so the same key does two things on one screen.

**Evidence.**
- Book page `g` versus the global chord prefix: line 2321 "**Keys:** as §8.12 plus `g` go to chapter" while line 2057 makes `g` the prefix of `g h` … `g ,` with a 1 s chord window. Only the readers switch the chords off (line 2408). §8.12 already binds `/` to the go-to field.
- Series detail `d` versus the global row action: line 2308 "`d` download next 10", line 2067 "`m`, `d`, `Delete` | Row actions: mark read, download, remove". With a chapter row focused, `d` is ambiguous.
- Horizontal reorder versus browser back: line 2069 and line 1863 bind `alt+←/→` to reordering grid items, while line 2045 says "`alt+←` stays the browser's" (Chrome and Firefox on Windows and Linux navigate back on Alt+←).
- Search `j`/`k` versus grid movement: line 2266 "`j`/`k` next / previous source group", while line 2063 binds `h j k l` to grid movement and line 2260 makes each source section a grid on desktop.
- Circle `l` (line 3079, "`l` Letters") versus `h j k l` grid movement on the Shelves tab.
- Desktop reader `o`: line 2408 "`o` show dialogue" (the page overlay, §8.14.9) versus line 2431 "`,`, `o` and `shift+c` open them" (the right panel's Dialogue tab).

**Fix.** Book page: drop `g`; `/` focuses the go-to field as on §8.12. Series detail: `d` downloads the focused chapter row; `shift+d` downloads the next 10. Grid reorder: `alt+shift+←/→` moves one slot horizontally; `alt+↑/↓` and `alt+shift+↑/↓` stay for vertical and top/bottom; never bind bare `alt+←/→`. Search: `shift+j` / `shift+k` jump between source groups; bare `h j k l` stay grid movement. Circle: drop `l` (tabs are `[`/`]`). Desktop reader: `o` toggles the page overlay and, when the right panel is open, switches it to the Dialogue tab; `shift+o` opens the panel's Dialogue tab without the overlay.

---

## WEB-8 · low · §7.27 Keycaps, §8.0.6, §9.1.2, §8.28 (platform key matching and labels)

**Problem.** Some bindings and labels only work or read correctly on one platform, and the `allowInInput` set is never listed.

**Evidence.**
- Line 2898: "`alt+1` to `alt+3` fill an example": on macOS, `event.key` for Option+1 is "¡", so a `key`-based matcher never fires.
- Line 2067 and others bind `Delete`; Mac laptop keyboards have no forward-delete key (the "delete" key sends `Backspace`).
- Line 1522 "Search  ⌘K" and line 2836 "Press ⌘K to search everything" hard-code the Mac glyph; `inventory/web.md` §2.9: "`mod` = ⌘ on Mac, Ctrl elsewhere. Formatter renders ⌘ ⌥ ⇧ glyphs on Mac", and S1 reads "Press Ctrl K".
- Line 2072: "No shortcut fires while typing in a field unless it is marked `allowInInput`", with no list of which bindings are.

**Fix.** Match `alt+` combinations on `event.code` (`Digit1`…`Digit3`, `KeyX`); bind "remove" to `Delete` or `Backspace` (Backspace only when focus is not in a field); render every keycap and hint through the shared formatter ("⌘K" on macOS, "Ctrl K" elsewhere) including the sidebar capsule and the 404 hint. `allowInInput`: `mod+k`, `Esc`, `mod+enter` (in the Ask box it asks), `mod+\`; nothing else.

---

## WEB-9 · medium · §7.1 Hold-to-confirm, §7.25 The 18+ gate

**Problem.** The hold button is specified two incompatible ways for a mouse or touch release before 1200 ms: "releasing early drains the fill", and "a plain click opens an alert". There is no threshold separating a click from an aborted hold. For the 18+ gate the hold button already sits inside an alert, so the §7.1 rule would open an alert on top of an alert.

**Evidence.**
- Line 1482: "Releasing early drains the fill back on `dismiss` from its current position … a keyboard activation, a screen-reader double-tap, or a plain click opens an alert with an explicit confirm button".
- Line 1776: the gate alert holds "a **hold-to-confirm** button 'Hold: I am 18 or older' (1200 ms) plus 'Cancel'. Keyboard and screen-reader users get the explicit 'I am 18 or older, enable' button in the same alert."

**Fix.** Pointer down starts the fill only after 200 ms; a release before 200 ms with less than 8 px of movement is a click and opens the confirm alert; a release between 200 and 1200 ms drains the fill and shows the helper line "Keep holding, or click once to confirm" for 2 s; Enter/Space always opens the alert. When the hold button is itself inside an alert (the 18+ gate, sign out everywhere's alert path), a click reveals the explicit confirm button in that same alert instead of opening a second one; the explicit button is always present for keyboard and screen-reader users.

---

## WEB-10 · medium · §7.35 Bulk selection, §7.17 Chapter rows, §7.2 Toggle icons (web semantics)

**Problem.** Select mode and toggle buttons have no web roles or states, and the keyboard meaning of Enter and Space in select mode is undefined (does Enter open the item or toggle it?). The inventory rows being replaced specify them.

**Evidence.**
- `inventory/web.md` LB18: "Whole card becomes a checkbox (`role="checkbox"`, Space/Enter)"; SL9 pin toggle `aria-pressed`; NS3 "Row becomes a `role="checkbox"` button"; DP2 row checkbox, saved rows disabled.
- DESIGN.md: grep for `aria-checked`, `role="checkbox"`, `aria-multiselectable` returns nothing; `aria-pressed` appears only on the password eye (line 1510). Line 1864 says only "each tap toggles"; line 1496 (Toggle icon) gives no role or state.

**Fix.** In select mode the grid or list gets `aria-multiselectable="true"` and its items `role="checkbox"` with `aria-checked`; Space and Enter both toggle (Enter never opens while selecting); `shift+Space` selects the range from the last toggled item (same as `shift+x`); already-saved chapter rows are `aria-disabled="true"` with the reason in `aria-describedby`; a polite live region announces "{n} selected" after each change. Every toggle button (follow, favourite, pin, notify bell, bookmark, "In library", "Hide from my Circle", reaction) carries `aria-pressed`, and its accessible name does not change with state.

---

## WEB-11 · medium · §8.14.11 and §8.15.2 (desktop reader side panels)

**Problem.** Both reader side panels cannot fit beside the strip at the low end of desktop, and their focus and Esc behaviour is undefined. At 1024 px, 300 + 360 + four 12 px insets leave 316 px, below the strip's 480 px minimum, yet "panels push the strip, never cover it". The novel column (68 ch of Literata at 19 px, about 700 px) fails the same way below about 1410 px. Nothing says whether panels are modal, where focus goes when `t` or `,` opens one, how focus moves between the strip and a panel, or whether Esc closes a panel before leaving fullscreen or cinema.

**Evidence.**
- Lines 2430–2432: left panel 300 wide, right panel 360 wide, "panels push the strip, never cover it"; line 291 `readerStripMax` `clamp(480px, 50vw, 900px)`.
- Line 2463: novel panels 300 and 360, "never cover the text".
- Line 2408: "Esc closes the topmost overlay, then leaves fullscreen, then cinema, then the reader" (panels not mentioned). Grep for "non-modal", "aria-modal", "F6": no hits.

**Fix.** Only one side panel may be open when `viewport − 660 − 48 < 480` (manga) or `viewport − 660 − 48 < column width in px` (novel), that is below 1188 px (manga) and about 1410 px at the default novel measure: opening the second closes the first with the same `sheet` spring. Panels are non-modal `role="complementary"` landmarks labelled "Chapters" and "Reader settings" (novel: "Contents", "Type, voices and listen"); opening one by key moves focus to its current row or first control; `F6` cycles strip → left panel → right panel; Esc inside a panel closes it and returns focus to the strip; the Esc order becomes menu or popover → panel → fullscreen → cinema → leave the reader.

---

## WEB-12 · medium · §7.15 Dock and accessory, §15.2 Document defaults (mobile web soft keyboard)

**Problem.** Mobile web sets `interactive-widget=resizes-content` for the whole app, which shrinks the layout viewport when the on-screen keyboard opens, so the fixed dock, search orb, accessory and bulk toolbar (about 150 px) ride up above the keyboard and cover the field being typed in on every screen with a text field (Library filter, Sources filter, the Ask box, collection name, bookmark note, settings search, go-to fields). Only the search orb's own field is specified with the keyboard.

**Evidence.**
- Line 3804: "the viewport meta with `viewport-fit=cover, interactive-widget=resizes-content`"; line 1521 explains it only for the orb's search field.
- Line 1643: the dock is "Hidden in both readers, on the profile picker, auth and setup, and while a full-height sheet is open"; no keyboard rule (grep for "keyboard open", "keyboard is open", "on-screen keyboard": no hits).

**Fix.** On mobile web (and phones), while an `input`, `textarea` or `[contenteditable]` other than the orb's search field has focus under `pointer: coarse`, the dock, orb, accessory and floating toolbars dematerialise (`dematerialize`, 350 ms) and become `inert`; they return 100 ms after `focusout`. The bottom scroll inset drops to 16 px meanwhile and the focused field is scrolled into view with `scroll-padding-bottom: 16px`.

---

## WEB-13 · medium · §8.0.8 Mobile web gesture hygiene, §7.23, §8.15.3 (long-press on mobile web)

**Problem.** Glass relies on long-press everywhere, but only posters, pages and orbs suppress the browser's own long-press behaviour. Rows, chapter rows, history tiles, cards, dock tabs, the back button (back menu), Continue buttons and the reaction button are links or buttons that will show iOS Safari's link preview or callout and Android Chrome's link context menu at the same moment Glass lifts the item. The `contextmenu` event is never prevented on touch, and Base UI's ContextMenu (a listed dependency) has its own touch long-press. In the novel reader, the Glass menu "above the selection" collides with the native selection toolbar that iOS Safari and Android Chrome draw in the same place.

**Evidence.**
- Line 2099: "Posters, pages and orbs set `-webkit-touch-callout: none; user-select: none`".
- Line 3461: press and hold applies to "Posters, rows, cards, orbs, the hero card"; line 1642 long-press on dock tabs; line 1888 long-press on Back (500 ms); line 3504 reaction hold.
- Line 3805: `@base-ui/react` "Dialog, Menu, ContextMenu …"; grep for "contextmenu" (the DOM event): no hit.
- Line 2476: "blooms a `glassThick` menu above the selection".

**Fix.** Apply `-webkit-touch-callout: none; -webkit-user-select: none; user-select: none` to every long-press target listed in §11, keep them real `<a href>` elements, and call `preventDefault()` on `contextmenu` when the preceding `pointerdown` had `pointerType === "touch"`. Glass's own 150/450 ms timer owns long-press; Base UI's ContextMenu is used for right-click and `shift+F10` only. Novel reader on mobile web: keep the native selection toolbar (Copy lives there) and place the Glass menu 12 px **below** the selection's last line with only Bookmark this paragraph, Play from here, React and Recommend.

---

## WEB-14 · low · §8.17, §8.15.4, §9.4.3, §11, §15.2 Dependencies (pinch on mobile web outside the manga reader)

**Problem.** The gesture matrix promises pinch on mobile web for Library density, novel text size and the guided-view overview, but the dependency note limits the pinch library to the manga reader, and no `touch-action` rule stops the browser from page-zooming instead.

**Evidence.**
- Line 3805: "`@use-gesture/react` 10.3.1 (reader pinch only)"; line 2436 gives `touch-action: pan-y` only for the manga strip.
- Line 3475 (Pinch the grid, Mobile web "Same"), line 3486 (Pinch, Novel reader, Mobile web "Same"), line 3487 (Pinch out, Guided view, "Same").

**Fix.** Change the ledger line to "reader, Library grid, novel column and guided view pinch" and state `touch-action: pan-x pan-y` on the Library grid, the novel column and the guided-view camera (browser pinch-zoom stays available everywhere else, WCAG 1.4.4); the grid pinch is ignored while `visualViewport.scale > 1`.

---

## WEB-15 · low · §7.9 Rails (desktop arrows) versus §2.4.1 rule 2 and §15.7

**Problem.** Desktop rail arrows are real glass inside scrolling page content, which breaks the "at most two single page-level controls" rule (Home's hero already uses both: the tinted Continue and the `glassClear` Details) and pushes the desktop count past its budget of six.

**Evidence.**
- Line 1582: "glass arrow buttons (44 `glassThin` circles) materialise at each end when the pointer is over the rail".
- Line 348: "Allowed in scrolling page content: at most two single page-level controls per screen"; line 3960 desktop budget has no slot for them.

**Fix.** Draw rail arrows as content twins (§2.4.1 rule 1): 44 px circles, `rgba(19,19,23,0.62)` fill, 0.5 px `rgba(255,255,255,0.22)` rim, inner light, no backdrop read; hover brightens the fill to `rgba(40,40,48,0.72)`; they fade in over `fadeIn` when the pointer enters the rail and out 300 ms after it leaves.

---

## WEB-16 · low · §7.8 Poster overlays, §8.17 Desktop hover, §7.7 Selected state

**Problem.** On desktop hover, the follow bell and favourite star appear "at its top corners", where the status tag (top-left), the 18+ capsule (top-left) and the "N new" badge (top-right) already sit; in select mode the 24 px check orb also goes top-right. Which element wins is unspecified.

**Evidence.**
- Line 1571: "status tag top-left … 'N new' badge top-right … 18+ capsule top-left".
- Line 2586: "hovering a poster reveals the follow bell and favourite star as 32 px content-twin buttons … at its top corners".
- Line 1565: selected "a 24 px check orb top-right".

**Fix.** On hover (and on keyboard focus), the status tag and "N new" badge fade out over 120 ms while the star (top-left, 8 px inset) and bell (top-right, 8 px inset) fade in; the 18+ capsule moves to bottom-right while the buttons show. In select mode the status tag, "N new" badge, star and bell are hidden (as inventory LB13), the check orb takes the top-right, and the new count stays in the accessible name.

---

## WEB-17 · low · §7.13 In-page tabs versus §7.6 Segmented control (Search, Updates, Statistics, Downloads)

**Problem.** The same controls are specified as two different components. §7.13 lists "Search scopes on desktop", "Updates (All | Unread | Followed)" and "Statistics ranges" as tab strips with a swipeable pager, while the screens specify a vertical segmented list (not defined in §7.6, which is horizontal only), and segmented controls for Updates and Statistics. The Downloads tab order also differs.

**Evidence.**
- Line 1619: "Where: … Downloads (Chapters | Storage | Queue) … Updates (All | Unread | Followed), Search scopes on desktop, Statistics ranges."
- Line 2260: desktop Search "left filter column 220 px (scopes as a vertical segmented list …)"; line 2638: Updates "Segmented **All · Unread · Followed**"; line 2962: Statistics "range segmented **7 d · 30 d · 90 d · Year**"; line 2652: Downloads "**Chapters · Queue · Storage**"; line 3478 lists Updates and Statistics as horizontal pagers.

**Fix.** Updates and Statistics use the §7.6 segmented control (no pager, no swipe); remove them from line 1619 and from line 3478. Desktop Search scopes are a vertical list in the 220 px column: 40 px rows, `role="tablist" aria-orientation="vertical"`, the `glassThin` droplet indicator travelling vertically on `tab`, `↑`/`↓` move; remove "Search scopes on desktop" from line 1619. Downloads order is Chapters · Queue · Storage everywhere.

---

## WEB-18 · low · §7.7, §7.8, §2.8.3 (focus appearance)

**Problem.** Keyboard focus scales a poster by 1.04 in one section and a card or poster by 1.03 in another; and the focus glow is applied with a `box-shadow` utility that replaces the glass surface's own drop shadow and inner light while focused.

**Evidence.**
- Line 1565: cards "**focused** ring + scale 1.03"; line 1574: posters "focus scale 1.04 + ring".
- Line 709: `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-iris300 focus-visible:shadow-(--mm-focus-glow)`, while every glass tier draws its thickness with `box-shadow` (§2.4.3 "Inner light … `inset 1px 1px 0` …").

**Fix.** Focus scale 1.04 for posters and cards (1.02 for rows). On glass surfaces, `:focus-visible` appends to the surface's own shadow list instead of replacing it: `box-shadow: 0 0 0 2px #000, 0 0 0 6px rgba(188,176,255,0.28), var(--glass-shadow), var(--glass-inner-light)`; the Tailwind `shadow-(--mm-focus-glow)` utility is for content-layer elements only.

---

## WEB-19 · low · §8.0.3 `index`, §8.24 (desktop `/more`)

**Problem.** "On desktop `/more` redirects to `/settings`" cannot be done by the server (it does not know the viewport), so it becomes a client redirect after paint, and resizing a window across 768 or 1024 px while on `/more` would navigate the user away. Cinematic renders `/more` on desktop.

**Evidence.** Line 1998: "Tab root (phone); on desktop `/more` redirects to `/settings`"; line 2679 repeats it; `cinematic/DESIGN.md` line 2868: "`/more` renders the same index in two columns".

**Fix.** `/more` renders the You screen at every width (desktop: the profile block and cards in a two-column layout at most 880 px wide, the grouped lists beneath); no viewport-dependent redirect.

---

## WEB-20 · low · §7 Component catalog, §8.0.7 Desktop web (pointer cursors)

**Problem.** Desktop web requires "hover states on everything interactive", but no cursor is specified anywhere, including the cases where the browser default is wrong: draggable glass (reorder handles, the speed dial, the voice orbit, slider thumbs, the scrub rail, the spotlight card), the image viewer's zoom states, the novel column, the hidden-chrome reader and the middle-click autoscroll anchor.

**Evidence.** Grep for "cursor" in DESIGN.md: only a pagination `cursor` query parameter (line 3115). Line 2080: "hover states on everything interactive".

**Fix.** Add a cursor table to §7: `pointer` on every activatable element (posters, cards, rows, orbs, chips); `grab` / `grabbing` on reorder handles, the sheet grabber, the speed dial, the voice orbit, slider and switch thumbs, and the spotlight card; `ns-resize` on the reader's scrub rail; `zoom-in` at 1× and `zoom-out` when zoomed in the image viewer; `text` on the novel column; `none` over the manga strip after 3000 ms without pointer movement while the chrome is hidden (restored on move); `all-scroll` while the middle-click autoscroll anchor is active; `not-allowed` on disabled controls.

---

## WEB-21 · low · §8.25 Settings (desktop search)

**Problem.** The settings search is placed only for phones ("a search well … a full-screen overlay"), but the desktop keys bind `/` to it; where the field sits on desktop and how its results show beside the 240 px section list is not stated.

**Evidence.** Line 2686: "**Layout, phone:** pushed page 'Settings' with a search well (a full-screen overlay filters …) … **Desktop:** a 240 px section list at left … and the section panel at right"; line 2689: "`/` searches settings".

**Fix.** Desktop: a 36 px `fill3` search capsule "Search settings" heads the 240 px section list; typing replaces the section list in place with the matching rows (grouped by section, "No settings match “{q}”" when empty); Enter or a click opens the section at right and flashes the row (Row pulse); Esc clears the field and restores the list; `/` focuses it.
