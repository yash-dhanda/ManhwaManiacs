# Glass DESIGN.md: accessibility, privacy and safety audit

Audited file: `docs/redesign/glass/DESIGN.md` (4,184 lines, post-critic). Sources of truth: `inventory/00-decisions.md`, `inventory/capabilities.md`.

**Method.** Every contrast figure below was computed for this audit with the WCAG 2.x relative-luminance formula, compositing the glass stack exactly as §2.1.7 and §2.4.2 describe it: backdrop, then any scrim, then `dimLegibility`, then the tier fill. The glass fills are T2 `rgba(255,255,255,0.07)`, T3 `rgba(255,255,255,0.06)` and T4 `rgba(28,28,34,0.52)`. The alpha labels use `rgba(235,235,245,a)`. A reproduction of the document's own figures confirms the model: `onGlass` on T3 over white at dim 0.64 comes out at 5.18 (the doc says 5.14), and on the dock plateau at 8.78 (the doc says 8.8). Before reporting anything as missing, I grepped the whole file for it.

The thresholds are 4.5:1 for text, 3:1 for large text (24 px, or 18.66 px bold), and 3:1 for icons, focus rings and non-text UI.

There are 34 findings: 7 high, 17 medium and 10 low.

---

## High

### A11Y-1 · high · §2.4.2, §2.1.7, §7.31, §8.8, §8.12: `glassClear` contradicts the legibility floor and fails badly over light art
- **Problem.** Two rules disagree:
  - The variant table says `glassClear` gets no `dimLegibility` at all. It gets only `dimClear` beneath the media, and only when the media's `Lb > 0.45`.
  - §2.1.7 puts `dimLegibility` inside every variant except `solid*`, and lists `Lb` sources for the `glassClear` hero controls.

  If an implementer follows the variant row, labels and glyphs on clear glass fail:
  - The image-viewer close button over a white page measures 2.14:1.
  - The Home "Details" secondary over a pale cover measures 2.14:1.
  - Over a light-grey cover with `Lb` 0.43 (no dim at all), it measures 1.91:1.
- **Evidence.**
  - §2.4.2 `glassClear` row: "`dimClear` beneath the media region when the media's `Lb > 0.45`, never inside the glass".
  - §2.1.7: "`dimLegibility` … Inside **every** glass surface … (all tiers, all variants except `solid*`)".
  - §2.1.7 `Lb` table: "Home hero controls (`glassClear` over the spotlight card …) | The spotlight cover palette's `l`".
  - §7.31: "`glassClear` close button top-left (44)".
- **Fix.**
  - Replace the Dim cell of the `glassClear` row with "`dimLegibility` (as every tier), plus `dimClear` `rgba(0,0,0,0.35)` beneath the media region at any `Lb`".
  - Add a check-contrast case: `onGlass` on `glassClear` over `#FFFFFF` with the 0.35 `dimClear` and dim 0.64 must be ≥ 4.5:1.
  - Alternatively, give every `glassClear` control a local plateau `rgba(0,0,0,0.60)` under its footprint, feathered 12 px. That measures 4.92:1 with no dim.

### A11Y-2 · high · §2.1.7, §2.1.8, §7.12, §8.14, §15.8: the legibility floor is built on cover-mean luminance and a 0.5 fallback, and whole classes of surfaces have no `Lb` source
- **Problem.**
  - **Mean luminance hides bright patches.** `palette.l` is the cover's *mean* luminance, but a dark cover can have a white area directly under a control. Hero controls, the series band group and the image viewer use `palette.l` and have no `edgeSoft` plateau. With `l` = 0.2 over a white patch:
    - T3 `onGlass` measures 1.81:1.
    - T2 measures 1.80:1.
    - The tinted primary's `onTint` measures 3.97:1.
  - **The fallback is unsafe.** "Unknown → `Lb` 0.5" gives dim 0.43. That leaves T2 at 2.55:1 and T3 at 2.59:1 over white, which applies on the first frame of every surface and in the reader before the first page sample lands.
  - **Reader overlays have no `Lb` row at all.** These surfaces sit over pages with no `Lb` source:
    - the page menu and the go-to popover (`glassThick`)
    - the next-chapter card (`glassThick`)
    - the reaction bubbles (T2)
    - the brightness HUD and the cruise HUD
    - the "Previously · 20 s" pill (T2)
    - the "Match 1 of 3" capsule
    - the reader settings sheet
  - **Desktop has no bottom plateau.** Desktop toasts (bottom-left), the app-update capsule and the catalogue "Top" capsule use the `lItems` mean estimate with no bottom plateau.
  - **The gate is too narrow.** §2.1.7 says "menus and sheets sit over their own dim", but menus opened by a tap have no dim (only context menus get `dimContext`). The CI gate asserts only three cases.
- **Evidence.**
  - §2.1.8: "ships … the cover's mean relative luminance as `palette: {…, l: 0.41}`".
  - §2.1.7: "Anything whose backdrop is unknown … | `Lb = 0.5`".
  - §2.1.7: "Sidebar, menus, sheets on ordinary screens | The field term alone (… menus and sheets sit over their own dim)".
  - §15.8: "composites the three worst glass cases".
- **Fix.**
  1. Add `lMax` (the 95th-percentile relative luminance of the `w=96` cover) to `palette` in the same Pillow pass, and use `Lb = lMax` for every surface over cover art.
  2. Change the unknown fallback to `Lb = 1.0` (dim 0.64).
  3. Add `Lb` rows for reader overlays: `max(lTop, lMid, lBottom)` over the vertical bands the surface overlaps.
  4. Add `Lb` rows for tap-opened menus and popovers: `max(field term, lItems under the surface)`.
  5. Give every free-floating glass surface over content that has no `edgeSoft` plateau a local plateau `rgba(0,0,0,0.60)` under its footprint, feathered 12 px. T3 with `Lb` 0.2 over white then measures 7.0:1.
  6. Extend `check-contrast.mjs` with `onGlass` over `#FFFFFF` on T2, T3 and T4 at the fallback dim, `onTint` over `#FFFFFF` at dim 0.30, and `onGlass` on T3 under the 0.60 local plateau at dim 0.30. Each must be ≥ 4.5:1.

### A11Y-3 · high · §2.1.2, §2.1.3, §7.1, §7.2, §7.15, §7.23, §8.14.2, §14.2: accent and semantic colours are drawn on glass, contradicting "every glyph on glass is `onGlass`", and fail
- **Problem.** Several components put `iris*`, `danger` and other state colours directly on glass. Measured values:

  | Where | Colour | Surface | Ratio | Needed |
  |---|---|---|---|---|
  | Dock active label, 11 px (§7.15) | `iris400` | edge plateau | 4.11:1 | 4.5 |
  | Reader bookmark "saved" glyph (§8.14.2) | `iris400` | reader T3 over a white page at dim 0.64 | 2.43:1 | 3 |
  | Selected toggle-button label over media (§7.1) | `iris300` | reader glass | 2.97:1 | 4.5 |
  | Reader download-control states | `danger` / `iris500` | reader glass | 1.91 / 1.81:1 | 3 |
  | Destructive menu rows (§7.23) | `danger` | T4 over a white cover | 1.94:1 | 4.5 |
  | Selected menu check (§7.23) | `iris400` | T4 over a white cover | 2.47:1 | 3 |
  | Destructive row in a context menu | `danger` | `dimContext` | 3.77:1 | 4.5 |
  | Button error label "Couldn't save" on the tinted primary | `danger` | tinted primary | 1.84:1 | 4.5 |

  §14.2 states the opposite: text on glass is only `onGlass`/`onTint`.
