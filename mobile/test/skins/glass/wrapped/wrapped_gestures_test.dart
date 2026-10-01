import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart' show WrappedCard;
import 'package:manhwamaniacs/skins/glass/parts/share/share_side.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_frame.dart';

import '../../../support/numbers_fixtures.dart';
import '../stats/stats_rig.dart';

const _path = '/library/statistics/annual/2026';

Annual _year() => Annual.fromJson({...annualJson(partial: false), 'busiest_day': {'date': '2026-03-14', 'chapters': 42, 'series': <Object?>[]}});

Future<void> settle(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _open(WidgetTester t, {Size size = const Size(390, 844), bool assistive = false}) async {
  final rig = await pumpStats(t, FakeNumbers(annuals: {2026: _year()}), start: _path, size: size, settle: false);
  if (assistive) rig.container.read(glassAssistiveProvider.notifier).state = true;
  await settle(t);
}

Finder _card(WrappedCard c) => find.byKey(ValueKey('wrapped-card-${c.name}'));

void main() {
  testWidgets('1180 x 820: the frame scales to min(1.2, (h - 64) / 640) and the slots follow, within 1 px', (t) async {
    await _open(t, size: const Size(1180, 820));
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight); // card 2: headline, figure and Export
    await settle(t, 5);
    const scale = 756 / 640;
    const origin = Offset((1180 - 360 * scale) / 2, (820 - 640 * scale) / 2);
    Rect want(Rect r) => scaledSlot(r, scale, origin);
    void near(Rect got, Rect r) {
      final w = want(r);
      expect(got.left, closeTo(w.left, 1));
      expect(got.top, closeTo(w.top, 1));
      expect(got.width, closeTo(w.width, 1));
    }

    near(t.getRect(find.ancestor(of: find.byType(LetterReveal), matching: find.byType(Align)).first), WrappedSlots.headline);
    near(t.getRect(find.byWidgetPredicate((w) => w is SizedBox && w.width == 312 && w.height == 304).first), WrappedSlots.figure);
    near(t.getRect(find.ancestor(of: find.byType(GlassButton), matching: find.byType(SizedBox)).first), WrappedSlots.export);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('390 x 844: the headline slot too', (t) async {
    await _open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settle(t, 5);
    const scale = 358 / 360;
    const origin = Offset(16, 16 + (844 - 32 - 640 * scale) / 2);
    final got = t.getRect(find.ancestor(of: find.byType(LetterReveal), matching: find.byType(Align)).first);
    final w = scaledSlot(WrappedSlots.headline, scale, origin);
    expect(got.top, closeTo(w.top, 1));
    expect(got.height, closeTo(w.height, 1));
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('swipes move with the story stack; the first card rubber-bands back', (t) async {
    await _open(t);
    await t.drag(find.byKey(const ValueKey('wrapped-card-cover')), const Offset(120, 0));
    await settle(t, 4);
    expect(_card(WrappedCard.cover), findsOneWidget, reason: 'nothing before the cover');
    await t.fling(find.byKey(const ValueKey('wrapped-card-cover')), const Offset(-200, 0), 1200);
    await settle(t, 4);
    expect(_card(WrappedCard.time), findsOneWidget);
    await t.fling(_card(WrappedCard.time), const Offset(200, 0), 1200);
    await settle(t, 4);
    expect(_card(WrappedCard.cover), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('a hold pauses at once and a late release does not advance', (t) async {
    await _open(t);
    final g = await t.startGesture(const Offset(300, 420));
    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(seconds: 4));
    expect(_card(WrappedCard.cover), findsOneWidget, reason: 'held: the capsule stops');
    await g.up();
    await t.pump(const Duration(milliseconds: 300));
    expect(_card(WrappedCard.cover), findsOneWidget, reason: 'a release after 450 ms is not a tap');
    await t.pump(const Duration(seconds: 6));
    await settle(t, 3);
    expect(_card(WrappedCard.time), findsOneWidget, reason: 'resumed');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('auto-advance stops on the last card', (t) async {
    await _open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.space); // paused while the keys walk to the end
    for (var i = 0; i < 14 && _card(WrappedCard.summary).evaluate().isEmpty; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(t, 3);
      printOnFailure('step $i: ${[for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('wrapped-card-')).evaluate()) (e.widget.key! as ValueKey<String>).value]}');
    }
    expect(_card(WrappedCard.summary), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.space); // playing again
    await t.pump(const Duration(seconds: 7));
    await settle(t, 3);
    expect(_card(WrappedCard.summary), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('never auto-advances with a screen reader on; previous and next are shown', (t) async {
    await _open(t, assistive: true);
    expect(find.bySemanticsLabel('Next card'), findsOneWidget);
    expect(find.bySemanticsLabel('Previous card'), findsOneWidget);
    await t.pump(const Duration(seconds: 7));
    await settle(t, 3);
    expect(_card(WrappedCard.cover), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('swipe down closes the story to Statistics when there is no entry rect', (t) async {
    final rig = await pumpStats(t, FakeNumbers(annuals: {2026: _year()}), start: _path, settle: false);
    await settle(t);
    await t.fling(find.byKey(const ValueKey('wrapped-card-cover')), const Offset(0, 260), 1500);
    await settle(t, 4);
    expect(rig.at, '/library/statistics');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('e flips to the share side, 2 picks Post, Esc flips back, Esc again closes', (t) async {
    final rig = await pumpStats(t, FakeNumbers(annuals: {2026: _year()}), start: _path, settle: false);
    await settle(t);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settle(t, 3);
    await t.sendKeyEvent(LogicalKeyboardKey.keyE);
    await settle(t, 3);
    expect(find.text('Story'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.digit2);
    await t.pump();
    expect(t.state<GlassShareSideState>(find.byType(GlassShareSide)).format.name, 'post');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(t, 4);
    expect(find.byType(GlassShareSide), findsNothing);
    expect(rig.at, _path);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(t, 4);
    expect(rig.at, '/library/statistics');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('the "Your reading" and "Wrapped" key groups are registered for the ? sheet', (t) async {
    final rig = await pumpStats(t, FakeNumbers(annuals: {2026: _year()}));
    List<String> groups() => rig.container.read(shortcutRegistryProvider.notifier).registeredGroups().map((g) => g.name).toList();
    expect(groups(), contains('Your reading'));
    rig.router.go(_path);
    await settle(t);
    expect(groups(), contains('Wrapped'));
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('hit targets on the Wrapped frame and the share strip at 390 x 844', (t) async {
    final h = t.ensureSemantics();
    await _open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settle(t, 3);
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    await t.sendKeyEvent(LogicalKeyboardKey.keyE);
    await settle(t, 3);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
    await t.pump(const Duration(minutes: 11));
  });
}
