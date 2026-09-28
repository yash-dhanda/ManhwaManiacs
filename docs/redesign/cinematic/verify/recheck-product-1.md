# Cinematic DESIGN.md: recheck round 1, lens "product" (capabilities and owner decisions)

Source: the **Confirmed** section of `cinematic/verify/judge-product.md` (28 findings; PRODUCT-29 and PRODUCT-30 were refuted and are out of scope), checked against `cinematic/DESIGN.md` as it stands after the round-1 fixes (`verify/fixed-product.md`). For every finding I searched for the final-fix text, grepped for the old values that should be gone, and grepped every other place the changed value or shape is repeated. DESIGN.md was not edited. Line numbers are approximate: other lenses were editing DESIGN.md while this check ran, so sections are the stable reference.

**Result: 24 resolved, 4 unresolved (PRODUCT-1, PRODUCT-2, PRODUCT-3, PRODUCT-10).** None of the four is a missing fix. In each, the fix landed in its main section, but another place that repeats the shape or copy was not updated, so the two now contradict each other. Each needs a one-line or one-row edit.

---

## Verdicts

| ID | Verdict | Evidence in DESIGN.md | Notes |
|---|---|---|---|
| PRODUCT-1 | **Unresolved** | Resolved in §9.1.5: "Availability and range" block, range and 60-day stop, availability rules, budget, rendering rule, auto-open only when `available`, `NO RECAP FOR THIS ONE` only after a stale tap, chip `PREVIOUSLY ON · {ceil(est_seconds / 60)} MIN`. Also in §9.1.7: the availability row, SSE `meta`/`delta`/`done`/`error`, web `fetch` + `ReadableStream`, Flutter `dio` + `LineSplitter`, and `recap` on `cover`. Also §9.1.1, §9.1.2 case 3, §8.8 cover/strip/phone actions, §8.17, §8.18, §7.6 and §15.5. "a recap is possible" is gone. | Three places still disagree with the fix; details below |
| PRODUCT-2 | **Unresolved** | Resolved: the §8.7 18+ gate paragraph, the step 2 and step 5 data columns, Backend (`GET /onboarding/catalog`, `GET /ai/similar?anilist_id=`, the `onboarding_step` migration), the §8.8 new-profile 0-pin fallback (`SUGGESTED SOURCES`, taste genres), §9.1.2 case 5, the §9.1.7 `/ai/similar` row, and §15.5 | The §8.7 States line still gives the old seed source; details below |
| PRODUCT-3 | **Unresolved** | Resolved in §9.3.8: member endpoint with `404 circle_member_not_sharing`, feed filters, `DELETE /circle/activity`, `GET /circle/series`, the reaction `DELETE` body, shared-shelf fields and calls, 60 s polling, `409 recipient_unavailable`. Also the §8.17 `CIRCLE` tab, the §8.14.12 `CIRCLE` panel, §9.3.5 `SHARED WITH YOU` and the §15.5 Circle row | §8.11 still joins shelf members to the viewer's library; details below |
| PRODUCT-4 | Resolved | The §9.4.3 detection, rule (7 steps), parity (`design/panel-vectors/`, `panels.test.ts`, `panels_test.dart`), `POST /reader/panels` cache, entry and states (`FINDING PANELS`, `WHOLE PAGE`, offline). Also the §9.4.5 row, the §8.14.3 `panel-focus` button, the fifth engine duty in §15.4, the §15.5 row, the §15.6 worker note, `panel-vectors.json` in §15.8, S11 and the owner-call line in §15.10 | `GET /reader/panels`, `panels_ready` and "backend computes it" are all gone |
| PRODUCT-5 | Resolved | §8.3 States ("any 401 except `invalid_credentials`…"), §8.30.4 server answers (`invalid_credentials`, `weak_password` 422 with the server message, `rate_limited` with the countdown) | — |
| PRODUCT-6 | Resolved (deliberate deviation) | §9.3.4 eligibility (gate open **and** the recipient's own Include-18+ switch), the §7.25 ring conditions, the §9.3.8 `now` rule (also on `GET /circle/series` readers) and the §15.5 Circle row | The judge's caption "Only readers who share 18+ titles are listed." is absent. §9.3.4 reads "eligible recipients are listed without explanation, and nothing says that anyone is left out, §7.24". That is A11Y-35 (confirmed in `judge-a11y.md` and applied in `fixed-a11y.md`), which follows the §7.24 "absence, never a lock" rule. The disclosure defect PRODUCT-6 names is fixed. Re-adding the caption would break A11Y-35, so leave it out |
| PRODUCT-7 | Resolved | §8.17 gestures and the "Mark read and Mark unread" block (one chapter, up to here in chunks of 200, `DELETE /reader/progress`, `manual: true`, toasts with Undo, offline). Also the §8.18 gestures, §8.9 select mode, §7.6 Cutting Quick look and the §15.5 row | "Mark unread up to here" is gone |
| PRODUCT-8 | Resolved | §8.16.8 `RE-VOICE ⁽ⁿ⁾`, the `ALREADY NARRATED · WILL BE RE-VOICED` caption, `force: true`, `priority: 0` for the sheet and `priority: 9` for the opener. Also §8.16.5 `RE-VOICING` with `Re-narrate 38 chapters`, the §8.16.11 opener and the §15.5 row | — |
| PRODUCT-9 | Resolved | §9.1.3 states branch on `code` (`suggest_shelf_empty`, `ai_budget_exhausted`, `ai_not_configured`, `ai_failed`, `rate_limited`) with the "never on the HTTP status" note. The Results use the Shelf variant, and the §7.6 World card *Shelf* variant exists | — |
| PRODUCT-10 | **Unresolved** | Resolved: `/home` `tz_offset_minutes` (required, −720..840), the web and Flutter sources, the `/home` cache key with `tz_offset_minutes` and the local hour, the streak `{current, at_risk, last_active_date}`, the §9.1.2 client recompute, the §9.2.7 `/library/annual` parameter and the §15.5 rows | The §9.2.7 Annual cache key leaves the now-required offset out; details below |
| PRODUCT-11 | Resolved | The §9.4.2 route, §8.34 fonts through `GET /app/fonts/{file}.woff2`, and the two §15.5 rows (the id allowlist matches the eight loops; `ogg`/`m4a`; `FileResponse`; immutable caching) | "static folder" and `/app/media/soundscapes` are gone. `/app/media/{name}` now appears only as "screenshots only" |
| PRODUCT-12 | Resolved | The §10.1.1 Trigger row (`inView`/`mount`/`signal`, 480 ms / 160 ms `play`, no cap). §10.1.4 Flutter hover (`MouseRegion`, `200 + 10 × (n − 1)` ms, the `Interval` wipe, 160 ms exit). §10.1.5 `useTitleSignal`, spaces-excluded `n`, and spans kept after the reveal. §10.1.6 rules, `SetTrigger`, route-animation signal, `MouseRegion`, and the third test case. The §15.6 bullet | `AnimatedDefaultTextStyle`, "60-grapheme cap" and "word fallback" are gone. §4.6 also uses `n` without spaces |
| PRODUCT-13 | Resolved | §9.4.1 Pace (the median of 10, the 60–7200 s and 80–900 wpm bounds, 250 wpm until 3 samples), storage keys and the px/s formula | §8.15.5 still points to §9.4.1 |
| PRODUCT-14 | Resolved | The §15.6 limiter (placement, 50/min bucket, burst 8, P0–P3, rules). §8.17 rows (150 ms dwell, first 2), the §8.14.2 hold step (150 ms dwell, P3), the §8.18 states (P3) and the §8.24 crops (P3) | "first five" is gone |
| PRODUCT-15 | Resolved | §8.0.4 `coverTransitionName` (FNV-1a, synchronous, once per card, Flutter `Hero` tuple) and the §8.0.3 encoded route builders (with the `series_identity` note) | `cover-<sourceId>-<seriesKey>`, SHA-1 and `crypto.subtle` as a method are gone |
| PRODUCT-16 | Resolved | §9.3.2 Offline and Error rows. §9.3.4 Pass it on offline and failure, and letter-action failure. The §9.3.5 share-sheet failure. The §9.3.6 Clear dialog with the 1000 ms arm and its failure toast. §9.3.7 offline | The old "Offline / error: Notices" row is gone |
| PRODUCT-17 | Resolved (already present) | §9.2.5 iOS `NSPhotoLibraryAddUsageDescription`. Android 10+ uses MediaStore `Pictures/ManhwaManiacs` through the `mm/media` channel. Android 24–28 hides `Save image`, leaving `Share` | The channel is named `mm/media` (the judge said `mm/media_store`), but §9.2.5 and §8.23 use the same name consistently |
| PRODUCT-18 | Resolved | The §9.2.4 colophon `NARRATED BY` (from `top_voices`). §9.2.7 `POST /novels/listen-sessions`, with batching, `seconds ≥ 10` and the offline outbox, and `top_voices` in the response. The §15.5 row | — |
| PRODUCT-19 | Resolved | The §8.14.6 **The end** state, the §8.15.2 novel end matter, and the §8.8 `continue` row ("never a finished Completed series") | — |
| PRODUCT-20 | Resolved | The §9.1.8 copy table, used by §7.8 (appends "Here is your shelf instead."), the §9.1.3 states and masthead deck, and §9.1.6 `From your shelf` | "Today's asks are used up" and "Try again in a minute" are gone |
| PRODUCT-21 | Resolved (via CONSISTENCY-10) | §10.2.1, §10.2.3 and §10.2.4: six exact 530 ms halves (off, on, …, on), then a 160 ms fade from 1. Keyframes 15.87 / 31.74 / 47.60 / 63.47 / 79.34 / 95.21 % of 3340 ms, all verified | Both defects PRODUCT-21 names (556.7 ms halves, a fade from 0) are gone. The design keeps a visible fade instead of the judge's "drop the fade", which is equally correct |
| PRODUCT-22 | Resolved | The §8.8 at-risk state and the §9.1.2 table: above 60 graphemes (counts ≥ 101), "Your {n}-day streak ends at midnight." with a numeral | — |
| PRODUCT-23 | Resolved | §9.2.2 "Read today" rule and Just extended (triggered by `last_active_date` flipping). §8.8 and §9.1.2 condition ("nothing read today") and deck ("Open any chapter before midnight to keep your streak.") | "first completed chapter of the day" and "no chapter read today" are gone. `last_active_date` already exists on `/library/statistics` (`backend/tests/test_reading_statistics.py`) |
| PRODUCT-24 | Resolved | §9.2.4 "Calendar year" paragraph ("Your year so far" until 31 December) | "Rolling windows" is gone. See PRODUCT-10 for the cache key |
| PRODUCT-25 | Resolved | §8.15.9 cross-device toast (stock colours, `Jump`) and the `SAVED COPY · 3 H` badge with its tooltip | — |
| PRODUCT-26 | Resolved | §8.30.6 mobile export (`dio.download` with Bearer, then the share sheet) and the failed-nightly line in `proof` | Uses `share_plus` 12.0.2, not the judge's 13.3.0. That matches the §15.11 ledger (13.x needs `win32 ^6`) and every other mention (§8.0.5, §9.2.5, §15.3). No 13.3.0 remains |
| PRODUCT-27 | Resolved (via CONSISTENCY-34) | §5 event `splash.impress` (iOS and Android `impress`, web —). §12.4 at 1180 ms fires "haptic `splash.impress` (§5)". The §15.1 map has `"splash.impress": "ahap:impress"`. §6 and S8 keep `splash.reveal` sound-only | Consistent across §5, §6, §12.4, §15.1 and S8. The defect (a pattern name used as an event) is gone |
| PRODUCT-28 | Resolved | §8.23 result paths (iOS and Android 10+), Android destinations (MediaStore `Download/ManhwaManiacs/Exports/{series}/`, `saveDownload(relativePath, name, mime, path)` on `mm/media`, `Share` on API 24–28, no folder picker), and the §9.2.5 channel note | — |

---

## Unresolved

### PRODUCT-1: recap availability is missing on items that are told to use it

1. **`Where were we?` has no `recap` field.** §8.8's section table says the long-press "offers `Previously on` first (only when that item's `recap.available`, §9.1.5)". But §9.1.7 puts `recap` only "on `cover` and on each `continue` item". Its items table gives `where_were_we` as "FollowedSeries list rows + `ambient`", with no `recap`. As written, the button never renders on the one rail made for returning readers (last read 21–120 days ago).
   *Fix:* add `recap` (the §9.1.5 availability object) to `where_were_we` items in three places: the §9.1.7 `Returns` note, the items-table row (split `where_were_we` from `new_this_week`), and the §15.5 `/home` row ("+ `recap` on `/home` `cover`, `continue` and `where_were_we` items").
