// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_collection_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/rule_chips.dart';

import 'hub_test_support.dart';

const _tablet = Size(834, 1194);

HubLibrary _lib({List<Collection>? shelves, Map<int, List<(String, String)>>? members}) => HubLibrary(
      all: [
        for (var i = 1; i <= 6; i++) shelfSeries(i, status: i <= 3 ? 'reading' : 'completed', newCount: i == 1 ? 5 : (i == 2 ? 3 : 0)),
      ],
      collections: shelves ?? [shelfOf(1, 'Slow burns', at: DateTime.utc(2026)), shelfOf(2, 'Night reads', order: 1, at: DateTime.utc(2026, 3)), shelfOf(3, 'Unread pile', order: 2, at: DateTime.utc(2026, 2))],
      members: members ?? {
        1: [('shelf', 'series-1'), ('shelf', 'series-2'), ('shelf', 'series-3')],
        2: [('shelf', 'series-4')],
        3: <(String, String)>[],
      },
    );

Future<LibRig> _pump(WidgetTester t, HubLibrary lib, {String start = '/library/collections', Size size = const Size(390, 1600), bool reduced = false, TargetPlatform platform = TargetPlatform.android, Map<String, Object> prefs = const {}}) =>
    pumpShelf(t, lib: lib, start: start, size: size, reduced: reduced, platform: platform, prefs: prefs, extra: updatesOverrides(FakeUpdates()));

Finder _headline(String s) => find.byWidgetPredicate((w) => w is TypedHeadline && w.text == s);

