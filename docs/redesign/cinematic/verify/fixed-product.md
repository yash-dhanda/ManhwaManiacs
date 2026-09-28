# Cinematic DESIGN.md: fixes applied from the capabilities and owner-decisions judge

## Round 1

Source: `cinematic/verify/judge-product.md`, section "Confirmed" (28 findings; PRODUCT-29 and PRODUCT-30 were refuted and are not applied). Section numbers refer to `cinematic/DESIGN.md`.

| ID | Sections changed |
|---|---|
| PRODUCT-1 | §9.1.5 new "Availability and range" block (`GET /ai/recap/availability`, 12-chapter range with the 60-day gap stop, availability rules, rendering rule, budget), entry behaviours (auto-open only when `available`), reader chip `PREVIOUSLY ON · {ceil(est_seconds / 60)} MIN`, `NO RECAP FOR THIS ONE` only after a stale tap; §9.1.7 availability row, SSE framing (`meta` / `delta` / `done` / `error`), web `fetch` + `ReadableStream`, Flutter `dio` stream + `LineSplitter`, `recap` on `/home` `cover` and `continue`; §9.1.1 row; §9.1.2 case 3; §8.8 cover actions, now-showing strip, phone actions, `Where were we?`; §7.6 Cutting Quick look; §8.17 and §8.18 action rows; §15.5 |
| PRODUCT-2 | §8.7 18+ gate paragraph, steps 2 and 5, Backend (`GET /onboarding/catalog`, `GET /ai/similar?anilist_id=`, `onboarding_step` migration); §8.8 new-profile state (0-pin fallback: 3 healthiest non-18+ sources, `SUGGESTED SOURCES`, taste genres); §9.1.2 case 5; §9.1.7 `/ai/similar` row; §15.5 |
| PRODUCT-3 | §9.3.8 member, filtered feed, `DELETE /circle/activity`, `GET /circle/series`, reaction `DELETE` body, shared-shelf fields and calls, polling, `409 recipient_unavailable`; §8.17 CIRCLE tab; §8.14.12 CIRCLE panel; §9.3.5 `SHARED WITH YOU`; §15.5 Circle row |
| PRODUCT-4 | §9.4.3 client-side detection, gutter rule, parity vectors, `POST /reader/panels` cache, entry, states (`FINDING PANELS`, `WHOLE PAGE`, offline); §9.4.5 row; §8.14.3 running-head button; §15.4 fifth engine duty (panel detection); §15.5 row; §15.6 worker note; §15.8 `panel-vectors.json`; §15.10 new S11 (sign-off) and owner-call line |
| PRODUCT-5 | §8.3 States (every 401 except `invalid_credentials` signs out); §8.30.4 Change password server answers (`invalid_credentials`, `weak_password`, `rate_limited`) |
| PRODUCT-6 | §9.3.4 Pass it on recipients and caption; §7.25 reading-now ring conditions; §9.3.8 `now` rule for 18+ series |
| PRODUCT-7 | §8.17 gestures and new "Mark read and Mark unread" block (one chapter, up to here, unread, `manual: true`, toasts with Undo, offline); §8.18 gestures; §8.9 select mode; §7.6 Cutting Quick look; §15.5 row |
| PRODUCT-8 | §8.16.8 `RE-VOICE` quick pick, re-voice selection, `force` and priorities (`priority: 0` sheet, `priority: 9` opener); §8.16.5 `RE-VOICING` and the owner's `Re-narrate 38 chapters`; §8.16.11 opener; §15.5 row |
| PRODUCT-9 | §9.1.3 masthead deck, results (Shelf variant), states branch on `code` (`suggest_shelf_empty`, `ai_budget_exhausted`, `ai_not_configured`, `ai_failed`, `rate_limited`) and the "branch on code" note; §7.6 World card *Shelf* variant |
| PRODUCT-10 | §9.1.7 `/home` `tz_offset_minutes`, cache key, streak `last_active_date`; §9.1.2 client at-risk recompute; §9.2.7 `/library/annual` `tz_offset_minutes`; §15.5 rows |
| PRODUCT-11 | §9.4.2 soundscape route; §8.34 font route; §15.5 two new rows (`GET /app/soundscapes/{id}.{ext}`, `GET /app/fonts/{file}.woff2`) replacing the static-folder row |
| PRODUCT-12 | §10.1.1 Trigger row (`trigger` prop, `play` signal, no cap); §10.1.4 Flutter hover; §10.1.5 web `SetHeading` (trigger, `useTitleSignal`, spaces-excluded count, letter spans kept after the reveal); §10.1.6 rules paragraph, Flutter `SetHeading` (`SetTrigger`, route-animation signal, `MouseRegion` wipe, no word fallback) and a third test case; §15.6 cap bullet |
| PRODUCT-13 | §9.4.1 Speed (novel pace definition, storage, px/s formula) |
| PRODUCT-14 | §15.6 new sources request limiter (P0–P3, bucket, rules); §8.17 schedule-row prefetch (150 ms dwell, first 2); §8.14.2 hold step; §8.18 states; §8.24 crops |
| PRODUCT-15 | §8.0.4 shared-cover name (synchronous, once per card, Flutter `Hero` tuple); §8.0.3 encoded route builders |
| PRODUCT-16 | §9.3.2 states (Offline, Error); §9.3.4 Pass it on offline and failure, letter action failure; §9.3.5 share sheet failure; §9.3.6 Clear dialog; §9.3.7 offline |
| PRODUCT-17 | No change: §9.2.5 already carries `NSPhotoLibraryAddUsageDescription` on iOS and the MediaStore `mm/media` channel on Android 10+ (Android 7–9 hides `Save image`, leaving `Share`). §9.2.5 now notes the channel's second method for PRODUCT-28 |
| PRODUCT-18 | §9.2.4 colophon `NARRATED BY` source; §9.2.7 `top_voices` and `POST /novels/listen-sessions` with client batching; §15.5 row |
| PRODUCT-19 | §8.14.6 new "The end" state; §8.15.2 novel end matter; §8.8 `continue` row |
| PRODUCT-20 | §9.1.8 unavailable copy table; §7.8 AI-unavailable line; §9.1.6 `From your shelf` note; §9.1.3 states reference the table |
| PRODUCT-21 | No change: CONSISTENCY-10 already rewrote the caret (six exact 530 ms halves ending on, then a visible 160 ms fade from 1), which removes both defects this finding names |
| PRODUCT-22 | §8.8 at-risk state and §9.1.2 table: "Your {n}-day streak ends at midnight." above 60 graphemes |
| PRODUCT-23 | §9.2.2 "Read today" rule and Just extended trigger; §8.8 and §9.1.2 at-risk condition and deck ("Open any chapter before midnight…") |
| PRODUCT-24 | §9.2.4 "Rolling windows" paragraph replaced by the calendar-year rule |
| PRODUCT-25 | §8.15.9 cross-device toast and `SAVED COPY` badge |
| PRODUCT-26 | §8.30.6 mobile export through `dio` + share sheet (`share_plus` 12.0.2, the ledger's pinned version) and the failed-nightly line |
| PRODUCT-27 | No change: CONSISTENCY-34 already added the haptic event `splash.impress` (iOS and Android `impress`, §5, §15.1) fired at the 1180 ms impression, and §12.4 fires it by event name; `splash.reveal` stays the sound-only reel |
| PRODUCT-28 | §8.23 Save to Files result paths and Android destinations (MediaStore `Downloads` on API 29+, `Share` on 24–28, no folder picker); §9.2.5 `mm/media` channel note |

The Coverage appendix (Appendix B) is unchanged: no screen was added, removed or renamed.

## Round 2

Source: the four findings `verify/recheck-product-1.md` left unresolved. The other 24 were confirmed resolved there and are unchanged.

| ID | Sections changed |
|---|---|
| PRODUCT-1 | §9.1.5 "Availability and range": `recap` also on `/home` `where_were_we` items and on every `GET /library/continue-reading` row (Library's Continue rail, its cuttings' Quick look and `Continue` now follow the setting); any other Quick look calls `GET /ai/recap/availability` when it opens and adds `Previously on` only on `available`; any other `Continue` without `recap` calls it on press and goes straight to the reader on failure or after 400 ms. §9.1.7 `/home` Returns note (`cover`, `continue` and `where_were_we`); §9.1.7 items table (`continue` row names `recap`; `where_were_we` split from `new_this_week` with `recap`); §8.9 Continue reading rail (rows carry `recap`); §15.5 `/home` row (`recap` on `cover`, `continue`, `where_were_we` and continue-reading rows) |
| PRODUCT-2 | §8.7 States: "Catalog unreachable at steps 2 and 5 (`GET /onboarding/catalog` fails)" and "AI unavailable: the taste is saved, the wall still comes from the catalog, and a pick inserts no similar posters." |
| PRODUCT-3 | §8.11 Collection detail: library join and `NO LONGER FOLLOWED` scoped to the owner's own unshared shelves; a shared shelf renders every row from its own `title`, `cover_url` and `ambient` for owner and members alike. §8.11 Collections: new `SHARED WITH YOU` group from `shared_with_me` (owner avatar, `CAN ADD` / `VIEW ONLY` caption, outside `Custom order`, deck count) |
| PRODUCT-10 | §9.2.7 Annual cache key is now `(profile_id, mature_content_enabled, content_kind, year, tz_offset_minutes)`. The §15.5 composed-caches row ends in "…" and needed no change |

The Coverage appendix (Appendix B) is unchanged: no screen was added, removed or renamed (`SHARED WITH YOU` is a group inside the existing Collections screen).

## Round 3

Source: the three findings `verify/recheck-product-2.md` left unresolved. The other 25 were confirmed resolved there; a grep for each one's removed text (for example "a recap is possible", "Rolling windows", `getDirectoryPath`, `GET /reader/panels`, "556.7") still finds nothing, so they are unchanged.

| ID | Sections changed |
|---|---|
| PRODUCT-1 | §9.1.7 `GET /ai/recap` **No stream** note: the clients map `reason` onto the §9.1.5 states as they would a stream `error` with that code (`no_dialogue` → `NO RECAP FOR THIS ONE`; `not_configured` and `budget_exhausted` → `RECAP UNAVAILABLE`; `rate_limited` → `RECAP UNAVAILABLE` plus the §9.1.8 `SLOW DOWN` line and its `Retry-After` countdown, the JSON answer carrying `Retry-After` for this reason; `first_chapter` → straight to the reader with no slate). §9.1.5 States: the "No recap" row reads "the answer is `no_dialogue`, as JSON or as a stream `error`"; the unavailable row adds "rate limited" with the `SLOW DOWN` line; the "First chapter" row adds that a stale `first_chapter` answer goes straight to the reader. §15.5 defers to §9.1.7 for the recap framing and needed no change |
| PRODUCT-9 | §7.6 World card row: "Two visibly different variants" → "Three variants"; "Both variants" → "Every variant", ending with "(Shelf: when its source is mature, as the §7.7 poster badge)" |
| PRODUCT-14 | §15.6 sources request limiter: "burst 8, floor 0" → "capacity 50 (one minute of refill), floor 0", so the 20-token P3 reserve can hold. No per-second start cap was added. No other section repeats the bucket size |

The Coverage appendix (Appendix B) is unchanged: no screen was added, removed or renamed.

## Round 4 (main session)

- PRODUCT-14: §15.6 sources limiter is now a sliding window of 50 request starts per 60 s (a capacity-50 refilling bucket admits up to 99 in a window and trips the 60/minute server limit).
- PRODUCT-9: §7.6 Shelf kicker shows ` · {chapter_count} CHAPTERS` only when chapter_count > 0; /library/suggest returns 0 for source items.
