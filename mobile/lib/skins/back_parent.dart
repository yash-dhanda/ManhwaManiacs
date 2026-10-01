import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Where Back goes from [location] when nothing is beneath it (a deep link, a `go`, a notification,
/// the skin-switch restart's return route): the logical parent, or null on a tab or dock root and
/// on the entry screens (setup, sign in, the profile picker, onboarding).
///
/// The two skins share every parent except where their tabs differ: Cinematic's Discover owns
/// Sources, Dialogue and Picks and its Library hub owns Updates; Glass's Sources is a tab, Home owns
/// Updates and Picks, and Search is an overlay over Home.
String? backParentOf(String location, {required bool glass}) {
  final s = [for (final x in Uri.parse(location).pathSegments) if (x.isNotEmpty) x];
  String feature(String source, String series) => '/sources/$source/series/$series';
  if (s.isEmpty) return null;
  final n = s.length;
  switch (s[0]) {
    case 'register':
      return '/login';
    case 'search':
      return glass ? '/' : null;
    case 'updates':
      return glass ? '/' : null;
    case 'ocr':
      return glass ? '/sources' : '/search';
    case 'circle':
      return n == 1 ? '/more' : '/circle';
    case 'settings':
      return n == 1 ? '/more' : '/settings';
    case 'admin':
      return '/more';
    case 'profiles':
      if (n == 1) return null;
      return s[1] == 'manage' ? '/more' : '/profiles/manage';
    case 'recap':
    case 'read-all':
      return n >= 3 ? feature(s[1], s[2]) : null;
    case 'reader':
      return n >= 3 ? feature(s[1], s[2]) : '/library';
    case 'novels':
      final o = s.length > 1 && s[1] == 'read' ? 1 : 0;
      return n >= 3 + o ? feature(s[1 + o], s[2 + o]) : null;
    case 'sources':
      if (n == 1) return glass ? null : '/search';
      if (n == 2) return '/sources';
      if (n <= 4) return '/sources/${s[1]}';
      return feature(s[1], s[3]); // .../chapters/:c/read
    case 'collections':
      return n == 1 ? null : '/library/collections';
    case 'library':
      if (n == 1) return null;
      switch (s[1]) {
        case 'browse':
        case 'history':
        case 'bookmarks':
          return null;
        case 'collections':
          return n == 2 ? null : '/library/collections';
        case 'recommendations':
          return glass ? '/' : '/search';
        case 'statistics':
          return n == 2 ? '/more' : '/library/statistics';
        case 'read':
          return n >= 4 ? feature(s[2], s[3]) : '/library';
      }
      return '/library'; // `/library/:followedId`
  }
  return null;
}

/// The location of the page [context] sits in, else the router's.
String skinLocationOf(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.toString();
  } catch (_) {
    final cfg = GoRouter.maybeOf(context)?.routerDelegate.currentConfiguration;
    return cfg == null || cfg.isEmpty ? '/' : cfg.uri.toString();
  }
}

/// A visible Back control's tap: pop when the page's navigator has something beneath, else go to
/// [backParentOf] (Home when the location has no parent), so Back is never a dead end.
void skinBack(BuildContext context, {required bool glass, String? location}) {
  final nav = Navigator.maybeOf(context);
  if (nav != null && nav.canPop()) {
    nav.maybePop();
    return;
  }
  GoRouter.maybeOf(context)?.go(backParentOf(location ?? skinLocationOf(context), glass: glass) ?? '/');
}

/// Android back on a page with nothing beneath it on the root navigator (a deep link, the
/// skin-switch return route): goes to [backParentOf] instead of leaving the app. Branch pages are
/// left to the shell's own back handler, which sees the same parent.
class SkinBackFallback extends StatelessWidget {
  const SkinBackFallback({super.key, required this.glass, required this.child});
  final bool glass;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final nav = Navigator.maybeOf(context);
    if (route == null || nav == null || route.canPop || nav != Navigator.maybeOf(context, rootNavigator: true)) return child;
    final parent = backParentOf(skinLocationOf(context), glass: glass);
    if (parent == null) return child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) GoRouter.maybeOf(context)?.go(parent);
      },
      child: child,
    );
  }
}
