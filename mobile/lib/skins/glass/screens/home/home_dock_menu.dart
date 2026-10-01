import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/features/home/utils/offline_edition.dart' show clearLastFeeds;
import 'package:manhwamaniacs/skins/glass/parts/recap/continue_series.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_chrome.dart' show homeMarkAllReadEntry;
import 'package:manhwamaniacs/skins/glass/shell/dock_menus.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart' show registerPurgeHolder;
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/stack_overview_host.dart';

/// The first Continue row that is not hidden, for "Continue last read" and the accessory.
HomeContinueItem? firstContinue(HomeFeedView? view, List<HiddenContinue> hidden) {
  final rows = view?.feed?.section(HomeSectionType.continueReading)?.items.whereType<HomeContinueItem>() ?? const <HomeContinueItem>[];
  for (final r in rows) {
    if (!hidden.any((h) => h.sourceId == r.row.sourceId && h.seriesKey == r.row.seriesKey && h.chapterKey == r.row.chapterKey)) return r;
  }
  return null;
}

/// Home's rows of the dock's long-press menu (glass 7.15): Mark all read and Continue last read (Updates is the stock row). Registered
/// once by the shell, so the menu works from every tab. Returns the disposer.
VoidCallback registerHomeDockMenu() => registerDockMenu(GlassTab.home, (ref) {
      final item = firstContinue(ref.read(homeFeedProvider).valueOrNull, ref.read(continueHiddenProvider));
      return [
        homeMarkAllReadEntry(ref),
        if (item != null)
          GlassMenuEntry(
            label: 'Continue last read',
            onSelected: () {
              final ctx = ref.read(glassNavigatorsProvider)?.root.currentContext;
              if (ctx == null) return;
              final size = MediaQuery.sizeOf(ctx);
              unawaited(continueSeries(ctx, ref, HomeContinueTarget.fromContinue(item), Rect.fromCenter(center: Offset(size.width / 2, size.height - 120), width: 88, height: 132)));
            },
          ),
      ];
    });

/// What Home needs from the shell, registered once by `GlassShell.initState`: its dock menu rows and its purge holder (a closing 18+ gate
/// deletes the cached home payload outright, glass 8.0.8 step 5). Returns the disposer.
VoidCallback registerHomeShellHooks() {
  final dock = registerHomeDockMenu();
  final purge = registerPurgeHolder('home', clearLastFeeds);
  return () {
    dock();
    purge();
  };
}
