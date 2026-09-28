# Cinematic DESIGN.md: recheck round 2, lens "product" (capabilities and owner decisions)

Source: the **Confirmed** section of `cinematic/verify/judge-product.md` (28 findings; PRODUCT-29 and PRODUCT-30 were refuted and are out of scope). I checked them against `cinematic/DESIGN.md` as it stands after both fix rounds (`verify/fixed-product.md`, Rounds 1 and 2). All 28 were re-verified, not only the four that round 1 left open, because other lenses have edited the file since. For every finding I looked for the final-fix text, grepped for old values that should be gone, and grepped every other place that repeats a changed value or shape. DESIGN.md was not edited. Another session was writing to DESIGN.md during this check (it grew from 4647 to 4657 lines), so line numbers are approximate and the section numbers are the stable reference.

**Result: 25 resolved, 3 unresolved (PRODUCT-1, PRODUCT-9, PRODUCT-14).**

- All four round-1 leftovers are fixed as `recheck-product-1.md` asked: PRODUCT-1's three missing `recap` carriers, PRODUCT-2's seed-source sentence, PRODUCT-3's §8.11 library join and PRODUCT-10's Annual cache key.
- PRODUCT-1 is still open because a later edit contradicts it. STACK-17 added the plain-JSON "no stream" answer, and that answer sends `no_dialogue` to a different recap slate than §9.1.5 does.
- PRODUCT-9 and PRODUCT-14 are fixes that landed word for word but contradict themselves. Round 1 did not catch either.
- Each of the three needs a one- or two-sentence edit.

---

## Verdicts

