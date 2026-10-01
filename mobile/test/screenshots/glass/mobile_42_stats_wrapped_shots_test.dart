@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/providers/streak_events_provider.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/glass_chart.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/share_card.dart';

import '../../skins/glass/stats/stats_rig.dart';
import '../../support/numbers_fixtures.dart';
import '../glass_shell_shots_support.dart';
import '../support/shot_covers.dart';
import '../support/shot_harness.dart';
import '../support/shot_network.dart';
import '../support/skin_shots.dart';

/// The mobile/42 proof captures (glass 9.2): "Your reading", the streak flame, Wrapped and the share side, on the numbers fixtures and
/// painted demo covers. Written only when `MM_PROOF_DIR` is set; otherwise rasterised and discarded.

const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
const _sizes = [_phone, SkinShotSize('tablet', Size(834, 1194), 2.0, EdgeInsets.only(top: 24, bottom: 20)), kSkinShotTabletWide];

final _coverBytes = <String, Uint8List>{};

Future<void> _covers(WidgetTester t) async {
  final out = _coverBytes;
  await t.runAsync(() async {
    for (var i = 0; i < 9; i++) {
      out['/sources/shelf/series/series-$i/cover'] = await ShotCoverArt(title: 'Series ${i + 1}', seed: i).toPng(width: 240, height: 360);
    }
  });
  addShotCovers(out);
}

Future<ShotSession> _open(WidgetTester t, SkinShotSize size, FakeNumbers repo, {String start = '/library/statistics', List<Override> extra = const [], int settleMs = 6}) async {
  await _covers(t);
  final s = await openShell(t, size, start: start, settle: false, extra: [...statsOverrides(repo), ...extra]);
  for (var i = 0; i < settleMs; i++) {
    await s.settle(500);
  }
  await pumpUntilCoversLoad(t, rounds: 12);
  return s;
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(minutes: 11));
}

/// Pumps [ms] of frames 50 ms apart, so tickers (count-ups, the pile, the podium) see every step.
Future<void> _frames(WidgetTester t, int ms) async {
  for (var e = 0; e < ms; e += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// Lets a share render (real async: precache, toImage, PNG encode) finish, then the flip settle.
Future<void> _rendered(WidgetTester t) async {
  for (var i = 0; i < 120; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump(const Duration(milliseconds: 16));
  }
  await _frames(t, 800);
}

Annual _annual() => Annual.fromJson({
      ...annualJson(partial: false, circle: true),
      'busiest_day': {
        'date': '2026-03-14',
        'chapters': 42,
        'series': [
          for (var i = 0; i < 4; i++) {'source_id': 'shelf', 'series_key': 'series-$i', 'title': 'Series ${i + 1}', 'cover_url': '/sources/shelf/series/series-$i/cover'},
        ],
      },
      'firsts_lasts': {
        'first': {
          'series': {'source_id': 'shelf', 'series_key': 'series-1', 'title': 'Tower of God', 'cover_url': '/sources/shelf/series/series-1/cover'},
          'read_at': '2026-01-05T10:00:00Z'
        },
        'last': {
          'series': {'source_id': 'shelf', 'series_key': 'series-4', 'title': 'Lookism', 'cover_url': '/sources/shelf/series/series-4/cover'},
          'read_at': '2026-09-20T10:00:00Z'
        },
      },
    });

bool _only(WrappedCard c) {
  final keys = [
    for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('wrapped-card-')).evaluate()) (e.widget.key! as ValueKey<String>).value,
  ];
  return keys.length == 1 && keys.single == 'wrapped-card-${c.name}';
}

