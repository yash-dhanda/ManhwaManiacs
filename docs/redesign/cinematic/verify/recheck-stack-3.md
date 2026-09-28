# Cinematic DESIGN.md: recheck round 3, stack lens

Checked 2026-09-28 against the 31 findings in the "Confirmed" section of `cinematic/verify/judge-stack.md`. I used `cinematic/verify/fixed-stack.md` (rounds 1–3) as the list of what the fixer changed, and `recheck-stack-2.md` for the round-2 fixes to STACK-18 and STACK-23. DESIGN.md was not edited.

**Snapshot note.** Other lenses were still editing DESIGN.md during this recheck. The mtime moved from 23:06:17 to 23:12:11 UTC, and the file stayed at 4,657 lines. I diffed my working snapshot against the last copy. The concurrent edits touched l.71 (`ink.45` on solid grounds), l.494 (`scrim.sole` positioning), l.1143 (the Source card kicker), l.3184 (recap countdown keys) and l.4416 (the request limiter's sliding window). None of them touches a stack fix. All line numbers below refer to the 23:12:11 copy.

**Method.** For each finding I read the target sections and compared them with the judge's final fix. For STACK-4, 8, 16, 18 and 23 I compared them with the later rechecks' rewritten fixes. I then grepped the whole file for old values that should be gone, and for every other place where a changed value is repeated. For STACK-23 I also read the installed `frontend/src/app/layout.tsx`, `providers.tsx` and `globals.css`:

- `layout.tsx` imports `./globals.css`;
- `globals.css` `@import`s `tailwindcss`, `./themes.generated.css` and `./presets.css`;
- `Providers` holds the app's `QueryClientProvider` with its 401 and profile-scope handlers, and `KeyboardProvider`.

**Result: 30 resolved, 1 unresolved (STACK-23).**

- Round 3 closes **STACK-18**.
- **STACK-23** now imports the stylesheet exactly as the round-2 fix asked. But the preview still renders without the duotone filters Tonight paints through, because those filters are mounted in the Shell the preview leaves out.

The 8 refuted findings (STACK-10, 21, 27, 29, 30, 31, 34, 38) are out of scope.

---

## Verdicts

| ID | Status | Evidence (current line numbers) | Notes |
|---|---|---|---|
| STACK-1 | Resolved | `share_plus` 12.0.2 at l.1676 (§8.0.5 Share row), l.3007 (Backup export), l.3373 (§9.2.5, full `ShareParams` call), l.4361 (§15.3), l.4498 (§15.11, with the `win32 ^6` note) | `13.3.0` appears 0 times |
| STACK-2 | Resolved | `flutter_soloud` 4.1.7 at l.978 (§6), l.2560 (§8.16.5: always `format=ogg`, on iOS too; no AAC decoder), l.4361 (§15.3, `loadMem`), l.4496 (§15.11, the `meta` 1.18.0 / `native_toolchain_c` note) | `5.1.4` appears 0 times |
| STACK-3 | Resolved | l.575 (§3.1) and l.4315 (§15.2 `fonts.ts`) | Each of the four calls appears exactly twice, and both copies are character-identical. All four carry `subsets: ["latin", "latin-ext"]` |
| STACK-4 | Resolved | §8.2 Outcomes (l.1807); §8.30.3 t = 0, `500, web` and `500, app` rows (l.2953–2958); "The switch waits for the server" (l.2960); §8.30.1 offline caption (l.2901); S12 (l.4465) | Unchanged since round 2 |
| STACK-5 | Resolved | §2.8.4 Flutter cells 504 / 576 / 288 ms (l.543–545); "Springs on each client" (l.557–561); §4.4 (l.765–767); §15.1 (l.4307); S13 (l.4466) | Round-2 nit N1 was applied. `CineSprings` now holds `const SpringToken`s, and `SpringToken.description` builds the `SpringDescription` at run time. §7.9 calls `CineSprings.sheet.description` (l.1230). `SpringSimulation(CineSprings.sheet,` without `.description` appears 0 times. No other Dart use of `CineSprings` exists |
| STACK-6 | Resolved | `--mm-spring-*-ms` 800 / 850 / 500 ms (l.543–545); stdlib generator and `tokens.test.ts` (l.560–561); §15.1 | "at least 30 points" appears 0 times |
| STACK-7 | Resolved | §7.9 "Flutter: `CineSheetRoute`" (l.1226–1235); §15.3 `primitives/` cell (l.4351); §15.3 Packages (l.4361) | `DraggableScrollableSheet` appears 0 times; `showModalBottomSheet` appears once, in the §7.9 rationale |
| STACK-8 | Resolved | §8.0.3 `tonight` (l.1608); §15.2 "Home route" (l.4336) | `src/app/page.tsx` appears 0 times |
| STACK-9 | Resolved | §8.0.4 web block (l.1662–1666); §15.2 View transitions (l.4334) | — |
| STACK-11 | Resolved | §8.16.10 "Native wiring and a single init" (l.2585–2591); §15.3 "Outside the skin folder" (l.4359); S14 (l.4467) | — |
| STACK-12 | Resolved | "The restart re-reads the boot state" (l.2964–2985); the `500, app` row (l.2958); §8.32 (l.3046) and §12.3 (l.4074) both use `AppRestart.of(context).restart()`; S15 (l.4468) | `AppRestart(child` and "logic runs again" appear 0 times |
| STACK-13 | Resolved | §2.1.5 reader-page row (l.159) | — |
| STACK-14 | Resolved | §4.5 Rack focus and **Develop** rows (l.787–788); §4.8 (l.842); §15.6 (l.4409); §15.8 device pass (l.4435) | — |
| STACK-15 | Resolved | §9.4.2 **Formats** (l.3529) | — |
| STACK-16 | Resolved | §9.3.8 lead (l.3488), member page (l.3491), feed filter (l.3492), Response shapes (l.3497–3502), Adders (l.3503); §15.5 Circle row | Round-2 nit N2 was applied: the member page's `now` is "the `GET /circle/members` shape, or `null`" (l.3491) |
| STACK-17 | Resolved | §9.1.7 `GET /ai/recap` row (l.3225) | — |
| STACK-18 | **Resolved** | One streak object, `{current_days, longest_days, at_risk, last_active_date, milestones_seen}`, appears in three places: l.3222 (§9.1.7 top-level `streak`), l.3243 (the `numbers` item) and l.4378 (§15.5 `GET /home`). l.4379 puts `milestones_seen` on "the one streak object that `GET /library/statistics` and `GET /home` share". §9.2.2 (l.3327) reads `streak.milestones_seen` from either endpoint and posts `…/milestones/{days}/seen` | `last_active_date}` (the old four-field object) appears 0 times, and all 5 hits for `milestones_seen` are on the one object. The §15.5 phrase "the statistics streak object plus `at_risk`" is now literally true. The Similar envelope and the section-item table (l.3223, l.3232–3243) are unchanged. See nit N1 |
| STACK-19 | Resolved (by the exclusive alternative) | PRODUCT-4 stays applied: §9.4.3 (l.3536–3540), §15.5 (l.4377), S11 (l.4464). The reader's trailing `panel-focus` gate (l.2193) reads "only once the current page has panels" | `panels_ready` appears 0 times |
| STACK-20 | Resolved | §9.2.7 response by field name (l.3389–3405), `partial` (l.3407) | — |
| STACK-22 | Resolved | §8.11 (l.2109); §15.5 collections `rules` row (l.4388) | — |
| STACK-23 | **Unresolved** | §8.30.3 *Root files stay* (l.2937) and *Preview layout* (l.2939) now import `app/globals.css` from both root layouts, with correct relative paths (`../globals.css` and `../../../globals.css`). The **Fixture** (l.2940) now has its own client `QueryClientProvider`. §15.2 (l.4330) and S17 (l.4470) repeat both points | The preview has no Shell, but the Shell is where the duotone filters are mounted (l.4327). The new sentence also says `globals.css` brings in the tokens, but nothing states where the per-skin token CSS is imported. See below |
| STACK-24 | Resolved | §2.1.5 (l.133, l.135, l.158); §15.5 first row (l.4373) | See nit N2 |
| STACK-25 | Resolved | l.151: `<filter id="duo-<id>" color-interpolation-filters="sRGB">` | — |
| STACK-26 | Resolved | §2.1.5 (l.178); §2.8.1 (l.429); §15.6 (l.4412) | "compositor-friendly" appears 0 times |
| STACK-28 | Resolved | §8.0.5 iOS Back cell (l.1672) and route-transition paragraph (l.1684); §4.4 use column (l.765); §7.22 Quick look (l.1476) | — |
| STACK-32 | Resolved | §15.3 "Outside the skin folder" (l.4359); `skin_previews` appears only there and at l.2942; S16 (l.4469) | — |
| STACK-33 | Resolved | §15.11 `fantasticon` 4.1.0, `@resvg/resvg-js` 2.6.2 and `sox` 14.4.2 rows (l.4505–4507); CI `flutter build apk --release` in the resolution check (l.4479) | "build time" appears 0 times |
| STACK-35 | Resolved | §15.2 Service worker (l.4340); §8.32 offline-fallback row; the `500, web` row (l.2957) | "chosen by the `mm-skin` cookie" appears 0 times |
| STACK-36 | Resolved | §8.2 Warm start (l.1805); §12.4 `mm.skin.splash` rule | — |
| STACK-37 | Resolved | §7.11 (l.1263); §8.33.3 (l.3069) | "member of the same stack" appears 0 times |
| STACK-39 | Resolved | Repoint at l.2630, l.2662 and l.4381 (all use `/library/series/{followed_id}/repoint`); `POST /ai/feedback` (l.3226; the §8.17 reject body at l.2620); page-tints → 204 (l.160, l.4374); milestones seen → 204 (l.4379); `preview_covers` (l.4389); §8.7 `seeds` and `styles` (l.1943) | — |

---

## Unresolved

### STACK-23: the preview leaves out the Shell, and the Shell mounts the duotone filters Tonight paints through

Round 3 applied the round-2 fix as written. Both root layouts import `app/globals.css`, and both relative paths resolve to `frontend/src/app/globals.css`. The fixture also gained its own client `QueryClientProvider` with `staleTime: Infinity` and `retry: false`.

The goal the judge set for the route is "the skin's real Tonight renders unchanged" (l.2940). Two gaps remain.

**1. No duotone filters in the preview document.**

- §15.2 says `duotone.tsx` is "One SVG `<filter>` per ambient duo, keyed by colour, mounted in the shell" (l.4327).
- On the web, duotone is applied as `filter: url(#duo-<id>)` against those document-level filters (l.151).
- The *Preview layout* renders "no Shell" (l.2939).
- Tonight depends on duotone in the part of the page the preview shows most:
  - the cover-story spread: "the same cover at `blur.bleed`, duotoned to `ambient.duo`" (l.1959);
  - the `Sources` tiles (l.1975);
  - the Letter cards of `sent_to_you` (l.1146).
- Filter Effects says a `url()` that points at a missing element makes the whole filter chain ignored. The preview card would therefore show full-colour art where the real Tonight shows the skin's signature duotone.

**2. The sentence the fix added names an import that the file never states.**

- l.2939 says `globals.css` brings in "Tailwind, `theme.generated.css` and the tokens Tonight is written in".
- §15.2 lets `globals.css` import only `theme.generated.css` (l.4314). That file is the `@theme inline` mapping (`--color-paper-2: var(--mm-color-paper-2)`), not the values.
- The values are the `[data-skin="cinematic"]` block in `skins/cinematic/tokens.generated.css` (l.337, l.4313). Neither DESIGN.md nor `stack-decision.md` §2.1–§2.2 says what imports that file, or `motion.css`, which registers `--animate-caret-out` for Tonight's typed headline.
- If the implementer imports them from `Shell.tsx`, the preview has no `--mm-*` values at all.

**Fix.**

- **l.2939 (*Preview layout*).** After "with that skin's `fonts.ts` classes and no Shell", add: "It does mount the skin's duotone filter host (`duotone.tsx`), which the Shell mounts in the app, because Tonight's spread, source tiles and letter cards paint through `filter: url(#duo-<id>)`, and a reference to a missing filter is ignored, which would leave the art in full colour."
- **l.4327 (§15.2 `duotone.tsx`).** Change "mounted in the shell" to "mounted in the shell and in the edition preview layout (§8.30.3)".
- **l.4313 (§15.2 `tokens.generated.css`).** Add the import point: "`@import`ed by `app/globals.css`, after `../skins/theme.generated.css`, together with `motion.css`". The blocks are scoped by `[data-skin]`, so Glass's file can sit beside it. Tailwind 4 registers `@theme` entries only in the stylesheet compiled with `@import "tailwindcss"`, so this is also what makes `animate-caret-out` exist. The l.2939 parenthesis is then literally true for both root layouts.

---

## Non-blocking nits (no finding reopened)

- **N1 (STACK-18).** §9.2.2 opens the card "when `current_days` has reached a milestone missing from that list" (l.3327), but it does not say what happens when several are missing. On the first release, every profile with an existing long streak has an empty `milestones_seen`. For example, at 120 days the milestones 7, 30 and 100 are all missing. Suggested: "open only the highest missing milestone; its `…/milestones/{days}/seen` marks it and every lower milestone as seen".
- **N2 (STACK-24 wording, pre-existing).** §15.6 (l.4412) says page-tint sampling runs on the client "so the shared VPS image proxy does no colour work". Read literally, that contradicts `ambient` being computed in the cover proxy's resize path (l.135, l.4373). The sentence dates from before the stack fixes (HEAD l.3867). Suggested: "does no page colour work (cover `ambient` is the one server-side colour job, §2.1.5)".
- **N3 (STACK-16, carried over).** The READING tab's empty copy "Nobody is reading right now." (l.3444) still describes live reading, while the tab filters `kind=reading` dispatches. This is for the product lens.

## Old values confirmed gone (live file, 23:12:11)

| Grep | Hits |
|---|---|
| `13.3.0`, `5.1.4` | 0 |
| `DraggableScrollableSheet`, `panels_ready`, `compositor-friendly` | 0 |
| `chosen by the \`mm-skin\` cookie`, `member of the same stack` | 0 |
| `alive_today`, `streak: {current,`, `last_active_date}` | 0 |
| `sharing: {activity`, `kind=reading\|reaction\|letter` | 0 |
| `src/app/page.tsx` | 0 |
| `AppRestart(child`, "logic runs again" | 0 |
| "at least 30 points", "build time" | 0 |
| `SpringSimulation(CineSprings.sheet,` (without `.description`) | 0 |
| `showModalBottomSheet` | 1, the §7.9 rationale only |
| `milestones_seen` | 5, all on the one streak object |
| `globals.css` | 5, all consistent (both root layouts, S17, the §15.2 `theme.generated.css` row) |
