# Mobile 06 plan

Built by one implementer with the parts in dependency order; every step ends with analyze and its tests.

1. Skin-neutral foundations: shortcut registry, fuzzy ranker, not-available codes, fatal-error channel,
   unread count, server capabilities, offline-edition controller (items 1.1 to 1.7).
2. Pure logic first (tests before UI): `nav_map`, `router_gate`, `wipe_geometry`, `g_sequence`,
   `splash_timeline`, `back_order`, `system_bars`.
3. Transitions: parameters read from the sources before writing.
   - `swipeable_page_route` 0.4.8: `SwipeablePage(canSwipe, canOnlySwipeFromEdge, backGestureDetectionWidth,
     transitionDuration, reverseTransitionDuration, transitionBuilder(context, animation, secondaryAnimation,
     isSwipeGesture, child))`; `dragEnd` uses `Curves.fastLinearToSlowEaseIn`, commit past 0.5 or 1 width/s,
     forward animation at most 300 ms; `isSwipeGesture` is `route.popGestureInProgress`, which is the
     NAVIGATOR's flag, so the page beneath sees it true too (the current route is the one under the finger).
   - Flutter's private predictive-back detector (`material/predictive_back_page_transitions_builder.dart`):
     copied as `_CineBackDetector` (start returns false for `isButtonEvent` or when `!(route.isCurrent &&
     route.popGestureEnabled)`, forwards `1 - progress`).
   - go_router 14.8.1: `StatefulShellRoute.indexedStack`, `StatefulShellBranch.defaultRoute` is the first
     descendant `GoRoute` (so the nested Library hub gives branch 1 its `/library` initial location).
   - Flutter's delegated transitions: a page beneath paints its own outgoing move only when it is in the
     same route family as the page above (Material or Cupertino), so every route is a `SwipeablePageRoute`
     on iOS and a Material route on Android, Cut pages included.
4. Router, gate, branches, aliases, hub shell scope; shell, thumb index, running head, scaffold.
5. Reader route page (Column wipe, Dip), shutter and Iris, navigation helpers, prefetch.
6. Global keys, `g` sequence, keyboard sheet, command palette; stop-press banner, first-run note, rating
   slot, not-available notice.
7. Press start splash; status screens and error hooks.
8. Stand-ins of earlier steps replaced: the match-cut page, the reader-entry overlay wipe, the reader prefetch
   (all `TODO(mobile/06)`), and the feature pages' callers moved to `enterReader` / `ReaderTarget`.
9. Gallery `shell` section, harness group `mobile-06`, proof, device checklist, report.