2. **The `continue` items row leaves out `recap`.** The §9.1.7 `Returns` note says every `continue` item carries `recap`, but the items table row reads "continue-reading rows + `ambient`, `nudge`, `new_count`, `paused_days`" without it. The typed contract is generated from that table.
   *Fix:* append `recap` to the `continue` row.
3. **Library Continue has no availability source.** Library's Continue rail (§8.9) is built from `GET /library/continue-reading?limit=12`, which has no `recap`. Yet §7.6 renders the Cutting Quick look's `Previously on` only "when `recap.available`", and §9.1.5 cites "a Library cutting's Quick look" as a place a recap opens from. The `ALWAYS` / `AFTER N DAYS AWAY` auto-open on a Library `Continue` also needs an answer. Nothing in the contract supplies one, so on Library the button never shows and the setting never fires.
   *Fix (either):*
   - `GET /library/continue-reading` rows gain the same `recap` object (with a §15.5 row); or
   - §9.1.5 states that a Quick look or `Continue` outside Tonight and the feature and book pages calls `GET /ai/recap/availability` when it opens or is pressed. If the call fails or takes longer than 400 ms, the tap goes straight to the reader.

### PRODUCT-2: the onboarding "AI unavailable" state still names the old seed source

§8.7 States (about l.1941) still reads "AI unavailable: the taste is saved for later and seeds come from source popularity." Since the fix, step 5's wall comes from `GET /onboarding/catalog` `seeds` (AniList trending filtered by genre), which does not depend on the AI desk. Only the "insert 3 similar" step uses `/ai/similar`. The two sentences now contradict each other.
*Fix:* "AI unavailable: the taste is saved, the wall still comes from the catalog, and a pick inserts no similar posters." Optionally also rename "Sources unreachable at steps 2 and 5" to "Catalog unreachable at steps 2 and 5", since those steps no longer read from sources.

