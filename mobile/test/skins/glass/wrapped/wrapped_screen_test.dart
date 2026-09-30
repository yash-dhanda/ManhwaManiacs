import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';

import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_frame.dart';

import '../../../support/numbers_fixtures.dart';
import '../stats/stats_rig.dart';

const _path = '/library/statistics/annual/2026';

Future<void> settle(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

FakeNumbers _repo({Annual? annual}) => FakeNumbers(annuals: {2026: annual ?? Annual.fromJson({...annualJson(partial: false), 'busiest_day': {'date': '2026-03-14', 'chapters': 42, 'series': <Object?>[]}})});

void main() {
  testWidgets('the cover, taps move through the cards and the capsules renumber', (t) async {
    final repo = _repo();
    await pumpStats(t, repo, start: _path, settle: false);
    await settle(t);
    expect(find.bySemanticsLabel('Wrapped 2026'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Your 2026 in chapters')), findsWidgets);
    final size = t.getSize(find.byKey(const ValueKey('wrapped-card-cover')));
    expect(size.width, closeTo(360, 0.5), reason: 'the card is laid out in the 360 x 640 frame');
    expect(size.height, closeTo(640, 0.5));
    await t.tapAt(const Offset(300, 420)); // right two thirds
    await settle(t, 5);
    expect(find.byKey(const ValueKey('wrapped-card-time')), findsOneWidget);
    await t.tapAt(const Offset(30, 420)); // left third
    await settle(t, 5);
    expect(find.byKey(const ValueKey('wrapped-card-cover')), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('auto-advance moves on after 6 s and pause stops it', (t) async {
    final repo = _repo();
    await pumpStats(t, repo, start: _path, settle: false);
    await settle(t);
    await t.pump(const Duration(seconds: 6));
    await settle(t, 4);
    expect(find.byKey(const ValueKey('wrapped-card-time')), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Pause'));
    await t.pump();
    await t.pump(const Duration(seconds: 7));
    await settle(t, 3);
    expect(find.byKey(const ValueKey('wrapped-card-time')), findsOneWidget, reason: 'paused');
    expect(find.bySemanticsLabel('Play'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('export flips to the share side with Story and Post', (t) async {
    final repo = _repo();
    await pumpStats(t, repo, start: _path, settle: false);
    await settle(t);
    await t.tapAt(const Offset(300, 420));
    await settle(t, 5);
    await t.tap(find.text('Export'));
    await settle(t, 6);
    expect(find.text('Story'), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);
    expect(find.text('Show my profile name'), findsWidgets);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('a non-numeric year is the not-found lens', (t) async {
    await pumpStats(t, _repo(), start: '/library/statistics/annual/abc', settle: false);
    await settle(t, 3);
    expect(find.text('Nothing here'), findsWidgets);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('not enough data says how many days are recorded', (t) async {
    final a = Annual.fromJson(annualJson(recordedDays: 5));
    await pumpStats(t, _repo(annual: a), start: _path, settle: false);
    await settle(t, 3);
    expect(find.textContaining('Not enough reading this year'), findsOneWidget);
    expect(find.text('5 days recorded so far'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('the card slots sit where the frame table says, scaled, at 390 x 844', (t) async {
    final repo = _repo();
    await pumpStats(t, repo, start: _path, settle: false);
    await settle(t);
    await t.tapAt(const Offset(300, 420));
    await settle(t, 5);
    const scale = 358 / 360;
    const origin = Offset(16, 16 + (844 - 32 - 0 - 0 - 640 * scale) / 2);
    Rect want(Rect slot) => scaledSlot(slot, scale, origin);
    final figure = find.byWidgetPredicate((w) => w is SizedBox && w.width == 312 && w.height == 304).first;
    final f = t.getRect(figure);
    expect(f.left, closeTo(want(WrappedSlots.figure).left, 1));
    expect(f.top, closeTo(want(WrappedSlots.figure).top, 1));
    expect(f.width, closeTo(312 * scale, 1));
    final export = t.getRect(find.ancestor(of: find.byType(GlassButton), matching: find.byType(SizedBox)).first);
    expect(export.left, closeTo(want(WrappedSlots.export).left, 1));
    expect(export.top, closeTo(want(WrappedSlots.export).top, 1));
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('keys: arrows move, Space pauses, previous and next appear after a key', (t) async {
    final repo = _repo();
    await pumpStats(t, repo, start: _path, settle: false);
    await settle(t);
    expect(find.bySemanticsLabel('Next card'), findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settle(t, 5);
    expect(find.byKey(const ValueKey('wrapped-card-time')), findsOneWidget);
    expect(find.bySemanticsLabel('Next card'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await settle(t, 5);
    expect(find.byKey(const ValueKey('wrapped-card-cover')), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pump();
    expect(find.bySemanticsLabel('Play'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  for (final f in [1.3, 2.0]) {
    testWidgets('large text $f: the card is a scrolling column', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = f;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final repo = _repo();
      await pumpStats(t, repo, start: _path, settle: false);
      await settle(t);
      expect(find.byKey(const ValueKey('wrapped-column')), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(t, 5);
      expect(find.byKey(const ValueKey('wrapped-card-time')), findsOneWidget);
      expect(find.byKey(const ValueKey('wrapped-column')), findsOneWidget);
      // a vertical drag inside the card scrolls it and never advances it
      await t.drag(find.byKey(const ValueKey('wrapped-column')), const Offset(0, -200));
      await settle(t, 3);
      expect(find.byKey(const ValueKey('wrapped-card-time')), findsOneWidget);
      await t.pump(const Duration(minutes: 11));
    });
  }
}