void main() {
  setUpAll(loadAppFonts);
  setUpAll(setUpShotCoverCache);

  testWidgets('stats: the ranges on phone, tablet and the wide frame', (t) async {
    for (final size in _sizes) {
      final s = await _open(t, size, FakeNumbers(), start: '/library/statistics?range=30');
      await s.snap('stats-30', size);
    }
    var s = await _open(t, _phone, FakeNumbers(), start: '/library/statistics?range=7');
    await s.snap('stats-7', _phone);
    s = await _open(t, _phone, FakeNumbers(), start: '/library/statistics?range=90');
    await s.snap('stats-90', _phone);
    for (final size in _sizes) {
      s = await _open(t, size, FakeNumbers(), start: '/library/statistics?range=year');
      await s.snap('stats-year', size);
    }
    await _end(t);
  });

  testWidgets('stats: the states', (t) async {
    var s = await _open(t, _phone, FakeNumbers(stats: {30: statisticsFixture(empty: true)}));
    await s.snap('stats-empty', _phone);
    s = await _open(t, _phone, FakeNumbers(stats: {30: statisticsFixture(neverRead: true)}));
    await s.snap('stats-never-read', _phone);
    s = await _open(t, _phone, FakeNumbers(failWith: const UnknownError(message: 'boom')));
    await s.snap('stats-error', _phone);
    final repo = FakeNumbers()..gate = Completer<void>();
    s = await _open(t, _phone, repo, settleMs: 1);
    await s.snap('stats-loading', _phone);
    repo.gate!.complete();
    s = await _open(t, _phone, FakeNumbers(stats: {30: statisticsFixture(atRisk: true)}));
    await s.snap('stats-at-risk', _phone);
    await _end(t);
  });

  testWidgets('wrapped: every card of the fixture year', (t) async {
    final repo = FakeNumbers(annuals: {2026: _annual()});
    final cards = wrappedCards(_annual(), profileShares: true);
    for (final size in _sizes) {
      final s = await _open(t, size, repo, start: '/library/statistics/annual/2026', settleMs: 1);
      await t.sendKeyEvent(LogicalKeyboardKey.space); // paused on the cover before the 6 s auto-advance
      for (var f = 0; f < 55; f++) {
        await t.pump(const Duration(milliseconds: 100)); // the typing reveal runs frame by frame
      }
      await pumpUntilCoversLoad(t, rounds: 25);
      await s.snap('wrapped-01-cover', size);
      for (var i = 1; i < cards.length; i++) {
        // Step until this card is the only one up (the file name always matches what is shown).
        for (var k = 0; k < 3 && !_only(cards[i]); k++) {
          await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await s.settle();
          await s.settle(1200);
        }
        if (!_only(cards[i])) continue;
        for (var f = 0; f < 30; f++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await pumpUntilCoversLoad(t, rounds: 25);
        await s.snap('wrapped-${cards[i].number.toString().padLeft(2, '0')}-${cards[i].name}', size);
      }
    }
    await _end(t);
  });

  testWidgets('wrapped: large text, loading and thin year', (t) async {
    final repo = FakeNumbers(annuals: {2026: _annual()});
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    var s = await _open(t, _phone, repo, start: '/library/statistics/annual/2026');
    await s.snap('wrapped-large-text-1.3', _phone);
    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    s = await _open(t, _phone, repo, start: '/library/statistics/annual/2026');
    await s.snap('wrapped-large-text-2.0', _phone);
    t.platformDispatcher.clearTextScaleFactorTestValue();
    for (final size in _sizes) {
      final gated = FakeNumbers(annuals: {2026: _annual()})..gate = Completer<void>();
      s = await _open(t, size, gated, start: '/library/statistics/annual/2026', settleMs: 1);
      await s.snap('wrapped-loading', size);
      gated.gate!.complete();
      s = await _open(t, size, FakeNumbers(annuals: {2026: Annual.fromJson(annualJson(recordedDays: 5))}), start: '/library/statistics/annual/2026');
      await s.snap('wrapped-thin', size);
    }
    await _end(t);
  });

  testWidgets('share: the side and the real PNGs', (t) async {
    await _covers(t);
    final px = _coverBytes.values.first;
    for (final size in _sizes) {
      final repo = FakeNumbers(annuals: {2026: _annual()});
      final s = await _open(t, size, repo, start: '/library/statistics/annual/2026', settleMs: 1, extra: [glassShareImageProvider.overrideWithValue((url) => MemoryImage(_coverBytes[url] ?? px))]);
      await t.sendKeyEvent(LogicalKeyboardKey.space); // paused on the cover
      await _frames(t, 1000);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _frames(t, 2000);
      expect(_only(WrappedCard.time), isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.keyE);
      await _rendered(t);
      await s.snap('share-side-story', size);
      await t.sendKeyEvent(LogicalKeyboardKey.digit2);
      await _rendered(t);
      await s.snap('share-side-post', size);
    }
    await _end(t);
  });

  testWidgets('share: rendered PNG files', (t) async {
    await _covers(t);
    final repo = FakeNumbers(annuals: {2026: _annual()});
    final px = _coverBytes.values.first;
    final s = await _open(t, _phone, repo, extra: [glassShareImageProvider.overrideWithValue((url) => MemoryImage(_coverBytes[url] ?? px))]);
    Future<void> write(String name, ShareSpec spec, ShareFormat f) async {
      final ctx = t.element(find.byType(Text).first);
      Uint8List? bytes;
      Object? err;
      unawaited(renderShareCard(ctx, spec, f).then((b) => bytes = b, onError: (Object e) => err = e));
      for (var i = 0; i < 600 && bytes == null && err == null; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await t.pump();
      }
      if (err != null) throw err!;
      final dir = proofDir;
      if (dir != null) {
        await t.runAsync(() async {
          await Directory(dir).create(recursive: true);
          await File('$dir/$name.png').writeAsBytes(bytes!);
        });
      }
    }

    final a = _annual();
    await write('card-02-time-story', ShareSpec.forCard(WrappedCard.time, a)!, ShareFormat.story);
    await write('card-04-top-five-post', ShareSpec.forCard(WrappedCard.topFive, a)!, ShareFormat.post);
    await write('card-12-summary-story', ShareSpec.forCard(WrappedCard.summary, a)!, ShareFormat.story);
    final st = statisticsFixture();
    await write('share-range-story', ShareSpec.stat(id: 'range-30', eyebrow: 'Your reading', numeral: '${st.window.chaptersRead}', unit: 'chapters', contextLine: 'Last 30 days', bars: st.daily),
        ShareFormat.story);
    await write('share-streak-story', ShareSpec.stat(id: 'streak', eyebrow: 'Streak', numeral: '12', unit: 'day streak', contextLine: 'Longest: 31 days', flame: true), ShareFormat.story);
    await s.settle(100);
    await _end(t);
  });

  testWidgets('stats: table view, scrub, offline, goal menu, flare and milestone', (t) async {
    late ShotSession s;
    for (final size in _sizes) {
      s = await _open(t, size, FakeNumbers());
      await t.tap(find.text('Show as table').first);
      await s.settle(600);
      await s.snap('stats-table-view', size);

      s = await _open(t, size, FakeNumbers(), start: '/library/statistics?range=30');
      final chart = find.byType(GlassChart).first;
      await t.ensureVisible(chart);
      await s.settle(300);
      final r = t.getRect(chart);
      final g = await t.startGesture(Offset(r.left + 20, r.center.dy));
      for (var x = r.left + 20; x < r.center.dx; x += 10) {
        await g.moveTo(Offset(x, r.center.dy));
        await t.pump(const Duration(milliseconds: 16));
      }
      await s.snap('stats-scrub', size);
      await g.up();
    }

    for (final size in _sizes) {
      final repo = FakeNumbers();
      s = await _open(t, size, repo);
      repo.failWith = const NetworkError(message: 'offline');
      s.container.invalidate(numbersStatisticsProvider(30));
      await s.settle(800);
      await s.settle(800);
      await s.snap('stats-offline', size);
    }

    for (final size in _sizes) {
      s = await _open(t, size, FakeNumbers());
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyG);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await s.settle(500);
      await s.snap('goal-menu', size);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await s.settle(300);

      final repo = FakeNumbers()..stats[1] = LibraryStatistics.fromJson(statisticsJson(days: 1, currentDays: 30, milestonesSeen: const []));
      s = await _open(t, size, repo);
      final handle = s.container.read(progressAnswerHandlerProvider);
      handle(const ProgressAnswer(streak: StreakSnapshot(currentDays: 29, extendedToday: false), todaySeconds: 300));
      handle(const ProgressAnswer(streak: StreakSnapshot(currentDays: 30, extendedToday: true), todaySeconds: 900));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await s.snap('flare', size);
      await s.settle(900);
      await s.snap('milestone-toast', size);
    }
    await _end(t);
  });

  testWidgets('stats: the states at tablet and the wide frame', (t) async {
    for (final size in _sizes.skip(1)) {
      var s = await _open(t, size, FakeNumbers(), start: '/library/statistics?range=7');
      await s.snap('stats-7', size);
      s = await _open(t, size, FakeNumbers(), start: '/library/statistics?range=90');
      await s.snap('stats-90', size);
      s = await _open(t, size, FakeNumbers(stats: {30: statisticsFixture(empty: true)}));
      await s.snap('stats-empty', size);
      s = await _open(t, size, FakeNumbers(stats: {30: statisticsFixture(neverRead: true)}));
      await s.snap('stats-never-read', size);
      s = await _open(t, size, FakeNumbers(failWith: const UnknownError(message: 'boom')));
      await s.snap('stats-error', size);
      final gated = FakeNumbers()..gate = Completer<void>();
      s = await _open(t, size, gated, settleMs: 1);
      await s.snap('stats-loading', size);
      gated.gate!.complete();
    }
    await _end(t);
  });

  testWidgets('accessibility: reduced motion, solid glass, increased contrast', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    var s = await _open(t, _phone, FakeNumbers());
    await s.snap('reduced-motion-stats', _phone);
    s = await _open(t, _phone, FakeNumbers(annuals: {2026: _annual()}), start: '/library/statistics/annual/2026');
    await s.snap('reduced-motion-wrapped', _phone);
    t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    s = await _open(t, _phone, FakeNumbers());
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    await s.settle(600);
    await s.snap('stats-solid', _phone);
    s.container.read(glassInAppPrefsProvider.notifier)
      ..setSolidGlass(false)
      ..setIncreaseContrast(true);
    await s.settle(600);
    await s.snap('stats-contrast', _phone);
    await _end(t);
  });

  testWidgets('flame states, the pile, the podium mid-drop and the share flip', (t) async {
    for (final size in _sizes) {
      await captureSkinWidget(
        t,
        name: 'flame-states',
        size: size,
        overrides: [gravitySensorProvider.overrideWithValue(() => const Stream.empty())],
        settle: (t) async => t.pump(const Duration(milliseconds: 400)),
        child: ColoredBox(
          color: const Color(0xFF000000),
          child: Center(
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final px in const [16.0, 20.0, 44.0, 96.0, 220.0]) StreakFlame(size: px, days: 12, state: FlameState.litToday),
                const StreakFlame(size: 96, days: 12, state: FlameState.notYetToday),
                const StreakFlame(size: 96, days: 12, state: FlameState.atRisk),
                const StreakFlame(size: 96, state: FlameState.none),
              ],
            ),
          ),
        ),
      );
    }
    final cards = wrappedCards(_annual(), profileShares: true);
    for (final size in _sizes) {
      final repo = FakeNumbers(annuals: {2026: _annual()});
      final s = await _open(t, size, repo, start: '/library/statistics/annual/2026', settleMs: 1);
      await t.sendKeyEvent(LogicalKeyboardKey.space); // paused: the keys move
      Future<void> goTo(WrappedCard c) async {
        for (var i = 0; i < cards.length && find.byKey(ValueKey('wrapped-card-${c.name}')).evaluate().isEmpty; i++) {
          await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await _frames(t, 900);
        }
      }

      await goTo(WrappedCard.time);
      await _frames(t, 1600);
      await t.sendKeyEvent(LogicalKeyboardKey.keyE);
      await _frames(t, 200);
      await s.snap('share-flip', size);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await _rendered(t);
      await goTo(WrappedCard.volume);
      await _frames(t, 5000);
      await s.snap('wrapped-pile', size);
      await goTo(WrappedCard.topFive);
      await _frames(t, 2000);
      await pumpUntilCoversLoad(t, rounds: 25); // the covers in the image cache, then the drop again
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await _frames(t, 900);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _frames(t, 1100); // the settle, then #5, #4 and #3 down while #2 and #1 still fall
      await s.snap('wrapped-podium-drop', size);
    }
    await _end(t);
  });
}
