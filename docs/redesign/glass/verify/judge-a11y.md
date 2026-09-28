# Judge: Glass accessibility, privacy and safety findings (`find-a11y.md`)

Method: for each of the 34 findings I tried to refute the claim by grepping `glass/DESIGN.md` for the missing rule, reading the cited sections (§2.1, §2.4, §3.3, §3.7, §4.10–4.11, §7, §8.0.6–8.0.9, §8.14, §8.16, §8.17–8.23, §9.2–9.3, §10.1, §11, §14, §15.5–15.8), `inventory/00-decisions.md`, `stack-decision.md`, `inventory/capabilities.md`, `cinematic/DESIGN.md` (where Glass reuses its endpoints), and, where the claim or the fix touches existing code, the checkout (`backend/services/ocr_search.py`, `backend/core/content_rating.py`, `frontend/public/sw-policy.js`, `mobile/lib/features/downloads/services/blob_store.dart`, `docs/superpowers/specs/2026-09-03-mobile-source-native-design.md`). I recomputed every contrast figure used in a verdict with the WCAG 2.x formula, compositing in sRGB as the finder did (backdrop, then scrim, then `dimLegibility`, then the tier fill). The finder's figures reproduce to within 0.3.

`DESIGN.md` was being edited by the other lenses' fixers while I worked (the new §2.4.2 rule 7 "fill2 twins on glass", the collapsed sidebar, the desktop toolbar insets, the sheet host). The verdicts judge the post-critic text the finder audited; the fixes below are written to fit the edited text, and cite sections rather than line numbers.

Result: **31 confirmed, 3 refuted** (A11Y-7, A11Y-10, A11Y-27). Of the confirmed ones, 14 fixes were rewritten or corrected (A11Y-1, 2, 3, 4, 5, 6, 8, 9, 13, 14, 18, 24, 29, 33), 7 were narrowed (A11Y-12, 15, 16, 17, 21, 22, 23), and A11Y-30 duplicates WEB-9 and takes that fix.

---

## Verdicts and reasons

