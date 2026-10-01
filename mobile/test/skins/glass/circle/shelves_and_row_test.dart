import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/glass/parts/circle/series_circle_row.dart';
import 'package:manhwamaniacs/skins/glass/parts/collections/collection_share_sheet.dart';
import 'package:manhwamaniacs/skins/glass/parts/collections/shared_shelf_menu.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;

import '../../../features/circle/fakes.dart';
import '../../../support/test_overrides.dart' show activeProfileOverride;
import '../primitives/support.dart';

const _shelvesOn = CircleShares(activity: true, shelves: true, recommendations: true);
const _shelvesOff = CircleShares(activity: true, recommendations: true);

class _NoProgress extends SourceProgressNotifier {
  @override
  Map<String, SourceChapterProgress> build() => const {};
}

Future<FakeCircleRepository> pumpShare(WidgetTester t, {bool sharing = true, List<CircleMember>? members, bool offline = false}) async {
  final repo = FakeCircleRepository(
    membersList: members ?? const [CircleMember(profileId: 2, name: 'Aarav', shares: _shelvesOn), CircleMember(profileId: 3, name: 'Mira', shares: _shelvesOff)],
    sharingValue: Sharing(activity: sharing),
    detail: const SharedShelfDetail(shelf: SharedShelf(id: 7, name: 'Weekend reads', role: 'owner')),
  );
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(primHost(
    Navigator(onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const CollectionShareBody(collectionId: 7))),
    align: false,
    overrides: [circleRepositoryProvider.overrideWithValue(repo), activeProfileOverride(), glassOfflineProvider.overrideWithValue(offline)],
  ),);
  await pumpFor(t, 300);
  return repo;
}

void main() {
  testWidgets('the share sheet lists only members whose shelves are on and sends {profile_ids, mode}', (t) async {
    final repo = await pumpShare(t);
    expect(find.text('Aarav'), findsOneWidget);
    expect(find.text('Mira'), findsNothing);
    await t.tap(find.bySemanticsLabel('Aarav'));
    await t.tap(find.text('Can add'));
    await pumpFor(t, 200);
    await t.tap(find.text('Share'));
    await pumpFor(t, 400);
    expect(repo.log, contains('share 7 2 can_add'));
  });

  testWidgets('share sheet states: nobody accepts shelves, not sharing, offline', (t) async {
    await pumpShare(t, members: const [CircleMember(profileId: 3, name: 'Mira', shares: _shelvesOff)]);
    expect(find.text('Nobody on this server accepts shared shelves yet.'), findsOneWidget);
    await pumpShare(t, sharing: false);
    expect(find.textContaining("doesn't share yet"), findsOneWidget);
    await pumpShare(t, offline: true);
    expect(find.text('Sharing needs a connection'), findsOneWidget);
  });

  test('rights: view only has no Add, Edit, Reorder, Remove or Delete; can add adds and removes; the owner keeps the rest', () {
    const v = ShelfRights('view_only'), a = ShelfRights('can_add'), o = ShelfRights('owner');
    expect([v.canAdd, v.canEdit, v.canReorder, v.canRemove, v.canDelete], everyElement(isFalse));
    expect([v.canSaveCopy, v.canLeave], everyElement(isTrue));
    expect([a.canAdd, a.canRemove, a.canLeave], everyElement(isTrue));
    expect([a.canEdit, a.canReorder, a.canDelete], everyElement(isFalse));
    expect([o.canEdit, o.canReorder, o.canDelete, o.canShare], everyElement(isTrue));
    expect(o.canLeave, isFalse);
  });

  testWidgets('Leave shelf asks, then calls DELETE …/share/me and toasts', (t) async {
    final repo = FakeCircleRepository();
    late WidgetRef r;
    late BuildContext ctx;
    await t.pumpWidget(primHost(
      Navigator(onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => Consumer(builder: (c, ref, _) {
            r = ref;
            ctx = c;
            return const SizedBox.expand();
          },),),),
      align: false,
      overrides: [circleRepositoryProvider.overrideWithValue(repo)],
    ),);
    await pumpFor(t, 100);
    final left = leaveShelf(ctx, r, const SharedShelf(id: 7, name: 'Weekend reads', owner: ProfileRef(profileId: 2, name: 'Aarav')));
    await pumpFor(t, 500);
    expect(find.text('Leave Weekend reads?'), findsOneWidget);
    expect(find.text('It disappears from your Collections; Aarav keeps it.'), findsOneWidget);
    await t.tap(find.text('Leave'));
    await pumpFor(t, 600);
    expect(await left, isTrue);
    expect(repo.log, contains('unshare 7 me'));
  });

  testWidgets('the series Circle row: orbs, guarded reactions, and nothing at all when empty; never a hidden line', (t) async {
    Future<void> pumpRow(CircleSeriesData data) async {
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpWidget(primHost(
        const SeriesCircleRow(sourceId: 's', seriesKey: 'or'),
        overrides: [
          circleSeriesProvider.overrideWith((ref, key) async => data),
          sourceProgressProvider.overrideWith(_NoProgress.new),
        ],
      ),);
      await pumpFor(t, 300);
    }

    await pumpRow(CircleSeriesData(
      readers: const [CircleReader(member: ProfileRef(profileId: 2, name: 'Aarav'), chapterKey: 'c212')],
      chapters: [ChapterReactions(chapterKey: 'c212', chapterNumber: 212, counts: const {ReactionKind.hype: 1}, total: 1, by: [ReactionBy.of(const ProfileRef(profileId: 2, name: 'Aarav'), ReactionKind.hype)])],
    ),);
    expect(find.text('reacted to Ch 212'), findsOneWidget);
    expect(find.bySemanticsLabel('Aarav, reading this'), findsOneWidget);
    final bad = RegExp(r'hidden|18\+|mature', caseSensitive: false);
    for (final e in find.byType(Text).evaluate()) {
      expect(bad.hasMatch((e.widget as Text).data ?? ''), isFalse);
    }
    await pumpRow(const CircleSeriesData());
    expect(find.byType(Text), findsNothing);
  });
}
