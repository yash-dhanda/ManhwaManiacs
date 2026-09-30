// ignore_for_file: require_trailing_commas, directives_ordering, avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/chapter_reaction_folio.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/pass_it_on_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/react_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/reaction_stamps.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/share_shelf_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid_overlay.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/shared_shelf_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/circle_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/circle_tab.dart' as reader;
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/schedule_row.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_reader_view.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'dart:convert';

import '../skins/cinematic/circle/circle_harness.dart' hide loadAppFonts, settle;
import '../skins/cinematic/hub/hub_test_support.dart' show HubLibrary, shelfOf, FakeUpdates, updatesOverrides;
import '../skins/cinematic/library/library_test_support.dart' show ShelfLibrary, shelfSeries, pumpShelf;
import '../skins/cinematic/reader/reader_test_support.dart' show pumpReader, settleReader, disposeReader;
import '../skins/cinematic/settings/settings_rig.dart' show pumpSettings;
import '../skins/cinematic/tonight/tonight_test_support.dart' show pumpTonight, settleTonight;
import 'support/series_shots.dart';
import 'support/shot_covers.dart';
import 'support/shot_network.dart';
import '../support/test_overrides.dart' show apiBaseUrlOverride;
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'support/skin_shots.dart';

const _titles = {
  'or': 'Omniscient Reader',
  'tog': 'Tower of God',
  'sl': 'Solo Leveling',
  'tbate': 'The Lantern Courier',
  'nl': 'Night Ledger',
  'ms': 'Moonlit Bakery',
};

String _cover(String key) => '/sources/s/series/$key/cover';

const _rose = ProfileRef(profileId: 2, name: 'Riya', avatarKey: 'rose', username: 'riya');
const _blade = ProfileRef(profileId: 3, name: 'Arjun', avatarKey: 'blade', username: 'arjun');
const _star = ProfileRef(profileId: 4, name: 'Mei', avatarKey: 'star', username: 'mei');
const _duo = Ambient(duo: Color(0xFF7AB88C), tint: Color(0xFF0A140D), ink: Color(0xFFA8E9BA));
final _now = DateTime.now().toUtc();

FeedItem _f(String id, FeedKind kind, ProfileRef actor, String key, {double? n, ReactionKind? r, bool? sealed, bool followed = false, Duration ago = const Duration(hours: 2)}) => FeedItem(
      id: id,
      kind: kind,
      actor: actor,
      sourceId: 's',
      seriesKey: key,
      title: _titles[key]!,
      coverUrl: _cover(key),
      ambient: _duo,
      chapterKey: n == null ? null : 'c${n.toInt()}',
      chapterNumber: n,
      reaction: r,
      sealed: sealed,
      followedByViewer: followed,
      createdAt: _now.subtract(ago),
    );

Letter _l(int id, ProfileRef from, String key, {String? note = "you'll love the tower arc.", LetterState state = LetterState.newLetter}) =>
    Letter(id: id, from: from, sourceId: 's', seriesKey: key, title: _titles[key]!, coverUrl: _cover(key), ambient: _duo, note: note, state: state, createdAt: _now.subtract(Duration(hours: id)));

List<FeedItem> _feed() => [
      _f('1', FeedKind.finishedChapter, _rose, 'or', n: 142, ago: const Duration(hours: 2)),
      _f('2', FeedKind.started, _blade, 'sl', followed: true, ago: const Duration(hours: 5)),
      _f('3', FeedKind.reacted, _rose, 'tog', n: 12, r: ReactionKind.loved, sealed: true, ago: const Duration(hours: 7)),
      _f('4', FeedKind.reacted, _star, 'or', n: 140, r: ReactionKind.chefsKiss, sealed: false, ago: const Duration(days: 1, hours: 1)),
      _f('5', FeedKind.finishedSeries, _blade, 'nl', ago: const Duration(days: 1, hours: 3)),
      _f('6', FeedKind.started, _star, 'ms', ago: const Duration(days: 3)),
    ];

