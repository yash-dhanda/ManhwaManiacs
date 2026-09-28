# Cinematic DESIGN.md: recheck round 3, lens "product" (capabilities and owner decisions)

Source: the **Confirmed** section of `cinematic/verify/judge-product.md` (28 findings; PRODUCT-29 and PRODUCT-30 were refuted and are out of scope). I checked them against `cinematic/DESIGN.md` as it stands after all three product fix rounds (`verify/fixed-product.md`, Rounds 1–3). All 28 were re-verified, not only the three that round 2 left open, because other lenses edit the same file. For every finding I looked for the final-fix text, grepped for old values that should be gone, and grepped every other place that repeats a changed value or shape. Where a fix renders a backend field, I read the backend code that produces it (read-only). DESIGN.md was not edited. It stayed at 4657 lines throughout (md5 `3a27703b…`), so the line numbers below are exact for this revision.

**Result: 26 resolved, 2 unresolved (PRODUCT-9, PRODUCT-14).**

- All three round-2 leftovers landed word for word as `recheck-product-2.md` prescribed. PRODUCT-1 is now fully resolved.
- **PRODUCT-14 is open again, because of the round-2 prescription.** "Capacity 50" lets the P3 reserve hold, but combined with the 50/min refill the client can start up to 99 bucket-gated requests in 60 s. The server allows 60. The original "burst 8" was the one value that kept 8 + 50 under 60. That same cap is why the 20-token reserve could never hold.
- **PRODUCT-9's round-2 defect is fixed. A second defect in the judge's own fix text, missed by rounds 1 and 2, keeps it open.** The Shelf card's kicker prints `{chapter_count} CHAPTERS`, but `/library/suggest` hard-codes `chapter_count: 0` for every item (`backend/services/suggestion_service.py:782`). As specified, every Shelf card would read "… · 0 CHAPTERS".
- Each of the two needs a one-sentence edit.

---

## Verdicts

