# mobile/19 report

Lane L15, branch `redesign/L15`. Not pushed (the integrator pushes).

## Acceptance

Everything below holds and is covered by a widget or unit test unless marked.

- `picks` and `recap` are out of the Cinematic `PENDING` set; the completeness and import-boundary tests pass.
- Picks: every part of B, every state of the table (proof shots). Ask field types and cycles its three examples, submits on the send key and `Enter`, `Shift+Enter` does not ask, `n / 600`, 3-600, the toggle picks `/library/suggest` or `/library/world/suggest`, `?ask=1` focuses it.
- Thinking, the 40 s timeout without cancelling, `Try again`, a late answer still rendering: widget tests with a fake clock. Deviation: `Try again` supersedes the running ask (its answer is dropped) instead of cancelling a `CancelToken`, because `LibraryRepository.worldSuggest` has no cancel hook and 22 fakes implement it.
- Not for me / More like this: fade, gap, `not_interested` / `liked_pick`, the dismissed set hides the card on Tonight, the Fill glyph, toast, local clear; long-press menu, `dots-three` and `Delete`.
- `03 MORE LIKE THIS`: Similar, Because you read, `SAME GENRES` under the `NOTE`, stale badge, empty, thinking. `?tab=more-like-this` opens it. Quick look offers More like this and Not for me on picks.
- Tonight's AI rails: dismissed items hidden, `planSections(noted:)` re-ranks and `noteOpenedFromRail` is called from a rail; `cineAiUnavailableCopy` now delegates to the one copy module.
- Recap: streams word by word under a three-line drop cap (split unit-tested), italic cast names, cast list, footnote (with the stale line only when `generated_at` is old), `Skip recap` from t = 0, exits by Column wipe / Dip / back by origin.
- Countdown: 12 s after done, only with auto-continue on, drains the 2 px rule, folio counts, pauses on touch, hover, focus, background and a non-reserved key, resets on scroll up, announces once, never starts with a screen reader (all widget-tested), `Space` toggles (reducer + widget test).
- Every state of D11 renders; a JSON no-stream answer maps like the stream `error`; `Scan saved chapters` only with saved manga chapters and OCR available.
- `mm.recap.u{user}p{profile}` keeps the glass 15.6 shape (`recap_setting.dart` from mobile/18, untouched); `continueTo` covers ALWAYS / AFTER N DAYS AWAY / NEVER, `skipSeries`, the 400 ms ask and giving up.
- Reduced motion, hit targets (Android and iOS), labelled targets and contrast pass on Picks, the recap and the feature tab.
- Glass still maps `picks` and `recap` to its pending screen; shared files (A1-A10) carry no Cinematic copy.
- Not verified here (owner): device checks in `device-checklist.md`.

## Stand-ins (the reader lane has not integrated)

- `PreviouslyOnChip` (`screens/reader/previously_on_chip.dart`) is built and tested; it is not mounted under a reader's running head. TODO(mobile/12), TODO(mobile/14).
- `CreditsMoreLikeThis` (`screens/reader/credits_rails.dart`) and `upNextChain` (`features/ai/utils/up_next_chain.dart`) are built and tested; the credits do not mount them. `up_next_provider.dart` and `up_next_rail.dart` do not exist yet. TODO(mobile/12).

## Open issues

- Backend: world recommendations carry no `generated_at`, so Picks never shows `PICKED n DAYS AGO` from them until the field exists (parsed when present). Recap `meta` has no `generated_at` either; the stale line uses the `done` event's.
- The cast field of `meta.cast` is `note`, not `role` (the model reads either).
- The series page (mobile/11) overflows by 35 px on the tablet spread under the harness's tablet insets; the tablet proof shot shows it. Not changed here.
- The series tab row is now 48 dp and scrolls on phones (three tabs do not fit); the third tab is `03 MORE LIKE THIS`.
- Suggested tags (mobile/11's `DashedToken` line) were verified against C5 and left as is; the reject fades by invalidation, not a 160 ms fade.
- The Picks rails use `CinePoster` cards with the Quick look menu (More like this, Not for me); the World card widget (with the on-art buttons and `dots-three`) is used for For you and the ask results.

## Numbers

- `flutter test`: 4844 passed, 0 failed (baseline 2012 at `00-baseline.md`; other lanes have added since).
- `flutter analyze`: No issues found.
- New tests: 20 files, about 190 cases.
- Lowest `free -m` available seen: 11.9 GB.
- Proof: 55 PNG (Picks 16 states x 2 sizes, feature tab 2 x 2, recap 7 x 2, reader chip 1 x 2, 3 reduced copies).

## Commits

a586e0ad, 92656c43, 66523cd0, 1a90cf1d, 2c919ae6, 0dc5860a (see `git log redesign/L15`).