| ID | Verdict | Reason |
|---|---|---|
| A11Y-1 | Confirmed, fix rewritten | The `glassClear` row of §2.4.2 gives the dim cell "`dimClear` beneath the media … never inside the glass", while §2.1.7 puts `dimLegibility` in "every glass surface … all variants except `solid*`" and gives `Lb` rows for the hero controls and the image viewer. §2.4.2 rule 6 also says the glass thickens "on the Home hero … and in the image viewer". Reproduced: `onGlass` on clear glass over `#FFFFFF` with only `dimClear` is 2.14:1, and over a uniform grey of `Lb` 0.43 with no dim it is 1.91:1. The finder's fix went further than it needs to. With `dimLegibility` inside the clear glass, a uniform backdrop passes at every `Lb` (minimum 4.56:1 near `Lb` 0.5, 5.72:1 over white). So `dimClear` can stay conditional, and a 0.60 plateau under "clear" glass is unnecessary. The bright-patch case belongs to A11Y-2. |
| A11Y-2 | Confirmed, fix rewritten | `palette.l` is the cover's mean (§2.1.8 step 1) and `lTop`/`lMid`/`lBottom` are band means (step 3), so a white patch under a control in a dark cover or page fails: T3 1.81:1, T2 1.80:1 at `Lb` 0.2 over white. The unknown fallback `Lb = 0.5` (dim 0.43) gives T2 2.55:1 and T3 2.59:1 over white. §2.1.7 has no row for the reader's T2/T3 overlays (reaction bubbles, brightness and cruise HUDs, the "Previously" pill, the "Match" capsule, the seam chip, the loading capsule). The CI gate checks only three cases. One claim is weaker than stated: T4 menus and popovers keep `onGlass` at 4.55:1 over white even at the 0.22 floor, so tap-opened menus fail only for coloured glyphs (A11Y-3) and alpha labels (A11Y-4). I dropped the finder's 0.60 local plateau. A 95th-percentile luminance fixes the estimate at its source for every caller, keeps clear glass clear, and matches the "adaptive thickness" rule of §2.4.2 rule 6. |
| A11Y-3 | Confirmed, fix rewritten | §2.1.2 says "every glyph on glass is `onGlass`" and §14.2 says text on glass is only `onGlass`/`onTint`. But §2.1.3 gives `iris300` the role "accent text on glass", §7.15 draws the active dock label in `iris400`, §7.1 the Selected label in `iris300` and errors in `danger` on the same glass, §7.23 destructive rows in `danger` with a selected check in `iris400`, and §8.14.2 the saved bookmark in `iris400`. Reproduced: the dock label is 4.11:1; on reader T3 over white at 0.64, `iris400` is 2.43:1, `iris300` 2.97:1, `danger` 1.91:1 and `iris500` 1.81:1; `danger` on the tinted primary is 1.54:1. The finder's menu fix combined a backing disc with a new 0.80 dim floor, which is two mechanisms for one problem. The disc alone passes inside T4 even at the 0.22 floor (`danger` 4.61:1, `iris400` 5.86:1), so the dim-floor raise is dropped. The Selected toggle does not need a disc: its state is already carried by the label text, the Fill glyph and the wash, and `onGlass` on the wash passes (4.95:1). |
| A11Y-4 | Confirmed, fix tightened | §7.3 puts `label3` placeholders and `label2` field labels in `fill2` wells "on a sheet". §7.6 puts `label2` unselected segments on a `fill3` track "compact 32 inside sheets". Partial detents are `glassThick` (§7.10), and the reader settings sheet opens at `medium` over the page (§8.14.5). Reproduced over `#FFFFFF` under `dimSheet` 0.28 at dim 0.22: `label2` on `fill3` is 3.40:1, `label3` on the sheet 3.01:1, `label3` on `fill2` 2.70:1. This contradicts §2.1.2's "text on glass never uses alpha". The finder offered two fixes (dark wells, or reader sheets at `solid1`); a spec must pick one. I kept the dark well, because it matches §2.1.2 and works on every sheet, not only the reader's. I also added the rule the finder left implicit: secondary text on the glass body itself (field labels, helpers, subtitles, section headers) uses `onGlass`. |
| A11Y-5 | Confirmed, fix edited | §9.2.4 excludes only "mature series and covers". Card 10 prints the top source's logo and name and three source bars, and `capabilities.md` counts 56 of the 90 connectors as 18+. Cards 5 and 12 print genre words, and §8.7 names Adult, Ecchi, Hentai, Mature and Smut as mature genres. Card 11 exports a friend's name, orb and series. The finder offered two options for card 11; I picked "no Export", because an anonymised card still exports the fact that a Circle member read the series. |
| A11Y-6 | Confirmed, fix rewritten | §8.0.8 step 5 deletes five payload types, and step 6 filters only downloads. But §8.17, §8.10, §8.18, §8.19 and §8.20 read follows, sources and pins, collection members, local progress and local bookmarks from device caches offline. §8.25.16 lists `skipSeries` with covers from the library cache, §7.28 shows "recent items", and §8.25.2 confirms the service worker keeps a pages cache. §7.25 even claims "local copies (downloads, caches) are filtered on read (§8.0.8)", but §8.0.8 never says how. The finder's predicate is wrong. It filters on "resolved `rating == mature` … **or** `source.mature`", but the server's rule (`backend/core/content_rating.py::resolve_series_rating`) lets `mature_override = false` win over the source's maturity. The finder's predicate would hide a series the user marked "not 18+" on an 18+ source, which the server shows. The per-holder table is also the wrong altitude: one read-side guard in the shared data layer covers every list holder. The finder's `x-mm-mature` header tagging needs a backend change, while the service worker already drops its pages cache on a message (§8.25.2). |
| A11Y-7 | **Refuted** | iOS Files visibility of the download store is an explicit owner decision. `docs/superpowers/specs/2026-09-03-mobile-source-native-design.md` §3b ("owner request, 2026-09-04") sets `UIFileSharingEnabled` so the owner can "browse, copy and delete chapters" in Files, and `mobile/lib/features/downloads/services/blob_store.dart` implements it under `Documents/mm-store/blobs`. The Storage note in §8.22 describes that correctly. Moving the store to Application Support would reverse the owner's request, so the fix contradicts a binding decision. The two iOS notes do not contradict each other: the store is visible but unreadable (hash-named blobs), and Save to Files makes readable copies. The Android half concerns an explicit user export to the public Downloads folder, which §8.22 already names "Save to Downloads" with its path. A file the user chose to export leaving the app is the action's purpose, not a gate bypass: only a gate-open profile can see the series to export it. |
| A11Y-8 | Confirmed, fix rewritten | Rule 4 deletes "Cache Storage entries tagged `mature=1`", and on the web the downloads are Cache Storage (`sw-policy.js` `offlineCacheName(scope)`). So a gate close could delete them, against rule 6 and checklist item (9). The download's `mature` flag is "set … at download time" and never refreshed after a `mature_override` or a re-resolved rating. The novel-text index keys (`source:series:chapter:n`; `novel_text(source, series, chapter, para, text)`) carry no profile, yet the search claims "this profile's downloads scope", and "dropped when its download is removed" would drop another profile's rows. The finder's cache names (`mm-img-v1`, `mm-pages-v1`, `mm-downloads-v1`) do not exist; the real ones come from `sw-policy.js`. Its predicate has the same error as A11Y-6. |
| A11Y-9 | Confirmed, fix corrected | §8.0.9 makes downloads profile-scoped, but §8.22's "Free up space", "Remove all downloads", "Reset offline storage" (which "unregisters the service worker and clears caches", every scope's cache in the origin), the cap and the cache cards never say whose data they act on. As written, a gate-closed profile can remove mature downloads it cannot see, breaking checklist (9). The finder's "`is_admin` only" restriction is wrong. The cap is a per-install device property (`mobile-source-native-design.md` §3b), and a non-admin account holder on their own phone must be able to manage their own device. Clear labelling and an honest alert are enough. |
| A11Y-10 | **Refuted** | The server already does what the fix asks. `backend/services/ocr_search.py` restricts every hit to the active profile's followed series with the 18+ gate applied ("a search result is only returned when the caller *follows* that series … and the 18+ gate allows it"), and `total` is counted with the same scope predicate. So no other account's hits come back, every hit joins to the library, and "Showing the first 20 of 86" counts only rows the viewer can see. The inventory line "OCR text is global" describes storage, not reads. |
| A11Y-11 | Confirmed | No rule in §3.3, §7 or §14.7 says component heights grow with the text scaler. Flutter lays out in logical px, so a 32 px chip holding `subhead` at 2.0× (30/40) clips, and so do the 24 px tag, the 20–22 px badges, the 36 px title capsule, 44 px menu rows and the 60 px two-line toast. On the web the Tailwind spacing is `rem`, but the layout tokens are px (`--mm-layout-*: …px`, §2.8.2), so the two halves diverge. The fix is correct. |
| A11Y-12 | Confirmed, narrowed | §3.3 and §14.7 keep the reader chrome at fixed sizes, and §3.7 gives `wrappedNumeral` "none (the frame scales, not the text)". Phone users on Dynamic Type or a larger Android font scale therefore get no larger chrome or Wrapped text. The web half is refuted: §3.2 authors every web size in `rem`, and browser zoom scales the whole frame, so WCAG 1.4.4 holds there. |
| A11Y-13 | Confirmed, fix extended | The §10.1 Flutter code wraps the animated path in `Semantics(label:)` with no `header: true`, and its done and reduced paths return a bare `Text`, so §8.0.8's "focus on the title's `Semantics(header: true)` node" has nothing to land on. The `Wrap` holds one `Text` per grapheme, so lines break inside words, against the table's "wrapped per word". A `TextStyle` cannot carry a `TextScaler`, so §3.7's "GlassType … builds a TextStyle … and `TextScaler.clamp`" cannot apply the caps, and each `Text` takes the unclamped scaler (`largeTitle` 34 × 3.12 = 106 px at AX5). The web splits on `" "` inside `white-space: nowrap` words, so a CJK title (no spaces) is one unbreakable word. The finder fixed CJK on the web only; Flutter's per-word grouping has the same CJK overflow, so the fix covers both. `overflow-wrap: anywhere` cannot break inside `inline-block` nowrap spans, so I dropped it. |
| A11Y-14 | Confirmed, fix edited | Four behaviours key on "a screen reader is on" (§7.12, §8.14.2, §9.2.3, §8.16.4), browsers expose no such signal, and the Flutter signal is never named (grep: no `accessibleNavigation`). Two parts of the finder's fix conflict with other findings. "Toasts with an action never auto-dismiss" contradicts A11Y-15's timed Undo toast with its `mod+z` fallback. The unconditional web auto-play default change is unnecessary once the switch exists. |
| A11Y-15 | Confirmed, fix edited | §7.12 says "no close button (swipe or wait)" and "with a screen reader active, toasts stay until dismissed". A VoiceOver or TalkBack user has no swipe, so an action-less toast never leaves. Undo is `u` only "while its toast is visible" (§8.0.6), and the Single-key switch disables it. I dropped `F6`, which browsers keep for cycling their own panes, and bound the region to `alt+n`. That key is unbound in Chrome, Firefox (whose menu access keys are F, E, V, S, B, T, H) and Safari, and matches on `event.code` per WEB-8. |
| A11Y-16 | Confirmed, fix narrowed | §8.0.6 skips "every binding without a modifier", which includes arrows, Home/End, Page Up/Down, Space, Enter and Esc. WCAG 2.1.4 covers only character keys. The finder's wording is right, but it should say Shift+letter explicitly: WCAG counts upper-case letters, and §8.0.6 binds `shift+r`, `shift+x` and more. Of the finder's aliases only `mod+z` is needed. Bookmark and search already have visible controls, and `alt+/` adds nothing. |
| A11Y-17 | Confirmed, narrowed | §8 promises layout, states and keys but no semantics, and the §15.8 accessibility pass checks "focus order" against nothing. No role, name or value exists for the voice orbit, the three-part storage meter, the jump bar, the split button's two targets, the soundscape scene orbs and level bars, the onboarding dots or the avatar grid. `aria-live` appears 4 times. The transport buttons and the listen scrubber are already covered generically: §7.2 requires an `aria-label` on every icon button, and §7.21 makes every slider `role="slider"` with `aria-valuetext`. Those only need their strings. I made the offline and rate-limit capsules polite rather than assertive, because they are status messages (WCAG 4.1.3). |
| A11Y-18 | Confirmed, fix corrected | §7.20 defines the status tag as "colour at 18 % over black", but §7.8 places it on the poster image. Reproduced over a white cover: READING 2.07:1, COMPLETED and ON HOLD 1.59:1, 18+ 2.30:1, the droplet disc 2.67:1, the progress bar 2.04:1. The finder's figures (`mature` 5.35:1 and so on) are for colour text on the bare 0.86 backing. If the tag keeps its 18 % colour wash on top of the backing, `mature` drops to 4.13:1 and `iris400` to 4.69:1, so the fix removes the wash on covers. |
| A11Y-19 | Confirmed | The ambient field is fixed, its blobs reach relative luminance 0.475 (OKLCH L 0.78) at up to 36 %, and `label3` (series-card meta, chart axes, timestamps) over a blob centre measures 4.36:1 at 24 % down to 3.59:1 at 36 %. `check-contrast.mjs` checks labels only on black and slabs. The fix holds: `label2` passes at 36 % (4.57:1). |
| A11Y-20 | Confirmed | Updates read cards at 70 % (§8.21), TOC read rows at 45 % (§8.13) and inactive sentences at 40 % (§8.16.2) are still activatable, so the WCAG 1.4.3 exemption for inactive components does not apply. Reproduced: `label2` at 70 % is 3.86:1, `label3` at 70 % is 2.85:1, `label1` at 45 % is 4.06:1, and `label1` at 40 % on `solid1` is 3.53:1. Statistics offline "dimmed" dims static content text. |
| A11Y-21 | Confirmed, narrowed | The input chip × has "hit 32" (§7.5), and sidebar items are "40 tall" (§7.16) on a frame used on touch tablets (§8.0.1). The filter chip's "6 px vertical padding" gives 44, not the 48 that §2.2 `touchMin` and §14.6 require on Android. The jump bar is a 28 px strip, and §14.6 gives the scrub strip as "44 wide" with no Android value. Refuted part: the 32 px poster hover buttons are a visual size, and §14.6's "whatever the visual size" already gives them a 44 hit. |
| A11Y-22 | Confirmed, narrowed | Wrapped auto-advances every 6 s (§9.2.3). For a sighted touch user the only pause is a sustained hold, and the visible pause button appears only with a screen reader or keyboard, which fails WCAG 2.2.1 for anyone who cannot hold. Refuted parts: the "Previously" pill is an optional offer whose recap is reachable elsewhere (the continue stack's swipe, the context menu's "Previously on", §9.1.3), and the "Next chapter in 5" card has Cancel plus the "Continue to the next chapter" setting, which is WCAG's "turn off" option. The finder's new "Auto-advance stories" setting is not needed once the pause control is always visible. |
| A11Y-23 | Confirmed, narrowed | §4.11 swaps "every glass variant" to `solid1`/`solid2`, which includes `glassTinted`, so under Reduce Transparency the lit action becomes a grey slab like every secondary. `iris700` with white is 6.28:1, and `#4A3CB0` pressed is 8.19:1. The Increase Contrast half shrinks to one line once A11Y-3 moves every state colour on glass onto the backing disc. |
| A11Y-24 | Confirmed in part, fix rewritten | (a) The sharing copy (§8.25.15, §9.3.1) promises "what this profile starts and finishes", but the friend sheet (§9.3.5) shows "their shared continue list as posters with their progress lines". The shared endpoint Glass reuses (`cinematic/DESIGN.md` §9.3.8 `GET /circle/members/{profile_id}` → `reading: [series]`) carries no progress, so the lines have no data source either. (c) The Letters "Sent" filter shows "whether it was added", which discloses the recipient's library action even when their `share_activity` is off. `GET /circle/letters` returns received letters only and has no `added` state. (b) is refuted. Glass reuses Cinematic's Circle endpoints "as they are" (§15.5), and `cinematic/DESIGN.md` §9.3.8 already computes `now` from the shareable set S(member, viewer): excluded series removed, 18+ only with `share_mature` **and** an open viewer gate, enforced server-side. Glass's `show_presence` adds one more condition on top of that. |
| A11Y-25 | Confirmed | §4.10 calls itself exhaustive, and `play()` throws on unknown names. Yet the speaking-orb audio pulse, the voice-preview pulse, the soundscape level bars, the cruise disc spin, the highlight band, the sentence lozenge morph and follow scroll, the count-badge pop, the offline-retry lens hop, the new-collection drop, the Wrapped count-up, the privacy preview typing, the manage-mode breathing and the queued ring turn are all missing (grep of the table: none present except the Deal's own 12 ms typing). |
| A11Y-26 | Confirmed, Flutter part simplified | CSS `mask-image` on the bar-group element clips every descendant, including the 2 px outline and 6 px glow of the focus ring (§2.6) outside the shapes. §2.2's `scroll-padding-block` fixes 2.4.11 only on the web. Flutter's default traversal calls `Scrollable.ensureVisible` against the edge-to-edge viewport, so focus can land under the dock. The fix is right; the `OverlayPortal` is heavier than needed, so the ring is painted by the clip's parent. |
| A11Y-27 | **Refuted** | The 18+ gate decides what each profile sees inside the app (§7.25, `capabilities.md` §1). The lock-screen media card, the app-switcher snapshot and browser history show the device user's own current session, which only exists on a profile whose gate is open. The purge already stops narration and closes a mature reader when the gate closes or a gated profile becomes active (§8.0.8 steps 1–2), which ends the media session. Hiding titles from the OS (`FLAG_SECURE`, neutral media metadata, a generic `document.title`) would be a new discretion feature the owner never asked for (`00-decisions.md`), not a defect in the gate. |
| A11Y-28 | Confirmed | §7.15 minimises the dock to "only the active tab's icon" after 20 px of scroll, and VoiceOver and TalkBack scroll the list as focus moves. The semantics line covers dragging only; nothing says the other three tabs stay in the tree. |
| A11Y-29 | Confirmed, fix edited | Swiping the accessory down "dismisses it for the session" (§7.15), and the §11 alternative exists only for narration. The new-chapters capsule dismisses only by swiping up (§7.30); "View" acts on it but navigates away. A × on the 48 px accessory would crowd its title and play control. The narration variant already has a long-press menu (§8.16.1 "Pin"), so the accessory gets a menu item plus a dismiss action, and the capsule gets the × that A11Y-15 gives every toast. |
| A11Y-30 | Confirmed, duplicate of WEB-9 | §7.1 ("a plain click opens an alert") and §7.25 ("keyboard and screen-reader users get the explicit … button in the same alert") disagree, and the 18+ gate's hold already sits in an alert. `judge-web.md` WEB-9 confirmed the same defect with a complete fix (200 ms threshold, an explicit button visible to everyone inside alerts, keyboard as click). A second, different fix would conflict, so this finding takes WEB-9's fix unchanged. |
| A11Y-31 | Confirmed | Button, icon-button and menu-row errors swap the label for 2 s (§7.1, §7.2, §7.23) with no live announcement (WCAG 4.1.3). Tooltips (§7.27) and the poster peek capsule (§7.8) have no Esc dismissal and no hover or persistence rule (WCAG 1.4.13). |
| A11Y-32 | Confirmed | The scrub rail is the reader's slider. Its track `rgba(255,255,255,0.28)` is 2.27:1 on a black page and invisible on a white one, and the 12 px thumb has no colour, while §7.21's generic white thumb would be invisible on white (WCAG 1.4.11). The fix reproduces: the 0.50 track is 5.28:1 on black, and the black outline and ring carry white pages. |
| A11Y-33 | Confirmed, check corrected | White on the gradients measures 1.53:1 (Starlight) up to 2.80:1 (Amber Coffee) at the stops. The finder's CI rule "verifies both gradient stops" fails for its own fix: dark on Steel Blade's `to` stop `#475569` is 2.57:1. The glyph sits in the middle of the orb, so the check must sample the gradient under it. Sampled across the 30–70 % band of the diagonal, the finder's colour choice passes everywhere (dark 3.58:1 to 8.84:1; white 3.58:1 to 5.74:1). |
| A11Y-34 | Confirmed | `g600` is licensed as "meta text at 15 px and larger" at 4.12:1 on `surface1` (§2.1.1, §14.2), which fails §15.8's own gate (4.5:1 below 24 px). A grep shows `g600` is used only for non-text (chevrons, rings, the checkbox border, the add-profile ring, the unknown bead), so the fix costs nothing. `label3` is scoped to "13 px and up" but used at `caption1` 12 and `caption2` 11, where it still passes 4.92:1 on black. |

---

## Confirmed

### A11Y-1 · high · `glassClear` carries the legibility dim

- **§2.4.2, `glassClear` row, Dim cell:** "`dimLegibility` inside the glass, as every tier (§2.1.7); `dimClear` beneath the media region when the media's `Lb > 0.45`, unchanged." The rest of the row (fill `rgba(255,255,255,0.02)`, blur 1, rim 0.28) stays, so the glass still reads as clear over dark art (dim 0.22).
- **§2.1.7:** the hero-controls and image-viewer rows read `lMax` (A11Y-2).
- **§15.8 contrast gate:** add "`onGlass` on `glassClear` over `#FFFFFF` at dim 0.64 ≥ 4.5:1" (computed 5.72:1) and "`onGlass` on `glassClear` over a uniform backdrop at `Lb` 0.5 with dim 0.43 ≥ 4.5:1" (computed 4.56:1, the formula's minimum).

### A11Y-2 · high · The legibility estimate reads the brightest part of the backdrop, and every surface has a source

1. **Covers: add `lMax`.**
   - Change §2.1.8 step 1 and the §15.5 `palette` row to `palette: {a: [...], l, lMax}`. `lMax` is the 95th-percentile relative luminance of the `w=96` cover's pixels, computed in the same Pillow pass.
   - The client fallback (step 2) computes it from the decode it already makes: the web's 32 × 32 canvas (`getImageData`) and Flutter's 64 px `ResizeImage`.
   - Every §2.1.7 row that reads a cover's `l` for a surface drawn over that cover reads `lMax` instead: hero controls, the series band, the image viewer, and `lItems`. The field term keeps `l`, because the field is blurred blobs.
2. **Pages: add band maxima.**
   - `PageSample` (step 3) gains `pTop`, `pMid` and `pBottom`: the 95th-percentile relative luminance of each band, from the same 16 × 16 (web) or 64 px (Flutter) decode.
   - Reader chrome reads the p-value of its band instead of the mean.
3. **Fallback.** "Anything whose backdrop is unknown" becomes `Lb = 1.0` (dim 0.64). The dim then eases down over `dimShift` once a sample lands.
4. **New `Lb` rows in §2.1.7:**
   - Every other surface over a reader page (page menu, go-to popover, next-chapter card, reaction bubbles, brightness and cruise HUDs, the "Previously" pill, the "Match" capsule, the seam chip, the zoom chip, the loading capsule, the reader settings sheet) reads the maximum of `pTop`, `pMid` and `pBottom` over the bands its rect overlaps.
   - Menus, popovers and partial sheets on ordinary screens read `max(field term, lItems under the surface's rect)` instead of "the field term alone". The sidebar keeps the field term.
5. **§15.8 contrast gate, added cases:**
   - `onGlass` on T2 over `#FFFFFF` at dim 0.64 ≥ 4.5:1 (5.05:1).
   - `onGlass` on T4 over `#FFFFFF` at dim 0.22 ≥ 4.5:1 (4.55:1).
   - A physics check `dimFor(lMax = 1.0) == 0.64` beside the existing `dimFor` asserts.

### A11Y-3 · high · State colour on glass sits on a backing disc; text on glass is `onGlass` or `onTint`

- **§2.1.2, the rule.** Add after "every glyph on glass is `onGlass`": "A state colour (`iris*`, a semantic colour, `bloom`, `streak*`) appears on glass only as a glyph or ring drawn on a backing disc `rgba(0,0,0,0.60)`. The disc is 28 px behind a 22 px glyph and 20 px behind a 16 px glyph, inside the control's 44 px hit. It is never text. The one exception is the dock's active glyph over the `edgeSoft` plateau."
- **§2.1.3.** `iris300`'s role becomes "focus ring; accent text on black under Increase Contrast". Delete "accent text on glass".
- **§7.15 dock.** The active glyph stays `iris400` (4.11:1 on the plateau, above the 3:1 icon threshold). The active label becomes `onGlass` at `wght` 700 (8.78:1); the droplet and the weight carry the state.
- **§7.1 buttons:**
  - *Selected (toggle buttons):* the label and the Fill icon are `onGlass`. The 22 % `iris600` wash and the `iris300` rim at 40 % stay, and `onGlass` on the wash over white at dim 0.64 measures 4.95:1.
  - *Destructive (secondary):* the label is `onGlass`, and a leading `trash` or `warning-circle` glyph in `danger` sits on the disc.
  - *Error:* the label swaps to "Couldn't save" in `onGlass` (`onTint` on the primary), led by a `warning-circle` glyph in `danger` on the disc. The error shake stays.
- **§7.2 icon buttons on glass** (toggle icons for pin, follow, favourite and downloaded; the error glyph): the coloured glyph sits on the disc. Icon buttons on black are unchanged.
- **§7.23 menus.**
  - Destructive rows keep an `onGlass` label and add a `danger` glyph on the disc (4.61:1 inside T4 over white at dim 0.22).
  - The selected row's trailing check is `iris400` on the disc (5.86:1).
  - The error state is an `onGlass` label led by a `danger` glyph on the disc.
- **§8.14.2 reader chrome.** The bookmark's saved state is Fill `iris400` on the disc (6.14:1 on T3 over white at 0.64). Download-control states (`iris500`, `warning`, `danger`, `success`) also sit on the disc; the lowest is `iris500` at 4.59:1.
- **§14.2:** add "State colours on glass appear only as glyphs on the backing disc".
- **§15.8 contrast gate:**
  - Each of `iris400`, `iris500`, `danger`, `warning`, `success`, `streakCore`, `bloom` and `mature`, as a glyph on the 0.60 disc inside T2, T3, T4 and `glassClear` over `#FFFFFF` at dim 0.64, must be ≥ 3:1 (lowest: `iris500` on T2, 4.55:1).
  - The same colours inside T4 at dim 0.22 must be ≥ 3:1 (lowest: `iris500`, 4.38:1).
  - `onGlass` on the Selected wash inside T3 over `#FFFFFF` at 0.64 must be ≥ 4.5:1.
  - `iris400` on the dock plateau must be ≥ 3:1.

### A11Y-4 · high · No alpha labels on the body of T4/T5 glass

- **§2.1.2:** add "Inside T4 and T5 glass (partial sheets, menus, popovers and alerts over art), text on the glass body is `onGlass`, with hierarchy carried by size and weight (§3.5). `label2`, `label3` and `label4` are not used there."
- **New token `color.wellOnGlass`** = `rgba(0,0,0,0.35)`: `--mm-color-well-on-glass`, `bg-well-on-glass`, `colorWellOnGlass` = `Color(0x59000000)`. Inside T4 and T5 glass, text wells (§7.3), segmented tracks (§7.6) and stepper wells use `wellOnGlass` instead of `fill2` and `fill3`.
- **Inside a `wellOnGlass`:** `label2` is allowed (5.20:1 worst case), and placeholders use `label2` (`label3` would be 4.0:1).
- **On the sheet body:** field labels above wells, helper text, grouped-list subtitles, section headers and footers, and the reader sheet's scope captions ("This series") are `onGlass` at their role's size (6.84:1 worst case).
- **Scope.** The rule covers wells and tracks that carry alpha labels. Controls drawn as the §2.4.2 rule 7 twins keep their `onGlass` labels.
- **§15.8:** add "`label2` on `wellOnGlass` inside T4 over `#FFFFFF` under `dimSheet` 0.28 at dim 0.22 ≥ 4.5:1".

### A11Y-5 · high · Share sides never export gated or another person's data

- **§9.2.4.** Replace the mature sentence with: "Share sides never draw a mature series or cover, a mature source's name or logo (`source.mature`), or a mature genre (Adult, Ecchi, Hentai, Mature, Smut, the §8.7 list), whatever the gate says. The next eligible item takes the place: the next source on card 10, the next genre on cards 5 and 12, and the radar drops mature axes. A card left with no eligible item is omitted from the share set."
- **Card 11 "Together"** has no Export button and never appears on a share side. Amend §9.2.3's "Every card has an **Export** button" to "every card except 11".
- **§14.11:**
  - The share-card line becomes "Share cards never draw mature covers, titles, sources or genres, or anything from the Circle, whatever the gate".
  - Add a checklist item: "render every share side for a gate-open profile whose year is mostly mature, and assert that no mature title, source name or genre word appears in the PNG's source strings".

### A11Y-6 · high · One read-side gate guard for every local holder

- **§8.0.8, new step 5a: "Filter every local list on read."**
  - While the active profile's gate is closed, the shared data layer drops rows from every list it returns from a device store: the follow and library cache, the source list and pins (`manhwamaniacs:source-pins`, and the service worker's per-scope `-api-` cache on the web), collection members, local progress and history, local bookmarks, continue items, and the `mm.recap.skipSeries` display.
  - The predicate is the server's. A series row is hidden when its resolved `rating` is `"mature"`, where the rating resolves in `backend/core/content_rating.py::resolve_series_rating` order: `mature_override`, then `content_rating` or genres, then the source's `mature`. A source row is hidden when `source.mature`.
  - Local progress and bookmark rows store the series' resolved `rating` when written and refresh it from the follow cache on every sync.
  - Online this is a no-op, because the server already gated.
- **Step 3 addition:** the palette's recent items are stored as `{item, gateOpen}`, like recent searches, and every entry made while the gate was open is deleted.
- **Step 4 addition:** the purge posts `{ type: "gate-closed" }` to the service worker, which drops its pages cache exactly as on `skin-changed` (§8.25.2).
- **§7.25:** "local copies (downloads, caches) are filtered on read (§8.0.8 steps 5a and 6)".
- **§14.11 checklist:** add "(10) the palette's recent items, an offline Library, an offline Sources directory, offline Collections, History and Bookmarks, and the recap skip list show none of it".

### A11Y-8 · medium · The purge never touches downloads, the mature flag stays current, and the text index is per profile

- **§8.0.8 step 4, web:** "object URLs made from mature images are revoked, and the service worker's `-pages-` cache is dropped (A11Y-6). The saved-chapter cache `offlineCacheName(scope)` (`{PREFIX}-offline-{CONTENT_VERSION}-u{user}p{profile}`, `frontend/public/sw-policy.js`) and Flutter's blob store are never touched by the purge."
- **Step 6:** replace "set from the series payload at download time" with "the download record stores the series' resolved `rating`, refreshed from the follow row on every library sync and after a `mature_override` change; lists apply the A11Y-6 predicate".
- **Novel text scope (§8.9):**
  - Web: the IndexedDB database is per scope, `mm-novel-text-u{user}p{profile}`.
  - Flutter: queries join `novel_text` to the active profile's saved-chapter rows on `(source, series, chapter)` and apply the gate predicate. Index rows are deleted only when no profile's saved-chapter row still references the chapter.

### A11Y-9 · medium · Storage actions say whose data they touch

- **Active profile only:** "Free up space", "Remove all downloads", per-series removal and the web's "Remove all downloads" act only on the active profile's visible downloads. Hidden mature downloads stay (checklist item 9).
- **Device-wide:** "Reset offline storage", the storage cap, "Chapters at once", "Clear image cache" and "Clear metadata cache" act on the whole device. Their rows carry the caption "For everyone on this device", and the reset alert's body reads "This removes downloads for every profile on this device, including ones you can't see here." There is no admin restriction: the cap is a per-install device setting.
- **Eviction** under the cap or the retention setting counts a chapter as read only when every profile holding it has read it. It never removes another profile's pinned or unread chapters.

### A11Y-11 · medium · Component heights are minimums

- **§7 intro rule:** "Every height in this catalog is a minimum: `height = max(token, lineHeight × textScale + 2 × verticalPadding)`. Capsules keep `rCapsule` as they grow."
- **Web:** these heights are authored as `min-height` in `rem` with vertical padding, never `height` (chip `min-h-8`, tag `min-h-6`, menu row `min-h-11`). Layout tokens that bound text use `rem`.
- **Flutter:** `ConstrainedBox(constraints: BoxConstraints(minHeight: token))` plus padding, never `SizedBox(height:)` around text.
- **Toasts:** from AX1 they wrap to as many lines as needed, with radius 22.

### A11Y-12 · medium · Reader chrome and Wrapped follow the text scale on phones

- **§3.3 and §14.7 reader chrome.** Replace "keeps its own fixed sizes" with "scales with the text scaler up to 1.35× (xxxL), its capsules growing in height (A11Y-11). Above 1.35× the title capsule truncates, the page readout moves into the go-to popover, and secondary controls move into the settings sheet, so a capsule never wraps."
- **§9.2.3 Wrapped.** At text scale ≥ 1.3, cards lay out in a reflowing column instead of the 360 × 640 frame: the same slots (eyebrow, headline, figure, footnote, Export), stacked in a vertically scrolling card. Text is at the scaled size with the §3.3 caps, and the figure is scaled to the remaining width. The frame stays for the share side.
- **§3.7:** `wrappedNumeral` does not scale in the reflowing layout, because 88 px is already above every cap. Only the eyebrow, headline and footnote roles scale.

### A11Y-13 · medium · Letter reveal keeps its heading, breaks at words and applies the caps

- **§3.7:** add a `GlassText(role:, text)` widget. It resolves the role's `TextStyle` and passes `textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: cap / baseSize)` where the role has a cap. It is the only way Glass draws role text on Flutter, because a `TextStyle` cannot carry a scaler.
- **§10.1 Flutter:**
  - Both the animated path and the done or reduced path are wrapped in `Semantics(header: true, label: text)`.
  - The `Wrap` has one child per wrap unit. A unit is a word, drawn as a `Row(mainAxisSize: MainAxisSize.min)` of its graphemes, or a single grapheme inside a Han, Hiragana, Katakana or Hangul run.
  - Every grapheme is a `GlassText`, and the rise offset uses the scaled font size.
- **§10.1 web:**
  - Wrap units follow the same rule. A run matching `\p{Script=Han}|\p{Script=Hiragana}|\p{Script=Katakana}|\p{Script=Hangul}` emits its `.g` spans without a `.word` wrapper, so the line can break between any two of them.
  - Latin words keep `.word { white-space: nowrap }`.

### A11Y-14 · medium · One screen-reader signal per client

- **Flutter:** "a screen reader is on" means `MediaQuery.accessibleNavigationOf(context)` (VoiceOver, Switch Control, TalkBack), read through one `glassAssistiveProvider`. Name it in §4.11 beside the other signals.
- **Web:**
  - Add a **Screen reader mode** switch to Settings → Appearance (web only, per profile), stored as `sr` in `mm.boot.a11y` (`{legible, motion, solid, contrast, sr}`; Cinematic ignores it) and stamped `data-sr="on"` by `appearance-boot-source.ts`.
  - It turns on every behaviour keyed on "a screen reader is on": toasts stay until dismissed, reader chrome never auto-hides, Wrapped stops auto-advancing, and voice previews don't auto-play.
- **Web, independent of the switch:** reader chrome never idle-hides within 30 s of a keyboard interaction (a `keydown` or a Tab). Wrapped's pause button is always visible (A11Y-22).

### A11Y-15 · medium · Toasts can be closed by anyone, and Undo has a keyboard path

- **§7.12 close control.** Replace "no close button (swipe or wait)" with "a trailing close button (× 16 px glyph, 44 hit), and on Flutter `Semantics(onDismiss:)` plus a 'Dismiss' custom action (the VoiceOver escape gesture and TalkBack's dismiss)".
- **Web region.** Toasts live in a `role="region" aria-label="Notifications"` landmark. `alt+n` moves focus to the newest toast, Esc dismisses the focused toast, and focus or the pointer inside a toast pauses its timer.
- **Undo timing.** A toast with Undo lasts 10 s. `mod+z` undoes the last destructive action while its toast shows and for 60 s after it leaves (§8.0.6; `mod+z` survives the Single-key switch, and fields keep their native undo).

### A11Y-16 · medium · The Single-key switch skips character keys only

- **§8.0.6:** replace the sentence with "Off, every binding whose key is a printable character is skipped: letters (with or without Shift), digits, punctuation and symbols, including `?`, `/`, `[`, `]`, `.`, `,`, `<`, `>`, `=`, `+`, `-`, `*` (WCAG 2.1.4). Arrows, Home, End, Page Up/Down, Space, Enter, Esc, Tab, Delete, Backspace, F-keys and every `mod+` or `alt+` combination stay."
- **§14.4:** the same wording.
- **Alias:** Undo gets the alias `mod+z` (A11Y-15). Every other character action already has a visible control.

### A11Y-17 · medium · Semantics for the custom widgets and the missing live regions

- **§8 intro:** add "Semantics" to the list each screen gives: landmarks, heading levels, focus order, and the role, name and value of every control that is not a §7 catalog component (catalog components carry their §7 semantics).
- **Minimum semantics:**
  - **Voice orbit (§8.16.4):** web `role="region" aria-roledescription="carousel" aria-label="Voices"`; each card is `role="group" aria-roledescription="voice"` with `aria-label="Aurora, 3 of 31, female, warm, in use for Kade"`. Flutter uses `onIncrease`/`onDecrease` like the Home spotlight.
  - **Storage meter (§8.22):** `role="meter"`, `aria-valuemin="0"`, `aria-valuemax` = the cap, and `aria-valuetext="1.2 GB of 10 GB used: this profile 1.2 GB, other app data 3.4 GB, 5.4 GB free"`.
  - **Jump bar (§8.9):** a list of buttons, each "Jump to {source} results".
  - **Split button (§7.1):** two buttons, "Continue, chapter 143" and "More ways to read" with `aria-haspopup="menu"`.
  - **Listen transport and scrubber:** the §7.2 and §7.21 strings are "Back 15 seconds", "Previous sentence", "Play" / "Pause", "Next sentence" and "Forward 15 seconds", with `aria-valuetext="5 minutes 12 of 23 minutes 52"`. The active sentence carries `aria-current="true"`.
  - **Soundscape (§9.4.2):** the scene orbs are a radio group "Soundscape" (Off, Rain … Deep); the level bars are `aria-hidden`.
  - **Onboarding (§8.7):** the progress dots read "Step 3 of 7".
  - **Avatar grid (§8.6):** a radio group "Avatar".
- **Polite live regions (`role="status"`; Flutter `SemanticsService.sendAnnouncement`):**
  - Search's "searching 8 more sources" and each late group's arrival.
  - The AI phase lines and "N picks" arrivals.
  - Download completion ("Chapter 12 downloaded"; once per batch).
  - "Match 1 of 3" and "Panel 4 of 38".
  - The "Offline" and rate-limit capsules when they first appear.
  - The listen "now speaking" chip on speaker changes, at most once per 5 s.

### A11Y-18 · medium · Every overlay on a cover has an opaque backing

- **§7.8 and §7.20.** On a cover (posters, list covers, history tiles), every overlay sits on `rgba(0,0,0,0.86)`.
- **Status and 18+ tags on covers** drop the 18 % colour wash. They are colour text on the 0.86 capsule with a 1 px rim in the colour at 40 %: `iris400` 6.54:1, `success` 8.73:1, `warning` 8.87:1, `info` 7.37:1, `mature` 5.35:1.
- **Other overlays:**
  - The downloaded droplet's circle is `rgba(0,0,0,0.72)` (`success` 5.17:1).
  - The progress bar is `iris500` on a 5 px `rgba(0,0,0,0.86)` track (4.89:1).
  - The favourite star and the `age-gate` glyph each sit on a 22 px `rgba(0,0,0,0.72)` disc.
  - The "N new" capsule (opaque `iris400`, black text) is unchanged.
- **§15.8:** add these pairs over `#FFFFFF`.

### A11Y-19 · medium · `label3` stays off the brighter ambient fields

- **Screens:** on screens whose field opacity exceeds 20 % (Home, series detail, book page, recap deck, profile picker, Statistics, Wrapped), text drawn over the field's top 60 % uses `label2` where it would use `label3` (4.57:1 at 36 %).
- **§15.8:** add `label2` and `label3` over a `#B7B7B7` blob at each screen's opacity from the §2.1.8 table. `label3` is asserted only where the opacity is ≤ 20 %.

### A11Y-20 · medium · Dim by role, never by opacity, on anything activatable or readable

- **§8.21 read cards:** title `label1` → `label2`, meta `label2` → `label3`, and the time stays `label3`. Only the cover image dims to 70 %.
- **§8.13 TOC read rows:** `label3` (4.93:1).
- **§8.16.2 inactive sentences:** `label2` (6.57:1 on `solid1`).
- **§8.17 Library offline:** posters dim the cover image only; titles and meta keep their roles.
- **§9.2.1 Statistics offline:** no dimming. A `warning` inline notice reads "Last updated 2 h ago" above the content.

### A11Y-21 · medium · Hit areas meet the document's own minimum

- **§7.5:**
  - The input chip's × has a 44 × 44 hit (48 × 48 on Android), extending beyond the chip.
  - The filter chip's vertical hit padding is 6 px on iOS and web and 8 px on Android.
- **§7.16:** expanded sidebar items are 44 tall (48 on Flutter touch frames), radius 12.
- **§8.9 jump bar:** the hit strip is 44 wide (48 on Android) around the 28 px visual. The initials are a drag-to-scrub control like the scrub rail, and the group filter chips are its tap alternative.
- **§14.6:** "the scrub thumb's hit strip is 44 wide (48 dp on Android)". Add "a component's 'hit 44' means 44, and 48 on Android, everywhere".

### A11Y-22 · low · Wrapped can always be paused

- **§9.2.3:** a 44 px pause/play button (the `fill2` twin, `aria-label` "Pause" / "Play") is always visible at top-right beside the close button, for every input. The previous and next buttons keep their screen-reader-or-keyboard condition, because the tap thirds are their pointer path.
- **§14.1:** "Wrapped always shows its pause control".

### A11Y-23 · medium · The lit action stays lit under Reduce Transparency

- **§4.11 Reduce Transparency and Solid glass:**
  - `glassTinted` becomes a solid `iris700` `#5B4AD1` capsule (white 6.28:1; `iris600` would be 4.35:1) with the 1 px `rgba(255,255,255,0.10)` rim.
  - Its pressed state is `#4A3CB0` (white 8.19:1).
  - Every other variant goes to `solid1`/`solid2` as written.
- **Increase Contrast** also draws `hcBorder` around A11Y-3's backing discs.

### A11Y-24 · low · The Circle shows no more than its copy promises

- **§9.3.5:** the friend sheet's **Reading** section shows posters only, with no progress lines. That matches the shared `GET /circle/members/{profile_id}` → `reading: [series]`.
- **§9.3.1 Letters:**
  - The "Sent" filter shows "Added" only when the recipient has `share_activity` on (their follows are in the feed anyway); otherwise it shows "Delivered".
  - The server computes it: `GET /circle/letters?box=sent` returns `added: true | null`. List this in §15.5.

### A11Y-25 · low · The missing moves join the motion table

Add these rows to §4.10, each with its Reduce Motion column:

- **Speaking orb pulse** (§8.16.2), **Preview orb pulse** (§8.16.4), **Level bars** (§9.4.2) and **Cruise disc spin** (§9.4.1): static.
- **Highlight band** (§8.16.7), **Lozenge morph** and **Follow scroll** (§8.16.2): jump with a 120 ms cross-fade; the follow scroll is instant.
- **Badge pop** (§7.20) and **Lens hop**, **Card drop** (§7.24, §8.18): a 150 ms fade.
- **Count-up** (§9.2.3): the final number.
- **Preview typing** (§8.25.15): shown whole.
- **Orb breathe** (§8.5) and **Queued ring turn** (§7.29): static, with the dashed ring kept.

The generated `MotionName` union and enum pick them up through `build.mjs --check`.

### A11Y-26 · low · Focus rings are never masked or hidden under bars

- **§2.4.1 (web):** a bar group's `backdrop-filter` and `mask-image` live on an `aria-hidden` sibling background layer (or `::before`) beneath the controls, never on the element that contains focusable children.
- **§2.6 (Flutter):** `FocusRingSpec` is painted by a `foregroundPainter` on the widget that wraps the clipped glass, never inside `ClipRSuperellipse`.
- **§2.2 and §14.4 (Flutter).** Glass's `FocusTraversalPolicy` uses a `requestFocusCallback` that, after `Scrollable.ensureVisible`, checks whether the focused rect intersects the top band (safe + 60) or the bottom band (safe + 85, + 56 with the accessory). If it does, the policy animates the nearest `ScrollPosition` by the overlap plus 8 px on `settle`. This mirrors the web's `scroll-padding-block`.

### A11Y-28 · low · The minimised dock stays a full tab list

- **§7.15 Minimise:** the dock never minimises while `accessibleNavigation` (Flutter) or `data-sr="on"` (web) is on.
- **Otherwise:** the minimised capsule keeps all four `tab` nodes in the tree, visually hidden but focusable (web `clip-path` hiding, never `display: none`; Flutter `Semantics` nodes kept). Focusing any of them restores the dock on `minimize`.

### A11Y-29 · low · Every dismissal has a non-gesture path

- **§7.15 accessory:** every accessory variant (Now narrating, Downloading, Continue) has a long-press menu with "Hide for this session" beside "Pin". It also gets a Flutter `Semantics(onDismiss:)` plus a "Dismiss" custom action, and on the web Delete or Esc while it has focus.
- **§7.30 new-chapters capsule:** it takes the toast close button of A11Y-15 (× 44 hit, `onDismiss`, Esc when focused). Its dismissal holds until a newer notification arrives.
- **§11:** add both rows with these alternatives.

### A11Y-30 · low · Hold-to-confirm alternative (duplicate of WEB-9)

Apply `judge-web.md` WEB-9's fix unchanged (a click threshold of 200 ms and 8 px; an explicit confirm button visible to everyone inside an alert; keyboard activation is a click; a click outside an alert opens the §7.11 confirm alert). It covers the tremor case, because a short tap inside the 18+ alert moves focus to the visible explicit button and never opens a second alert. If WEB-9 has already been applied, no further edit is needed. §14.8 and §14.11's "for keyboard and screen-reader users" become "for everyone".

### A11Y-31 · low · Transient errors are announced, and hover content follows WCAG 1.4.13

- **§7.1, §7.2, §7.23:** every transient error also goes to the assertive region (web: a visually hidden `role="alert"` whose text stays 6 s; Flutter: `SemanticsService.sendAnnouncement` with `assertive: true`).
- **§7.27 and §7.8:** tooltips and the peek capsule close on Esc without moving the pointer. They stay while the pointer is over them or within 8 px of them, and never disappear on their own while hovered or focused.

### A11Y-32 · low · The scrub rail is visible on any page

- **§8.14.2 and §7.21:** the track is `rgba(255,255,255,0.50)` (5.28:1 on black) with a 1 px `rgba(0,0,0,0.60)` outline for white pages.
- **Thumb:** `#FFFFFF` with a 1.5 px `#000000` ring.
- **Fill:** `iris500` inside the outlined track. The touch state widens the track to 6 px as written.

### A11Y-33 · low · Avatar glyph colour per preset

- **§7.26:** the glyph is `rgba(0,0,0,0.85)` on Starlight, Amber Coffee, Ember Flame, Cyan Rocket, Emerald Cat, Bookworm and Steel Blade, and white on the other five.
- **`design/tokens/glass.json`:** store the per-preset glyph colour.
- **`check-contrast.mjs`:** sample each gradient at 30, 50 and 70 % of the diagonal (the band the glyph covers) and require ≥ 3:1 at every sample. Computed minimums: dark 3.58:1 (Steel Blade) to 8.84:1 (Starlight); white 3.58:1 (Rose Heart) to 5.74:1 (Phantom). Do not check the extreme stops: Steel Blade's `to` stop `#475569` would fail for either colour, but the glyph never sits there.

### A11Y-34 · low · Contrast rules match the gate

- **§2.1.1 and §14.2:** `g600` becomes non-text only ("icons, rings, chevrons and borders; 4.12:1 on `surface1` ≥ 3:1"). Delete "meta text at 15 px and larger".
- **§2.1.2:** `label3`'s use becomes "placeholders, timestamps and captions at any size on black and slabs (≥ 4.67:1)". In §14.2, drop "at 13 px and larger".
- **§15.8:** "large text" means ≥ 24 px, or ≥ 18.66 px at `wght` ≥ 700.