- **Evidence.**
  - §2.1.2: "every glyph on glass is `onGlass`".
  - §2.1.3 `iris300`: "accent text on glass"; `iris400`: "active tab glyph".
  - §7.15: "the active glyph and label are `iris400`".
  - §7.1: Selected "label `iris300`"; Error "in `danger` on the same glass"; Destructive (secondary) "`glassThin` | `headline` `danger`".
  - §7.23: "destructive rows `danger`" and "selected (trailing check `iris400`)".
  - §8.14.2: "bookmark (toggle; saved state Fill `iris400`)".
- **Fix.**
  - **Rule.** On glass, text is always `onGlass`/`onTint`. State colour appears only as a glyph or ring drawn on an opaque backing disc or droplet `rgba(0,0,0,0.60)`. Inside reader glass over white, that gives `iris400` 6.14:1, `danger` 4.83:1 and `iris500` 4.59:1.
  - **Dock.** The label stays `onGlass` at weight 700 and the glyph is `iris400`: 4.11:1, which passes the 3:1 icon threshold.
  - **Menus.** Destructive rows use an `onGlass` label plus a `danger` glyph on the backing disc. T4/T5 surfaces carrying coloured glyphs raise their dim floor to 0.80 when `Lb` > 0.5; at that floor `danger` measures 4.92:1 and `iris400` 6.25:1.
  - **Button errors.** Show the error line under the button in `danger` on content (6.94:1), not inside the tinted glass.
  - **CI.** Add every (accent colour, glass tier, worst backdrop) pair to `check-contrast.mjs`.

### A11Y-4 · high · §2.1.2, §7.3, §7.6, §7.10, §7.17, §8.14.5: alpha label roles are used inside partial-detent glass sheets and menus, and fail over white pages
- **Problem.** Component specs put `label2`/`label3` inside T4 glass:
  - wells "on a sheet" with `label3` placeholders and `label2` field labels;
  - segmented controls "compact 32 inside sheets", with unselected segments in `label2`;
  - grouped-list subtitles in sheets.

  The manga reader settings sheet opens at `medium` over the page. The same case applies to the chapter list, Tags and Recommend sheets over art. Over a white page, with `dimSheet` 0.28, the field-term dim of 0.22 and T4:
  - an unselected segment label (`label2` on a `fill3` track) measures 3.40:1;
  - `label3` measures 2.79:1;
  - even at the 0.5 fallback, `label2` measures 4.02:1 and a `label3` placeholder in a `fill2` well measures 3.07:1.

  This also contradicts "text on glass never uses alpha".
- **Evidence.**
  - §7.3: "fill `fill3` on black or `fill2` on a sheet … placeholder `label3`; label above in `footnote` 13/600 `label2`".
  - §7.6: "Track: `fill3` capsule, height 36 (compact 32 inside sheets) … `label2` elsewhere".
  - §7.10: partial detents are `glassThick`.
- **Fix.**
  - Inside any T4/T5 glass surface, wells and tracks use `rgba(0,0,0,0.35)` instead of `fill2`/`fill3`. Text roles map as follows:
    - `label1` → `onGlass`;
    - `label2` stays allowed only on that dark well (5.20:1 worst case);
    - `label3` is never used inside glass (it still measures 4.0:1 on the dark well), so use `label2`.
  - Alternatively, reader sheets use `solid1` at every detent.
  - Add a check-contrast case: `label2` on a `rgba(0,0,0,0.35)` well inside T4 over `#FFFFFF` under `dimSheet` 0.28 at dim 0.22 must be ≥ 4.5:1.

### A11Y-5 · high · §9.2.3, §9.2.4, §14.11: share cards export mature source and genre names and another profile's reading
- **Problem.** The share-side rule only excludes "mature series and covers", but the exported images carry other gated content:
  - Card 10 prints the top source's logo and name, and its share bars list the top three sources. 56 of the 90 connectors are 18+.
  - Cards 5 and 12 print genre words ("Mostly …", "the genre words"). The design itself names Adult, Ecchi, Hentai, Mature and Smut as mature genres.
  - Card 11 "Together" exports a *friend's* name, orb and the series they read. The friend shared that with the Circle, not with the public.

  These images leave the device through `navigator.share` and `share_plus`.
- **Evidence.**
  - §9.2.4: "**Mature series and covers are never drawn on a share card**".
  - §9.2.3 card 10: "the source logo 64 px … the top three sources as share bars"; card 5: "the top genre named large"; card 11: "You and Aarav both read …".
  - §8.7: "Mature genres (Adult, Ecchi, Hentai, Mature, Smut)".
- **Fix.** Extend the rule to: "Share sides never draw a mature series, cover, source name or logo (`source.mature`), or a mature genre. The next eligible item takes the place, and a card with no eligible item is omitted from the share set." In addition:
  - Card 11 has no Export. Alternatively, its share side omits the friend's name and orb, showing "You and a friend both read …" with no second orb.
  - Add a gate-close checklist item: render every share side for a gate-open profile with a mature-heavy year, then assert that no mature source or genre string appears.

### A11Y-6 · high · §8.0.8, §14.11: the gate-close purge misses local holders that the design itself reads offline
- **Problem.** Purge step 5 deletes only the cached `/home`, statistics, Wrapped, recap and Circle payloads. Several offline views read other device caches that can hold mature rows, and none of them is purged or filtered:
  - Library offline: "follows from the device cache".
  - Sources offline: "the web's cached `GET /sources` response and mobile's `manhwamaniacs:source-pins` plus the follow cache", which holds 18+ sources.
  - Collections offline: "members from the library cache".
  - History offline: "the device's recent reads from local progress".
  - Bookmarks offline: "phones read the local store".
  - Settings → AI: the "Series you asked not to recap" list (`mm.recap.skipSeries`, with covers from the library cache).
  - The command palette's "recent items".
  - The web service worker's pages cache, which holds RSC/HTML of visited mature routes and is served offline.

  Checklist item (6), "no mature cover appears anywhere", cannot pass with the purge as written.
- **Evidence.**
  - §8.0.8 step 5 lists five payload types.
  - §8.10, §8.17, §8.18, §8.19, §8.20 offline states.
  - §8.25.16.
  - §7.28: "idle (recent items and suggested actions)".
  - §8.25.2: "(it drops the pages cache …)".
