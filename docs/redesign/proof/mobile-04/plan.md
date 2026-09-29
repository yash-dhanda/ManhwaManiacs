# mobile/04 plan

Lane L01, branch redesign/L01, worktree /srv/manhwamaniacs/dev/wt/L01. Floor: `flutter test` 2160 passing before this step.

Order (each step: analyze, its tests, commit):

1. Skin-neutral core: contrast, key labels, snapped cover widths, a11y prefs (A6-A8, D7 helper).
2. Foundations: stock scopes, focus ring, hit sizes, type helpers, scroll behaviour, ambient scope (A1-A5, A9, A10).
3. Motion recorder, debug switches, CineMotion, timings panel, Diagnostics rows (B1-B7).
4. SetHeading and TypedHeadline with their tests (C1-C2).
5. Tint roles and contrast loops, duotone, grain shader (D16-D18).
6. Buttons, icon buttons, tooltips, fields, search (D1-D4).
7. Slug lines, cards, posters, rails (D5-D8).
8. Galleys, progress, badges, avatars, keycaps, masthead, layout (D9-D15).
9. Gallery and widget checks (E1, E3).
10. Harness group `mobile-04`, proof screenshots, device checklist (E2).

Each pure function (tint maths, folio labels, stagger maths, typed clock, rail maths, key labels, snapped widths, recorder formatting, prefs) gets its Dart test first or with it. Helper files added beyond the layout list: `feedback.dart` (haptic + cue helper that never throws), `primitives/glyphs.dart` (Phosphor codepoints no icon role names). Both are skin-internal.
