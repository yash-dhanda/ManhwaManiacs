# mobile/16 report (lane L09)

Cinematic Discover, Sources, Catalogue and Dialogue search, phone and tablet.

## Proof

`mobile/test/screenshots/cinematic/mobile_16_discover_shots_test.dart`, on the mobile/03 shot harness:

    MM_PROOF_DIR=../docs/redesign/proof/mobile-16 /srv/manhwamaniacs/dev/heavy.sh mobile flutter test test/screenshots/cinematic/mobile_16_discover_shots_test.dart

26 states, each as `<state>-phone.png` (390x844 @2x), `<state>-tablet.png` (834x1194 @1.5x) and
`<state>-reduced-phone.png` (reduced motion): discover idle, searching, partial (tier 2 running),
results, no results, offline, error, rate limited, ask; sources directory, loading, none, pinned
empty, pins failed; catalogue loaded, opening, not browsable, not found, error, rate limited;
dialogue idle, results (subtitled stills), none, unavailable, novels, offline. Titles and art are invented.

## Verification

- `flutter analyze`: no issues.
- `flutter test` (whole app): 2348 passed.
- `test/skins/cinematic/discover`: 86 tests: per screen iOS + Android tap targets, labelled
  targets and `textContrastGuideline`; key groups registered under Discover / Sources /
  Catalogue / Dialogue; hardware keys (`/`, Esc, Enter, `3`, `]`, `p`, Alt+Down); reduced motion
  (letter reveal stopped after 250 ms, typed hint complete, group jump `jumpTo`, highlight sweep at
  its end state); tier 1 then tier 2 with the indeterminate rule; filters; genre-tile cap 12 and
  `All n genres`; trending; wall 3 / 5 per row; opening-state timers; live `Retry-After`
  countdowns; Quick look; still crop wiring; 12-still rack focus cap; reader landing host
  (known page, OCR-text page, chapter start, other chapter, reduced motion).

## Fixed in this pass

Reader hook (`DialogueLandingHost`: take, `jumpToPage`, toast, `BubblePulse` in the per-page overlay),
Quick look on a 450 ms long-press plus trailing `dots-three` on result rows, `CineFocusRing` on every
control, key registry, Cinematic toast (no SnackBar), pull to reprint (`custom_refresh_indicator`, 96 px
arm, `refresh.arm`), highlight sweep (200 ms per band, 60 ms apart), live countdowns (search SLOW DOWN
notice, catalogue deck), tablet source table head aligned to the row columns, `SetHeading` letter
reveal on the Sources and catalogue mastheads, deck health count after the 18+ gate, poster rail and
wall heights that no longer overflow with real fonts. The lane now uses the mobile/03 limiter.

## Deviations (each with its reason)

- Stand-ins, marked `TODO(mobile/04|05|06|08|12)`: the primitives of mobile/04, 05, 06, 08 and 12 are not
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