| ID | Verdict | Evidence in DESIGN.md | Notes |
|---|---|---|---|
| PRODUCT-1 | Resolved | **Round-3 edits:**<ul><li>§9.1.7 `GET /ai/recap` **No stream** note, l.3225: the clients map `reason` onto the §9.1.5 states the way they would a stream `error` with that code. `no_dialogue` → `NO RECAP FOR THIS ONE`. `not_configured` and `budget_exhausted` → `RECAP UNAVAILABLE`. `rate_limited` → that slate plus the §9.1.8 `SLOW DOWN` line and the `Retry-After` countdown, which the JSON answer carries. `first_chapter` → straight to the reader.</li><li>§9.1.5 States, l.3202–3204: "the answer is `no_dialogue`, as JSON or as a stream `error`". The unavailable row adds "rate limited" with the `SLOW DOWN` line. The First chapter row adds the stale `first_chapter` rule.</li></ul>**Earlier rounds, all intact:**<ul><li>availability endpoint and its shape (l.3187, l.3224);</li><li>range with the 60-day stop, availability rules, rendering rule, budget;</li><li>auto-open only when `available`, the chip `PREVIOUSLY ON · {ceil(est_seconds / 60)} MIN`;</li><li>SSE `meta` / `delta` / `done` / `error`; web `fetch` + `ReadableStream`; Flutter `dio` + `LineSplitter`;</li><li>`recap` on `/home` `cover`, `continue` and `where_were_we` and on `GET /library/continue-reading` rows (l.3187, l.3222, l.3234, l.3236, l.2039, l.4378);</li><li>§8.8 cover (l.1998), strip (l.1985) and `Where were we?` (l.1969); §7.6 Cutting (l.1142); §8.17 (l.2612); §8.18 (l.2662); §9.1.2 case 3 (l.3111).</li></ul> | "treat that `Content-Type: application/json` as the §9.1.8 unavailable state" and "a recap is possible" are gone. §9.1.8's `rate_limited` copy is the same line §9.1.5 now adds. §15.5 defers to §9.1.7 for framing ("SSE, framing in §9.1.7"), so nothing there repeats the old mapping |
| PRODUCT-2 | Resolved | <ul><li>§8.7 18+ gate paragraph (l.1918): `GET /onboarding/catalog`, never pins or `for_you`.</li><li>Steps 2 and 5 (l.1925, l.1928) read catalog `formats[].covers` and `seeds`, plus `GET /ai/similar?anilist_id=`.</li><li>§8.7 States (l.1941): catalog unreachable at steps 2 and 5, and AI unavailable.</li><li>§8.7 Backend (l.1943–1946): catalog shape, 24 h cache, `onboarding_step` migration.</li><li>§8.8 0-pin fallback (l.2014); §9.1.2 case 5 (l.3113); §9.1.7 `/ai/similar` row (l.3223); §15.5 (l.4395–4396).</li></ul> | "source popularity" and "Sources unreachable" are absent. "ordered by popularity" in l.1918 refers to the catalog's genre `weight`, not to sources |
| PRODUCT-3 | Resolved | <ul><li>§9.3.8 (l.3491–3506): member endpoint with `shares: {…}` and `404 circle_member_not_sharing`; feed `kind=reading\|reaction` with the letters note; `DELETE /circle/activity`; `GET /circle/series`; reaction `DELETE` body; shared-shelf fields and calls; 60 s polling; `409 recipient_unavailable`.</li><li>§8.11 library join scoped to the owner's own unshared shelves, and the `SHARED WITH YOU` group.</li><li>§8.17 `CIRCLE` tab (l.2623); §8.14.12 `CIRCLE` panel (l.2388); §15.5 Circle row (l.4386).</li></ul> | The old `sharing: {activity, reactions}` shape and `kind=…\|letter` are absent |
| PRODUCT-4 | Resolved | <ul><li>§9.4.3 (l.3536–3545): client detection, the 7-step rule, parity fixtures, `POST /reader/panels` cache, entry, and the states `FINDING PANELS`, `WHOLE PAGE` and offline.</li><li>§8.14.3 `panel-focus` (l.2193); §15.4 engine duties (`panels`); §15.5 row (l.4377).</li><li>§15.6 worker note (l.4412); §15.8 `panel-vectors.json` (l.4435); §15.10 S11 (l.4464) and the owner-call line (l.4475).</li></ul> | `GET /reader/panels`, `panels_ready` and "computes it in the background" are absent |
| PRODUCT-5 | Resolved | §8.3 States (l.1836): "any 401 except `invalid_credentials`". §8.30.4 (l.2991): `invalid_credentials`, `weak_password` 422 and `rate_limited`, with the countdown and the disabled button | — |
| PRODUCT-6 | Resolved (deliberate deviation) | <ul><li>§9.3.4 (l.3467): gate open **and** the recipient's own Include-18+ switch.</li><li>§7.25 ring (l.1529): includes the member's own switch.</li><li>§9.3.8 `now` rule (l.3488), also applied to `GET /circle/series` readers; §15.5 (l.4386).</li></ul> | The caption "Only readers who share 18+ titles are listed." is still replaced by A11Y-35's "nothing says that anyone is left out, §7.24", as accepted in rounds 1 and 2 |
| PRODUCT-7 | Resolved | <ul><li>§8.17 gestures (l.2640) and the Mark read / Mark unread block (l.2642–2648): one chapter, up to here in chunks of 200, `DELETE /reader/progress`, `manual: true`, toasts with Undo, offline.</li><li>§8.18 gestures (l.2672); §8.9 select mode (l.2053); §7.29 bar (l.1551); §7.6 Cutting (l.1142); §15.5 (l.4376).</li></ul> | "Mark unread up to here" is absent |
| PRODUCT-8 | Resolved | <ul><li>§8.16.8 (l.2576): `RE-VOICE ⁽ⁿ⁾`, `ALREADY NARRATED · WILL BE RE-VOICED`, `force: true`, `priority: 0` for the sheet and `priority: 9` for the opener, `rendered_at` and `cast_changed_at`.</li><li>§8.16.5 (l.2563) `RE-VOICING` and `Re-narrate 38 chapters`; §8.16.11 (l.2597); §15.5 (l.4399).</li></ul> | — |
| PRODUCT-9 | **Unresolved** | **Round-2 defect fixed.** §7.6 World card (l.1143) reads "Three variants.", "Every variant:" and "(Shelf: when its source is mature, as the §7.7 poster badge)".<br>**Rest in place:**<ul><li>§9.1.3 branching on `code` (l.3150–3155, l.3162);</li><li>the Shelf results note (l.3135);</li><li>every Shelf field the fix names.</li></ul> | The Shelf kicker's `{chapter_count}` is always 0 from the backend; details below. "Two visibly" and "Both variants" are absent |
| PRODUCT-10 | Resolved | <ul><li>§9.1.7 `/home` (l.3222): `tz_offset_minutes` required, −720..840, with the web and Flutter sources; cache key `(profile_id, mature_content_enabled, content_kind, tz_offset_minutes, local hour)`.</li><li>§9.2.7 Annual key (l.3387) `(profile_id, mature_content_enabled, content_kind, year, tz_offset_minutes)`.</li><li>§9.1.2 client recompute (l.3128); §15.5 (l.4378, l.4382).</li></ul> | The streak object is `{current_days, longest_days, at_risk, last_active_date}` everywhere (l.3222, l.3243, l.3303, l.4378). No bare `current` field remains |
| PRODUCT-11 | Resolved | §9.4.2 (l.3526) `GET /app/soundscapes/{id}.{ogg\|m4a}`. §8.34 (l.3083) `GET /app/fonts/{file}.woff2`. §15.5 rows (l.4401–4402) | "static folder" is absent. `/app/media/{name}` appears only as "screenshots only" |
| PRODUCT-12 | Resolved | <ul><li>§10.1.1 Trigger row (l.3582): `inView` / `mount` / `signal`, 480 ms `dur.spread` / 160 ms, no cap.</li><li>§10.1.4 Flutter hover (`MouseRegion`, `200 + 10 × (n − 1)` ms, `Interval`, 160 ms exit).</li><li>§10.1.5 `useTitleSignal` and the spaces-excluded `n` (l.3634, l.3691).</li><li>§10.1.6 `SetTrigger`, route-animation signal and `MouseRegion` (l.3733–3865), and the third test case (l.3880).</li><li>§15.6 (l.4409).</li></ul> | `AnimatedDefaultTextStyle`, "60-grapheme" and "word fallback" are absent. `dur.spread` = 480 ms (l.510, l.729) |
| PRODUCT-13 | Resolved | §9.4.1 (l.3516): median of 10, 60–7200 s, 80–900 wpm, 250 wpm until 3 samples, storage keys, the px/s formula recomputed after Type changes. The §8.15.5 row (l.2458) points to §9.4.1 | — |
| PRODUCT-14 | **Unresolved** | <ul><li>§15.6 (l.4416) reads "capacity 50 (one minute of refill), floor 0". "burst 8" is absent.</li><li>P3 users unchanged: §8.14.2 (l.2176), §8.17 (l.2618, 150 ms dwell, first 2), §8.18 (l.2676), §8.24 (l.2819).</li></ul> | Capacity 50 plus a 50/min refill admits up to 99 starts in 60 s against the server's 60; details below |
| PRODUCT-15 | Resolved | §8.0.4 (l.1665) FNV-1a of `sourceId + "\u0000" + seriesKey`: synchronous, once per card, Flutter `Hero` tuple. §8.0.3 (l.1645) encoded builders, "routers decode exactly once", and the `series_identity` note | SHA-1 and `cover-<sourceId>-<seriesKey>` are absent. `crypto.subtle` appears only as the reason it is not used |
| PRODUCT-16 | Resolved | <ul><li>§9.3.2 Offline and Error (l.3449–3450).</li><li>§9.3.4 offline and failure (l.3467) and letter failure (l.3468).</li><li>§9.3.5 share-sheet `CORRECTION` (l.3472).</li><li>§9.3.6 Clear dialog with the 1000 ms arm and its failure toast (l.3480); §9.3.7 offline (l.3484).</li></ul> | — |
| PRODUCT-17 | Resolved | §9.2.5 (l.3374–3376): iOS `NSPhotoLibraryAddUsageDescription`; Android 29+ MediaStore `Pictures/ManhwaManiacs` through `mm/media`; Android 24–28 hides `Save image`, leaving `Share` | Same three harmless departures from the judge's wording as in round 2: the `mm/media` channel name, the Info.plist sentence and the "Pictures › ManhwaManiacs" toast. All are used consistently |
| PRODUCT-18 | Resolved | §9.2.4 colophon `NARRATED BY` (l.3356). §9.2.7 `POST /novels/listen-sessions` (l.3389) and `top_voices` (l.3387, l.3401). §15.5 (l.4398) | — |
| PRODUCT-19 | Resolved | §8.14.6 **The end** (l.2257). §8.15.2 novel end matter (l.2416). §8.8 `continue` (l.1966) | The button is `Mark as done` (CONSISTENCY-19), and both places agree |
| PRODUCT-20 | Resolved | §9.1.8 copy table (l.3258–3265), used by §7.8 (l.1200), the §9.1.3 masthead deck (l.3133), §9.1.3 states and §9.1.6 | "Today's asks are used up" and "Try again in a minute" are absent |
| PRODUCT-21 | Resolved (via CONSISTENCY-10) | <ul><li>§10.2.1 (l.3891): six 530 ms halves (3180 ms), ending on, then a 160 ms fade from 1.</li><li>§10.2.3 keyframes at 15.87 / 31.74 / 47.60 / 63.47 / 79.34 / 95.21 % of 3340 ms (l.3974–3984), each checked as n × 530 / 3340.</li><li>§10.2.4 `(ms ~/ 530).isOdd` (l.3990); §14.10 "0.94 Hz" (l.4207), matching 1060 ms cycles.</li></ul> | "556.7" is absent |
| PRODUCT-22 | Resolved | §8.8 at-risk (l.2016) and §9.1.2 table (l.3126): "Your {n}-day streak ends at midnight." above 60 graphemes | — |
| PRODUCT-23 | Resolved | §9.2.2 "Read today" (l.3301) and Just extended (l.3321). §8.8 and §9.1.2 condition and deck ("Open any chapter before midnight to keep your streak.") | "first completed chapter of the day" is absent |
| PRODUCT-24 | Resolved | §9.2.4 calendar year (l.3359). `partial` (l.3407). Banner thresholds unchanged (l.3278) | "Rolling windows" is absent |
| PRODUCT-25 | Resolved | §8.15.9 (l.2502): the `advanced: false` toast in stock colours with `Jump`, and the `SAVED COPY · 3 H` badge with its tooltip | — |
| PRODUCT-26 | Resolved | §8.30.6 (l.3006–3007): `dio.download` with Bearer, temp file, determinate rule, `share_plus` 12.0.2, error toast, and the `FAILED AT {PHASE}` line in `proof` | `share_plus` 12.0.2 at l.1676, l.3373, l.3007 and in the §15.11 ledger (l.4498). "13.3.0" is absent |
| PRODUCT-27 | Resolved (via CONSISTENCY-34) | `splash.impress` in the §5 table (l.928), fired at the §12.4 impression (l.4090), and in §15.1 (l.4291). `splash.reveal` stays sound-only in §6 (l.955, l.976) and S8 (l.4461) | Consistent across all five places |
| PRODUCT-28 | Resolved | §8.23 (l.2789): result paths for iOS and Android 10+, MediaStore `Download/ManhwaManiacs/Exports/{series}/` through `mm/media` `saveDownload(relativePath, name, mime, path)`, API 24–28 app documents plus `Share`, and no folder picker. §9.2.5 notes the channel's second method (l.3375) | `getDirectoryPath` is absent |

