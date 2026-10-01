# mobile/45 plan (working file)

Each check of the prompt as a task, with its command and pass condition. Results are in `qa.md`.

| Task | Command | Pass condition |
|---|---|---|
| A completeness and boundary | `flutter test test/skins/completeness_test.dart test/skins/import_boundary_test.dart` | no PENDING symbol; every ScreenId resolves; boundary failure line recorded |
| B rig and audit | `flutter test test/skins/glass/qa/glass_qa_test.dart` | 0 open violations on 35 screens x (390 iOS, 390 Android, 834 iOS) |
| C physics, contrast, worst cases | `glass_physics_test`, `glass_worst_cases_test`, `node design/build.mjs --check` | every 15.8 value; three cases hold |
| D calibration | harness group `mobile-45 calibration` | capture exists; refraction recorded as absent in flutter_tester |
| E screenshots | harness groups `screens`, `a11y`, `textscale`, `states`, `pairs` | files at every size; in-app switch equals OS path |
| F screen readers | `glass_screen_reader_test` | behaviours hold |
| G motion | `motion_names_test`, `glass_motion_test` | 116 names; planned settles; Reduce Motion column; frozen at rest |
| H signatures | `typed_headline_test`, `letter_reveal_test`, `glass_signature_test` | timelines and placements |
| I accessibility | `glass_focus_test`, `glass_textscale_test`, `glass_gestures_qa_test`, `glass_haptics_qa_test` | no overflow; focus pass; alternatives |
| J gate | `glass_gate_test` | checklist for both scenarios |
| K budget | `glass_budget_test` | counts within the table |
| L float | harness group `mobile-45 float` | five frames |
| M switch | `glass_switch_test` | both directions |
| N device checklist | owner | awaiting owner |
| O CI | integrator pushes | recorded in the report |
