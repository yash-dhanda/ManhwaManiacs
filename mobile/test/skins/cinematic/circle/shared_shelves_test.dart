// ignore_for_file: directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_collection_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';

import '../../../features/circle/fakes.dart';
import '../hub/hub_test_support.dart';

const _riyaRef = ProfileRef(profileId: 2, name: 'Riya', avatarKey: 'rose');

SharedShelf _mine(int id, {String name = 'Slow burns'}) => SharedShelf(
      id: id,
      name: name,
      seriesCount: 3,
      role: 'owner',
      shared: const SharedShelfInfo(ownerProfileId: 1, mode: 'can_add', memberProfileIds: [2], members: [_riyaRef]),
    );

SharedShelf _theirs(int id, String role, {String name = 'Riya picks'}) => SharedShelf(id: id, name: name, seriesCount: 2, owner: _riyaRef, role: role);

SharedShelfDetail _detail(SharedShelf s) => SharedShelfDetail(
      shelf: s,
      series: [
        const ShelfSeriesRow(sourceId: 'shelf', seriesKey: 'series-1', title: 'Tower of God', addedByProfileId: 2, addedBy: _riyaRef),
        const ShelfSeriesRow(sourceId: 'shelf', seriesKey: 'series-2', title: 'Solo Leveling', addedByProfileId: 1),
      ],
    );

Future<(LibRig, FakeCircleRepository)> _pump(WidgetTester t, {List<SharedShelf> mine = const [], List<SharedShelf> withMe = const [], SharedShelfDetail? detail, bool sharing = true, String start = '/library/collections', Size size = const Size(390, 1600)}) async {
  final repo = FakeCircleRepository(
    membersList: [member(riya, canReceive: true)],
    shared: (collections: mine, sharedWithMe: withMe),
    detail: detail,
    sharingValue: Sharing(activity: sharing),
  );
  final lib = HubLibrary(
    all: [for (var i = 1; i <= 3; i++) shelfSeries(i)],
    collections: [shelfOf(1, 'Slow burns', at: DateTime.utc(2026)), shelfOf(2, 'Night reads', order: 1, at: DateTime.utc(2026, 3))],
    members: {
      1: [('shelf', 'series-1')],
      2: <(String, String)>[],
    },
  );
  final rig = await pumpShelf(t, lib: lib, start: start, size: size, extra: [circleRepositoryProvider.overrideWithValue(repo), ...updatesOverrides(FakeUpdates())]);
  return (rig, repo);
}

void main() {
  testWidgets('shared plates carry SHARED and avatars; SHARED WITH YOU lists shelves with their role; the deck counts them', (t) async {
    await _pump(t, mine: [_mine(1)], withMe: [_theirs(9, 'can_add')]);
    expect(find.text('SHARED'), findsWidgets);
    expect(find.text('SHARED WITH YOU'), findsOneWidget);
    expect(find.textContaining('CAN ADD'), findsOneWidget);
    expect(find.textContaining('2 shelves · 1 shared · 1 shared with you', findRichText: true), findsWidgets);
    final plates = t.widgetList<CineCollectionPlate>(find.byType(CineCollectionPlate)).toList();
    expect(plates.where((p) => p.sharedWith.isNotEmpty && p.badges.isNotEmpty), hasLength(1));
  });

  testWidgets('a can_add shelf renders from its own snapshot and shows only what the role allows', (t) async {
    final shelf = _theirs(9, 'can_add');
    await _pump(t, withMe: [shelf], detail: _detail(shelf));
    await t.tap(find.text('Riya picks'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(find.text('Tower of God'), findsOneWidget);
    expect(find.text('Solo Leveling'), findsOneWidget);
    expect(find.textContaining('NO LONGER FOLLOWED'), findsNothing);
    expect(find.text('Add series'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Reorder'), findsNothing);
    expect(find.text('Share'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Added by Riya')), findsOneWidget);
  });

  testWidgets('a view_only shelf hides Add series', (t) async {
    final shelf = _theirs(9, 'view_only');
    await _pump(t, withMe: [shelf], detail: _detail(shelf));
    await t.tap(find.text('Riya picks'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(find.text('Add series'), findsNothing);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('Leave shelf asks with the 1000 ms arm, then leaves', (t) async {
    final shelf = _theirs(9, 'can_add');
    final (rig, repo) = await _pump(t, withMe: [shelf], detail: _detail(shelf));
    await t.tap(find.text('Riya picks'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    await t.tap(find.byKey(const Key('shared-more')));
    await settleShelf(t, by: const Duration(milliseconds: 400));
    await t.tap(find.text('Leave shelf'));
    await settleShelf(t, by: const Duration(milliseconds: 400));
    expect(find.textContaining('Leave Riya picks? It disappears from your Collections.'), findsOneWidget);
    // Dead while armed.
    await t.tap(find.widgetWithText(CineButton, 'Leave shelf').last);
    await settleShelf(t, by: const Duration(milliseconds: 100));
    expect(repo.log.where((e) => e.startsWith('unshare')), isEmpty);
    await settleShelf(t, by: const Duration(milliseconds: 1200));
    await t.tap(find.widgetWithText(CineButton, 'Leave shelf').last);
    await settleShelf(t, by: const Duration(milliseconds: 1200));
    expect(repo.log, contains('unshare 9 me'));
    expect(find.text('Left Riya picks.'), findsOneWidget);
    expect(rig.at, '/library/collections');
  });

  testWidgets('the owner shares: members who take shelves, the mode, Save; an empty selection unshares', (t) async {
    final (_, repo) = await _pump(t, mine: [_mine(1)], detail: _detail(_mine(1)));
    await t.tap(find.text('Slow burns'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(find.byKey(const Key('collection-share')), findsOneWidget);
    await t.tap(find.byKey(const Key('collection-share')));
    await settleShelf(t, by: const Duration(milliseconds: 700));
    expect(find.text('SHARE SHELF'), findsWidgets);
    await t.tap(find.text('VIEW ONLY'));
    await settleShelf(t, by: const Duration(milliseconds: 400));
    await t.tap(find.byKey(const Key('share-save')));
    await settleShelf(t, by: const Duration(milliseconds: 600));
    expect(repo.log, contains('share 1 2 view_only'));
  });

  testWidgets('sharing off: Share leaves the action row and the overflow explains', (t) async {
    await _pump(t, mine: [_mine(1)], detail: _detail(_mine(1)), sharing: false);
    await t.tap(find.text('Slow burns'));
    await settleShelf(t, by: const Duration(milliseconds: 1400));
    expect(find.byKey(const Key('collection-share')), findsNothing);
    await t.tap(find.byKey(const Key('collection-more')));
    await settleShelf(t, by: const Duration(milliseconds: 400));
    expect(find.text('Share…'), findsOneWidget);
  });

  testWidgets('New shelf from the Circle opens the form with Share with the circle on', (t) async {
    await _pump(t, start: '/library/collections?sheet=collection-new&view=shared');
    await settleShelf(t, by: const Duration(milliseconds: 900));
    expect(find.text('Share with the circle'), findsWidgets);
  });
}
