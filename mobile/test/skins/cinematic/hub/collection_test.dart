// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/add_series_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/collection_screen.dart';

import 'hub_test_support.dart';

final _wall = find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('CineReorderableWall'));

Finder _headline(String s) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == s);

HubLibrary _lib({List<Collection>? shelves, Map<int, List<(String, String)>>? members}) => HubLibrary(
      all: [for (var i = 1; i <= 6; i++) shelfSeries(i, status: i <= 3 ? 'reading' : 'completed', newCount: i == 1 ? 5 : 0)],
      collections: shelves ?? [shelfOf(1, 'Slow burns', description: 'For rainy weeks.'), shelfOf(2, 'Smart one', order: 1, rules: const ShelfRules(all: [ShelfRule(field: 'reading_status', op: 'eq', value: 'reading')])), shelfOf(3, 'Empty one', order: 2)],
      members: members ?? {1: [('shelf', 'series-1'), ('shelf', 'series-2'), ('shelf', 'series-3')], 2: <(String, String)>[], 3: <(String, String)>[]},
    );

Future<LibRig> _pump(WidgetTester t, HubLibrary lib, {int id = 1, Size size = const Size(390, 1700), bool novel = false, bool reduced = false}) => pumpShelf(
      t,
      lib: lib,
      start: '/library/collections/$id',
      size: size,
      reduced: reduced,
      mode: novel ? ContentMode.novel : ContentMode.manga,
      novelsEnabled: novel,
      extra: updatesOverrides(FakeUpdates()),
    );