---

## Unresolved

### PRODUCT-14: capacity 50 plus a 50/min refill overshoots the server's 60/min

§15.6 (l.4416) now reads: "(the server allows 60 requests/min per IP across `/sources/*`, covers and page images included) … A token bucket of 50 tokens per minute (refill 1 every 1.2 s), capacity 50 (one minute of refill), floor 0."

A token bucket with capacity C and refill r admits up to C + r·T requests in any window of length T. Here that is 50 + 49 = 99 starts within 60 s. From a full bucket, which is the normal state after a minute of reading, a cover wall or a scrolling Discover page can spend all 50 tokens at once and then one every 1.2 s.

The backend's `sources` limit is `rate_limit_sources = "60/minute"` (`backend/core/config.py:282`), applied through slowapi `@limiter.limit(sources_limit)` on the cover and page-image routes too (`backend/routes/sources.py`). The 61st request inside the server's window gets a 429 after about 12 s of sustained demand. §15.6 then pauses P2 and P3 for `Retry-After`, and P0 has to retry: the visible reader page waits, which is what the limiter exists to prevent.

The judge's "burst 8" was the one capacity that kept gated traffic under the server's window (8 + 50 = 58 ≤ 60). That same cap made the 20-token P3 reserve impossible. With a token bucket at this refill rate, the reserve and the server bound cannot both hold. The round-2 prescription ("the server's 60/min window leaves room for 50 at once") counted the burst but not the refill that follows it in the same window.