| ID | Verdict | Evidence in DESIGN.md | Notes |
|---|---|---|---|
| PRODUCT-1 | **Unresolved** | Round-2 items are all in place. (1) §9.1.5 "Availability and range": `recap` is on `/home` `cover`, `continue` and `where_were_we` items and on every `GET /library/continue-reading` row. Any other Quick look calls the endpoint when it opens, and any other `Continue` calls it on press with the 400 ms fall-through. (2) §9.1.7 `Returns` note; the items table (`continue` "carry `recap`"; `where_were_we` split from `new_this_week`, with `recap`). (3) §8.9 Continue rail ("whose rows gain `recap`"). (4) §15.5 `/home` row. Round-1 content is still intact: the endpoint and its shape, range with the 60-day stop, the availability rules, the budget, the rendering rule, auto-open only when `available`, the chip `PREVIOUSLY ON · {ceil(est_seconds / 60)} MIN`, the SSE `meta`/`delta`/`done`/`error` framing, web `fetch` + `ReadableStream`, Flutter `dio` + `LineSplitter`, and the §8.8 cover, strip, phone and `Where were we?` conditions. The §7.6 Cutting Quick look, §8.17 and §8.18 buttons use `available`. "a recap is possible" is gone | STACK-17's no-stream answer contradicts the §9.1.5 `NO RECAP FOR THIS ONE` state; details below |
| PRODUCT-2 | Resolved | §8.7 18+ gate paragraph (`GET /onboarding/catalog`, never pins or `for_you`). Steps 2 and 5 read catalog `formats[].covers` and `seeds`, and step 5 uses `GET /ai/similar?anilist_id=`. §8.7 States now read "Catalog unreachable at steps 2 and 5 (`GET /onboarding/catalog` fails)" and "AI unavailable: the taste is saved, the wall still comes from the catalog, and a pick inserts no similar posters." §8.7 Backend: catalog shape, 24 h cache, the `onboarding_step` migration (`"done"` for existing profiles, `NULL` = step 1). §8.8 new-profile 0-pin fallback (3 healthiest non-18+ sources, `SUGGESTED SOURCES`, taste genres loved first, omitted when none). §9.1.2 case 5, the §9.1.7 `/ai/similar` row and both §15.5 rows | "source popularity" and "Sources unreachable" are gone |
| PRODUCT-3 | Resolved | §8.11 Collection detail joins library rows and shows `NO LONGER FOLLOWED` only on "the owner's own unshared shelves". A shared shelf renders each row from its own `title`, `cover_url` and `ambient` for owner and members alike, and never shows `NO LONGER FOLLOWED`. §8.11 Collections has the `SHARED WITH YOU` group (owner avatar, `CAN ADD` / `VIEW ONLY`, outside `Custom order`, deck "9 shelves · 2 shared · 1 shared with you"). §9.3.8: member endpoint with `404 circle_member_not_sharing`, feed filters, `DELETE /circle/activity`, `GET /circle/series`, the reaction `DELETE` body, shared-shelf fields and calls, 60 s polling, `409 recipient_unavailable`. Also §8.17 `CIRCLE` tab, §8.14.12 `CIRCLE` panel, §9.3.5 and the §15.5 Circle row | Two later refinements, both consistent everywhere they appear. (1) The member endpoint returns `shares: {activity, reactions, shelves, recommendations}`, the same shape as `GET /circle/members` and `GET /profiles/{id}/sharing`. (2) The feed filter is `kind=reading\|reaction`, with the note "Letters are not feed items; the `LETTERS` tab reads `GET /circle/letters`". The §15.5 row matches both |
| PRODUCT-4 | Resolved | §9.4.3: client detection (worker at 360 px on web, `compute()` isolate on Flutter, one page ahead), the 7-step rule, parity fixtures (`design/panel-vectors/`, `panels.test.ts`, `panels_test.dart`), the `POST /reader/panels` cache, entry, and the states `FINDING PANELS`, `WHOLE PAGE` and offline. Also the §9.4.5 row, the §8.14.3 `panel-focus` button, the fifth engine duty in §15.4, the §15.5 row, the §15.6 worker note, §15.8, S11 and the §15.10 owner-call line | `GET /reader/panels`, `panels_ready` and "computes it in the background" are all absent |
| PRODUCT-5 | Resolved | §8.3 States: "any 401 except `invalid_credentials`, which the global handler ignores and leaves to the calling form". §8.30.4 server answers: `invalid_credentials`, `weak_password` 422 with the server message, and `rate_limited` with the countdown and the disabled button | These are the only two mentions of 401 in the file |
| PRODUCT-6 | Resolved (deliberate deviation) | §9.3.4 eligibility (gate open **and** the recipient's own Include-18+ switch). The §7.25 ring conditions include the member's own switch. §9.3.8 `now` rule, also applied to `GET /circle/series` readers. §15.5 Circle row | As in round 1: the caption "Only readers who share 18+ titles are listed." is replaced by A11Y-35's "nothing says that anyone is left out, §7.24". Keep it that way |
| PRODUCT-7 | Resolved | §8.17 gestures and the "Mark read and Mark unread" block (one chapter, up to here in chunks of 200, `DELETE /reader/progress`, `manual: true`, toasts with Undo, offline). Also §8.18 gestures, §8.9 select mode, §7.6 Cutting Quick look, §7.29 select-mode bar and the §15.5 row | "Mark unread up to here" is absent |
| PRODUCT-8 | Resolved | §8.16.8: `RE-VOICE ⁽ⁿ⁾`, the `ALREADY NARRATED · WILL BE RE-VOICED` caption, `force: true`, `priority: 0` for the sheet and `priority: 9` for the opener, and `rendered_at` / `cast_changed_at`. §8.16.5 `RE-VOICING` and `Re-narrate 38 chapters`. §8.16.11 opener `priority: 9`. §15.5 row | — |
| PRODUCT-9 | **Unresolved** | The `code` branching in §9.1.3 (five codes plus the "never on the HTTP status" note), the Shelf results in §9.1.3, and the §7.6 World card *Shelf* variant with every field the fix names | The §7.6 World card row now contradicts itself; details below |
| PRODUCT-10 | Resolved | §9.2.7 Annual cache key is `(profile_id, mature_content_enabled, content_kind, year, tz_offset_minutes)`. `/home` key is `(profile_id, mature_content_enabled, content_kind, tz_offset_minutes, local hour)`. `tz_offset_minutes` is required (−720..840) on both endpoints, and the web and Flutter sources are given in §9.1.7. §9.1.2 recomputes on the client. §15.5 rows | The streak object is now `{current_days, longest_days, at_risk, last_active_date}` (the judge wrote `current`). The rename is applied in §9.1.2, §9.1.7 (both places), §9.2.2 and §15.5, and no bare `current` is left |
| PRODUCT-11 | Resolved | §9.4.2 `GET /app/soundscapes/{id}.{ogg\|m4a}`. §8.34 fonts through `GET /app/fonts/{file}.woff2`. Two §15.5 rows (id allowlist of the eight loops, `FileResponse`, immutable caching, 404 otherwise) | "static folder" is absent. `/app/media/{name}` appears only as "screenshots only" |
| PRODUCT-12 | Resolved | §10.1.1 Trigger row (`inView` / `mount` / `signal`, 480 ms / 160 ms `play`, no letter cap). §10.1.4 Flutter hover (`MouseRegion`, `200 + 10 × (n − 1)` ms, `Interval` wipe, 160 ms exit). §10.1.5: `useTitleSignal`, `n = graphemes(text.replaceAll(" ", "")).length`, spans kept after the reveal. §10.1.6 rules and code (`SetTrigger`, route-animation signal, `MouseRegion`, `_n` without spaces) and the signal test case. §15.6 bullet | `AnimatedDefaultTextStyle`, "60-grapheme" and "word fallback" (as a length cap) are absent. The "Long words" plain-string fallback is a separate, width-based overflow rule, and it does not conflict |
| PRODUCT-13 | Resolved | §9.4.1 Pace: median of 10 samples, the 60–7200 s and 80–900 wpm bounds, 250 wpm until 3 samples, storage keys, and the px/s formula recomputed after Type changes. The §8.15.5 row points to §9.4.1 | — |
| PRODUCT-14 | **Unresolved** | §15.6 limiter (placement, bucket, P0–P3, rules). §8.17 schedule rows (150 ms dwell, first 2). §8.14.2 hold step (P3). §8.18 states (P3). §8.24 crops (P3) | The bucket's size and the P3 threshold contradict each other; details below |
| PRODUCT-15 | Resolved | §8.0.4 `coverTransitionName` (FNV-1a of `sourceId + "\u0000" + seriesKey`, synchronous, once per card, Flutter `Hero` tuple). §8.0.3 encoded route builders ("routers decode exactly once", `series_identity` note) | SHA-1, `cover-<sourceId>-<seriesKey>` and `crypto.subtle` as a method are absent |
| PRODUCT-16 | Resolved | §9.3.2 Offline and Error rows. §9.3.4 Pass it on offline and failure, and letter-action failure. §9.3.5 share-sheet `CORRECTION`. §9.3.6 Clear dialog with the 1000 ms arm and its failure toast. §9.3.7 member page offline | — |
| PRODUCT-17 | Resolved | §9.2.5: iOS `NSPhotoLibraryAddUsageDescription`. Android 29+ MediaStore `Pictures/ManhwaManiacs` through `mm/media`. Android 24–28 hides `Save image`, leaving `Share` | Three differences from the judge's text, all harmless and used consistently. The channel is `mm/media`, not `mm/media_store`, in both §9.2.5 and §8.23. The Info.plist string reads "ManhwaManiacs saves share cards to Photos only when you choose Save image. It never reads your library." The toast reads "Pictures › ManhwaManiacs" |
| PRODUCT-18 | Resolved | §9.2.4 colophon `NARRATED BY` from `top_voices`. §9.2.7 `POST /novels/listen-sessions` (batching, `seconds ≥ 10`, offline outbox) and `top_voices` in the response. §15.5 row | — |
| PRODUCT-19 | Resolved | §8.14.6 **The end**. The §8.15.2 novel end matter in stock colours. The §8.8 `continue` row: "never a finished Completed series" | The button is `Mark as done`, not `Mark as completed`, by CONSISTENCY-19 (the body is still `reading_status: "completed"`). §8.14.6 and §8.15.2 agree |
| PRODUCT-20 | Resolved | §9.1.8 copy table, used by §7.8 (the budget line plus "Here is your shelf instead."), the §9.1.3 masthead deck and states, and §9.1.6 `From your shelf` | "Today's asks are used up" and "Try again in a minute" are absent |
| PRODUCT-21 | Resolved (via CONSISTENCY-10) | §10.2.1, §10.2.3 and §10.2.4: off, on, off, on, off, on in 530 ms halves (3180 ms), then a 160 ms fade from 1. Web keyframes 15.87 / 31.74 / 47.60 / 63.47 / 79.34 / 95.21 % of 3340 ms. Flutter `(ms ~/ 530).isOdd` | The 556.7 ms halves and the fade from 0 are both gone. §14.10 "0.94 Hz" matches 1060 ms cycles |
| PRODUCT-22 | Resolved | §8.8 at-risk state and §9.1.2 table: above 60 graphemes (counts ≥ 101), "Your {n}-day streak ends at midnight." with a numeral | — |
| PRODUCT-23 | Resolved | §9.2.2 "Read today" rule and Just extended (`last_active_date` flips). §8.8 and §9.1.2 condition ("nothing read today") and deck ("Open any chapter before midnight to keep your streak.") | "first completed chapter of the day" and "no chapter read today" are absent. `manual: true` marks write no `ReadingSession`, so they cannot extend a streak, which agrees with PRODUCT-7 |
| PRODUCT-24 | Resolved | §9.2.4 "Calendar year" paragraph ("Your year so far" until 31 December), plus `partial` in §9.2.7 | "Rolling windows" is absent. The banner thresholds are unchanged, as the fix says |
| PRODUCT-25 | Resolved | §8.15.9 cross-device toast (stock colours, `Jump`) and the `SAVED COPY · 3 H` badge with its tooltip | — |
| PRODUCT-26 | Resolved | §8.30.6 mobile export (`dio.download` with Bearer, temp file, determinate rule, share sheet, error toast) and the failed-nightly line in `proof` | `share_plus` 12.0.2 matches §8.0.5, §9.2.5, §15.3 and the §15.11 ledger. 13.3.0 appears nowhere |
| PRODUCT-27 | Resolved (via CONSISTENCY-34) | §5 `splash.impress` (iOS and Android `impress`, web —). §12.4 at 1180 ms fires "haptic `splash.impress` (§5)". §15.1 `"splash.impress": "ahap:impress"`. §6 and S8 keep `splash.reveal` sound-only | Consistent across §5, §6, §12.4, §15.1 and S8 |
| PRODUCT-28 | Resolved | §8.23: result paths for iOS and Android 10+, MediaStore `Download/ManhwaManiacs/Exports/{series}/` through `mm/media` `saveDownload(relativePath, name, mime, path)`, API 24–28 app-documents plus `Share`, and "no folder picker" | `file_picker.getDirectoryPath()` is absent. The STORAGE tab's Android note ("Files live in the app's private storage.") is about saved chapters, not exports, so it does not conflict |

---

## Unresolved

### PRODUCT-1: the "no stream" answer sends `no_dialogue` to the wrong slate

The four places round 1 flagged are fixed. The conflict is new: STACK-17 (from `judge-stack.md`, applied in round 1 of `fixed-stack.md`) gave `GET /ai/recap` a plain-JSON answer, and it collides with the recap states that PRODUCT-1 defined.

- **§9.1.7, `GET /ai/recap` notes:** "**No stream:** when no recap can be written at request time … it answers plain JSON 200 before any stream, `{"available": false, "reason": "not_configured" | "budget_exhausted" | "rate_limited" | "no_dialogue" | "first_chapter"}`, and the clients treat that `Content-Type: application/json` as the §9.1.8 unavailable state."
- **§9.1.8:** the recap's unavailable state is the `RECAP UNAVAILABLE` slate ("Pick up where you left off: chapter 143.").
- **§9.1.5 States:** `no_dialogue` belongs to a different row, "No recap (only after an explicit tap on a button whose availability went stale, e.g. the stream answers `error` `no_dialogue`)", which renders `NO RECAP FOR THIS ONE` with its own copy and the app's `Scan saved chapters` action.

The server now detects `no_dialogue` before streaming, so it always arrives as JSON. Read literally, the stale-tap case therefore shows `RECAP UNAVAILABLE`, and the `NO RECAP FOR THIS ONE` slate PRODUCT-1 specified never renders. The JSON reasons `rate_limited` and `first_chapter` have no §9.1.5 row either.

*Fix (two sentences):*
- In the §9.1.7 **No stream** note, replace "the clients treat that `Content-Type: application/json` as the §9.1.8 unavailable state" with: "the clients map `reason` onto the §9.1.5 states exactly as they would a stream `error` with that code: `no_dialogue` → `NO RECAP FOR THIS ONE`; `not_configured` and `budget_exhausted` → the `RECAP UNAVAILABLE` slate; `rate_limited` → the `RECAP UNAVAILABLE` slate with the §9.1.8 `SLOW DOWN` line and its `Retry-After` countdown; `first_chapter` → straight to the reader with no slate."
- In the §9.1.5 States "No recap" row, change "e.g. the stream answers `error` `no_dialogue`" to "e.g. the answer is `no_dialogue`, as JSON or as a stream `error`".

### PRODUCT-9: the World card row counts two variants but defines three

§7.6 World card now reads "Two visibly different variants. *Available*: … *Information only*: … Both variants: with the gate open, the 16 px certificate … sits top-left on the poster when `is_adult` is true or any `available[]` source is mature. *Shelf* (the `kind: "source"` items of `/library/suggest` …): …".

The Shelf variant was added after the count and after the "Both variants" certificate rule. The row therefore states two variants and defines three. The certificate rule keys on `is_adult` and `available[]`, and Shelf items carry neither, so as written it does not reach the Shelf card. The §7.7 poster badge rule ("`18` certificate (only when the profile's gate is open and the series is mature)") would cover it, but the row never points there.

*Fix:*
- Change "Two visibly different variants." to "Three variants."
- Change "Both variants:" to "Every variant:", and end that sentence with "(Shelf: when its source is mature, as the §7.7 poster badge)".

### PRODUCT-14: a burst of 8 tokens cannot keep 20 in reserve

§15.6 reads "A token bucket of 50 tokens per minute (refill 1 every 1.2 s), burst 8, floor 0" and, in the same bullet, "P3 runs only while at least 20 tokens remain". In token-bucket terms, burst is the bucket's capacity. A bucket that holds at most 8 tokens can never have 20 left, so P3 never runs, and P3 is every prefetch in the app:

- hover and focus manifests (§8.14.2, §8.17);
- the first 2 schedule rows;
- the next chapter's manifest;
- novel chapter prefetch (§8.18);
- dialogue crops (§8.24);
- preview slates.

A capacity of 8 would also hold P2 covers to 8 at once and then 1 every 1.2 s, so a screen of 30 covers would take about 26 s (8 at once, then 22 × 1.2 s). The judge's text has the same contradiction, and DESIGN.md copies it exactly, so this is a defect in the fix itself, not a transcription error.

*Fix:* in the §15.6 limiter bullet, replace "burst 8, floor 0" with "capacity 50 (one minute of refill), floor 0". The server's 60/min window leaves room for 50 at once, and the 20-token P3 reserve then means what it says. If an instantaneous cap is still wanted, state it separately, for example "at most 8 bucket-gated requests start in any one second". Do not call it the burst.

---

## Checked and consistent (no action)

- `GET /home` without `tz_offset_minutes` in §8.0.8 and in the §15.5 "Tonight in novels mode" row. Both are partial references about `content_kind` that point to §9.1.7, where the parameter is required.
- §7.22 Quick look lists `Previously on` among its possible actions without a condition. It is an inventory of conditional actions (`Continue` and `Unfollow` are conditional too). §7.6 and §9.1.5 carry the `available` rule, and §9.1.5 covers "any other Quick look".
- Tonight's `p` key "opens Previously on" has no availability note. A key bound to an absent button does nothing, as with every other conditional control.
- §9.2.2's at-risk streak **caption** spells the count ("Twelve days and counting…"). The 60-grapheme limit in PRODUCT-22 applies to typed headlines only, and the Tonight headline follows it.
- The `PICKED 3 DAYS AGO`, `SLOW DOWN` and budget copy repeated in §7.8 and in the §9.1.3 masthead deck are the §9.1.8 line plus that surface's non-AI path, which the fix allows. The recap's `RECAP UNAVAILABLE` slate keeps its own copy, which §9.1.8 exempts.
