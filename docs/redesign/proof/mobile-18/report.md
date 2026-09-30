# mobile/18 report

Lane L09, branch redesign/L09, not pushed. Proof: 91 screenshots in this folder (contents, search, every section on phone, tablet and tablet-wide, pushed pages, states, edition picker, Stop the press at 100/300/470 ms, toasts).

Deviations and stand-ins
- mobile/12-15 are not integrated: the manga, novel and listen records (`mm.reader-settings`, `mm.novel-settings`, `mm.listen-settings`) are created here under the prompt's exact key and field names (`TODO(mobile/12|14|15)`); the voice list is a browse stand-in without `Hear`.
- `mm.recap` default is the 7-day Glass 15.6 value (supersedes 14).
- Guided fixed hold is a slider (2 to 10 s), not a stepper (the stepper is integer-only).
- Preview frames come from test/fixtures/home/ready.json (`design/previews/demo-feed.json` does not exist); 36 frames, 1.5 MB after 256-colour quantising (3.3 MB raw; RELEASE.md has the command).
- Shared primitives touched: CineTextField (one-line fields carry their air inside, 48 px semantics), CineBannerStrip (stacks long actions), CineSearchField (`onArrowUp`), SideStoreCard (URL semantics).
- `mature_invalidators_test` fails independent of this step (backend service list drift).
