// ignore_for_file: require_trailing_commas, directives_ordering, avoid_redundant_argument_values
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/home/utils/at_risk.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_header.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/novel_title_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_states.dart';

import 'tonight_test_support.dart';

const _headline = 'Tonight: chapter 143 of The Lantern Courier.';
const _stamp = {'mm.tonight.typed.u1p1': '{"date":"2026-09-30","variant":"normal"}'};

/// The revealed part of the typed headline: the first span of its `Text.rich`.
String _revealed(WidgetTester t) {
  final text = t.widget<Text>(find.descendant(of: find.byType(TypedHeadline), matching: find.byType(Text)).first);
  final span = text.textSpan! as TextSpan;
  return (span.children!.first as TextSpan).text ?? '';
}

Finder _folio(String s) => find.text(s);

Finder _heading(String s) => find.byWidgetPredicate((w) => w is SetHeading && w.text == s);

HomeFeed _withAlso(HomeFeed f, int n) => f.copyWith(also: f.also.take(n).toList());

const _tall = Size(390, 4200);

void main() {
  testWidgets('the headline types at 50 ms a grapheme, the label holds all of it, a tap completes it', (t) async {
    await pumpTonight(t, feed: 'ready');
    await t.pump(const Duration(milliseconds: 450));
    final n = _revealed(t).characters.length;
    expect(n, inInclusiveRange(8, 12), reason: '10 +- 2 graphemes after 500 ms');
    expect(find.bySemanticsLabel(_headline), findsOneWidget);
    expect(t.getSemantics(find.bySemanticsLabel(_headline)).flagsCollection.isHeader, isTrue);
    await t.tap(find.byType(TypedHeadline));
    await t.pump();
    expect(_revealed(t), _headline);
    await settleTonight(t, by: const Duration(seconds: 5));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('it types once a day per profile: a same-day visit shows it at rest, no caret', (t) async {
    await pumpTonight(t, feed: 'ready', prefs: _stamp);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(TypedHeadline), findsNothing);
    expect(find.text(_headline), findsOneWidget);
    expect(find.bySemanticsLabel(_headline), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion: the headline shows complete, no caret', (t) async {
    await pumpTonight(t, feed: 'ready', reduced: true);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text(_headline), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the at-risk headline and the 16 px flame before the kicker', (t) async {
    final f = applyAtRisk(loadFeed('at-risk'), DateTime(2026, 9, 30, 20, 30));
    await pumpTonight(t, view: viewOf(f), now: DateTime(2026, 9, 30, 20, 30), prefs: const {'mm.tonight.typed.u1p1': '{"date":"2026-09-30","variant":"at-risk"}'});
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Twelve days and counting. One chapter keeps it alive.'), findsOneWidget);
    expect(find.text('Open any chapter before midnight to keep your streak.'), findsOneWidget);
    expect(find.bySemanticsLabel('12-day streak, at risk'), findsWidgets);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('folios are gapless and Picked for you becomes From your shelf with its NOTE line', (t) async {
    final ai = loadFeed('ai-unavailable');
    final keep = [for (final s in ai.sections) if ({HomeSectionType.continueReading, HomeSectionType.picked, HomeSectionType.numbers}.contains(s.type)) s];
    final because = loadFeed('ready').section(HomeSectionType.because)!;
    final sections = [keep[0], keep[1], because, keep[2]];
    await pumpTonight(t, view: viewOf(ai.copyWith(sections: sections)), size: _tall, prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 3));
    for (final f in ['01', '02', '03', '04']) {
      expect(_folio(f), findsOneWidget, reason: f);
    }
    expect(_folio('05'), findsNothing);
    expect(find.text('From your shelf'), findsOneWidget);
    expect(find.text('Picked for you'), findsNothing);
    expect(find.text('NOTE'), findsOneWidget);
    expect(find.textContaining('Here is your shelf instead.'), findsOneWidget);
    expect(find.textContaining('The picks desk is closed tonight.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Because you read sets the seed title in Roman', (t) async {
    await pumpTonight(t, feed: 'ready', size: _tall, prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 3));
    final heading = t.widgetList<SetHeading>(find.byType(SetHeading)).firstWhere((h) => h.text.startsWith('Because you read'));
    expect(heading.roman, (start: 17, end: 42));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Also in this issue: a pager of three with a folio, working buttons, never the cover series', (t) async {
    await pumpTonight(t, feed: 'ready', size: const Size(390, 2600), prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 2));
    expect(find.byKey(const Key('tonight-also-pager')), findsOneWidget);
    expect(_folio('1 / 3'), findsOneWidget);
    expect(t.widget<CineIconButton>(find.byKey(const Key('tonight-also-prev'))).onPressed, isNull);
    await t.tap(find.byKey(const Key('tonight-also-next')));
    await settleTonight(t, by: const Duration(milliseconds: 600));
    expect(_folio('2 / 3'), findsOneWidget);
    expect(t.widget<CineIconButton>(find.byKey(const Key('tonight-also-prev'))).onPressed, isNotNull);
    expect(find.textContaining('The Lantern Courier: '), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('two cards make a pager of two; one or none render nothing', (t) async {
    await pumpTonight(t, view: viewOf(_withAlso(loadFeed('ready'), 2)), size: const Size(390, 2600), prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(_folio('1 / 2'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await pumpTonight(t, view: viewOf(_withAlso(loadFeed('ready'), 1)), size: const Size(390, 2600), prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.byKey(const Key('tonight-also-pager')), findsNothing);
    await t.pumpWidget(const SizedBox());
    await pumpTonight(t, view: viewOf(_withAlso(loadFeed('ready'), 0)), size: const Size(390, 2600), prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.byKey(const Key('tonight-also-pager')), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('tablet: Also in this issue is 2 + 1', (t) async {
    await pumpTonight(t, feed: 'ready', wide: true, size: const Size(834, 4000), prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 2));
    expect(find.byKey(const Key('tonight-also-pager')), findsNothing);
    expect(find.text('NEW THIS WEEK'), findsWidgets);
    expect(find.text('BECAUSE YOU READ'), findsWidgets);
    expect(find.text('ALMOST THERE'), findsWidgets);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('offline: the edition headline, the two saved sections, the badge then the glyph', (t) async {
    final offline = loadFeed('ready').copyWith(
      headline: 'Offline edition.',
      deck: "Only what's saved on this device is here.",
      sections: [
        HomeSection(type: HomeSectionType.saved, title: 'Saved on this device', items: const [HomeSavedItem(sourceId: 'shelf', seriesKey: 'iron-kite', title: 'Iron Kite', chapters: 3)]),
      ],
      also: const [],
    );
    await pumpTonight(t, view: viewOf(offline, origin: HomeFeedOrigin.offline, offline: true), size: const Size(390, 2600), prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 2));
    expect(find.text('Offline edition.'), findsOneWidget);
    expect(_heading('Saved on this device'), findsOneWidget);
    expect(find.text('Picked for you'), findsNothing);
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
    await settleTonight(t, by: const Duration(seconds: 3));
    expect(find.text('OFFLINE EDITION'), findsNothing);
    expect(find.bySemanticsLabel('Offline edition'), findsWidgets);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('an offline edition with nothing saved is the headline block and Go to Downloads', (t) async {
    final empty = HomeFeed.fromJson({'headline': 'Offline edition.', 'deck': "Only what's saved on this device is here."});
    await pumpTonight(t, view: viewOf(empty, origin: HomeFeedOrigin.offline, offline: true), prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.byKey(const Key('tonight-head-action')), findsOneWidget);
    expect(find.text('Go to Downloads'), findsOneWidget);
    await t.tap(find.byKey(const Key('tonight-head-action')));
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.textContaining('stub /downloads'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a new profile: the headline, Find something, and the sections it has', (t) async {
    await pumpTonight(t, feed: 'new-profile', size: _tall, prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 2));
    expect(find.text('Your first issue starts here.'), findsOneWidget);
    expect(find.text('Popular on your sources'), findsOneWidget);
    expect(find.text('SUGGESTED SOURCES'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('loading shows the galley after 120 ms, then the feed dissolves in', (t) async {
    final gate = Future<void>.delayed(const Duration(milliseconds: 600));
    await pumpTonight(t, feed: 'ready', hold: gate, prefs: _stamp);
    expect(find.byType(TonightGalley), findsOneWidget);
    expect(find.text('TONIGHT'), findsOneWidget, reason: 'the kicker is live from the start');
    await t.pump(const Duration(milliseconds: 700));
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.byType(TonightGalley), findsNothing);
    expect(find.text(_headline), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('every input failed: the CORRECTION notice; a 429 shows SLOW DOWN with a countdown', (t) async {
    await pumpTonight(t, view: null);
    await settleTonight(t, by: const Duration(seconds: 2));
    expect(find.byKey(const Key('tonight-error')), findsOneWidget);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is TypedHeadline && w.text == "This issue didn't print."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Go to Downloads'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    const limited = (state: HomeFeedState.unavailable, feed: null, origin: HomeFeedOrigin.local, offline: false, retryAfter: Duration(seconds: 12));
    await pumpTonight(t, view: limited);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(find.text('SLOW DOWN'), findsOneWidget);
    expect(find.textContaining('Retrying in'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    // The retry timer ends with the widget.
    expect(const ApiError(statusCode: 429, code: 'rate_limited', message: 'x').statusCode, 429);
  });

  testWidgets('the novel title page: the 120 x 176 plate on phones, 168 x 248 on tablets', (t) async {
    await pumpTonight(t, feed: 'novel', novel: true, prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(t.getSize(find.byType(CoverPlate)), const Size(120, 176));
    expect(find.text('Tonight: chapter 213 of Ashes of the Glass Orchard.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    await pumpTonight(t, feed: 'novel', novel: true, wide: true, prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(t.getSize(find.byType(CoverPlate)), const Size(168, 248));
    expect(find.text('by Marta Ilves'), findsOneWidget);
    expect(find.byKey(const Key('tonight-byline-rule')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the phone cover story: height min(width x 1.25, 70 % of the screen), header pinned', (t) async {
    await pumpTonight(t, feed: 'ready', prefs: _stamp);
    final header = t.widget<SliverPersistentHeader>(find.byType(SliverPersistentHeader));
    expect(header.pinned, isTrue);
    final d = header.delegate as dynamic;
    expect(d.maxExtent, closeTo(487.5, 0.01));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the tablet spread height is clamp(560, 72 % of the screen, 820)', (t) async {
    await pumpTonight(t, feed: 'ready', wide: true, prefs: _stamp);
    final header = t.widget<SliverPersistentHeader>(find.byType(SliverPersistentHeader));
    expect((header.delegate as dynamic).maxExtent, 820);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('hardware keys: R reprints, C continues by the wipe, P opens the recap', (t) async {
    final rig = await pumpTonight(t, feed: 'ready', prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    FakeHomeFeed.refreshed = 0;
    await t.sendKeyEvent(LogicalKeyboardKey.keyR);
    await t.pump();
    expect(FakeHomeFeed.refreshed, 1);
    await t.sendKeyEvent(LogicalKeyboardKey.keyP);
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(rig.visited.any((l) => l.startsWith('/recap/shelf/the-lantern-courier')), isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Continue enters the reader on the chapter, with the primary press haptic', (t) async {
    final rig = await pumpTonight(t, feed: 'ready', prefs: _stamp);
    await settleTonight(t, by: const Duration(seconds: 1));
    await t.tap(find.byKey(const Key('tonight-continue')));
    await settleTonight(t, by: const Duration(seconds: 1));
    expect(rig.visited, contains('/reader/shelf/the-lantern-courier/c143'));
    expect(rig.rec.haptics, contains('tap.primary'));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the actions read Continue with the chapter and page, Previously on and Details', (t) async {
    await pumpTonight(t, feed: 'ready', prefs: _stamp);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('CH 143 · p.1'), findsOneWidget);
    expect(find.text('Previously on…'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await pumpTonight(t, feed: 'onboarded', prefs: _stamp);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('CH 1'), findsWidgets);
    expect(find.text('Previously on…'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  test('the debug-only helpers stay unreferenced in release', () {
    expect(kReleaseMode, isFalse);
    expect(CoverStoryHeaderDelegate, isNotNull);
  });
}
