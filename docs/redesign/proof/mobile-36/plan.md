# mobile/36 plan: Glass novel reader

Lane M36, worktree `/srv/manhwamaniacs/dev/wt/M36`, branch `redesign/M36`. One task per scope letter; each task ends in its own commit.

Preconditions found: `mobile/14` (controller, `paginateNovel`, `NovelParagraphLayout`, `speaker_slots.dart`), the four fonts, the Glass foundation (`mobile/25`–`29`) are in. `mobile/33` (book page, `GlassBookOpenPage`) and `mobile/35` (reader system UI helper, go-to popover, toast placement) are not in the ledger; both are Glass screen steps, waived by the lane rules. Their pieces this step needs are local stand-ins marked `TODO(mobile/35)` / `TODO(mobile/33)`, to be swapped when those land. `glass_reader_values.dart` is present (the `mobile/39` stand-in with `glassPageTinted`, `glassKeepAwake`); `autoNextChapter` is the reader record's shared field.

- **A. Data layer** (`features/novels`, no pixels). A1 `glass_novel_prefs.dart` (pure resolve: clamps, K25/K26 fallbacks, profile defaults `mm.novel-defaults`, Glass defaults, text-scale first open) + `glass_novel_prefs_provider.dart` (setBook / setProfile / resetBook through the existing record notifiers, which keep unknown fields). A2: `novel_pace.dart` (`mm.novel-pace`, wpm samples) already exists; use it, `ready` = 3 samples. A3: `isSceneBreak` already lives in `features/novels/utils/novel_book.dart`; nothing to move. A4: `NovelType` gains `faceStyle` and `dropCapSpec` (null = Cinematic path unchanged). A5: `NovelParagraphLayout.dropCapSplit`. TDD tests for all of it.
- **B. Route**: `novel` + alias in the Glass router with a book-scoped page key (seamless next keeps the page), out of `PENDING`; system UI stand-in; Nothing beneath; Android back order; semantics + announcement.
- **C. Papers**: `papers.dart` (token table, contrast, `oklabMix`), `paper_frame.dart` (`PaperScope`, Glass paper field top 30 %), chrome `Lb` and the 12 % ink tint with the 900 ms cross-fade.
- **D. Layout**: column width from the `0` advance; header; `GlassParagraph` (Text.rich + ordered decorations); drop cap in three selectable pieces; scene breaks; speaker bands; run chip; end matter + Next card; `GlassChapterEndPhysics` and the arm/lock machine; further-ahead toast; desktop panels.
- **E. Chrome**: materialise/dematerialise, hide rules, inert when hidden, top groups (one layer), bottom capsule, hairline, go-to popover, landscape, keep awake, top-centre slot.
- **F. Selection**: `SelectionArea` + `GlassSelectionMenu` (Copy, Bookmark this paragraph, Play from here, React, Recommend), press.lift listener, `GlassListenBridge`.
- **G. Paged**: `PageView` over `paginateNovel`, tap bands, Slide physics, Lift layer, Fade, pinch steps, line guide.
- **H. Aa sheet**: ordered rows; faces, steppers, switches, segmenteds, ambient, screen, paper orbs + ripple, reset, scope captions.
- **I. Contents**: sheet and left panel.
- **J. States**: loading, offline, error, empty, stale, saved copy, end of book, end of download, rate limited, unavailable.
- **K. Keys**: pure reducer + registration.
- **L. Budget**: registry walk in a widget test.
- Proof: harness captures, device checklist, report.