- **Fix.** Make step 5 an exhaustive holder table:

  | Holder | Action on gate close |
  |---|---|
  | Library/follow cache rows (they carry `rating`, `mature_override`) | filter on read with the same predicate the server uses for the gate (resolved `rating == "mature"` honouring `mature_override`, or `source.mature`) |
  | Source list and pins caches (`mature: bool`) | filter on read |
  | Collection member cache | filter on read |
  | Local progress and bookmark stores | filter on read by the series' mature flag |
  | `mm.recap.skipSeries` display | filter on read |
  | Palette recents (stored as `{item, gateOpen}` like recent searches) | delete entries made while the gate was open |
  | Service-worker pages cache (entries tagged `x-mm-mature: 1` at fetch time) | delete |

  Add the palette recents, an offline Library and an offline Sources directory to the §14.11 checklist.

### A11Y-7 · high · §8.22: downloads and exports are exposed outside the app, bypassing the per-profile scope and the 18+ gate
- **Problem.**
  - **iOS.** The design contradicts itself. The Chapters tab says downloads "live inside ManhwaManiacs", while the Storage tab tells the user to "Browse, copy or delete downloads in the Files app". If the download store sits in `Documents` (the Files-visible folder that Save to Files also writes into), every profile's downloads, including gate-hidden mature pages, are browsable in Files by anyone using the device.
  - **Android.** Save to Files writes page images into `MediaStore.Downloads`. MediaStore indexes image MIME types, so the pages appear in gallery apps, with no mature handling or warning.
- **Evidence.**
  - §8.22 Chapters: "(iOS: 'Downloaded chapters live inside ManhwaManiacs. For a copy you can open elsewhere, use Save to Files.')".
  - §8.22 Storage: "(iOS: 'Browse, copy or delete downloads in the Files app: On My iPhone → ManhwaManiacs')".
  - §8.22 Save to Files: "iOS writes into the app's Documents folder …; Android writes through `MediaStore.Downloads` (`RELATIVE_PATH = "Download/ManhwaManiacs/{series}"`)".
- **Fix.**
  - The chapter store lives in `getApplicationSupportDirectory()` (iOS `Library/Application Support`, never shown in Files) and is marked `NSURLIsExcludedFromBackupKey`.
  - Only explicit Save to Files exports go to `Documents`. The Storage note becomes: "Files you saved with Save to Files are in the Files app: On My iPhone → ManhwaManiacs."
  - For a mature series, Save to Files offers CBZ only (`application/vnd.comicbook+zip`, never indexed as images) and shows the line "Saved files leave ManhwaManiacs: other apps and anyone using this device can open them, and the 18+ setting can't hide them."
  - Page-image exports write a `.nomedia` file into the series folder first.

---

## Medium

### A11Y-8 · medium · §8.0.8, §8.9, §8.22: purge rule 4 deletes the web's downloads, and the local mature flag goes stale
- **Problem.**
  - **Rule 4 against rule 6.** Rule 4 deletes "Cache Storage entries tagged `mature=1`". On the web, downloads *are* Cache Storage behind the service worker (capabilities §24), so a gate close deletes them. That contradicts rule 6 ("never delete them") and checklist item (9) ("reopening the gate brings all downloads back untouched").
  - **Stale flag.** A download's `mature` flag is "set from the series payload at download time". A later `mature_override` (§8.12 "Always mature"), a `rating` resolved from `unknown` to `mature`, or `source.mature` never updates it, so a gated profile can see the chapter.
  - **Unscoped text index.** The novel-text FTS index `novel_text(source, series, chapter, para, text)` and the IndexedDB `mm-novel-text` carry no profile scope or mature flag, although the scope says "in this profile's downloads scope". Removing one profile's download also drops the shared index rows for another profile.
- **Evidence.** §8.0.8 steps 4 and 6; §14.11 item (9); §8.9 Novel text scope.
- **Fix.**
  - Rule 4 applies only to the image and HTTP caches (for example `mm-img-v1`, `mm-pages-v1`), never to the downloads cache (`mm-downloads-v1`).
  - The local mature flag is recomputed on every library or series sync, and at read time from the cached follow row, with the same predicate the server uses for the gate (resolved `rating` honouring `mature_override`, or `source.mature`).
  - Novel-text queries join the per-profile downloads index on `(source, series, chapter)`, filter out mature items when the gate is closed, and delete index rows only when no profile still holds the chapter.

### A11Y-9 · medium · §8.22, §8.25.9: device-wide storage actions have no defined scope against per-profile downloads and gate-hidden items
- **Problem.** Downloads are "profile-scoped", but several Storage controls act on the device without saying for whom they run:
  - "Free up space" (removes read chapters: read by whom?);
  - "Remove all downloads" and "Reset offline storage" (the latter "unregisters the service worker and clears caches");
  - the cap chips (2 to 20 GB), "Delete after reading", "Clear image cache".

  As written, a gated profile can delete other profiles' downloads and mature downloads it cannot see. That breaks isolation and checklist item (9).
- **Evidence.** §8.22 Storage tab and web Storage; §8.0.9: "downloads are profile-scoped".
- **Fix.**
  - "Free up space", "Remove all downloads" and per-series removal act only on the active profile's *visible* downloads.
  - "Reset offline storage", the cap and the image and metadata caches are device-wide. They are labelled "for everyone on this device", the alert body says "This removes downloads for every profile on this device, including ones you can't see here", and they are available only to `is_admin`.
  - Eviction under the cap never removes another profile's pinned or unread chapters.

### A11Y-10 · medium · §8.23, §8.9: dialogue search returns other accounts' OCR hits, which leaks their activity and implies hidden rows
- **Problem.**
  - OCR text is global across accounts (capabilities §20) and `GET /ocr/search` has no scope parameter. Results therefore include series that other accounts downloaded and scanned, which reveals what they read.
  - The screen says it searches "the series you follow" and joins only from the library, but it never says what happens to hits that can't be joined.
  - "Showing the first 20 of 86 matches" would count rows the viewer never sees, which is the pattern the gate forbids.
- **Evidence.**
  - §8.23: "Search what characters said across the series you follow … title (joined from the library)".
  - capabilities §20: "`GET /ocr/search` | `q, limit (≤100), offset`"; "OCR text is global (shared across accounts)".
- **Fix.**
  - Add `scope=followed` to `GET /ocr/search`: the server filters by the active profile's `followed_series` and returns `total` after the filter. List it in §15.5.
  - Until then, the client drops unjoinable hits and shows no total ("Showing 20 matches" plus "Load more").
  - The Search "Dialogue" scope uses the same rule.