void main() {
  testWidgets('shows a 16:9 plate per shelf with its credit; no back arrow on the hub tab', (t) async {
    final rig = await _pump(t, _lib());
    expect(find.byType(CineCollectionPlate), findsNWidgets(3));
    final size = t.getSize(find.byType(CineCollectionPlate).first);
    expect((size.width / size.height * 100).round(), 178);
    expect(find.text('3 SERIES'), findsOneWidget);
    expect(find.text('9 shelves').evaluate().isEmpty && find.textContaining('3 shelves').evaluate().isNotEmpty, isTrue);
    expect(rig.at, '/library/collections');
    expect(find.bySemanticsLabel('Back'), findsNothing);
  });

  testWidgets('Recently created orders by createdAt, newest first', (t) async {
    await _pump(t, _lib(), prefs: {'mm.collections.sort.u1p1': 'recentlyCreated'});
    final names = [for (final e in find.byType(CineCollectionPlate).evaluate()) (e.widget as CineCollectionPlate).name];
    expect(names, ['Night reads', 'Unread pile', 'Slow burns']);
  });

  testWidgets('tapping a plate pushes the detail with a back arrow', (t) async {
    final rig = await _pump(t, _lib());
    await t.tap(find.text('Slow burns'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(rig.at, '/library/collections/1');
    expect(find.text('Add series'), findsOneWidget);
    expect(find.text('SHELF · 3 SERIES'), findsWidgets);
    await t.tap(find.byTooltip('Back').first);
    await settleShelf(t);
    expect(rig.at, '/library/collections');
  });

  testWidgets('phones list one plate per row, tablets two', (t) async {
    await _pump(t, _lib());
    final phone = {for (final e in find.byType(CineCollectionPlate).evaluate()) t.getTopLeft(find.byWidget(e.widget)).dx.round()};
    expect(phone.length, 1);
    await t.pumpWidget(const SizedBox());
    await _pump(t, _lib(), size: _tablet);
    final tab = {for (final e in find.byType(CineCollectionPlate).evaluate()) t.getTopLeft(find.byWidget(e.widget)).dx.round()};
    expect(tab.length, 2);
  });

  testWidgets('New shelf: a smart shelf with status READING and 3+ new sends the rules, and its page shows exactly the matches', (t) async {
    final lib = _lib();
    final rig = await _pump(t, lib);
    await t.tap(find.text('New shelf'));
    await settleShelf(t, by: const Duration(milliseconds: 900));
    await t.enterText(find.byKey(const Key('shelf-name')), 'Hot right now');
    await t.tap(find.byType(CineSwitch).first);
    await settleShelf(t, by: const Duration(milliseconds: 500));
    expect(find.byKey(const Key('rule-chips')), findsOneWidget);
    // Status is READING.
    await t.tap(find.text('STATUS IS'));
    await settleShelf(t, by: const Duration(milliseconds: 700));
    await t.tap(find.text('READING').last);
    await settleShelf(t, by: const Duration(milliseconds: 700));
    // New chapters at least 3.
    await t.tap(find.bySemanticsLabel('Filter by new chapters'));
    await settleShelf(t, by: const Duration(milliseconds: 500));
    await t.tap(find.byKey(const Key('shelf-save')));
    await settleShelf(t, by: const Duration(milliseconds: 900));
    final create = lib.writes.firstWhere((w) => w['op'] == 'create');
    expect(create['rules'], {
      'all': [
        {'field': 'reading_status', 'op': 'eq', 'value': 'reading'},
        {'field': 'new_count', 'op': 'gte', 'value': 3},
      ],
    });
    expect(find.text('Hot right now'), findsWidgets);
    await t.tap(find.text('Hot right now').first);
    await settleShelf(t);
    expect(rig.at, startsWith('/library/collections/'));
    // Series 1 and 2 match; no Add, Reorder.
    expect(find.byType(LibraryPoster), findsNWidgets(2));
    expect(find.text('Add series'), findsNothing);
    expect(find.text('Reorder'), findsNothing);
    expect(find.text('SMART RULES: READING · 3+ NEW'), findsOneWidget);
    // Editing the rules updates the wall live.
    await t.tap(find.text('Edit'));
    await settleShelf(t, by: const Duration(milliseconds: 900));
    expect(find.byKey(const Key('shelf-save')), findsOneWidget);
  });

  testWidgets('a duplicate name shows under the field', (t) async {
    final lib = _lib();
    await _pump(t, lib);
    await t.tap(find.text('New shelf'));
    await settleShelf(t, by: const Duration(milliseconds: 900));
    await t.enterText(find.byKey(const Key('shelf-name')), 'Slow burns');
    await t.tap(find.byKey(const Key('shelf-save')));
    await settleShelf(t, by: const Duration(milliseconds: 600));
    expect(find.textContaining('A shelf with that name already exists.'), findsOneWidget);
  });

  testWidgets('Custom order writes only the changed sort_order values; Alt+arrow announces; failure reverts', (t) async {
    final lib = _lib();
    await _pump(t, lib, prefs: {'mm.collections.sort.u1p1': 'custom'});
    final plates = find.byType(CineCollectionPlate);
    expect([for (final e in plates.evaluate()) (e.widget as CineCollectionPlate).name], ['Slow burns', 'Night reads', 'Unread pile']);
    // Focus the first plate and move it down with Alt+Down.
    await t.tap(find.byTooltip('More actions').first);
    await settleShelf(t, by: const Duration(milliseconds: 600));
    await t.tap(find.text('Move down'));
    await settleShelf(t, by: const Duration(milliseconds: 900));
    final writes = lib.writes.where((w) => w['op'] == 'update' && w['sort_order'] != null).map((w) => (w['id'], w['sort_order'])).toSet();
    expect(writes, {(2, 0), (1, 1)});
    expect([for (final e in find.byType(CineCollectionPlate).evaluate()) (e.widget as CineCollectionPlate).name], ['Night reads', 'Slow burns', 'Unread pile']);

    lib.failSortWrites = true;
    await t.tap(find.byTooltip('More actions').first);
    await settleShelf(t, by: const Duration(milliseconds: 600));
    await t.tap(find.text('Move to bottom'));
    await settleShelf(t, by: const Duration(milliseconds: 900));
    expect(find.text("Couldn't save the order."), findsOneWidget);
    expect([for (final e in find.byType(CineCollectionPlate).evaluate()) (e.widget as CineCollectionPlate).name], ['Night reads', 'Slow burns', 'Unread pile']);
  });

  testWidgets('the states: empty, no match, error, offline', (t) async {
    await _pump(t, _lib(shelves: []));
    expect(find.text('NO SHELVES YET'), findsOneWidget);
    expect(_headline('No shelves yet.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    await _pump(t, _lib());
    await t.tap(find.byTooltip('Search shelves'));
    await settleShelf(t, by: const Duration(milliseconds: 600));
    await t.enterText(find.byType(EditableText).first, 'zzz');
    await settleShelf(t, by: const Duration(milliseconds: 500));
    expect(find.text('NOTHING MATCHES'), findsOneWidget);
    expect(_headline('No shelves match that.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    await _pump(t, _lib()..failCollections = true);
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(_headline("Collections didn't load."), findsOneWidget);
    await t.pumpWidget(const SizedBox());

    await _pump(t, _lib()..offlineCollections = true);
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
    expect(_headline('Collections need a connection to load.'), findsOneWidget);
  });

  testWidgets('hardware key N opens the New shelf form', (t) async {
    await _pump(t, _lib());
    await t.sendKeyEvent(LogicalKeyboardKey.keyN);
    await settleShelf(t, by: const Duration(milliseconds: 900));
    expect(find.byKey(const Key('shelf-name')), findsOneWidget);
  });

  test('rule drafts round trip through rules', () {
    const d = RuleDraft(status: 'reading', favourite: true, newCount: 3, formats: {'manga', 'manhwa'}, unfinished: true);
    final rules = d.toRules()!;
    expect(describeRules(rules), 'READING · FAVOURITES · 3+ NEW · MANHWA, MANGA · UNFINISHED NOVELS');
    final back = RuleDraft.from(rules);
    expect((back.status, back.favourite, back.newCount, back.unfinished), ('reading', true, 3, true));
    expect(back.formats, {'manga', 'manhwa'});
    expect(const RuleDraft().toRules(), isNull);
  });
}
