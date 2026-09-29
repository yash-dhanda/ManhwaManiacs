# Mobile 06 report

Items 1.1 to 13 are done; screens stay pending. Test floor: 2725 passed, 3 failed before (mobile/11:
`feature_screen_test` title reveal, `target_spacing_test` x2); after: 2889 passed, the same 3 failed.
`flutter analyze`: No issues found.

## Deviations and decisions
- Iris out is an overlay (`CineShutter.irisOut`), not a route transition: Tonight is a branch root reached by `go`.
- No `runZonedGuarded`: `PlatformDispatcher.onError` covers it and zoning `main` warns about zone mismatch. Benign
  errors (`AppError`, Dio, socket, timeout) never raise the route-error notice; a widget build error is replaced in
  place by `CineBrokenPart` and does not raise it either.
- Shortcuts dispatch through a `Focus(onKeyEvent)` instead of `CallbackShortcuts`, because the binding needs the key
  event for `GSequence.consumes`. `HardwareKeyboard` handlers do not stop focus dispatch, hence the consumer list.
- `swipeable_page_route` 0.4.8: `isSwipeGesture` is the navigator's flag, so the page beneath sees it true (DESIGN
  says false); the current route is the one under the finger. Cut pages and the shells are zero-duration
  Cupertino/Material family routes so the page beneath a push paints its own outgoing move (delegated transitions).
- Predictive back commit/cancel run on `CineBackGesture`'s own 240 / 160 ms `settle` clock shared by both pages; the
  route controller restarts on commit, its 224 ms reverse ends the route.
- `prefetchChapterStart` takes a `read` callback (WidgetRef, Ref and container all fit), fetches the manifest through
  the repository and the first two pages through Dio at P1/P3 (only `/sources/...` URLs are limiter-gated).
- `cinematicScreens` is not empty: `feature` and `featureByFollow` (mobile/11) are registered. Pending screens sit in a
  `CineScaffold` (running head, back arrow).
- Stand-ins retired: match-cut page, overlay Column wipe and reader prefetch of mobile/05 and mobile/11, the series
  page's Material bottom sheets and cover Lightbox (now `CineSheetRoute` and `CineLightbox`), the certificate Dip.
- `CineDialog` gained `maxWidth`, `CineToastHost` gained `hidden`, `ShortcutEntry` gained `keys` (display only).
- `Skin` gained `scrollBehavior`.

## API for later steps
`cinematicScreens` (register a `GoRouterWidgetBuilder`, delete the id from `PENDING` in `router.dart`; the route name
becomes the bare id); `extra` keys `transition` (page|match|dip), `entry` (wipe|dip), `mode` (switch);
`cinePage`, `cineMatchCutPage`, `cineDipPage`, `cineCutPage`, `CineHero`, `CineSwipeSlide`, `ColumnWipePainter`,
`wipeTotalMs`, `enterReader(context, ReaderTarget, entry:)`, `ReaderEntry`, `ReaderTarget`, `ReaderPrefetch`,
`goSection`, `CineShutter.of(context).dip / irisClose / irisOut / irisPreview`, `applyCineRestingSystemUi`,
`cineEdgeWidth`, `CineModalBack` (priorities `CineBackPriority`), `HubShellScope`, `CineScaffold`, `CineScrollToTop`,
`focusSearchSignalProvider`, `cineSectionEpochProvider`, `splashDoneProvider`, `showRatingCard` / `hideRatingCard`,
`RegisteredShortcuts` (groups in `cinematicShortcutGroupOrder`), `backOnlineEpochProvider`, `outboxSyncProvider`,
`unreadNotificationCountProvider`, `serverCapabilitiesProvider`, `notAvailableKind`, `CineNotAvailableNotice`.

## Proof
`docs/redesign/proof/mobile-06/`: `shell[-grid]-{phone,tablet,landscape}.png`, `shell-frames[-grid]-*.png`,
`splash-reduced-*`, `wipe-reduced-*`, `frame-{tonight,library,discover,downloads,index}-phone.png`. Critique: the
first capture showed underlined running title and tab labels (no `Material` ancestor): fixed by a `Material` in the
shell and scaffold. Web twin `web-06` captures not compared (not present).