### A11Y-11 · medium · §7.2–§7.30, §3.3, §14.7: fixed component heights clip text at 200 % text scale
- **Problem.** Heights are given as fixed values, and neither §3.3 nor §14.7 says they grow with the text scaler (only rows, grids, rails and dock labels are addressed). At 2.0× (Android 2.0, iOS AX2 1.94), with the web `rem`-sized text inside `px` heights:
  - a filter or choice chip (`subhead` 15/20 → 30/40) clips in its 32 px height;
  - a tag (`caption1` 12/16 → 24/32) clips in 24 px;
  - a status tag clips in 22 px;
  - the 18+ badge and source badge clip in 20 px;
  - the title capsule (`subhead` → 40 line) clips in 36 px;
  - the segmented track clips at 36/32 px;
  - a menu row (`body` → 48 line) clips in 44 px;
  - a two-line toast (2 × 43 px) clips in 60 px;
  - an S button (`subhead` 40 line) clips at 34 px;
  - the tab-strip indicator clips at 32 px;
  - the status capsule clips at 32 px.
- **Evidence.**
  - §7.5: "Height 32"; "Height 24".
  - §7.20: "22 tall capsule"; "20 tall capsule".
  - §7.14: "`glassThin` capsule, 36 tall".
  - §7.6: "height 36 (compact 32 inside sheets)".
  - §7.23: "rows 44 tall".
  - §7.12: "height 44 (two-line variant 60 with radius 22)".
  - §14.7 checks at 2.0 but defines no behaviour.
- **Fix.**
  - Add one rule to §7: every height in the catalog is a **minimum**, `height = max(token, lineHeight × textScale + 2 × verticalPadding)`.
  - Web: author these heights as `min-height` in `rem` (chip `min-height: 2rem`, tag `1.5rem`, menu row `2.75rem`) with vertical padding, never `height`.
  - Flutter: `ConstrainedBox(constraints: BoxConstraints(minHeight: token))` plus padding, never `SizedBox(height:)` around text.
  - Capsules keep `rCapsule` as they grow.
  - From AX1, toasts wrap to as many lines as needed with radius 22.

### A11Y-12 · medium · §3.3, §14.7, §8.14.2, §9.2.3: the reader chrome and Wrapped ignore the text scale
- **Problem.**
  - "The reader chrome keeps its own fixed sizes", so the title capsule, the "18 / 40" readout, chips and HUD values never scale. On the web that is a WCAG 1.4.4 failure; on phones it ignores Dynamic Type and the font scale.
  - Wrapped lays out in a fixed 360 × 640 frame "scaled uniformly", so the eyebrow (12 px), footnote (13 px) and headline (28 px) never respond to the text scale. Only the screen reader gets an alternative.
- **Evidence.**
  - §3.3: "the reader chrome keeps its own fixed sizes and moves secondary controls into the settings sheet".
  - §3.7 `type.wrappedNumeral`: "none (the frame scales, not the text)".
  - §9.2.3: "scaled uniformly to the frame on screen".
- **Fix.**
  - **Reader chrome.** Scales with the scaler up to 1.35× (xxxL), with capsules growing in height. Above that, the title capsule truncates and the page readout moves into the go-to popover. Web chrome text is sized in `rem`.
  - **Wrapped.** At text scale ≥ 1.3, cards switch to a reflowing layout: the same slots stacked in a vertically scrolling card, with text at the scaled size and the figure scaled to the remaining width. The 360 × 640 frame stays for the share side only.

### A11Y-13 · medium · §10.1, §3.3, §3.7, §8.0.8: the reveal primitives lose heading semantics, ignore the title caps and break words at large text
- **Problem.** The Flutter `LetterReveal` has four defects:
  - It wraps the heading in `Semantics(label: …)` without `header: true`.
  - Its "done" and reduced-motion path returns a plain `Text`, also with no header.
  - Route focus (§8.0.8 "Flutter requests focus on the title's `Semantics(header: true)` node") has no header node to land on, and screen-reader heading navigation loses every large title.
  - It builds a `Wrap` with one `Text` per grapheme, so lines break mid-word ("Libr / ary"), against its own "wrapped per word" rule. None of those `Text`s applies the §3.3 caps, and a `TextStyle` cannot carry a `TextScaler`, so a `largeTitle` reaches 106 px at AX5 instead of the 48 px cap.

  On the web, the component splits on `" "` and sets `.word { white-space: nowrap }`, so a CJK title (no spaces) is one unbreakable word. It overflows the viewport at 200 % zoom, and on phones even at 1×.
- **Evidence.**
  - §10.1 Flutter code: `Semantics(label: widget.text, child: ExcludeSemantics(child: Wrap(children: [for (var i = 0; i < chars.length; i++) …Text(chars[i], style: widget.style)` and `return Text(widget.text, style: widget.style);`.
  - Table: "wrapped per word so lines break at spaces".
  - Web: `text.split(" ")` and `.letter-reveal .word { display: inline-block; white-space: nowrap; }`.
- **Fix.**
  - **Flutter.**
    - Wrap both paths in `Semantics(header: true, label: text)`.
    - Group graphemes per word: one `Wrap` child per word, each an inner `Row(mainAxisSize: min)`.
    - Pass `textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: cap / baseSize)` to every `Text`, through a shared `GlassText` widget that §3.7 names as the only way to apply role caps.
  - **Web.**
    - Segment words with `Intl.Segmenter(undefined, { granularity: "word" })`.
    - Treat each grapheme as its own wrap unit for scripts without spaces (`\p{Script=Han}|\p{Script=Hiragana}|\p{Script=Katakana}|\p{Script=Hangul}` runs).
    - Add `overflow-wrap: anywhere` on `.letter-reveal`.

### A11Y-14 · medium · §7.12, §8.14.2, §9.2.3, §8.16.4, §14.1, §14.5: behaviour depends on "a screen reader is on", which the web cannot detect and Flutter never names
- **Problem.** Several rules switch on "a screen reader is on":
  - toasts stay until dismissed;
  - reader chrome never auto-hides;
  - Wrapped auto-advance stops and shows its buttons;
  - voice previews don't auto-play.

  Browsers expose no screen-reader signal. VoiceOver on iOS Safari and TalkBack on Chrome therefore get:
  - 4–5 s toasts;
  - hiding, inert chrome;
  - 6 s auto-advancing Wrapped with no visible pause;
  - auto-playing previews over speech.

  The Flutter signal (`MediaQuery.accessibleNavigationOf`) is never named, so implementations will diverge.
- **Evidence.**
  - §7.12: "with a screen reader active, toasts stay until dismissed".
  - §8.14.2: "never while a screen reader is on".
  - §9.2.3: "whenever a screen reader or a keyboard is in use, and auto-advance stops while a screen reader is on".
  - §8.16.4: "(on the web it is off whenever the orbit was reached by keyboard)".
- **Fix.**
  - Name the Flutter source: `MediaQuery.accessibleNavigationOf(context)`, read through one `glassAssistiveProvider`.
  - On the web, add a per-profile Settings → Appearance switch "Screen reader mode" (stored in `mm.boot.a11y.sr`, stamped as `data-sr="on"` by the boot script). It turns on all four behaviours.
  - Independently of detection, on the web:
    - toasts with an action never auto-dismiss;
    - Wrapped always shows its 44 px pause button;
    - reader chrome never idle-hides after a keyboard or `Tab` interaction in the last 30 s;
    - the voice orbit auto-play defaults to off.

