# mobile/38 report: Glass search, sources, catalogue, dialogue search

## Done by scope letter

- A (shared data layer): `GlassDiscoverScope` parser, the novel-text FTS4 index (downloads db v6 to v7, `unicode61` tokenizer with a `simple` fallback, index on ready, drop when unreferenced, backfill, ranking in SQL, 50 cap, byte-offset snippets), offline title search, `{q, gateOpen}` recent searches (already in mobile/29), `latestUpdateBySource`, `engineName`, `pendingAskProvider`.
- B (Search): built into the shell's existing `/search` page slot (`glassDiscoverBodyProvider`): idle (Recent, Trending, Browse sources; the Ask card is gated on `picksReady`, which stays false until mobile/41), scopes All, Library, Sources, Dialogue, Novel text (`[` and `]`), tiered results with the tier capsule (liquid fill, check, announcements), groups with tier-2 append only, surface from depth for late groups, failed-source rows with Retry, quiet-source disclosure, jump bar above six groups, Dialogue scope cards, Novel text rows and states, offline (downloaded titles), rate-limited capsule with auto retry.
- C (Sources): health line, filter, chips (All, Pinned, 18+, Having trouble only when something fails), Pinned section on the glass reorder list (drag handles, Alt+arrows, Move entries), swipe Pin, pin fly overlay, pull to refresh, pinned shelf of 180 x 96 cards on wide frames (update line from notifications), the C6 states.
- D (Catalogue): header with letter reveal, count line, freshness capsule (ticks every 30 s, stale explains on tap), health notices, search well, browse-mode chips and horizontal swipe, genre chip only with genres, 3-column grid (148 px minimum on wide), infinite scroll at 70 %, Top capsule after 400 px, novel shelf, opening lens with three orbiting covers and the 3 s line, the D8 states.
- E (Dialogue): title, subtitle, field, cards with highlighted terms, "212 words · Vision", Load more with `offset`, phone hint rows, novels-mode lens, capabilities lens, states. The hand-off sets `dialogueJumpProvider` and pushes the reader.

## Not done, with the reason

- E4 reader side (glide, hit lens, "Match 1 of 3", no-match toast): the Glass reader (mobile/35) is not in this worktree and not in the ledger, so there is nothing to wire. The hand-off is in `openDialogueHit`.
- B1 already existed in the shell (orb morph, dock sink, Cancel); B8 jump bar is visual plus semantics buttons; B11 tablet filter column, B12 lift and bloom on results, the field's downward drag: not built.
- C3 pin fly copy flies to the Pinned header, not to the exact new slot; C5 row menu on long press is offered only for pinned rows (through the reorder list).
- D5 lens pop and wave, D6 tag flight, D3/D8 P3 prefetch priority split (the browse notifier has no limiter hook; the next page is requested at 70 %), the Dialogue screen `LetterReveal` (the scaffold's large title is used).
- Glass screens in other lanes own the series sheet, so posters open it through `openSeries` (Zoom comes from that route).
- Screenshots: `test/screenshots/glass/mobile_38_discover_shots_test.dart` captures the main states of the four screens on phone and tablet plus Cinematic's two; the long per-state list of the prompt (mid-morph, mid-slosh, -reduced, -solid, -contrast copies) is not captured. Names follow the harness (`{skin}-{screen}-{size}`).

## Decisions where the contract was silent or differed

- "All" is the first scope segment (five segments is the maximum).
- `pendingAskProvider` hands the Ask query over; the card is hidden until `picksReady` (constant false for now).
- The search route stays the shell's transparent root page; `_write` in `search_orb.dart` now keeps `?scope=` when the query changes.
- The pinned-shelf update line reads `latestUpdateBySource` over the updates notifications (they carry `source_id`).
- FTS ranking is in SQL exactly as specified.
- No-match toast wording, when the reader exists: "Opened at the chapter start: the match moved."
- `glass/DESIGN.md` was not contradicted where read.

## Open issues

- Reader hand-off (glass 8.14.9) needs mobile/35.
- Limiter priorities for the browse prefetch (glass 7.33 and the P3 rule).
- Tablet filter column for Search (glass 8.9).
