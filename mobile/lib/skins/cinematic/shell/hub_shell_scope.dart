import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Exposes the nested Library `StatefulNavigationShell` to the hub: `HubShellScope.of(context)
/// .goBranch(i)` and `.currentIndex` (0 SHELF, 1 UPDATES, 2 COLLECTIONS, 3 HISTORY, 4 BOOKMARKS).
/// The five tabs keep go_router's default indexed stack, so each keeps its own navigator and
/// scroll position; switching replaces the route and none shows a back arrow. The visible hub
/// (masthead, contents-tab row, swipe between tabs) is mobile/09's `LibraryHub`.
class HubShellScope extends InheritedWidget {
  const HubShellScope({super.key, required this.shell, required super.child});
  final StatefulNavigationShell shell;

  static HubShellScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<HubShellScope>();

  static StatefulNavigationShell of(BuildContext context) {
    final s = maybeOf(context);
    assert(s != null, 'no HubShellScope above this context');
    return s!.shell;
  }

  int get currentIndex => shell.currentIndex;

  @override
  bool updateShouldNotify(HubShellScope o) => o.shell.currentIndex != shell.currentIndex;
}