### A11Y-15 · medium · §7.12, §7.34, §8.0.6: toast actions (Undo) can be unreachable, and toasts cannot be dismissed by screen-reader users
- **Problem.**
  - Toasts have "no close button (swipe or wait)". With VoiceOver or TalkBack on they "stay until dismissed", but a swipe is not available to screen-reader users (VoiceOver swipes move focus), so the toast never leaves.
  - Destructive swipe actions promise "a 5 s Undo toast instead of a confirm". The keyboard path is `u`, a single-key binding that the Single-key switch disables. No shortcut moves focus into the toast region, so a keyboard user cannot reach Undo within 5 s.
- **Evidence.**
  - §7.12: "no close button (swipe or wait)"; "5 s with Undo"; "with a screen reader active, toasts stay until dismissed".
  - §8.0.6: "`u` | Undo the last destructive action"; "Off, every binding without a modifier is skipped".
- **Fix.**
  - Every toast gets a 44 px × close button, which also becomes a Flutter `Semantics(customSemanticsActions: {Dismiss})` and the VoiceOver escape gesture (`onDismiss`).
  - Toasts live in a `role="region" aria-label="Notifications"` landmark reachable by `F6` and `alt+t`.
  - Keyboard focus inside a toast pauses its timer.
  - Undo also binds to `mod+z`, which survives the Single-key switch.
  - A toast with Undo lasts 10 s and stays indefinitely while focus or the pointer is inside it.
  - `mod+z` undoes the last destructive action for 60 s after its toast leaves, so the timed toast is never the only path (WCAG 2.2.1).

### A11Y-16 · medium · §8.0.6, §8.25.13, §14.4: the Single-key switch disables arrows, Esc, Enter and Space
- **Problem.** WCAG 2.1.4 only concerns character keys (letters, digits, punctuation, symbols). The switch as written skips "every binding without a modifier", which includes arrows, Home/End, Page Up/Down, Space, Enter, Esc, Delete and Tab-adjacent bindings. With the switch off, users cannot page the reader, move through grids and rails, or close layers with Esc.
- **Evidence.** §8.0.6: "Off, every binding without a modifier is skipped (WCAG 2.1.4)".
- **Fix.**
  - Change the wording to: "Off, every binding whose key is a printable character (letters, digits, punctuation and symbols, including `?`, `/`, `[`, `]`, `.`, `,`, `<`, `>`, `=`, `+`, `-`, `*`) is skipped. Arrows, Home, End, Page Up/Down, Space, Enter, Esc, Tab, Delete, Backspace and F-keys stay."
  - Every character action that loses its key keeps a visible button or a modifier alias (`mod+z` undo, `alt+b` bookmark, `alt+/` search).

### A11Y-17 · medium · §8 (intro and most screens), §9, §14.5: per-screen screen-reader semantics, focus order and live regions are missing for most custom widgets
- **Problem.** §8 promises that "every screen lists" layout, states, keys and so on, but not semantics or focus order. The accessibility pass (§15.8) then checks "focus order" against nothing. Only a few widgets define roles and names:
  - the dock, the spotlight, the genre field, the presence arc, the speed dial, charts, Wrapped and the recap.

  These have no role, name or value:
  - the voice orbit (a carousel of 31 cards);
  - the Downloads storage meter (a three-part liquid capsule);
  - the Search jump bar and the tier-progress capsule;
  - the listen transport buttons, the scrubber value ("5:12 of 23:52") and the sentence list;
  - the soundscape scene orbs and level bars;
  - the onboarding progress dots;
  - the avatar grid and mood chips;
  - the series split button (two targets);
  - the collection fanned stack;
  - the guided-view counter and panel content;
  - the image viewer (image name, zoom level).

  Live regions are defined only for toasts, reorder, chart readouts, palette searching and refresh. There are none for:
  - "searching 8 more sources" and late groups;
  - the AI phase lines and dealt answers;
  - download progress and completion;
  - "Match 1 of 3" and "Panel 4 of 38";
  - the "Offline" and rate-limit capsules;
  - the listen "now speaking" chip.
- **Evidence.**
  - §8 intro lists "layout per platform … all states, keyboard shortcuts … and inventory coverage".
  - A grep finds `aria-live` 4 times and "live region" once.
  - §8.16.4, §8.22 and §9.4.2 have no semantics lines.
- **Fix.** Add a **Semantics** line to every §8 and §9 screen giving its landmarks and heading levels, its focus order and the role, name and value of each non-text control. Minimums:
  - **Voice orbit:** `role="region" aria-roledescription="carousel"`, each card `role="group" aria-label="Aurora, 3 of 31, female, warm, in use for Kade"`; Flutter `onIncrease`/`onDecrease` like the spotlight.
  - **Storage meter:** `role="meter"` with `aria-valuetext="1.2 GB of 10 GB used: this profile 1.2 GB, other app data 3.4 GB, 5.4 GB free"`.
  - **Jump bar:** a list of buttons "Jump to MangaSource results".
  - **Split button:** "Continue, chapter 143" plus "More ways to read" (`aria-haspopup="menu"`).
  - **Transport:** "Back 15 seconds", "Previous sentence", "Play" / "Pause", "Next sentence", "Forward 15 seconds".
  - **Scrubber:** `aria-valuetext="5 minutes 12 of 23 minutes 52"`.
  - **Scene orbs:** a radio group "Soundscape" (Off, Rain … Deep); the level bars are hidden from assistive technology.
  - **Onboarding dots:** "Step 3 of 7".
  - **Avatar grid:** radio group "Avatar".
  - **Polite live region** for tier progress, AI phases, the "N picks" arrival, match and panel counters, and download completion.
  - **Assertive live region** for the offline and rate-limit capsules only when they first appear.

### A11Y-18 · medium · §7.8, §7.20, §8.17: poster overlays sit on cover art with no guaranteed backing
- **Problem.** Status tags are specified "at 18 % over black" but are placed on the poster image, and the other overlays have no backing either. Over a white cover:

  | Overlay | Ratio | Needed |
  |---|---|---|
  | READING tag (`iris400` text) | 2.07:1 | 4.5 |
  | COMPLETED / ON HOLD tags | 1.59:1 | 4.5 |
  | 18+ capsule | 2.30:1 | 4.5 |
  | Downloaded droplet (`success` on a `rgba(0,0,0,0.55)` circle) | 2.67:1 | 3 |
  | 3 px progress bar (`iris500` on `fill1`) | 2.04:1 | 3 |

  The favourite star and the `age-gate` glyph on posters have no specified backing at all.
- **Evidence.**
  - §7.20 Status tag: "colour at 18 % over black with the colour as text".
  - §7.8 Overlays: "status tag top-left … downloaded droplet glyph bottom-left (`success`, 16 px, on a 22 px `rgba(0,0,0,0.55)` circle) … 3 px bar … (`iris500` on `fill1`)".
