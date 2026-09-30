@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reveal_slots.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/ai_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_data.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/poster_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight.dart';
import 'package:sensors_plus/sensors_plus.dart' show AccelerometerEvent;

import '../../skins/glass/home/home_rig.dart';
import '../../skins/glass/primitives/support.dart' show pumpFor;
import '../../support/test_overrides.dart' show contentModeOverrides;
import '../glass_shell_shots_support.dart';
import '../support/shot_covers.dart';
import '../support/shot_harness.dart';
import '../support/shot_network.dart';
import '../support/skin_shots.dart';

/// The mobile/31 proof captures (glass 8.8, 9.1.1): Glass Home on the `GET /home` fixtures and painted demo covers. Written only when
/// `MM_PROOF_DIR` is set; otherwise rasterised and discarded.

const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
const _phoneFull = SkinShotSize('phone', Size(390, 3600), 1.5, EdgeInsets.only(top: 47, bottom: 34));
final _tablet = kSkinShotSizes[1];

Set<String> _coverPaths() {
  final paths = <String>{};
  void walk(Object? v) {
    if (v is Map) {
      for (final e in v.entries) {
        if (e.key == 'cover_url' && e.value is String) paths.add(Uri.parse(e.value as String).path);
        walk(e.value);
      }
    } else if (v is List) {
      v.forEach(walk);
    }
  }

  for (final f in Directory('test/fixtures/home').listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
    walk(jsonDecode(f.readAsStringSync()));
  }
  return paths;
}

Future<void> _loadCovers(WidgetTester t) async {
  final out = <String, Uint8List>{};
  await t.runAsync(() async {
    var i = 0;
    for (final p in _coverPaths()) {
      out[p] = await ShotCoverArt(title: p.split('/').reversed.skip(1).first.replaceAll('-', ' '), seed: i++).toPng(width: 240, height: 360);
    }
  });
  addShotCovers(out);
}

Future<ShotSession> _open(
  WidgetTester t,
  SkinShotSize size,
  FakeHomeRepo repo, {
  DateTime? now,
  int unread = 0,
  List<Override> extra = const [],
  bool settle = true,
  bool libraryDown = false,
}) async {
  await _loadCovers(t);
  final s = await openShell(
    t,
    size,
    settle: false,
    extra: [...homeOverrides(repo, now: now, unread: unread, libraryDown: libraryDown), ...extra],
  );
  if (settle) {
    for (var i = 0; i < 6; i++) {
      await s.settle(600);
    }
    await pumpUntilCoversLoad(t, rounds: 25);
  }
  return s;
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(minutes: 11));
}

class _FailingPins extends SourcePinsNotifier {
  @override
  Future<SourcePinsState> build() async => throw const NetworkError(message: 'down');
}

class _Sharing extends SharingNotifier {
  @override
  Future<Sharing> build(int arg) async => const Sharing(activity: true);
}

DownloadedSeriesGroup _saved() => DownloadedSeriesGroup(
      sourceId: 'shelf',
      seriesKey: 'the-lantern-courier',
      seriesTitle: 'The Lantern Courier',
      chapters: [
        SavedChapter(
          rowId: 1,
          scopeId: 'u1p1',
          sourceId: 'shelf',
          seriesKey: 'the-lantern-courier',
          chapterKey: 'c142',
          chapterNumber: 142,
          title: null,
          seriesTitle: 'The Lantern Courier',
          pageCount: 40,
          bytes: 100,
          state: DownloadChapterState.complete,
          pinned: false,
          readAt: null,
          createdAt: DateTime(2026, 9),
          retryCount: 0,
          error: null,
        ),
      ],
    );

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await pumpFor(t, 900);
}

