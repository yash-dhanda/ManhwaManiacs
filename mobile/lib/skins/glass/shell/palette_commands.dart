import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/server_capabilities_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_menu.dart';
import 'package:manhwamaniacs/skins/glass/shell/skin_switch_flow.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// One row of the command palette.
class PaletteItem {
  const PaletteItem({required this.id, required this.group, required this.title, this.subtitle, this.icon, this.run, this.keywords = ''});
  final String id;
  final String group;
  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Runs the item; the palette has already closed.
  final Future<void> Function(BuildContext context, WidgetRef ref)? run;
  final String keywords;
}

/// The palette's groups, in order.
const List<String> kPaletteGroups = ['Library', 'Sources', 'Go to', 'Actions', 'Skin'];

final Map<String, List<PaletteItem> Function()> _contexts = {};

/// A screen registers actions that only make sense there ("Download next 10 of the current series"). Returns the disposer.
VoidCallback registerPaletteContext(String key, List<PaletteItem> Function() items) {
  _contexts[key] = items;
  return () => _contexts.remove(key);
}

/// Pure: the character indices of [query] matched in [text] (a case-insensitive subsequence, preferring a contiguous run), or null.
List<int>? paletteMatch(String query, String text) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final t = text.toLowerCase();
  final i = t.indexOf(q);
  if (i >= 0) return [for (var k = 0; k < q.length; k++) i + k];
  final out = <int>[];
  var from = 0;
  for (final ch in q.split('')) {
    final j = t.indexOf(ch, from);
    if (j < 0) return null;
    out.add(j);
    from = j + 1;
  }
  return out;
}

/// Orders matches: prefix, then substring, then subsequence; ties by title length.
int paletteScore(String query, String text) {
  final q = query.trim().toLowerCase();
  final t = text.toLowerCase();
  if (q.isEmpty) return 0;
  if (t.startsWith(q)) return 0;
  if (t.contains(q)) return 1;
  return 2;
}

Future<void> continueMostRecent(BuildContext context, WidgetRef ref) async {
  final a = ref.read(glassAccessoryProvider).continueItem;
  if (a != null) {
    a.onOpen(Rect.zero);
    return;
  }
  final r = await ref.read(libraryRepositoryProvider).continueReading(limit: 1);
  if (!context.mounted || r.isErr || r.value.isEmpty) return;
  final i = r.value.first;
  final size = MediaQuery.sizeOf(context);
  final from = Rect.fromCenter(center: size.center(Offset.zero), width: 40, height: 60);
  String e(String s) => Uri.encodeComponent(s);
  unawaited(enterReader(context, ref, '/reader/${e(i.sourceId)}/${e(i.seriesKey)}/${e(i.chapterKey)}', fromRect: from));
}

/// Every destination, actions and the skin switch (glass 8.0.6), with capability gating (glass 8.0.8).
List<PaletteItem> paletteCommands(WidgetRef ref) {
  final caps = ref.read(serverCapabilitiesProvider).valueOrNull ?? const ServerCapabilities();
  final a11y = ref.read(glassInAppPrefsProvider);
  void go(String path) => ref.read(skinRouterProvider).go(path);
  PaletteItem nav(String id, String title, String path, {String kw = ''}) =>
      PaletteItem(id: 'go:$id', group: 'Go to', title: title, subtitle: path, keywords: kw, run: (c, r) async => go(path));
  final novel = ref.read(novelsEnabledProvider) && ref.read(contentModeControllerProvider) == ContentMode.novel;
  return [
    nav('home', 'Home', '/'),
    nav('library', 'Library', '/library'),
    nav('browse', 'Browse all', '/library/browse'),
    if (caps.onlineSources) nav('sources', 'Sources', '/sources'),
    nav('updates', 'Updates', '/updates'),
    if (caps.clientDownloads) nav('downloads', 'Downloads', '/downloads'),
    if (caps.collections) nav('collections', 'Collections', '/library/collections'),
    nav('history', 'History', '/library/history'),
    if (caps.bookmarks) nav('bookmarks', 'Bookmarks', '/library/bookmarks'),
    nav('stats', 'Stats', '/library/statistics'),
    nav('circle', 'Circle', '/circle'),
    nav('forYou', 'For you', '/library/recommendations'),
    if (caps.ocr && !novel) nav('dialogue', 'Dialogue search', '/ocr'),
    nav('profiles', 'Profiles', '/profiles/manage'),
    nav('settings', 'Settings', '/settings'),
    PaletteItem(id: 'act:ask', group: 'Actions', title: 'Ask for something to read', run: (c, r) async => go('/library/recommendations')),
    PaletteItem(id: 'act:settings', group: 'Actions', title: 'Open settings', run: (c, r) async => go('/settings')),
    PaletteItem(id: 'act:switch', group: 'Actions', title: 'Switch profile', run: (c, r) async => showProfileSwitcher(c, r, Rect.fromLTWH(MediaQuery.sizeOf(c).width / 2, 120, 1, 1))),
    if (ref.read(novelsEnabledProvider))
      PaletteItem(
        id: 'act:mode',
        group: 'Actions',
        title: 'Toggle content mode',
        run: (c, r) async => r.read(contentModeControllerProvider.notifier).setMode(r.read(contentModeControllerProvider) == ContentMode.manga ? ContentMode.novel : ContentMode.manga),
      ),
    if (caps.continueReading) const PaletteItem(id: 'act:continue', group: 'Actions', title: 'Continue reading', run: continueMostRecent),
    PaletteItem(
      id: 'act:check',
      group: 'Actions',
      title: 'Check for new chapters',
      run: (c, r) async {
        r.invalidate(newChaptersBannerProvider);
        r.invalidate(unreadNotificationCountProvider);
      },
    ),
    for (final list in _contexts.values) ...list(),
    PaletteItem(id: 'act:solid', group: 'Actions', title: 'Toggle solid glass', run: (c, r) async => r.read(glassInAppPrefsProvider.notifier).setSolidGlass(!a11y.solidGlass)),
    PaletteItem(id: 'act:legible', group: 'Actions', title: 'Legible text: ${a11y.hyperlegible ? 'off' : 'on'}', run: (c, r) async => r.read(glassInAppPrefsProvider.notifier).setHyperlegible(!a11y.hyperlegible)),
    PaletteItem(id: 'act:signout', group: 'Actions', title: 'Sign out', run: (c, r) async => r.read(authControllerProvider.notifier).logout()),
    PaletteItem(
      id: 'skin:cinematic',
      group: 'Skin',
      title: 'Skin: Cinematic (restarts the app)',
      run: (c, r) async => startSkinSwitch(c, r, sourceRect: Rect.fromLTWH(MediaQuery.sizeOf(c).width / 2 - 1, MediaQuery.sizeOf(c).height / 3, 2, 2)),
    ),
  ];
}