List<CircleMember> _members({bool now = true}) => [
      CircleMember(profileId: 2, name: 'Riya', avatarKey: 'rose', username: 'riya', shares: const CircleShares(activity: true, reactions: true, shelves: true, recommendations: true), canReceive: true, now: now ? const CircleNow(sourceId: 's', seriesKey: 'or', chapterKey: 'c212', chapterNumber: 212, title: 'Omniscient Reader', ambient: _duo) : null),
      const CircleMember(profileId: 3, name: 'Arjun', avatarKey: 'blade', username: 'arjun', shares: CircleShares(activity: true, reactions: true, shelves: true, recommendations: true), canReceive: true),
      const CircleMember(profileId: 4, name: 'Mei', avatarKey: 'star', username: 'mei', shares: CircleShares(activity: true, reactions: true, shelves: true, recommendations: true), canReceive: true),
    ];

SharedShelf _shelf(int id, String name, {String role = 'owner', bool mine = false}) => SharedShelf(
      id: id,
      name: name,
      seriesCount: 4,
      previewCovers: [for (final k in ['or', 'tog', 'sl', 'nl']) _cover(k)],
      role: role,
      owner: mine ? null : _rose,
      shared: mine ? const SharedShelfInfo(ownerProfileId: 1, mode: 'can_add', memberProfileIds: [2, 3], members: [_rose, _blade]) : null,
    );

FakeCircleRepository _repo({bool now = true, bool letters = true, bool shelves = true, bool sharing = true, List<CircleMember>? members, List<FeedItem>? feed}) => FakeCircleRepository(
      membersList: members ?? _members(now: now),
      feedItems: feed ?? _feed(),
      letterList: letters ? [_l(1, _rose, 'tog'), _l(2, _blade, 'sl', note: 'the first arc is a masterclass.'), _l(3, _star, 'nl', state: LetterState.kept)] : const [],
      sharingValue: Sharing(activity: sharing),
      shared: shelves ? (collections: [_shelf(1, 'Slow burns', mine: true)], sharedWithMe: [_shelf(9, 'Riya picks', role: 'can_add'), _shelf(10, 'Night reads', role: 'view_only')]) : (collections: <SharedShelf>[], sharedWithMe: <SharedShelf>[]),
      memberPage: MemberPage(
        profile: _rose,
        shares: const CircleShares(activity: true, reactions: true, shelves: true, recommendations: true),
        now: const CircleNow(sourceId: 's', seriesKey: 'or', chapterKey: 'c212', chapterNumber: 212, title: 'Omniscient Reader', ambient: _duo),
        reading: [for (final k in ['or', 'tog', 'sl', 'nl']) MemberSeries(sourceId: 's', seriesKey: k, title: _titles[k]!, coverUrl: _cover(k), ambient: _duo, chapterNumber: 100)],
        finished: [MemberSeries(sourceId: 's', seriesKey: 'ms', title: _titles['ms']!, coverUrl: _cover('ms'), ambient: _duo)],
        reactions: [
          MemberSeries(sourceId: 's', seriesKey: 'or', chapterKey: 'c212', title: _titles['or']!, coverUrl: _cover('or'), ambient: _duo, chapterNumber: 212, reaction: ReactionKind.loved, sealed: true),
          MemberSeries(sourceId: 's', seriesKey: 'sl', chapterKey: 'c1', title: _titles['sl']!, coverUrl: _cover('sl'), ambient: _duo, chapterNumber: 1, reaction: ReactionKind.tears, sealed: false),
        ],
        shelves: [_shelf(9, 'Riya picks', role: 'can_add')],
      ),
      seriesData: CircleSeriesData(
        followers: const [_rose, _blade],
        readers: [const CircleReader(member: _star, chapterKey: 'c150', chapterNumber: 150)],
        chapters: [_chapter('c142', 142, sealed: true), _chapter('c141', 141, sealed: false)],
      ),
      reactionList: [_chapter('c142', 142, sealed: true), _chapter('c141', 141, sealed: false)],
      detail: SharedShelfDetail(
        shelf: _shelf(9, 'Riya picks', role: 'can_add'),
        series: [
          for (final (i, k) in ['or', 'tog', 'sl', 'nl', 'ms'].indexed)
            ShelfSeriesRow(sourceId: 's', seriesKey: k, title: _titles[k]!, coverUrl: _cover(k), ambient: _duo, addedByProfileId: i.isEven ? 2 : 1, addedBy: i.isEven ? _rose : null),
        ],
      ),
    );