*Fix (one sentence, §15.6 l.4416):* replace "A token bucket of 50 tokens per minute (refill 1 every 1.2 s), capacity 50 (one minute of refill), floor 0." with:

> A sliding window of 50 request starts per 60 s (a log of start times; each slot frees 60 s after the request that took it), floor 0; a "token" below means a free slot in that window, so no 60 s ever holds more than 50 limiter-counted starts, 10 under the server's 60.

The rules after it need no change:

- "P2 waits for a token";
- "P3 runs only while at least 20 tokens remain";
- "gated images get their `src` assigned only when a token is granted".

A full window still lets 30 covers start at once with 20 slots left for P3.

### PRODUCT-9: the Shelf card's kicker prints "0 CHAPTERS"

The round-2 defect is fixed. §7.6 (l.1143) now reads "Three variants." and "Every variant: …", and ends the certificate sentence with "(Shelf: when its source is mature, as the §7.7 poster badge)".

The remaining defect is in the judge's own fix text, and rounds 1 and 2 did not catch it. The Shelf variant's kicker is `{SOURCE NAME} · {chapter_count} CHAPTERS`. The `kind: "source"` items of `/library/suggest` are built in `backend/services/suggestion_service.py:766–784` from the catalogue cache, which has no chapter counts, and they hard-code `"chapter_count": 0`. Nothing downstream fills it. `routes/library.py` passes the list through, and §15.5 lists no backend addition for it. As written, every `FROM YOUR SOURCES` result on Picks would read, for example, `ASURA · 0 CHAPTERS`.

