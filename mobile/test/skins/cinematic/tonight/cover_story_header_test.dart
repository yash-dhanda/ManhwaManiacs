// ignore_for_file: require_trailing_commas, directives_ordering, avoid_redundant_argument_values
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/also_in_this_issue.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_parts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';

import 'tonight_test_support.dart';

const _stamp = {'mm.tonight.typed.u1p1': '{"date":"2026-09-30","variant":"normal"}'};

/// A 390 x 844 phone: the header is 487.5 tall and its strip 64, so the scrub runs over the last 240 px.
const double _max = 487.5, _min = 64;

ScrollPosition _position(WidgetTester t) =>
    t.state<ScrollableState>(find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first).position;

/// Scrolls so that the header has shrunk by [shrink] and lets a frame land.
Future<void> _shrink(WidgetTester t, double shrink) async {
  _position(t).jumpTo(shrink);
  await t.pump();
  await t.pump(const Duration(milliseconds: 20));
}

double _shrinkFor(double p) => (_max - _min - 240) + p * 240;

double _textOpacity(WidgetTester t) => t.widget<Opacity>(find.ancestor(of: find.byType(TonightHeadline), matching: find.byType(Opacity)).first).opacity;

Finder _strip() => find.byKey(const Key('tonight-strip-continue'));

double _stripOpacity(WidgetTester t) {
  final o = find.ancestor(of: _strip(), matching: find.byType(AnimatedOpacity));
  return t.widget<AnimatedOpacity>(o.first).opacity;
}

bool _textExcluded(WidgetTester t) => t.widget<ExcludeFocus>(find.ancestor(of: find.byType(TonightHeadline), matching: find.byType(ExcludeFocus)).first).excluding;

bool _stripExcluded(WidgetTester t) => t.widget<ExcludeFocus>(find.ancestor(of: _strip(), matching: find.byType(ExcludeFocus)).first).excluding;

void main() {
  test('p is 0 at maxExtent - minExtent - 240, 0.5 half way, 1 when the strip is pinned', () {
    expect(scrubProgress(_max - _min - 240, _max, _min), 0);
    expect(scrubProgress(_max - _min - 120, _max, _min), closeTo(0.5, 1e-9));
    expect(scrubProgress(_max - _min, _max, _min), 1);
    expect(scrubProgress(0, _max, _min), 0);
    expect(scrubProgress(9999, _max, _min), 1);
  });

  testWidgets('at p = 0.5 the text is nearly gone and the strip is not there yet; at p = 1 the strip is pinned', (t) async {
    await pumpTonight(t, feed: 'ready', prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    final rest = t.getTopLeft(find.byType(TonightHeadline));
    final restArt = t.getSize(find.ancestor(of: find.byType(CoverArt), matching: find.byType(ClipRect)).first);
    expect(restArt.width, 390);

    await _shrink(t, _shrinkFor(0.5));
    expect(_textOpacity(t), lessThan(0.2));
    expect(_stripOpacity(t), 0);
    expect(t.getSize(find.ancestor(of: find.byType(CoverArt), matching: find.byType(ClipRect)).first).width, lessThan(390));

    await _shrink(t, _max - _min);
    expect(_textOpacity(t), 0);
    expect(_stripOpacity(t), 1);
    expect(t.getSize(find.ancestor(of: find.byType(CoverArt), matching: find.byType(ClipRect)).first), const Size(32, 48), reason: 'the thumbnail slot');
    expect(find.text('The Lantern Courier'), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('chapter 143')), findsWidgets);
    expect(find.text('CH 143'), findsWidgets);
    // Pinned: further scrolling keeps the strip at the top.
    await _shrink(t, _max - _min + 600);
    expect(t.getTopLeft(_strip()).dy, lessThan(64));
    expect(_stripOpacity(t), 1);

    // Scrolling back restores the rest layout exactly.
    await _shrink(t, 0);
    expect(_textOpacity(t), 1);
    expect(_stripOpacity(t), 0);
    expect(t.getTopLeft(find.byType(TonightHeadline)), rest);
    expect(t.getSize(find.ancestor(of: find.byType(CoverArt), matching: find.byType(ClipRect)).first), restArt);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('only the pinned header relayouts: Also in this issue is not rebuilt through p = 0 to 1', (t) async {
    await pumpTonight(t, feed: 'ready', prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.byKey(const Key('tonight-also-pager')), findsOneWidget, reason: 'the row exists before the scrub starts');
    final before = AlsoInThisIssue.debugBuilds;
    for (var p = 0.0; p <= 1.0; p += 0.1) {
      await _shrink(t, _shrinkFor(p));
    }
    expect(AlsoInThisIssue.debugBuilds, before);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('focus: the text block is inert from p 0.55, the strip Continue joins the order at p 0.8', (t) async {
    await pumpTonight(t, feed: 'ready', prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(_textExcluded(t), isFalse);
    expect(_stripExcluded(t), isTrue);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tonight-headline');

    await _shrink(t, _shrinkFor(0.5));
    expect(_textExcluded(t), isFalse);
    await _shrink(t, _shrinkFor(0.6));
    expect(_textExcluded(t), isTrue);
    expect(_stripExcluded(t), isTrue);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tonight-page', reason: 'focus left the inert text for the page node');

    await _shrink(t, _shrinkFor(0.85));
    expect(_stripExcluded(t), isFalse);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tonight-strip-continue');

    await _shrink(t, 0);
    expect(_textExcluded(t), isFalse);
    expect(_stripExcluded(t), isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion: no compression; the strip fades in over 150 ms once the cover is under the head', (t) async {
    await pumpTonight(t, feed: 'ready', reduced: true, prefs: _stamp);
    await settleTonight(t, by: const Duration(milliseconds: 500));
    await _shrink(t, _shrinkFor(0.5));
    expect(t.getSize(find.ancestor(of: find.byType(CoverArt), matching: find.byType(ClipRect)).first).width, 390, reason: 'no compression');
    expect(_stripOpacity(t), 0);
    await _shrink(t, _max - _min);
    await t.pump(const Duration(milliseconds: 200));
    expect(_stripOpacity(t), 1);
    expect(_stripExcluded(t), isFalse);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the tablet spread scrubs the same way', (t) async {
    await pumpTonight(t, feed: 'ready', wide: true, prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    const max = 820.0;
    _position(t).jumpTo(max - 64);
    await t.pump();
    await t.pump(const Duration(milliseconds: 20));
    expect(_stripOpacity(t), 1);
    expect(t.getSize(find.ancestor(of: find.byType(CoverArt), matching: find.byType(ClipRect)).first), const Size(32, 48));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('adjacent targets are at least 8 px apart: the strip controls, the action row, the pager buttons', (t) async {
    await pumpTonight(t, feed: 'ready', size: const Size(390, 2600), prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    final recap = t.getRect(find.byKey(const Key('tonight-recap'))), details = t.getRect(find.byKey(const Key('tonight-details')));
    expect(details.left - recap.right, greaterThanOrEqualTo(8));
    final primary = t.getRect(find.byKey(const Key('tonight-continue')));
    expect(recap.top - primary.bottom, greaterThanOrEqualTo(8));
    final prev = t.getRect(find.byKey(const Key('tonight-also-prev'))), next = t.getRect(find.byKey(const Key('tonight-also-next')));
    expect(next.left - prev.right, greaterThanOrEqualTo(8));
    await _shrink(t, _max - _min);
    final cont = t.getRect(_strip()), more = t.getRect(find.byKey(const Key('tonight-strip-more')));
    expect(more.left - cont.right, greaterThanOrEqualTo(8));
    await t.pumpWidget(const SizedBox());
  });
}
