# mobile/24 plan

Working file. Each row: task, command (from `mobile/`, through `/srv/manhwamaniacs/dev/heavy.sh mobile`), pass condition.

| # | Task | Command | Pass |
|---|---|---|---|
| A1 | Delete the Cinematic `PENDING` map | `flutter analyze lib/skins test/skins` | No issues |
| A2 | Strict completeness | `flutter test test/skins/completeness_test.dart` | 3 tests pass |
| A3 | Boundary proof | temporary import of `skins/glass/glass_skin.dart` in `tonight_screen.dart`, `flutter test test/skins/import_boundary_test.dart`, revert | failure line copied |
| B | QA harness | `flutter test test/skins/cinematic/qa/cinematic_qa_test.dart` (`MM_WRITE_QA=1` writes `audit/`) | 280 pass |
| B4 | Keyboard focus | `flutter test test/skins/cinematic/qa/cinematic_focus_test.dart` | 35 pass, ring findings listed |
| C1 | Contrast rows | `flutter test test/skins/cinematic/tint_test.dart` | pass |
| C4 | Increase Contrast | `flutter test test/skins/cinematic/qa/cinematic_increase_contrast_test.dart` | 3 pass |
| C5 | Screen reader | `cinematic_screen_reader_test.dart` and the module tests named in `qa.md` | pass |
| C6 | Text scale matrix | `MM_QA_MATRIX=1 flutter test test/skins/cinematic/qa/cinematic_text_scale_test.dart` | 630 pass |
| C11 | Destructive confirms | `flutter test test/skins/cinematic/qa/cinematic_confirm_arm_test.dart` | pass |
| D | Reduced motion | `flutter test test/skins/cinematic/qa/cinematic_reduced_motion_test.dart` | 74 pass |
| E | Screenshots | `MM_PROOF_DIR=../docs/redesign/proof/mobile-24/{screens,states,a11y} flutter test test/screenshots/cinematic_qa_shots_test.dart --plain-name "mobile-24 <group>"` | files written |
| F | Signature animations | `typed_headline_test.dart`, `set_heading_test.dart` | pass |
| G | Performance guards | `cinematic_perf_guards_test.dart` | pass |
| H | CI | not run: this lane never pushes; the integrator pushes | see `qa.md` |
| I | Audio probe and device pass | `skin_audio.dart`, Diagnostics row, `device-pass.md` | written |
| J | Fixes and `qa.md` | one commit per fix | `qa.md` written |