- **Fix.**
  - Every overlay on a cover sits on an opaque backing `rgba(0,0,0,0.86)` (capsule, disc or track). With that backing, tags measure: `iris400` 6.54:1, `success` 8.73:1, `warning` 8.87:1, `mature` 5.35:1, `info` 7.37:1.
  - The droplet circle goes to `rgba(0,0,0,0.72)` (`success` 5.17:1).
  - The progress bar sits on a 5 px `rgba(0,0,0,0.86)` track (`iris500` 4.89:1).
  - The favourite star and the 18+ glyph each sit on a 22 px `rgba(0,0,0,0.72)` disc.
  - Add these to `check-contrast.mjs` over `#FFFFFF`.

### A11Y-19 · medium · §2.1.8, §7.7, §7.39, §9.2.1: text on the ambient field is never checked, and `label3` fails where the field is above 21 %
- **Problem.**
  - The field is a fixed layer, so text scrolls across it. Blobs are clamped to OKLCH L ≤ 0.78 (relative luminance up to 0.475) at up to 36 %.
  - With a blob of that luminance, `label3` over the blob centre measures:

    | Screen | Field opacity | `label3` ratio |
    |---|---|---|
    | Statistics, Wrapped | 24 % | 4.36:1 |
    | Home | 26 % | 4.24:1 |
    | Series detail band | 28 % | 4.11:1 |
    | Profile picker | 30 % | 3.98:1 |
    | Home hero enlargement | 36 % | 3.59:1 |

  - `label3` passes only up to 21 %. It is used there for series-card meta (`caption1` `label3`), chart axes (`caption2` `label3`) and timestamps.
  - `check-contrast.mjs` checks labels only on black and slabs.
- **Evidence.**
  - §2.1.8: "field blobs L 0.55 to 0.78 … opacity 18 to 28 %"; Home hero "the ambient field turned up to 36 %".
  - §7.7: "meta `caption1` `label3`".
  - §7.39: "Axes and labels `caption2` `label3`".
- **Fix.**
  - On screens whose field opacity exceeds 20 % (Home, series detail, book page, recap, profile picker, Statistics, Wrapped), `label3` is replaced by `label2` (≥ 4.57:1 at 36 %).
  - Add check-contrast cases for `label2` and `label3` over `#B7B7B7` at each screen's field opacity from the §2.1.8 table.

### A11Y-20 · medium · §8.21, §8.13, §8.16.2, §8.17: active content is dimmed with opacity, which pushes text below 4.5:1
- **Problem.** Items that remain tappable are dimmed with whole-element opacity instead of a role swap. They are not disabled, so the WCAG exemption does not apply.

  | Item | Opacity | Surface | Resulting text contrast |
  |---|---|---|---|
  | Updates "read cards" | 70 % | black | `label2` meta 3.86:1; `label3` time 2.85:1 |
  | Book-page TOC "read rows" (Literata 16) | 45 % | black | 4.06:1 |
  | Listen sentence list "others" (tap to play) | 40 % | `solid1` | 3.53:1 |
  | Library offline posters (still openable from cache) | 70 % | — | meta text drops the same way |
  | Statistics offline | "dimmed", no value | — | — |

- **Evidence.**
  - §8.21: "read cards at 70 %".
  - §8.13: "title Literata 16 (read rows at 45 %)".
  - §8.16.2: "others at 40 %".
  - §8.17: "posters without downloaded chapters dim to 70 %".
  - §9.2.1: "the last cached statistics, dimmed".
- **Fix.** Dim by role swap, never by opacity, on anything activatable:
  - Read cards: title `label1` → `label2`, meta → `label3`, and the time stays `label3`. Cover images can dim to 70 %.
  - TOC read rows: `label3` (4.93:1).
  - Inactive sentences: `label2` (7.15:1 on black, ≥ 6.3:1 on `solid1`).
  - Statistics offline: a "Last updated 2 h ago" banner, with no dimming.

### A11Y-21 · medium · §7.5, §7.16, §8.17, §8.9, §14.6: several hit areas are below the document's own 44 pt / 48 dp minimum
- **Problem.** §14.6 requires ≥ 44 × 44 (iOS and web) and ≥ 48 × 48 dp (Android) "whatever the visual size", but:
  - The input-chip remove button (×) has "hit 32".
  - The filter chip reaches 44 "via 6 px vertical padding", which is only 44 on Android too.
  - Sidebar items are "40 tall", and the Flutter desktop frame is used on touch iPads and Android tablets (§8.0.1).
  - The poster hover buttons on web desktop are 32 px.
  - The Search jump bar is 28 px wide with stacked initials of unspecified height.
  - §14.6 itself says "the scrub thumb's hit strip is 44 wide", with no Android 48.
- **Evidence.**
  - §7.5: "Input chip … trailing × (16 px, hit 32)"; "Height 32 (hit 44 via 6 px vertical padding)".
  - §7.16: "Item: 40 tall".
  - §8.17: "32 px content-twin buttons".
  - §8.9: "one `glassThin` capsule 28 px wide".
- **Fix.**
  - Input-chip × hit: 44 × 44 (48 × 48 Android), extending beyond the chip.
  - Filter chip vertical hit padding: 8 px on Android.
  - Sidebar items: 44 tall (48 on Flutter touch devices; radius 12, gaps 4 px).
  - Poster hover buttons: 32 visual inside a 44 hit.
  - Jump bar: 44 wide, each group row ≥ 44 tall (the list scrolls when there are more groups than fit).
  - §14.6 scrub strip: "44 wide (48 dp on Android)".
  - Also state that a component table's "hit 44" means "44, and 48 on Android" everywhere.

### A11Y-22 · medium · §9.2.3, §9.1.3, §8.16.2, §14.1: timed content has no always-available pause or extend control for sighted touch users
- **Problem.** Wrapped auto-advances each card in 6 s. For touch users the only pause is a sustained hold, and the pause, previous and next buttons appear only with a screen reader or keyboard. Users with cognitive or motor impairments who read slowly, or cannot hold, lose content. The "Previously · 20 s" pill leaves after 6 s, and the chapter card "Next chapter in 5" auto-plays. WCAG 2.2.1 and 2.2.2 require the timing to be pausable, extendable or switched off.
- **Evidence.**
  - §9.2.3: "progress capsules … filling over 6 s each … **hold** pauses"; "visible previous, pause and next buttons … appear … whenever a screen reader or a keyboard is in use".
  - §14.1: "keeps its timing".
- **Fix.**
  - Wrapped always shows a 44 px pause/play button (top-right, beside the close button).
  - Add Settings → Appearance "Auto-advance stories" (per profile, default on). When it is off, Wrapped and the recap pill wait for input, and the pill stays until the chapter's first scroll.
  - The "Next chapter in 5" card stays until acted on while `mm.boot.a11y.sr` or `accessibleNavigation` is on.

