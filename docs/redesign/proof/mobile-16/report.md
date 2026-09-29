# mobile/16 report (lane L09)

Cinematic Discover, Sources, Catalogue and Dialogue search, phone and tablet.

## Proof

`mobile/test/screenshots/cinematic/mobile_16_discover_shots_test.dart`, on the mobile/03 shot harness:

    MM_PROOF_DIR=../docs/redesign/proof/mobile-16 /srv/manhwamaniacs/dev/heavy.sh mobile flutter test test/screenshots/cinematic/mobile_16_discover_shots_test.dart

47 states, each as `<state>-phone.png` (390x844 @2x), `<state>-tablet.png` (834x1194 @1.5x) and
`<state>-reduced-phone.png` (reduced motion): discover idle, searching, partial (tier 2 running),
results, no results, offline, error, rate limited, ask; sources directory, loading, none, pinned
empty, pins failed; catalogue loaded, opening, not browsable, not found, error, rate limited;
dialogue idle, results (subtitled stills), none, unavailable, novels, offline. Fix pass 2 added: genre sheet,
group jump sheet, ASK thinking / unavailable / rate limited, sources offline / row menu / health details /
row mid-drag, catalogue opening at 0.5 s and 3.5 s (replacing the single `opening`), stale, end of catalogue,
dialogue crop loading / crop failed, the bubble pulse, and the scan block in each of its six phases.
Titles and art are invented.

## Verification

- `flutter analyze`: no issues.
- `flutter test` (whole app): see the returned summary for the final count.
- `test/skins/cinematic/discover`: 122 tests: per screen iOS + Android tap targets, labelled
  targets and `textContrastGuideline`; key groups registered under Discover / Sources /
  Catalogue / Dialogue; hardware keys (`/`, Esc, Enter, `3`, `]`, `p`, Alt+Down); reduced motion
  (letter reveal stopped after 250 ms, typed hint complete, group jump `jumpTo`, highlight sweep at
  its end state); tier 1 then tier 2 with the indeterminate rule; filters; genre-tile cap 12 and
  `All n genres`; trending; wall 3 / 5 per row; opening-state timers; live `Retry-After`
  countdowns; Quick look; still crop wiring; 12-still rack focus cap; reader landing host
  (known page, OCR-text page, chapter start, other chapter, reduced motion).

## Fixed in this pass

Round 1: reader hook (`DialogueLandingHost`), Quick look, focus rings, key registry, toast, pull to
reprint, highlight sweep, live countdowns, tablet table head, `SetHeading` on the mastheads.

Fix pass 2:
- 429 `Retry-After`: `ErrorInterceptor` folds the header (`parseRetryAfter`) into `ApiError.details['retry_after']`
  (test through the real interceptor). Search, catalogue deck and ASK all count down from it.
- ASK: the dial appears after 1 s (`DelayedShow`), results are World cards fading in 160 ms each, 30 ms apart
  (plain fade under reduced motion), rate limited runs a live `RetryCountdown`; `aiCopyForError` carries the wait
  and reads a bare 429 as `rate_limited`. The thinking row no longer overflows.
- Route focus lands on each screen's level-1 heading (`HeadingFocus`, post-frame `requestFocus`); j / k / down
  arrow now move from the focused node (`focusStep`), not from the route scope.
- Dialogue not-available: `GET /settings` `capabilities.ocr == false` shows "...isn't available on this server."
  and removes the DIALOGUE scope (`serverOcrCapabilityProvider`; unknown means on).
- Dialogue hits build in a `ListView.builder` (masthead, hits, footer): crops load as items are built.
- Catalogue: source-hue wash is a screen-level layer behind the masthead, top 30% of the viewport (`CatalogueWash`);
  novel sources render a book list; the Genre control uses the 56 px header sheet with a grabber.
- Sources: `dots-six-vertical` handle, 2 px `spot` rule under a pinned toggle, heavy rule drawn after the letters
  land (`DrawnRule`), raised counts (`PINNED⁶`), header sheets for the row menu and Health details, drop index mapped
  to the full pin order (hidden pins keep their slots), and the drag proxy has its own `Material` (dragging a row
  used to throw "No Material widget found").
- Genre sheet rows carry the 24 px logo and a health mark; genre tiles are duotoned (fallback `ambient.duo`) with the
  1 px press impression.
- Tests: `keys_focus_test.dart` (heading focus per screen; Discover 1-5, down, `[` `]`; Sources j/k/Enter and a real
  drag; catalogue h j k l Home End r; Dialogue j/k/Enter; Tab order paints `CineFocusRing` on every screen; ASK
  countdown, dial delay and stagger; lazy stills; server / device notices).
- Proof: 21 more states listed above, all in phone, tablet and a `-reduced` phone copy.

## Open (blocked on steps that are not integrated)

- Reader landing (`DialogueLandingHost` mounted in the reader, `pageOverlayBuilder` slot, engine `jumpToPage`):
  Cinematic `ScreenId.reader` is still `PENDING` (mobile/12). The host, resolver, toast and `BubblePulse` are built
  and tested standalone; the Dialogue screen sets `dialogueJumpProvider` and pushes `Routes.reader`. Mount the host
  when mobile/12 lands. The bubble pulse proof is a painted page, not the real reader.
- Done after mobile/06 landed: the four screens are registered in `screens.dart` and off `PENDING`; Discover
  listens to the shell's `focusSearchSignalProvider`; Dialogue hits use `enterReader(entry: dip)`; the sheets use the real
  `CineSheetRoute`; 429 waits read `ApiError.retryAfter` (`retryAfterSeconds` in `ai_copy.dart`, `details.retry_after` kept as fallback).
- Remaining stand-ins for mobile/04 and mobile/05 primitives (`cine_kit.dart`, `cine_extras.dart`, `cine_poster.dart`) keep their
  DESIGN values and `TODO(mobile/NN)` markers; swapping each for the shared primitive is a follow-up.

## Deviations (each with its reason)

- Stand-ins (`showCineSheet` for `CineSheetRoute`, `Duotone`, `PressImpression`, `DrawnRule`, `CatalogueWash`, the book row), marked `TODO(mobile/04|05|06|08|12)`: the primitives of mobile/04, 05, 06, 08 and 12 are not
  in the integrated ledger (only mobile/03 is), so `cine_kit.dart` / `cine_extras.dart` /
  `cine_poster.dart` keep the DESIGN values and are renamed away when those steps land:
  slug lines, notices, plates, typed text, focus ring, toast, Quick look, pull to reprint,
  `SetHeading`, `CineKeyRegistry` (swap for the shell registry), the genre tile duotone
  (`ambient.duo` needs mobile/04), `ai_copy.dart` (mobile/08), the Dip entry into the reader
  (`enterReader(entry: dip)`, mobile/06: the Dialogue screen `push`es the reader) and the
  reader chrome that mounts `DialogueLandingHost` (mobile/12).
- `SetHeading` stand-in draws the letter fade only; the blur half (`letterBlur`) waits for mobile/04.
- The scan widgets are not in the mobile/04 Diagnostics gallery: the gallery does not exist yet.
  They are covered by `scan_widgets_test.dart`.
- File layout is guidance: `health_mark` lives in `cine_kit.dart`, genre tiles in `discover_idle.dart`,
  scope tabs are `SlugTabs`, the catalogue toolbar and wall live in `catalogue_screen.dart`.
  A separate `source_table.dart` holds the tablet column heads.
- Device checks are in `device-checklist.md` and `docs/redesign/owner-todo.md`.
