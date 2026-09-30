// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/history/history_row.dart';

import 'hub_test_support.dart';

const _tablet = Size(834, 1194);

Finder _headline(String s) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == s);

HubLibrary _lib(List<ReadingHistoryItem> history, {bool fail = false, bool offline = false}) => HubLibrary(all: [for (var i = 1; i <= 6; i++) shelfSeries(i)], history: history)
  ..failCollections = fail
  ..offlineCollections = offline;

Future<LibRig> _pump(WidgetTester t, HubLibrary lib, {FakeSources? sources, Size size = const Size(390, 5200)}) => pumpShelf(
      t,
      lib: lib,
      start: '/library/history',
      size: size,
      extra: [...updatesOverrides(FakeUpdates()), if (sources != null) sourcesRepositoryProvider.overrideWithValue(sources)],
    );

void main() {
  testWidgets('the log groups by day and keeps the time margin: 40 px on phones, 56 on tablets', (t) async {
    final rows = [
      logRow(1, 1),
      logRow(2, 2, at: kShelfNow.subtract(const Duration(hours: 3))),
      logRow(3, 3, at: kShelfNow.subtract(const Duration(days: 1))),
      logRow(4, 4, title: '', at: kShelfNow.subtract(const Duration(days: 3))),
    ];
    final lib = _lib(rows);
    await _pump(t, lib);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.byType(HistoryRow), findsNWidgets(4));
    expect(find.text('CH 142 · p.12 OF 40'), findsWidgets);
    expect(find.text('Unknown series'), findsOneWidget);
    expect(find.text(historyClock(kShelfNow.subtract(const Duration(minutes: 7)))), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is SizedBox && w.width == 40 && w.child is Padding), findsWidgets);
    expect(lib.historyCalls.first, (limit: 50, offset: 0, bySeries: true));
    await t.pumpWidget(const SizedBox());
    await _pump(t, _lib(rows), size: _tablet);
    expect(find.byWidgetPredicate((w) => w is SizedBox && w.width == 56 && w.child is Padding), findsWidgets);
    expect(find.text('Continue'), findsWidgets);
  });

  testWidgets('Continue enters the reader at the saved page by Dip', (t) async {
    final rig = await _pump(t, _lib([logRow(1, 1)]));
    await t.tap(find.bySemanticsLabel('Continue at p.12'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(fullLocation(rig), '/reader/shelf/series-1/c142?page=12');
  });

  testWidgets('a finished chapter offers Next │ CH n, shows it busy while resolving, and moves on', (t) async {
    final sources = FakeSources([chapterOf(142), chapterOf(143)]);
    final rig = await _pump(t, _lib([logRow(1, 1, done: true, page: 40)]), sources: sources, size: _tablet);
    expect(find.text('Next │ CH 143'), findsOneWidget);
    await t.tap(find.text('Next │ CH 143'));
    await t.pump(const Duration(milliseconds: 20));
    expect(sources.calls, 1);
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(fullLocation(rig), '/reader/shelf/series-1/c143?page=1');
  });

  testWidgets('with no next chapter Continue falls back to the series page', (t) async {
    final sources = FakeSources([chapterOf(142)]);
    final rig = await _pump(t, _lib([logRow(1, 1, done: true, page: 40)]), sources: sources);
    await t.tap(find.bySemanticsLabel('Next, CH 143'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(fullLocation(rig), '/sources/shelf/series/series-1');
  });

  testWidgets('Load earlier appends the next 50 rows and goes away on a short page', (t) async {
    final rows = [for (var i = 1; i <= 60; i++) logRow(i, 1 + i % 6, chapter: i.toDouble(), at: kShelfNow.subtract(Duration(minutes: i)))];
    final lib = _lib(rows);
    await _pump(t, lib, size: const Size(390, 9000));
    expect(find.text('Load earlier'), findsOneWidget);
    expect(find.byType(HistoryRow), findsWidgets);
    await t.ensureVisible(find.text('Load earlier'));
    await t.tap(find.text('Load earlier'));
    await settleShelf(t, by: const Duration(milliseconds: 600));
    expect(lib.historyCalls.map((c) => c.offset), [0, 50]);
    expect(find.text('Load earlier'), findsNothing);
    expect(find.text('CH 60 · p.12 OF 40'), findsOneWidget);
  });

  testWidgets('BY CHAPTER asks for one row per chapter', (t) async {
    final lib = _lib([logRow(1, 1)]);
    await _pump(t, lib);
    await t.tap(find.text('BY CHAPTER'));
    await settleShelf(t, by: const Duration(milliseconds: 800));
    expect(lib.historyCalls.last.bySeries, isFalse);
  });

  testWidgets('the states: empty, error, offline', (t) async {
    await _pump(t, _lib(const []));
    expect(find.text('NOTHING READ YET'), findsOneWidget);
    expect(_headline('Nothing read yet.'), findsOneWidget);
    expect(find.text('Go to library'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await _pump(t, _lib(const [], fail: true));
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(_headline("History didn't load."), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await _pump(t, _lib(const [], offline: true));
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
    expect(_headline('Reading history needs a connection to load.'), findsOneWidget);
  });

  testWidgets('J moves between rows and Enter continues', (t) async {
    final rig = await _pump(t, _lib([logRow(1, 1), logRow(2, 2)]));
    await t.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(fullLocation(rig), startsWith('/reader/shelf/series-2'));
  });

  test('captions and folios', () {
    final i = logRow(1, 1, chapter: 12, page: 5, pages: 10);
    expect(historyCaption(i, novel: false), 'CH 12 · p.5 OF 10');
    expect(historyCaption(i, novel: true), 'CH 12 · 50% IN');
    expect(historyActionFolio(i, novel: false), 'p.5');
    expect(historyActionFolio(logRow(1, 1, chapter: 12, done: true), novel: false), 'CH 13');
    expect(historyClock(DateTime(2026, 9, 30, 21, 4)), '21:04');
    expect(CineButtonVariant.split, isNotNull);
  });
}