### A11Y-23 · medium · §4.11, §2.4.2: Reduce Transparency flattens the one lit action into a grey slab, and Increase Contrast leaves accent-on-glass failing
- **Problem.** "Reduce Transparency and Solid glass swap every glass variant for `solid1` …", and that includes `glassTinted`. Under Reduce Transparency the screen's primary action then looks exactly like every secondary button, so users who need Reduce Transparency lose the primary affordance. Increase Contrast swaps `iris400` → `iris300` but does nothing for the glass cases in A11Y-3 (`iris300` on reader glass over white is still 2.97:1).
- **Evidence.** §4.11: "swap every glass variant for `solid1` (T1 to T3) or `solid2` (T4 and T5)"; Increase Contrast "uses `iris300` instead of `iris400` for accent text".
- **Fix.**
  - Under Reduce Transparency and Solid glass, `glassTinted` becomes a solid `iris700` `#5B4AD1` capsule (white 6.28:1; plain `iris600` would give only 4.35:1) with the 1 px `rgba(255,255,255,0.10)` rim, and its pressed state becomes `#4A3CB0`.
  - Under Increase Contrast, every coloured glyph on glass also takes the `rgba(0,0,0,0.60)` backing disc of A11Y-3, and `hcBorder` is drawn around it.

### A11Y-24 · medium · §9.3, §9.3.1, §9.3.5, §9.3.7, §8.25.15: the Circle shows more than its privacy copy promises, and presence ignores exclusions and the gate
- **Problem.**
  - The sharing copy says others see "what this profile starts and finishes", but the friend sheet shows "their shared continue list as posters with their progress lines", which is live position data.
  - Presence `now` is nulled only when `show_presence` is off. Nothing nulls it for a series in `excluded_series` ("excluded from everything shared"), for a mature series without `share_mature`, or for a viewer whose gate is closed. §9.3's isolation rules speak of "feeds" only.
  - Letters "Sent" shows the sender "whether it was added". That discloses the recipient's library action even when the recipient's `share_activity` is off.
- **Evidence.**
  - §8.25.15: "Other readers on this server see what this profile starts and finishes".
  - §9.3.5: "**Reading** (their shared continue list as posters with their progress lines in `bloom`)".
  - §9.3.7: "`now` … where the server sends `null` unless the member's `show_presence` is on".
  - §9.3.1 Letters: "whether it was added".
- **Fix.**
  - The friend sheet's Reading section shows covers only (no progress lines), or the copy adds "and how far you are in what you're reading".
  - The server sends `now: null` when the series is in the member's `excluded_series`, or is mature without `share_mature`, or the viewer's gate is closed. The same rule applies to the friend sheet's "Reading now".
  - Letter status shows "Added" only when the recipient has `share_activity` on; otherwise it shows "Delivered".
  - Add all three rules to §15.5.

---

## Low

### A11Y-25 · low · §4.10, §4.11, §8.5, §8.16.2, §8.16.7, §9.4.1, §9.4.2, §7.20, §8.25.15, §9.2.3: moves described in screens have no Reduce Motion rule and are missing from the "exhaustive" motion table
- **Problem.** These moves are neither in §4.10 (where `play()` "throws on a name that is not in this table") nor covered by a §4.11 category:
  - the speaking orb "pulsing with the audio level at 30 fps";
  - the voice-preview orb pulse;
  - the soundscape's "8 live level bars";
  - the cruise pill's "spinning disc glyph";
  - the highlight-as-read band that "slides … on `snappy`", the sentence lozenge morph and the automatic follow scroll on `settle`;
  - the count-badge pop (1 → 1.25 → 1);
  - the `celebrate` hops (the saved profile orb, the offline-retry lens, the new collection card "drops into the list on `celebrate`");
  - the Wrapped numeral "counting up on `drift`";
  - the Circle privacy preview line "typed once at 12 ms per character";
  - the manage-mode orb breathing;
  - the queued download ring's "one turn per 4 s".
- **Evidence.** §4.10: "This table is exhaustive: a move that is not here does not exist". The quoted phrases above are from §8.16.2, §9.4.2, §9.4.1, §8.16.7, §7.20, §8.6, §8.18, §9.2.3, §8.25.15, §8.5 and §7.29.
- **Fix.** Add each to §4.10 with its Reduce Motion replacement:
  - Audio-level pulses, level bars and the spinning disc: static.
  - Band, lozenge and follow: jump with a 120 ms cross-fade; follow scrolls instantly.
  - Badge pop and hops: a 150 ms fade.
  - Count-up: show the final number.
  - Preview line: shown whole.
  - Breathing and the queued ring: static, with the dashed ring kept.

### A11Y-26 · low · §2.4.1, §2.6, §2.2, §14.4: focus rings can be clipped by the bar-group mask, and Flutter has no "focus not obscured" rule
- **Problem.**
  - Each bar group "is one element whose backdrop is masked to its shapes with an SVG `mask-image`". CSS `mask-image` clips the element's descendants, including the 4–6 px outline and glow of the buttons inside it, so rings on nav rows, the dock and reader capsules vanish outside the shapes. The Flutter equivalent (`ClipRSuperellipse` on glass) is unspecified for where `FocusRingSpec` paints.
  - §2.2 prevents focus under the floating bars only on the web (`scroll-padding-block`). Flutter's focus traversal reveals focused items inside the full edge-to-edge viewport, so they can land under the dock or nav row on tablets with keyboards (WCAG 2.4.11).
- **Evidence.**
  - §2.4.1: "masked to its shapes with an SVG `mask-image`".
  - §2.6: "Flutter: `FocusRingSpec` paints both strokes".
  - §2.2: "`scroll-padding-block` on web equals these insets".
- **Fix.**
  - `backdrop-filter` and `mask-image` live on an `aria-hidden` sibling background layer (or `::before`) beneath the controls, never on the element that contains focusable children.
  - Flutter paints `FocusRingSpec` in the surface's foreground, outside any clip, through an `OverlayPortal`.
  - Add a Flutter rule, through a `GlassFocusReveal` helper that listens to `FocusManager.instance`:
    - when the focused render object's rect intersects the top inset band (safe + 60) or the bottom inset band (safe + 85, + 56 with the accessory), animate the nearest `ScrollPosition` by the overlap plus 8 px on `settle`;
    - this mirrors the web's `scroll-padding-block`.

### A11Y-27 · low · §8.16.2, §12.6, §14.11: OS-visible surfaces show mature titles and art with no rule
- **Problem.** Several system surfaces sit outside the in-app gate and purge, so anyone holding the device, or a gated profile's user, sees mature content there:
  - The lock-screen and notification media controls show "title, book, cover artwork".
  - The iOS app switcher snapshot and Android recents thumbnails capture the open mature reader.
  - The web `document.title` and browser history carry series titles.
- **Evidence.** §8.16.2: "the lock screen, notification and headset controls through `audio_service` … (title, book, cover artwork …)". There are no app-switcher or `document.title` rules (grep).
- **Fix.**
  - When the playing or open series is mature, media metadata uses "ManhwaManiacs" and "Narration" with the neutral mark as artwork.
  - While a mature reader is open, Android calls `Activity.setRecentsScreenshotEnabled(false)` (API 33+; `FLAG_SECURE` below that) and iOS covers the window with the black neutral-mark view on `applicationWillResignActive`.
  - Web routes for mature series set `document.title = "ManhwaManiacs"`.

