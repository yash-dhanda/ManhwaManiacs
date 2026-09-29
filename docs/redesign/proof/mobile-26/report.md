# mobile/26 report

Captures are written by `mobile/test/screenshots/glass_primitives_shots_test.dart` (frost path; shader glass does not run under `flutter test`). Each gallery capture shows the top of its section (toolbar included) over the black, ambient and white grounds.

| Capture | Proves |
|---|---|
| `<section>-phone.png`, `<section>-tablet.png` (16 sections) | every primitive of B to Q with its states, on three grounds (acceptance 1, 8) |
| `<section>-solid-phone.png` | Solid glass recipes, primary `#5B4AD1`, no caustic or sweep |
| `<section>-contrast-phone.png` | Increase contrast (3 px focus ring, dim range) |
| `buttons-phone.png` | press forced states, the lit primary, loading dots, error |
| `poster-lift-phone.png` | poster at 450 ms of a press: lift 1.06, deeper shadow |
| `hold-aborted-phone.png` | aborted hold with the helper line |
| `reveals-typing-200ms-phone.png` | the typed greeting at 200 ms |
| `reveals-rails-running-phone.png` | two letter reveals running, the third waiting |

Tests: `mobile/test/skins/glass/primitives/` (hold, poster_throw, wave, segmented_math, rail_columns, poster_columns, reveal_slots, letter_reveal, typed_headline, glass_button, primitives_behaviour, primitives_a11y, primitives_budget, primitives_reduced incl. solid): 117 pass.

Differences from the spec worth knowing: `glass/DESIGN.md` was not contradicted anywhere. No web-26 captures existed to compare against.
