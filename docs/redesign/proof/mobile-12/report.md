# mobile/12 report

Status: done. Every acceptance item has a widget test, a screenshot or both. Owner-only checks are in `device-checklist.md`.

## Done by scope letter
- A engine: `pinchZoom`, `zoomAt`, `jumpToPage`, `scrollByViewport`, `seekToChapter`, `setAutoScrollSpeedX`, `chapterCompleted`, `furtherElsewhere` + `reportServerProgress`, `endPull`/`topPull`, `ReaderEngineOptions` (ground, gap, column, margins, colour filter, tap window and slop, tap handler, auto-hide thresholds, pinch, page state / band / credits / page semantics / page layer slots, footer, top band, offline), `TapClassifier`, `zoom_math`, `autoScrollPxPerSecondX`, `PaceTracker`, `NextChapterAutoQueue(saveNextEnabled)`, preferences record and one-time migration, `upNextProvider`, `AiRepository.similar` (now on the shared `SimilarQuery`).
- B routes: `reader` and `readerLanding` out of PENDING, `CineReaderRoute.manifest/source`, `readerFramesProvider` seam.
- C route page, D system bars, E-N chrome, strip, bands, credits, end states, Contents, keys, lock, auto-hide, cinema, swipe, toasts: as before, plus this fix pass below.
- Fix pass: rate-limited countdown source, further-on-another-device source, the full test set, all screenshots, three real bugs found by the new tests (below).

## Sign-off
`docs/redesign/signoffs.md` lines 3 (S1) and 4 (S11), by backend/06.

## New in the fix pass
- `readerRateLimitedUntilProvider` (`features/reader/providers/reader_signals_provider.dart`): both entry screens' chapter loaders set it from an `ApiError` 429 (`retryAfter`, else 10 s); the engine footer draws `BandKind.rateLimited` with `retryIn` = the time left, the band counts down live, and the auto-retry waits for it.
- `ProgressOutboxController.notAdvanced`: a batch the server accepted with `advanced < saved` emits the series; `CineMangaReader` fetches `seriesProgress`, and when a row is past the chapter being read calls `reportServerProgress(advanced: false)`, which raises the existing Jump toast.
- Bugs the tests exposed and fixed: (1) the phone Contents sheet threw (a `Column`/`Expanded` list inside the sheet's scroll view, and no `Material` for its number field): now bounded and wrapped; (2) the last chapter of a series showed a "next chapter failed" band under the end notice: `nextState` is now `failed` only when a next chapter exists (`none` on a last chapter), and while a known next chapter is being fetched it is `loading` (so the `IS ON ITS WAY` band shows); engine test updated and extended; (3) the chapter announcement fired twice and without the number before the series resolved: once per chapter, with the series name; (4) auto-scroll resumed by itself after a band under reduced motion; (5) the download mark was 44 wide on Android (now 48); (6) the last-chapter footer reserved 1300 px, leaving the notice above the fold at the end of the strip (now 920).

## Screenshots and what they prove (`docs/redesign/proof/mobile-12/`, phone 390 x 844 and tablet 834 x 1194 from the harness)
| File | Acceptance item |
|---|---|
| reader-chrome-{phone,tablet} | running head, folio bar, ruler, page counter; ruler ticks and neighbours |
| reader-hidden-phone | auto-hide, micro progress while hidden |
| reader-landscape-chrome | landscape layout (844 x 390) |
| reader-wipe-hold-{phone,tablet} | Column wipe held at the 40 ms black (4 and 8 blades) |
| reader-contents-sheet-phone, reader-contents-panel-tablet | Contents: sheet on phones, left column panel on tablets |
| reader-jump-field-phone | `07 / 40` becomes a number field |
| reader-zoom-chip-phone | zoom chip (`200%`) |
| reader-brightness-hud-phone | brightness HUD (`NIGHT -38`) |
| reader-seam-phone, reader-top-band-phone | seam, top band |
| reader-credits-compact-phone, reader-credits-full-{phone,tablet} | compact and full credits, Coming up card, pull to continue |
| reader-caught-up-phone, reader-the-end-phone | caught up (Notify me), the end (Mark as done) |
| reader-loading-phone, reader-broken-page-phone | loading plates, `PAGE 1 DIDN'T LOAD` with Retry |
| reader-rate-limited-phone | rate limited with the live countdown |
| reader-not-available-phone | `NOT IN THIS ISSUE` (`series_not_found`) |
| reader-rating-card-phone | 18+ rating card |
| reader-locked-toast-phone | lock mode unlocked after five centre taps, `Controls unlocked` |
| reader-reduced-motion-phone | reduced-motion chrome |
| reader-legacy-phone | `LEGACY` edition, legacy reader untouched |
| entry-follow-phone, entry-source-phone | the two data paths (manifest and source) |

Page art is the procedural `ShotCoverArt` plates (never a source's pages); the harness now loads them (the fetch, cache write and decode run on real time before the capture). Web twin: `docs/redesign/proof/web-12/` is not in the tree (web/12 is not integrated), so there is no side-by-side yet; compare when it lands (stack-decision risk 1).

## Tests (mobile/test/skins/cinematic/reader/)
reader_route_test (616 / 744 / 440 / 200 / 150 ms, tap within 120 ms, `COLUMN WIPE` and `DIP` planned durations in the motion recorder), reader_system_bars_test (mocked `SystemChannels.platform`, iOS and Android: entry, chrome shown, hidden, exit), reader_chrome_behaviour_test (idle 3000 ms, 24 / 56 px, 800 ms grace, screen reader, focus in chrome, lock mode, hit-target walk 44 iOS / 48 Android with 8 px spacing), reader_keys_widget_test (every N key, Reader group in the registry), reader_states_test (loading, broken page, next loading with the 8 s caption, rate limited with a ticking countdown, next failed, caught up, the end, compact and full credits), reader_motion_a11y_test (Letter set 200 ms under reduced motion, typed caption 50 ms per character and 2000 ms hold, chrome fade without slide, tap-to-scroll jump, auto-scroll never starts, semantics label and OCR hint, chapter announcement once), reader_further_test (Jump toast, no toast when behind or for another series), reader_contents_test (sheet, panel, sort, go-to).

## Test counts and RAM
- `flutter analyze`: No issues found.
- `flutter test test/features/reader test/features/ocr test/skins` after the last change to the engine: 2110 passed, 1 failed (`reader_engine_state_test`, fixed and rerun: 6 of 6 pass).
- Full `flutter test`: 5104 passed, 0 failed. Before this pass the earlier report gave 4234 passed, 1 failed on the older base (the count grew with the merged lanes and the new tests; the figures are not from the same tree).
- `free -m` available before each heavy command: 19386, 17943, 19154, 18697, 18931 MB.

## Followed cinematic/DESIGN.md over the prompt
- Compact credits live inside the 96 px seam band (8.14.5) rather than a separate row.
- The 250 ms pull fade is the reader route's 440 ms Dip (8.14.1 says a pop is always the Dip).
- The strip column keeps the shared geometry's 768 px cap (stripWidth 769-860 is clamped) so the legacy reader stays byte-identical.
- Rate limited draws at the end of the loaded strip (where the next chapter would stitch), not over unloaded pages, because the strip reserves those boxes at exact size.
- Pinch reads raw pointers (recorded in the prompt); no `ScaleGestureRecognizer`.

## Open issues
- Guided view, paged layouts, read-all and the Reading setup sheet are mobile/13 and mobile/23.
- Device checks (wipe timings on hardware, VoiceOver and TalkBack, volume keys) are owner-only: `device-checklist.md`.