### PRODUCT-3: §8.11 still joins shelf members to the viewer's library

§8.11 Collection detail (about l.2107) still reads "Members are joined to library rows for titles and covers; orphans (no longer followed) show a title card and the caption `NO LONGER FOLLOWED`." The fix (§9.3.5, §9.3.8) says the opposite for members of a shared shelf: "its detail renders from the shelf's own `title`, `cover_url` and `ambient` per row, never from the member's library", "because a member's library cannot join the owner's series". A member opening a shared shelf would see every owner-added series as `NO LONGER FOLLOWED`.
*Fix:* scope the §8.11 sentence. The owner's own shelves join library rows (orphans `NO LONGER FOLLOWED`). A shared shelf, for owner and members alike, renders each row from its `title`, `cover_url` and `ambient` (§9.3.5), and never shows `NO LONGER FOLLOWED`. Also add the `SHARED WITH YOU` section (from `shared_with_me`) to the §8.11 Collections grid, which today lists only the owner's plates.

### PRODUCT-10: the Annual cache key leaves out the required offset

§9.2.7 makes `tz_offset_minutes` required on `GET /library/annual`, and §9.2.4 defines the year in the profile's local time. Yet the same paragraph keeps "cached per day under the key `(profile_id, mature_content_enabled, content_kind)`". An Annual composed for one offset is then served to a request with another offset: a second device in another zone, or travel. That is the same class of defect this finding fixed for `/home`, whose key does include `tz_offset_minutes`.
*Fix:* in §9.2.7, change the key to `(profile_id, mature_content_enabled, content_kind, year, tz_offset_minutes)`. `year` is also missing today, although the endpoint is per year. The §15.5 "Per-profile composed caches" row already ends in "…" and needs no change.

---

## Checked and consistent (no action)

- `GET /home` appears without `tz_offset_minutes` in §8.0.8 (`GET /home?content_kind=manga|novel`) and in the §15.5 "Tonight in novels mode" row. Both are partial references about `content_kind` that point to §9.1.7, where the parameter is required, so they do not contradict it.
- The `PICKED 3 DAYS AGO`, `SLOW DOWN` and budget copy are repeated verbatim in §7.8 and in the §9.1.3 masthead deck. Both are the §9.1.8 line plus their own non-AI path, which the fix allows.
- The recap's `RECAP UNAVAILABLE` slate keeps its own "Pick up where you left off" copy, which §9.1.8 explicitly exempts ("it is not a `NOTE`"). This was not part of PRODUCT-20's scope.
