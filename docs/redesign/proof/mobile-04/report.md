# mobile/04 report

Scope A1-E3 delivered. Proof: 90 harness captures here (`<section>[-grid|-reduced|-scale2|-mid400]-<phone|tablet>.png`), plan.md, device-checklist.md.

Deviations and open issues:
- Helper files beyond the layout list: `cinematic/feedback.dart`, `primitives/glyphs.dart` (Phosphor codepoints no icon role names).
- `grain.frag` takes a third uniform `uOpacity` folded into alpha (Paint alpha on runtime shaders is not guaranteed on Impeller). The shader loads under `flutter test` 3.44.6.
- `CineSearchVariant.indexField` (an enum member named `index` clashes with `Enum.index`).
- Slate: Space on a focused button inside the slate activates the button (its own shortcut wins); Esc closes.
- Wash grounds: spot text is tested on `spot.wash`, proof text on `proof.wash` (proof on spot.wash is 4.27:1 and never used).
- Credits and masthead rule on tablets: two columns from 600 px unless text scale >= 1.3; the masthead rule is the same 3 px rule at every width.
- `dart fix` wanted a `fake_async` dev dependency; not committed.
- Impeccable and taste-skill critiques were not run; captures were checked against cinematic/DESIGN.md by eye (radius 0, no shadows, no ripples).
- Web-twin comparison skipped (web-04 captures not in this worktree).
