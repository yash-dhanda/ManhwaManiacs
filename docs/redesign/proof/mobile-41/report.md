# mobile-41 report

Done: A1-A8 (data layer, committed first), B1-B14 (For you and Ask, Deal, Not interested), C1-C10 (continue path, offer, chapter pill, deck, states, keep-alive, How it works), D1-D3 (More like this rail), E1-E2 (one voice test, purge hooks).

Captures (`docs/redesign/proof/mobile-41/*.png`): for-you-* (idle, thinking, deal, results, grid, genre, no-matches, budget, not-configured, offline, novels, swipe, reduced-motion, text-scale-2), offer (+tablet-wide), recap-* (writing, deck-card1, deck-card3, lift, compact, no-source-text, unavailable, offline-cached, ready-toast, screen-reader-list), how-it-works, chapter-pill, more-like-this, more-like-this-genres. Every named capture now exists at phone and tablet (offer also tablet-wide); swipe, reduced-motion, text-scale-2 and screen-reader-list are phone-only by contract. Web twin screenshots were not present to compare.

Open issues:
- The recap endpoint has no cache-bypass parameter, so the "Write it again" button is not rendered.
- Series detail, book page, both readers, Library stack and accessories are other lanes' screens, absent from this tree. The Continue call sites that exist (Home spotlight, continue rail, poster menu, dock menu, rails) go through `continueSeries`; the rest must call it when they land, and mount `RecapChapterPill` and `MoreLikeThisRail` in their slots (the rail is in `parts/ai/`, the old series-folder copy never existed).
- "Continue" on the deck does not restore the saved page; the novel cast hue for Who's who uses g700 for all.
- Deck lift spring settles in about 700 ms at the default tolerance (spec 436 ms is the nominal settle).
- The recap offer/How it works use registered global sheets; the desktop popover form uses `GlassWideForm.popover`.
- `test/features/reader/engine/strip_120_test.dart` (mobile/34, untouched here, identical to the base branch) fails when run alone or with `test/features test/skins/glass` (sampler requests 54 > budget 53.81) and passes in the full suite: order-dependent, not this step.
- WorldCard (mobile/26 primitive) lets a long title run under the source chip at tablet width (more-like-this-tablet.png).

Verification (2026-10-01 restart run): `flutter analyze` No issues found; `flutter test` full suite 7,985 passed, 1 skipped, 0 failed; `flutter test test/features test/skins/glass` 3,445 passed, 1 skipped, 1 failed (strip_120 above); mobile-41 capture tests 12 passed; `node design/build.mjs --check` exit 0 (sound-intake warnings only); lowest `free -m` available 13,410 MB; `git status --short mobile/docs/screenshots` empty.