*Fix (one clause, §7.6 l.1143):* change "kicker `{SOURCE NAME} · {chapter_count} CHAPTERS`" to "kicker `{SOURCE NAME}`, plus ` · {chapter_count} CHAPTERS` only when `chapter_count` > 0 (`/library/suggest` sends 0, because its catalogue rows carry no count)". No backend change is needed.

---

## Checked and consistent (no action)

- **The JSON-versus-SSE discriminator.** The round-3 rewrite of the §9.1.7 **No stream** note dropped the explicit words "that `Content-Type: application/json`". A client still tells the two answers apart the same way: "plain JSON 200" against the **Stream headers**' `Content-Type: text/event-stream` in the same cell.
- **The Shelf certificate.** "(Shelf: when its source is mature, as the §7.7 poster badge)" is narrower than §7.7's "the series is mature". A series made mature only by its rating (`mature_override`) on a non-mature source would carry no `18` on a Shelf card, even though its poster elsewhere does. The Shelf item carries only `source`, so this is the most the card can know. It matters only for profiles with the gate open, because a closed gate is filtered server-side (`_MATURE_CLAUSE_CLOSED`). If it ever matters, give `/library/suggest` source items an `is_mature` field.
- **The feature page's phone action row** (l.2632) lists "a row of `Read all` and `Previously on`" with no availability condition. The desktop row (l.2612) and the §9.1.5 rendering rule ("every `Previously on…` button … the feature and book pages") both gate it on `available`, so the phone row inherits the rule. It does not say whether `Read all` takes the full width when `Previously on` is absent. That is a layout detail for the mobile lens, not a capability gap.
- **The at-risk parenthetical.** §9.1.2's "(counts ≥ 101)" sits under "above 60 graphemes", which is the operative condition. §8.8 states it precisely as "every count ≥ 101 spelled with 'and'". A round count such as 200 ("Two hundred days and counting. One chapter keeps it alive.", 58 graphemes) keeps the spelled line under either reading.
- **Items that round 2 found consistent and that still are:**
  - `GET /home` without `tz_offset_minutes` in §8.0.8 and in the §15.5 "Tonight in novels mode" row (l.4394). Both are partial references to §9.1.7.
  - §7.22 Quick look listing `Previously on` without a condition.
  - The `p` key on Tonight (l.2024).
  - The spelled count in the at-risk streak caption.
  - The `PICKED 3 DAYS AGO`, `SLOW DOWN` and budget copy repeated in §7.8 and §9.1.3.
