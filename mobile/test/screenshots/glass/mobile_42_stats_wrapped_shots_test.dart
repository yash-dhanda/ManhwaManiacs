@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
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

Future<void> _covers(WidgetTester t) async {
  final out = <String, Uint8List>{};
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
        'first': {'series': {'source_id': 'shelf', 'series_key': 'series-1', 'title': 'Tower of God', 'cover_url': '/sources/shelf/series/series-1/cover'}, 'read_at': '2026-01-05T10:00:00Z'},
        'last': {'series': {'source_id': 'shelf', 'series_key': 'series-4', 'title': 'Lookism', 'cover_url': '/sources/shelf/series/series-4/cover'}, 'read_at': '2026-09-20T10:00:00Z'},
      },
    });

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
      final s = await _open(t, size, repo, start: '/library/statistics/annual/2026');
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await s.settle(2600);
      await s.snap('wrapped-01-cover', size);
      if (size != _phone) continue;
      for (var i = 1; i < cards.length; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await s.settle();
        await s.settle(2600);
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
    final gated = FakeNumbers(annuals: {2026: _annual()})..gate = Completer<void>();
    s = await _open(t, _phone, gated, start: '/library/statistics/annual/2026', settleMs: 1);
    await s.snap('wrapped-loading', _phone);
    gated.gate!.complete();
    s = await _open(t, _phone, FakeNumbers(annuals: {2026: Annual.fromJson(annualJson(recordedDays: 5))}), start: '/library/statistics/annual/2026');
    await s.snap('wrapped-thin', _phone);
    await _end(t);
  });

  testWidgets('share: the side and the real PNGs', (t) async {
    final repo = FakeNumbers(annuals: {2026: _annual()});
    final s = await _open(t, _phone, repo, start: '/library/statistics/annual/2026');
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await s.settle(800);
    await t.tap(find.text('Export').first);
    await s.settle(1200);
    await s.snap('share-side-story', _phone);
    await t.sendKeyEvent(LogicalKeyboardKey.digit2);
    await s.settle(1200);
    await s.snap('share-side-post', _phone);
    await _end(t);
  });

  testWidgets('share: rendered PNG files', (t) async {
    await _covers(t);
    final repo = FakeNumbers(annuals: {2026: _annual()});
    final s = await _open(t, _phone, repo);
    final ctx = t.element(find.byType(Overlay).first);
    Future<void> write(String name, ShareSpec spec, ShareFormat f) async {
      final fut = renderShareCard(ctx, spec, f);
      await t.pump();
      await t.pump();
      final bytes = await t.runAsync(() => fut);
      final dir = proofDir;
      if (dir != null) {
        await Directory(dir).create(recursive: true);
        await File('$dir/$name.png').writeAsBytes(bytes!);
      }
    }

    final a = _annual();
    await write('card-02-time-story', ShareSpec.forCard(WrappedCard.time, a)!, ShareFormat.story);
    await write('card-04-top-five-post', ShareSpec.forCard(WrappedCard.topFive, a)!, ShareFormat.post);
    await write('card-12-summary-story', ShareSpec.forCard(WrappedCard.summary, a)!, ShareFormat.story);
    await write('share-streak-story', ShareSpec.stat(id: 'streak', eyebrow: 'Streak', numeral: '12', unit: 'day streak', contextLine: 'Longest: 31 days', flame: true), ShareFormat.story);
    await s.settle(100);
    await _end(t);
  });
}