ChapterReactions _chapter(String key, double n, {bool sealed = true, ReactionKind? mine}) => ChapterReactions(
      chapterKey: key,
      chapterNumber: n,
      counts: {for (final k in ReactionKind.values) k: k == ReactionKind.loved ? 2 : (k == ReactionKind.tears ? 1 : 0)},
      total: 3,
      by: [ReactionBy.of(_rose, ReactionKind.loved), ReactionBy.of(_blade, ReactionKind.loved), ReactionBy.of(_star, ReactionKind.tears)],
      mine: mine,
      sealed: sealed,
    );

/// The mobile-22 proof shots: the Circle screen and every state, reactions and the spoiler guard,
/// Pass it on, letters, shared shelves, the member page, Settings and Tonight. Invented fixtures.
void mobile22Shots() {
  Future<void> covers(WidgetTester t) async {
    final png = <String, Uint8List>{};
    var i = 0;
    for (final k in _titles.keys) {
      png[_cover(k)] = (await t.runAsync(() => ShotCoverArt(title: _titles[k]!, seed: i++).toPng()))!;
    }
    addShotCovers(png);
  }

  Future<void> load(WidgetTester t, {int ms = 2600}) async {
    await pumpMs(t, ms);
    await pumpUntilCoversLoad(t, rounds: 8);
    await pumpMs(t, 300);
  }

  /// Circle screens through the harness router.
  Future<void> shot(
    WidgetTester t,
    String name, {
    FakeCircleRepository Function()? repo,
    String route = '/circle',
    Widget? screen,
    bool phone = true,
    bool tablet = true,
    bool wide = false,
    bool reduced = false,
    double textScale = 1,
    int ms = 2600,
    List<Override> extra = const [],
    Future<void> Function(WidgetTester t, bool wide)? drive,
  }) async {
    await covers(t);
    final sizes = [if (phone) (kSkinShotSizes[0], false), if (tablet) (kSkinShotSizes[1], true), if (wide) (kSkinShotTabletWide, true)];
    for (final (size, isWide) in sizes) {
      await pumpCine(
        t,
        CineTestEnv(),
        router: circleRouter(initial: route, screen: screen),
        size: size.logical,
        padding: size.padding,
        reduced: reduced,
        textScale: textScale,
        boundaryKey: kSkinShotKey,
        extra: [
          apiBaseUrlOverride('http://example.test'),
          circleRepositoryProvider.overrideWithValue((repo ?? _repo)()),
          libraryRepositoryProvider.overrideWithValue(ShelfLibrary(all: [for (var i = 1; i <= 4; i++) shelfSeries(i)])),
          ...extra,
        ],
      );
      await load(t, ms: ms);
      if (drive != null) await drive(t, isWide);
      await captureSeriesShot(t, name, size);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 3));
    }
  }

  Future<void> open(WidgetTester t, String label) async {
    await t.tap(find.text(label).first);
    await pumpMs(t, 900);
  }

  // ---- The Circle screen ---------------------------------------------------------------------------
  testWidgets('mobile-22 circle tabs', (t) async {
    await shot(t, 'circle-all');
    await shot(t, 'circle-reading', route: '/circle?tab=reading');
    await shot(t, 'circle-reactions', route: '/circle?tab=reactions');
    await shot(t, 'circle-letters', route: '/circle?tab=letters');
    await shot(t, 'circle-shelves', route: '/circle?tab=shelves');
    await shot(t, 'circle-aside', phone: false, tablet: false, wide: true);
    await shot(t, 'circle-grid', screen: Stack(children: [const CircleScreen(), Consumer(builder: (c, ref, _) => const IgnorePointer(child: CineGridOverlay()))]), extra: [layoutGridOverlayOn]);
  });

  testWidgets('mobile-22 circle states', (t) async {
    await shot(t, 'circle-ring-tooltip', tablet: false, drive: (t, w) async {
      await t.longPress(find.text('Riya').first);
      await pumpMs(t, 800);
    });
    await shot(t, 'circle-quiet', tablet: false, repo: () => FakeCircleRepository(sharingValue: const Sharing()));
    await shot(t, 'circle-private-banner', tablet: false, repo: () => _repo(sharing: false));
    await shot(t, 'circle-only-me', tablet: false, repo: () => FakeCircleRepository(sharingValue: const Sharing(activity: true)));
    await shot(t, 'circle-loading', tablet: false, ms: 250, extra: [circleMembersProvider.overrideWith(_NeverMembers.new)]);
    await shot(t, 'circle-offline', tablet: false, extra: [deviceOnlineOverride(false)], route: '/circle?tab=letters');
    await shot(t, 'circle-error', tablet: false, repo: () => FakeCircleRepository()..failWith = const ApiError(statusCode: 500, code: 'x', message: 'x'));
    await shot(t, 'letter-unfold', tablet: false, route: '/circle?tab=letters', ms: 0, drive: (t, w) async {
      await pumpMs(t, 240);
    });
    await shot(t, 'reduced-motion-circle', tablet: false, reduced: true, route: '/circle?tab=letters');
    await shot(t, 'text-scale-2-circle', tablet: false, textScale: 2);
  });

  // ---- Member page ---------------------------------------------------------------------------------
  testWidgets('mobile-22 member', (t) async {
    await shot(t, 'member', route: '/circle/2', ms: 3200);
    await shot(t, 'member-not-sharing', tablet: false, route: '/circle/2', repo: () => FakeCircleRepository(membersList: _members()));
  });

  // ---- Series page CIRCLE tab, schedule rows -------------------------------------------------------
  Widget panel(Widget child) => Builder(
        builder: (c) => Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child))),
      );

  testWidgets('mobile-22 series circle', (t) async {
    await shot(t, 'feature-circle-tab', screen: panel(const FeatureCircleContent(sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader')));
    await shot(t, 'schedule-row-reactions', tablet: false, screen: panel(Column(children: [
      for (final n in [142, 141, 140])
        ScheduleRow(
          chapter: SourceChapterSummary(id: 'c$n', sourceId: 's', seriesId: 'or', title: 'Chapter $n', number: n.toDouble(), pageCount: 30),
          progress: null,
          downloadState: null,
          selecting: false,
          selected: false,
          current: false,
          highlighted: false,
          onTap: () {},
          onLongPress: () {},
          onMenu: () {},
          reactionSlot: ChapterReactionFolio(sourceId: 's', seriesKey: 'or', chapterKey: 'c$n', chapterNumber: n.toDouble()),
        ),
    ],),),);
  });

  // ---- Stamps, guard, sheets -----------------------------------------------------------------------
  testWidgets('mobile-22 stamps and sheets', (t) async {
    await shot(t, 'stamps-credits-guarded', tablet: false, screen: panel(const ReactionStamps(sourceId: 's', seriesKey: 'or', chapterKey: 'c142', chapterNumber: 142)));
    await shot(t, 'reader-circle-tab-guarded', tablet: false, screen: const Scaffold(body: SafeArea(child: reader.CircleTab(sourceId: 's', seriesKey: 'or', chapterKey: 'c142', chapterNumber: 142, completedOpen: false))));
    await shot(t, 'reader-circle-tab-unsealed', tablet: false, screen: const Scaffold(body: SafeArea(child: reader.CircleTab(sourceId: 's', seriesKey: 'or', chapterKey: 'c141', chapterNumber: 141, completedOpen: true))));
    Widget opener(void Function(BuildContext) f) => Scaffold(body: Center(child: Builder(builder: (c) => TextButton(onPressed: () => f(c), child: const Text('OPEN')))));
    await shot(t, 'react-sheet', tablet: false, screen: opener((c) => showReactSheet(c, sourceId: 's', seriesKey: 'or', chapterKey: 'c142', chapterNumber: 142)), drive: (t, w) => open(t, 'OPEN'));
    await shot(t, 'pass-it-on', screen: opener((c) => showPassItOnSheet(c, sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader', coverUrl: _cover('or'))), drive: (t, w) async {
      await open(t, 'OPEN');
      await t.tap(find.byKey(const ValueKey('recipient-2')));
      await t.enterText(find.byType(TextField), "you'll love the tower arc.");
      await pumpMs(t, 500);
    });
    await shot(t, 'pass-it-on-nobody', tablet: false, repo: () => _repo(members: [member(_rose, canReceive: false)]), screen: opener((c) => showPassItOnSheet(c, sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader')), drive: (t, w) => open(t, 'OPEN'));
    await shot(t, 'shelf-share-sheet', tablet: false, screen: opener((c) => showShareShelfSheet(c, collectionId: 1, name: 'Slow burns', current: _shelf(1, 'Slow burns', mine: true).shared)), drive: (t, w) => open(t, 'OPEN'));
  });

  testWidgets('mobile-22 shared shelf view', (t) async {
    SharedShelfDetail d() => _repo().detail!;
    await shot(t, 'shelf-member-view', tablet: false, screen: SharedShelfView(detail: d()));
    await shot(t, 'leave-shelf-arming', tablet: false, screen: SharedShelfView(detail: d()), drive: (t, w) async {
      await t.tap(find.byKey(const Key('shared-more')));
      await pumpMs(t, 500);
      await t.tap(find.text('Leave shelf'));
      await pumpMs(t, 450);
    });
  });

  // ---- Real-router pages ---------------------------------------------------------------------------
  testWidgets('mobile-22 collections shared', (t) async {
    await covers(t);
    for (final (size, w) in [(kSkinShotSizes[0], false), (kSkinShotSizes[1], true)]) {
      await pumpShelf(
        t,
        lib: HubLibrary(
          all: [for (var i = 1; i <= 6; i++) shelfSeries(i)],
          collections: [shelfOf(1, 'Slow burns', at: DateTime.utc(2026), description: 'Long arcs for rainy weeks.'), shelfOf(2, 'Night reads', order: 1, at: DateTime.utc(2026, 3))],
          members: {1: [('shelf', 'series-1')], 2: <(String, String)>[]},
        ),
        start: '/library/collections',
        size: size.logical,
        boundaryKey: kSkinShotKey,
        extra: [circleRepositoryProvider.overrideWithValue(_repo()), ...updatesOverrides(FakeUpdates())],
      );
      await load(t);
      await captureSeriesShot(t, 'collections-shared', size);
      await t.pumpWidget(const SizedBox());
      if (w) await t.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('mobile-22 settings circle', (t) async {
    for (final size in kSkinShotSizes) {
      await pumpSettings(
        t,
        path: '/settings/circle',
        size: size.logical,
        boundaryKey: kSkinShotKey,
        more: [
          circleRepositoryProvider.overrideWithValue(_repo()),
          matureGateOpenProvider.overrideWithValue(true),
          readingHistoryProvider.overrideWith((ref) async => [const ReadingHistoryItem(id: 1, sourceId: 's', seriesKey: 'or', chapterKey: 'c142', chapterNumber: 142, lastPage: 10, pageCount: 10, isCompleted: true, seriesTitle: 'Omniscient Reader')]),
        ],
      );
      await pumpMs(t, 3600);
      await captureSeriesShot(t, 'settings-circle', size);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('mobile-22 tonight circle sections', (t) async {
    await covers(t);
    for (final (size, w) in [(kSkinShotSizes[0], false), (kSkinShotSizes[1], true)]) {
      await pumpTonight(t, feed: 'circle', size: size.logical, wide: w, boundaryKey: kSkinShotKey, prefs: {'mm.tonight.typed.u1p1': '{"date":"2026-09-30","variant":"normal"}'}, extra: [circleRepositoryProvider.overrideWithValue(_repo())]);
      await settleTonight(t, by: const Duration(seconds: 3));
      final target = find.text('Sent to you');
      for (var i = 0; i < 12 && target.evaluate().isEmpty; i++) {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await t.pump(const Duration(milliseconds: 200));
      }
      await captureSeriesShot(t, 'tonight-circle-sections', size);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('mobile-22 credits stamps open', (t) async {
    Map<String, Object> single() => {kReaderPrefsMigratedKey: true, kReaderPrefsSeedKey: jsonEncode({'seriesDefaults': {'layout': 'single', 'direction': 'ltr', 'fit': 'height'}})};
    await pumpReader(t, prefsValues: single(), extra: [circleRepositoryProvider.overrideWithValue(_repo()), libraryRepositoryProvider.overrideWithValue(ShelfLibrary(all: [shelfSeries(1)]))]);
    await settleReader(t, ms: 600);
    final engine = t.widget<PagedReaderView>(find.byType(PagedReaderView)).controller;
    engine.jumpToPage(engine.value.pageCount);
    await settleReader(t, ms: 500);
    engine.pageBy(forward: true);
    await settleReader(t, ms: 1600);
    await captureSeriesShot(t, 'stamps-credits-open', kSkinShotSizes[0]);
    await disposeReader(t);
  });
}

class _NeverMembers extends CircleMembersNotifier {
  @override
  Future<List<CircleMember>> build() => Future.any<List<CircleMember>>([]);
}

/// The layout grid overlay on.
final Override layoutGridOverlayOn = layoutGridOverlayProvider.overrideWith((ref) => true);
