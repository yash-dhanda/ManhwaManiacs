import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/auth/providers/offline_edition_controller.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/shell.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/stop_press_banner.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/thumb_index.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../../../screenshots/support/skin_shots.dart';
import '../tonight/tonight_test_support.dart';

/// The whole app (SkinApp under AppRestart, as main.dart builds it) at an iPhone size: every
/// thumb-index tab must change the screen, not only the router. On iOS the shell's page is a
/// SwipeablePage updated in place, and its route used to keep its first child.
Future<void> _pumpApp(WidgetTester t, {required bool banner, required bool restart}) async {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  t.view.padding = const FakeViewPadding(top: 141, bottom: 102);
  addTearDown(t.view.reset);
  final root = await skinShotRootOverrides();
  await t.pumpWidget(AppRestart(
    builder: () => ProviderScope(
      overrides: [
        ...root,
        skinIdProvider.overrideWithValue(SkinId.cinematic),
        outboxSyncProvider.overrideWith((ref) => null),
        homeFeedProvider.overrideWith(() => FakeHomeFeed(viewOf(loadFeed('ready')))),
        clockProvider.overrideWithValue(() => kTonightNow),
        newChaptersBannerProvider.overrideWith((ref) async => banner ? (chapters: 6, series: 6, maxId: 9) : null),
      ],
      child: const SkinApp(),
    ),
  ),);
  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
  }

  await settle();
  if (restart) {
    // The boot restart path: a fresh ProviderScope and router under the same AppRestart.
    t.state<AppRestartState>(find.byType(AppRestart)).restart();
    await settle();
  }
}

void main() {
  for (final banner in [false, true]) {
    for (final restart in [false, true]) {
      testWidgets('every tab changes the screen (banner: $banner, after restart: $restart)', (t) async {
        await _pumpApp(t, banner: banner, restart: restart);
        expect(find.byType(CineStopPressBanner), banner ? findsOneWidget : findsNothing);
        const labels = ['LIBRARY', 'DISCOVER', 'DOWNLOADS', 'INDEX', 'TONIGHT'];
        const paths = ['/library', '/search', '/downloads', '/more', '/'];
        for (var i = 0; i < labels.length; i++) {
          await t.tap(find.descendant(of: find.byType(CineThumbIndex), matching: find.text(labels[i])));
          for (var k = 0; k < 4; k++) {
            await t.pump(const Duration(milliseconds: 300));
          }
          final shell = t.widget<CineShell>(find.byType(CineShell));
          expect(Uri.parse(shell.location).path, paths[i], reason: labels[i]);
          expect(t.widget<CineThumbIndex>(find.byType(CineThumbIndex)).active, (i + 1) % 5, reason: labels[i]);
        }
        await drainCacheTimers(t);
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS),);
    }
  }
}