void main() {
  setUpAll(loadAppFonts);
  setUp(glassRevealSlots.reset);
  setUpAll(setUpShotCoverCache);

  testWidgets('home: phone, tablet, desktop and the whole scroll', (t) async {
    var s = await _open(t, _phone, homeRepoOf('ready'), unread: 3);
    await s.snap('home', _phone);
    s = await _open(t, _tablet, homeRepoOf('ready'), unread: 3);
    await s.snap('home', _tablet);
    s = await _open(t, kSkinShotDesktop, homeRepoOf('ready'), unread: 3);
    await s.snap('home', kSkinShotDesktop);
    s = await _open(t, _phoneFull, homeRepoOf('ready'), unread: 3);
    await s.settle(1200);
    await s.snap('home-full', _phoneFull);
    await _end(t);
  });

  testWidgets('home: the signature moment, typing, drop and ripple', (t) async {
    final s = await _open(t, _phone, homeRepoOf('ready'), settle: false);
    await t.pump();
    await pumpFor(t, 200);
    await s.snap('home-typing-200ms', _phone);
    await pumpFor(t, 3000);
    final drop = await _open(t, _phone, homeRepoOf('ready'), settle: false);
    for (var i = 0; i < 40 && find.byType(Spotlight).evaluate().isEmpty; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    await pumpFor(t, 140);
    await drop.snap('home-spotlight-drop', _phone);
    await pumpFor(t, 3000);
    await _end(t);
  });

  testWidgets('home: light follows the story, tilt and the special cards', (t) async {
    var s = await _open(t, _phone, homeRepoOf('ready'));
    t.state<SpotlightState>(find.byType(Spotlight)).go(1);
    await pumpFor(t, 1400);
    await s.snap('home-spotlight-page2', _phone);
    s = await _open(t, kSkinShotDesktop, homeRepoOf('ready'));
    t.state<SpotlightState>(find.byType(Spotlight)).go(1);
    await pumpFor(t, 1400);
    await s.snap('home-spotlight-page2', kSkinShotDesktop);

    final sensor = StreamController<AccelerometerEvent>.broadcast();
    addTearDown(sensor.close);
    s = await _open(t, _phone, homeRepoOf('ready'), extra: [gravitySensorProvider.overrideWithValue(() => sensor.stream)]);
    sensor.add(AccelerometerEvent(0, 0, 9.8, DateTime(2026)));
    await pumpFor(t, 100);
    sensor.add(AccelerometerEvent(0.3 * 9.80665, 0, 9.4, DateTime(2026)));
    await pumpFor(t, 600);
    await s.snap('home-spotlight-tilt', _phone);

    s = await _open(t, _phone, homeRepoOf('caught-up'));
    await s.snap('home-spotlight-caught-up', _phone);
    s = await _open(t, _phone, homeRepoOf('ready'), now: DateTime(2026, 12, 3, 12));
    final state = t.state<SpotlightState>(find.byType(Spotlight));
    state.go(state.widget.specs.length - 1);
    await pumpFor(t, 1400);
    await s.snap('home-spotlight-wrapped', _phone);
    s = await _open(t, _phone, homeRepoOf('circle'));
    final st2 = t.state<SpotlightState>(find.byType(Spotlight));
    final li = st2.widget.specs.indexWhere((e) => e.from != null);
    if (li >= 0) st2.go(li);
    await pumpFor(t, 1400);
    await s.snap('home-spotlight-letter', _phone);
    await _end(t);
  });

  testWidgets('home: scrolled accessory, AI states, throw, orbs, refresh, bell, menu', (t) async {
    var s = await _open(t, _phone, homeRepoOf('ready'));
    await t.fling(find.byType(Scrollable).first, const Offset(0, -900), 2500);
    await pumpFor(t, 1400);
    await s.snap('home-scrolled-accessory', _phone);

    s = await _open(t, _phone, homeRepoOf('ready'), extra: [homeAiThinkingProvider.overrideWith((ref) => true)]);
    await _scrollTo(t, find.byType(HomeAiRail).first);
    await s.snap('home-ai-thinking', _phone);

    s = await _open(t, _phone, homeRepoOf('ai-unavailable'));
    await _scrollTo(t, find.byWidgetPredicate((w) => w is HomeAiRail && w.rail.id == 'picked'));
    await s.snap('home-ai-unavailable', _phone);

    s = await _open(t, _phone, homeRepoOf('stale'), now: DateTime(2026, 10, 4, 12));
    await _scrollTo(t, find.byWidgetPredicate((w) => w is HomeAiRail && w.rail.id == 'picked'));
    await s.snap('home-ai-stale', _phone);

    s = await _open(t, _phone, homeRepoOf('ready'));
    await _scrollTo(t, find.byType(HomeAiRail).first);
    final poster = find.descendant(of: find.byType(AiPickCard).first, matching: find.byType(GlassPoster)).first;
    final g = await t.startGesture(t.getCenter(poster));
    await pumpFor(t, 520);
    for (var i = 1; i <= 4; i++) {
      await g.moveBy(const Offset(40, 4), timeStamp: Duration(milliseconds: 520 + 12 * i));
      await t.pump(const Duration(milliseconds: 12));
    }
    await s.snap('home-not-interested-throw', _phone);
    await g.up(timeStamp: const Duration(milliseconds: 620));
    await pumpFor(t, 600);

    s = await _open(t, _phone, homeRepoOf('ready'), extra: [
      sharingProvider.overrideWith(_Sharing.new),
      recipientsProvider.overrideWith((ref, key) async => const [
            CircleMember(profileId: 2, name: 'Mira', avatarKey: 'rose', canReceive: true),
            CircleMember(profileId: 3, name: 'Noor', avatarKey: 'amber', canReceive: true),
            CircleMember(profileId: 4, name: 'Kai', avatarKey: 'steel', canReceive: true),
          ],),
    ],);
    await _scrollTo(t, find.byType(HomePosterRail).first);
    final p2 = find.descendant(of: find.byType(HomePosterRail).first, matching: find.byType(GlassPoster)).first;
    final g2 = await t.startGesture(t.getCenter(p2));
    await pumpFor(t, 800);
    await s.snap('home-friend-orbs', _phone);
    await g2.up();
    await pumpFor(t, 600);

    s = await _open(t, _phone, homeRepoOf('ready'));
    final g3 = await t.startGesture(const Offset(200, 300));
    for (var i = 1; i <= 8; i++) {
      await g3.moveBy(const Offset(0, 18), timeStamp: Duration(milliseconds: 16 * i));
      await t.pump(const Duration(milliseconds: 16));
    }
    await pumpFor(t, 120);
    await s.snap('home-pull-refresh', _phone);
    await g3.up(timeStamp: const Duration(milliseconds: 400));
    await pumpFor(t, 2500);

    final unread = MutableUnread()..initial = 2;
    s = await _open(t, _phone, homeRepoOf('ready'), extra: [unreadNotificationCountProvider.overrideWith(() => unread)]);
    unread.set(5);
    await t.pump();
    await pumpFor(t, 90);
    await s.snap('home-bell-swing', _phone);
    await pumpFor(t, 1500);

    s = await _open(t, _phone, homeRepoOf('ready'));
    await t.longPress(find.bySemanticsLabel(RegExp(r'^Home, tab')));
    await pumpFor(t, 900);
    await s.snap('home-dock-menu', _phone);
    await _end(t);
  });

  testWidgets('home: loading, new profile, offline, error, rate limited, at risk, novel', (t) async {
    final loadingRepo = homeRepoOf('ready');
    pendingFeed(loadingRepo);
    var s = await _open(t, _phone, loadingRepo, settle: false);
    await pumpFor(t, 600);
    await s.snap('home-loading', _phone);
    final repoD = homeRepoOf('ready');
    pendingFeed(repoD);
    s = await _open(t, kSkinShotDesktop, repoD, settle: false);
    await pumpFor(t, 600);
    await s.snap('home-loading', kSkinShotDesktop);

    s = await _open(t, _phone, homeRepoOf('new-profile'));
    await _scrollTo(t, find.text('Nothing followed yet'));
    await s.snap('home-new-profile', _phone);

    for (final size in [_phone, kSkinShotDesktop]) {
      final repo = homeRepoOf('ready');
      s = await _open(t, size, repo, extra: [downloadedSeriesProvider.overrideWith((ref) async => [_saved()])]);
      repo.answer = () async => const Err(NetworkError(message: 'down'));
      await s.container.read(homeFeedProvider.notifier).refresh();
      await pumpFor(t, 1500);
      await s.snap('home-offline', size);
    }

    final errRepo = FakeHomeRepo(() async => const Err(ApiError(statusCode: 500, code: 'boom', message: 'x')));
    s = await _open(t, _phone, errRepo, libraryDown: true, extra: [sourcePinsProvider.overrideWith(_FailingPins.new)]);
    await s.snap('home-error', _phone);

    final rateRepo = FakeHomeRepo(() async => const Err(ApiError(statusCode: 429, code: 'rate_limited', message: 'x', retryAfter: Duration(seconds: 12))));
    s = await _open(t, _phone, rateRepo, libraryDown: true, extra: [sourcePinsProvider.overrideWith(_FailingPins.new)]);
    await s.snap('home-rate-limited', _phone);

    s = await _open(t, _phone, homeRepoOf('at-risk'), now: DateTime(2026, 9, 30, 20, 40));
    await s.snap('home-at-risk', _phone);

    s = await _open(t, _phone, homeRepoOf('novel'), extra: contentModeOverrides(mode: ContentMode.novel, novelsEnabled: true));
    await s.snap('home-novel-mode', _phone);
    await _end(t);
  });

  testWidgets('home: solid, contrast, reduced and the motion timings', (t) async {
    var s = await _open(t, _phone, homeRepoOf('ready'), settle: false);
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    for (var i = 0; i < 8; i++) {
      await s.settle(600);
    }
    await pumpUntilCoversLoad(t, rounds: 25);
    await s.snap('home-solid', _phone);

    s = await _open(t, _phone, homeRepoOf('ready'), settle: false);
    s.container.read(glassInAppPrefsProvider.notifier).setIncreaseContrast(true);
    for (var i = 0; i < 8; i++) {
      await s.settle(600);
    }
    await pumpUntilCoversLoad(t, rounds: 25);
    await s.snap('home-contrast', _phone);

    s = await _open(t, _phone, homeRepoOf('ready'), settle: false);
    s.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
    for (var i = 0; i < 8; i++) {
      await s.settle(600);
    }
    await pumpUntilCoversLoad(t, rounds: 25);
    await s.snap('home-reduced', _phone);

    s = await _open(t, _phone, homeRepoOf('ready'), settle: false);
    s.container.read(glassShowMotionTimingsProvider.notifier).state = true;
    for (var i = 0; i < 8; i++) {
      await s.settle(600);
    }
    await pumpUntilCoversLoad(t, rounds: 25);
    await s.snap('home-motion-timings', _phone);
    await _end(t);
  });
}