### A11Y-28 · low · §7.15: the minimised dock's semantics are undefined
- **Problem.** After 20 px of scroll the dock becomes "a 50 px capsule showing only the active tab's icon". With VoiceOver or TalkBack, scrolling minimises it, and the spec never says whether the other three tabs stay in the accessibility tree. "The dock stays a tab list whatever the finger does" covers dragging only.
- **Evidence.** §7.15 Minimise and Semantics.
- **Fix.** The dock never minimises while `accessibleNavigation` (or `data-sr`) is on. Otherwise, the minimised capsule keeps all four `tab` nodes in the tree (visually hidden, still focusable), and focusing one restores the dock.

### A11Y-29 · low · §7.15, §7.30, §11: some dismissals are gesture-only
- **Problem.**
  - Swiping the bottom accessory down "dismisses it for the session", and the matrix gives an alternative only for narration.
  - The global new-chapters capsule is "persistent until acted on" and dismisses only by swiping up. It has no close button, so keyboard, switch and screen-reader users cannot clear the top band slot.
- **Evidence.**
  - §7.15: "Swiping the accessory down … dismisses it for the session".
  - §7.30: "swipe up dismisses until a newer notification arrives".
  - §11 has no rows for either.
- **Fix.**
  - Both get a 44 px × close button (and a Dismiss custom action), and Esc closes them when focused.
  - Add both rows to §11 with those alternatives.

### A11Y-30 · low · §7.1, §7.25: the hold-to-confirm alternative is defined two different ways
- **Problem.**
  - §7.1 says "a plain click opens an alert with an explicit confirm button".
  - §7.25 gives only "Keyboard and screen-reader users" the explicit button "in the same alert".

  For a touch user with a tremor on the 18+ gate (itself an alert), a tap would open an alert on top of an alert under §7.1, and do nothing under §7.25.
- **Evidence.**
  - §7.1: "a keyboard activation, a screen-reader double-tap, or a plain click opens an alert".
  - §7.25: "Keyboard and screen-reader users get the explicit 'I am 18 or older, enable' button in the same alert".
- **Fix.**
  - One rule: a press released before 450 ms on any hold-to-confirm button reveals, in place, the explicit confirm button ("Delete profile", "I am 18 or older, enable") beneath the hold button, in the same surface, for every input type.
  - Remove "opens an alert" from §7.1.

### A11Y-31 · low · §7.1, §7.2, §7.23, §7.27, §7.8: transient errors aren't announced, and hover content has no WCAG 1.4.13 behaviour
- **Problem.**
  - Buttons, icon buttons and menu rows show their error for 2 s by swapping the label or glyph, with no live-region announcement (WCAG 3.3.1 / 4.1.3).
  - Tooltips and the poster "peek capsule" (which holds ⋯ and "Continue" buttons) appear on hover, but the spec doesn't say they can be dismissed with Esc without moving the pointer, can be hovered, or persist.
- **Evidence.**
  - §7.1: "Label swaps to a short error ('Couldn't save') for 2 s".
  - §7.23: "row label swaps to the error for 2 s".
  - §7.27 has no dismiss rules.
  - §7.8: "after 600 ms of rest a peek capsule … grows out of the poster's bottom edge … and a ⋯ button".
- **Fix.**
  - Every transient error also goes to the assertive live region (web `role="alert"` visually hidden; Flutter `SemanticsService.sendAnnouncement`) and stays 6 s.
  - Tooltips and peek capsules close on Esc, stay while the pointer is over them or within 8 px, and never disappear on their own while hovered or focused.

### A11Y-32 · low · §8.14.2, §7.21: the scrub-rail track and thumb contrast is too low or unspecified
- **Problem.** The rail is the reader's slider (WCAG 1.4.11 applies to its track and thumb). Its track `rgba(255,255,255,0.28)` measures 2.27:1 on a black page and 1.0:1 on a white page, and the 12 px thumb has no colour at all.
- **Evidence.** §8.14.2: "visible 3 px track `rgba(255,255,255,0.28)`, fill `iris500`, 12 px thumb".
- **Fix.**
  - Track: `rgba(255,255,255,0.50)` (5.28:1 on black) with a 1 px `rgba(0,0,0,0.60)` outline (for white pages).
  - Thumb: `#FFFFFF` with a 1.5 px `#000000` ring.
  - Fill: `iris500` on that outlined track.

### A11Y-33 · low · §7.26, §2.8.1: the white avatar glyph fails 3:1 on half of the presets
- **Problem.** The "white Light glyph" on the orb gradients measures:
  - Starlight 1.53–2.15:1;
  - Amber Coffee 2.15–2.80:1;
  - Ember Flame "to" 2.15:1;
  - Cyan Rocket 2.43–2.77:1;
  - Emerald Cat 2.49–2.54:1;
  - Bookworm 2.49:1;
  - Steel Blade "from" 2.56:1.

  The glyph identifies the profile in the dock's You tab, the picker and friend orbs.
- **Evidence.** §7.26: "the avatar preset's two-colour gradient and a white Light glyph".
- **Fix.** Per preset, the glyph takes `rgba(0,0,0,0.85)` on Starlight, Amber Coffee, Ember Flame, Cyan Rocket, Emerald Cat, Bookworm and Steel Blade (7.15–10.77:1), and white on the rest. Add the per-preset glyph colour to `design/tokens/glass.json` so `check-contrast.mjs` verifies both gradient stops.

### A11Y-34 · low · §2.1.1, §2.1.2, §14.2, §15.8: the contrast rules sanction a failing pair and contradict the CI gate
- **Problem.**
  - `g600` is licensed as "meta text at 15 px and larger", which measures 4.12:1 on `surface1`. That is below 4.5, and 15 px is not large text. §15.8 says the gate fails below 4.5:1 except for text 24 px and larger, so the declared pair breaks CI.
  - `label3` is scoped to "13 px and up" but is used for `caption1` (12 px) and `caption2` (11 px) meta. It passes WCAG (4.93:1 on black) but contradicts its own rule, so the gate's size logic will be ambiguous.
- **Evidence.**
  - §2.1.1 `g600`: "Meta text at 15 px and larger only".
  - §14.2: "`g600` meta text is used only at 15 px and larger (4.12:1 on `surface1`)".
  - §2.1.2 `label3`: "captions at 13 px and up".
  - §7.7: "meta `caption1` `label3`".
- **Fix.**
  - Make `g600` non-text only (icons, rings and chevrons, 4.12:1 ≥ 3).
  - Remove the size clause from `label3` ("placeholders, timestamps and captions at any size on black and slabs; ≥ 4.65:1").
  - `check-contrast.mjs` treats "large" as ≥ 24 px, or ≥ 18.66 px at `wght` ≥ 700.
