# mobile/33 plan: Glass series detail and book page

Lane M33, branch `redesign/M33`. Glass screen preconditions (mobile/32) are waived by the lane override; foundation steps
mobile/25 to 29 and the Cinematic feature page (mobile/11, 19) are integrated.

1. A: pure helpers with tests first (`detent_from_throw`, `collapse`, `genre_link`, `toc_window`, `chapter_extents`); move the
   hero-tilt mapping to `skins/glass/glass/tilt.dart` in a no-pixel commit. A5 and A7 already exist in the shared data layer
   (`chapter_selection.dart` planners; enrichment, AI tags and feedback, tiered source search, repoint with `keep_old`).
2. Data and states: `series_data.dart` (one page model for both identities, resume, Mark read / Mark unread through the batch and
   delete calls only), `series_states.dart` (skeleton, lenses, chapter-list notices).
3. Presentation: `feature_screen.dart` (both routes), `series_detail.dart` (phone sheet, tablet window, 960 px desktop window
   with the 320 px left column at `max(24, 120 − offset)`, full page with the back chevron), router rows out of `PENDING`, the
   opening detent from the throw velocity.
4. Band and header, actions and the ⋯ menu, tags and move-source sheets, the download card, Previously on, More like this.
5. Chapters: pinned header, go-to, `SliverVariedExtentList` rows, swipe rows, row menu, select mode, toolbar, run summary.
6. Book page: plate, Literata front matter, windowed Contents (400 rows), `GlassBookOpenPage` on the `novel` route.
7. Tests (`test/skins/glass/series/`), the harness (`mobile_33_series_shots_test.dart`), captures, report.