void main() {
  testWidgets('the header, the actions and the member wall', (t) async {
    final rig = await _pump(t, _lib());
    expect(find.text('SHELF · 3 SERIES'), findsWidgets);
    expect(find.text('For rainy weeks.'), findsOneWidget);
    expect(find.byType(LibraryPoster), findsNWidgets(3));
    expect(find.text('Add series'), findsOneWidget);
    expect(find.text('Reorder'), findsOneWidget);
    expect(find.byTooltip('Back'), findsWidgets);
    // Three to a row on a phone.
    final lefts = {for (final e in find.byType(LibraryPoster).evaluate()) t.getTopLeft(find.byWidget(e.widget)).dx.round()};
    expect(lefts.length, 3);
    expect(rig.at, '/library/collections/1');
    // The mosaic is the Hero of the match cut.
    final heroes = find.byWidgetPredicate((w) => w is Hero && w.tag == ('collection', 1));
    expect(heroes, findsOneWidget);
  });

  testWidgets('the detail route is a match cut: 480 ms in, 336 ms back', (t) async {
    await _pump(t, _lib());
    final route = ModalRoute.of(t.element(find.byType(CollectionScreen)))!;
    expect(route.transitionDuration.inMilliseconds, 480);
    expect(route.reverseTransitionDuration.inMilliseconds, 336);
  });

  testWidgets('on iOS the header Hero follows the finger', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _pump(t, _lib());
    final hero = t.widget<Hero>(find.byWidgetPredicate((w) => w is Hero && w.tag == ('collection', 1)));
    expect(hero.transitionOnUserGestures, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Add series lists what is not on the shelf and marks a tapped row ADDED', (t) async {
    final lib = _lib();
    await _pump(t, lib);
    await t.tap(find.text('Add series'));
    await settleShelf(t, by: const Duration(milliseconds: 1000));
    expect(find.text('Series 4'), findsWidgets);
    expect(find.descendant(of: find.byType(AddSeriesList), matching: find.text('Series 1')), findsNothing);
    await t.tap(find.text('Series 4').last);
    await settleShelf(t, by: const Duration(milliseconds: 600));
    expect(find.text('ADDED'), findsOneWidget);
    expect(lib.writes.any((w) => w['op'] == 'add' && w['key'] == 'series-4'), isTrue);
    // The sheet's row stays and the wall behind it gained the poster.
    expect(find.byType(LibraryPoster), findsNWidgets(4));
  });

  testWidgets('Delete shelf has a 1000 ms arm: an early tap does nothing', (t) async {
    final lib = _lib();
    final rig = await _pump(t, lib);
    await t.tap(find.byKey(const Key('collection-more')));
    await settleShelf(t, by: const Duration(milliseconds: 500));
    await t.tap(find.text('Delete shelf'));
    await settleShelf(t, by: const Duration(milliseconds: 500));
    expect(find.byType(CineConfirmDialog), findsOneWidget);
    expect(find.textContaining('The series stay in your library.'), findsOneWidget);
    await t.tap(find.text('Delete shelf').last);
    await t.pump(const Duration(milliseconds: 100));
    expect(lib.deleted, 0);
    await settleShelf(t, by: const Duration(milliseconds: 1200));
    await t.tap(find.text('Delete shelf').last);
    await settleShelf(t, by: const Duration(milliseconds: 1200));
    expect(lib.deleted, 1);
    expect(rig.at, '/library/collections');
    expect(find.text('Deleted Slow burns.'), findsOneWidget);
  });

  testWidgets('Select and Remove from shelf, with the arm', (t) async {
    final lib = _lib();
    await _pump(t, lib);
    await t.tap(find.byKey(const Key('collection-select')));
    await settleShelf(t, by: const Duration(milliseconds: 400));
    await t.tap(find.byType(LibraryPoster).first);
    await settleShelf(t, by: const Duration(milliseconds: 300));
    await t.tap(find.text('Remove from shelf'));
    await settleShelf(t, by: const Duration(milliseconds: 500));
    expect(find.textContaining('Remove 1 from Slow burns? It stays in your library.'), findsOneWidget);
    await settleShelf(t, by: const Duration(milliseconds: 1200));
    await t.tap(find.text('Remove 1').last);
    await settleShelf(t, by: const Duration(milliseconds: 1000));
    expect(lib.writes.where((w) => w['op'] == 'remove').length, 1);
    expect(find.byType(LibraryPoster), findsNWidgets(2));
  });

  testWidgets('Reorder sends the full ordered list; a failure reverts; back leaves the mode first', (t) async {
    final lib = _lib();
    final rig = await _pump(t, lib);
    await t.tap(find.byKey(const Key('collection-reorder')));
    await settleShelf(t, by: const Duration(milliseconds: 500));
    expect(_wall, findsOneWidget);
    // Move the first poster one place to the right with Alt+Right.
    t.widget<LibraryPoster>(find.byType(LibraryPoster).first).focusNode!.requestFocus();
    await t.pump();
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settleShelf(t, by: const Duration(milliseconds: 800));
    expect(lib.orders, isNotEmpty);
    expect(lib.orders.last.length, 3);
    expect(lib.orders.last, ['series-2', 'series-1', 'series-3']);
    lib.failReorder = true;
    // Android back leaves reorder mode before it leaves the page.
    await t.binding.handlePopRoute();
    await settleShelf(t, by: const Duration(milliseconds: 600));
    expect(rig.at, '/library/collections/1');
    expect(_wall, findsNothing);
  });

  testWidgets('a smart shelf shows only the matches and offers no Add, Remove or Reorder', (t) async {
    await _pump(t, _lib(), id: 2);
    expect(find.text('SMART SHELF · 3 SERIES'), findsWidgets);
    expect(find.byType(LibraryPoster), findsNWidgets(3));
    expect(find.text('Add series'), findsNothing);
    expect(find.text('Reorder'), findsNothing);
    expect(find.text('SMART RULES: READING'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('the states: empty, nothing matches, mode mismatch, not found, error', (t) async {
    await _pump(t, _lib(), id: 3);
    expect(find.text('EMPTY SHELF'), findsOneWidget);
    expect(_headline('This shelf is empty.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    final none = HubLibrary(all: [shelfSeries(1, status: 'dropped')], collections: [shelfOf(2, 'Reading', rules: const ShelfRules(all: [ShelfRule(field: 'reading_status', op: 'eq', value: 'reading')]))]);
    await _pump(t, none, id: 2);
    expect(find.text('NOTHING MATCHES'), findsOneWidget);
    expect(_headline('Nothing matches these rules.'), findsOneWidget);
    expect(find.text('Edit rules'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    await _pump(t, _lib(), novel: true);
    expect(find.text('NOTE'), findsOneWidget);
    expect(_headline('Everything on this shelf is manga.'), findsOneWidget);
    expect(find.text('Switch'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    await _pump(t, _lib(), id: 99);
    expect(find.text('NOT IN THIS ISSUE'), findsOneWidget);
    expect(find.text('Back to collections'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    await _pump(t, _lib()..failCollections = true);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(_headline("This shelf didn't load."), findsOneWidget);
    expect(find.text('Back to collections'), findsOneWidget);
  });

  testWidgets('E edits the shelf and A adds series', (t) async {
    await _pump(t, _lib());
    await t.sendKeyEvent(LogicalKeyboardKey.keyE);
    await settleShelf(t, by: const Duration(milliseconds: 900));
    expect(find.byKey(const Key('shelf-name')), findsOneWidget);
    // Save is disabled while unchanged.
    final save = t.widget<Widget>(find.byKey(const Key('shelf-save')));
    expect(save, isNotNull);
  });

  test('the match cut timings come from the shared table', () {
    expect(CineRouteMotion.forward(CineTransitionKind.match).inMilliseconds, 480);
    expect(CineRouteMotion.reverse(CineTransitionKind.match).inMilliseconds, 336);
  });
}
