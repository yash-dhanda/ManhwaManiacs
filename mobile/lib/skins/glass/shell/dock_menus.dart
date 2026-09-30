import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/server_capabilities_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show moodColour;
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/shell/profile_menu.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';

typedef DockMenuBuilder = List<GlassMenuEntry> Function(WidgetRef ref);

/// The long-press menus of the dock's tabs (glass 7.15). Later steps add their rows with [registerDockMenu] (`mobile/31` registers
/// Home's items); each menu starts with a non-interactive header naming the tab.
abstract final class GlassDockMenus {
  static final Map<GlassTab, List<DockMenuBuilder>> _extra = {for (final t in GlassTab.values) t: []};
}

/// Adds rows to a tab's long-press menu. Returns the disposer.
VoidCallback registerDockMenu(GlassTab tab, DockMenuBuilder build) {
  GlassDockMenus._extra[tab]!.add(build);
  return () => GlassDockMenus._extra[tab]!.remove(build);
}

String glassTabName(GlassTab t) => switch (t) {
      GlassTab.home => 'Home',
      GlassTab.library => 'Library',
      GlassTab.sources => 'Sources',
      GlassTab.you => 'You',
    };

/// The rows of [tab]'s menu. [anchor] is the tab's global rect (the profile switcher flies its orb from there).
List<GlassMenuEntry> dockMenuEntries(GlassTab tab, WidgetRef ref, BuildContext context, Rect anchor) {
  void go(String path) => ref.read(skinRouterProvider).go(path);
  final caps = ref.read(serverCapabilitiesProvider).valueOrNull ?? const ServerCapabilities();
  final rows = <GlassMenuEntry>[];
  switch (tab) {
    case GlassTab.home:
      rows.add(GlassMenuEntry(label: 'Updates', onSelected: () => go('/updates')));
    case GlassTab.library:
      rows.addAll([
        GlassMenuEntry(label: 'Shelf', onSelected: () => go('/library')),
        if (caps.collections) GlassMenuEntry(label: 'Collections', onSelected: () => go('/library/collections')),
        GlassMenuEntry(label: 'History', onSelected: () => go('/library/history')),
        if (caps.bookmarks) GlassMenuEntry(label: 'Bookmarks', onSelected: () => go('/library/bookmarks')),
        if (caps.clientDownloads) GlassMenuEntry(label: 'Downloads', onSelected: () => go('/downloads')),
      ]);
      if (caps.collections) {
        final cols = ref.read(collectionsProvider).valueOrNull ?? const [];
        for (final c in cols.take(5)) {
          rows.add(GlassMenuEntry(label: c.name, separatorBefore: c == cols.first, onSelected: () => go('/library/collections/${c.id}')));
        }
      }
    case GlassTab.sources:
      if (caps.onlineSources) {
        for (final p in (ref.read(sourcePinsProvider).valueOrNull?.pins ?? const []).take(8)) {
          rows.add(GlassMenuEntry(label: p.name, onSelected: () => go('/sources/${Uri.encodeComponent(p.sourceId)}')));
        }
      }
    case GlassTab.you:
      final active = ref.read(activeProfileProvider);
      final others = [for (final p in ref.read(profilesProvider).valueOrNull ?? const <Profile>[]) if (p.id != active?.id) p];
      for (final p in others) {
        rows.add(
          GlassMenuEntry(
            label: p.name,
            leading: GlassProfileOrb(preset: avatarPresetFor(p.avatarKey), size: 24, mood: moodColour(p.mood)),
            onSelected: () => switchProfileWithHandoff(context, ref, p, from: anchor),
          ),
        );
      }
  }
  for (final b in GlassDockMenus._extra[tab]!) {
    rows.addAll(b(ref));
  }
  return [GlassMenuEntry(label: glassTabName(tab), enabled: false), ...rows];
}

/// Navigates without importing the router: used by menus that only have a `BuildContext`.
void glassGo(BuildContext context, String path) => GoRouter.of(context).go(path);
