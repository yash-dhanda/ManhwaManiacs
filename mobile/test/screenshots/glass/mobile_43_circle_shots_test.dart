@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:flutter/material.dart' show Brightness, MaterialApp, Material, MaterialType, Theme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/letters_deferred.dart' show pendingLettersProvider;
import 'package:manhwamaniacs/features/library/providers/lift_store.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/glass/glass_skin.dart' show GlassRoot;
import 'package:manhwamaniacs/skins/glass/parts/circle/series_circle_row.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/letter_schedule.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/lift_provider.dart' show magnetHeldProvider;
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart' show GlassAvatarPreset;
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_picker.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_strip.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/chapter_seam.dart' show CaughtUpCard;
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

import '../../skins/glass/circle/circle_rig.dart';
import '../glass_shell_shots_support.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The mobile/43 proof captures (glass 9.3): Circle and its states, the friend sheet, reactions, shared shelves, the recommend
/// gesture and sheets, Circle and privacy, the series Circle row. Written only when `MM_PROOF_DIR` is set (never
/// `MM_WRITE_SHOTS`); otherwise rasterised and discarded.
const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
const _sizes = [_phone, SkinShotSize('tablet', Size(834, 1194), 2.0, EdgeInsets.only(top: 24, bottom: 20)), kSkinShotTabletWide];

class _NoProgress extends SourceProgressNotifier {
  @override
  Map<String, SourceChapterProgress> build() => const {};
}

class _Sharing extends SharingNotifier {
  @override
  Future<Sharing> build(int arg) async => const Sharing(activity: true);
}

Future<ShotSession> _open(WidgetTester t, SkinShotSize size, String route, {CircleFake? repo, List<Override> extra = const []}) async {
  final s = await openShell(t, size, start: route, settle: false, extra: [...circleOverrides(repo ?? circleFake()), ...extra]);
  for (var i = 0; i < 4; i++) {
    await s.settle(500);
  }
  return s;
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(minutes: 11));
}

Future<void> _all(WidgetTester t, String name, String route, {CircleFake Function()? repo, List<Override> extra = const [], double? ring}) async {
  for (final size in _sizes) {
    final s = await _open(t, size, route, repo: repo?.call(), extra: [if (ring != null) circleClockProvider.overrideWithValue(() => circleNow), ...extra]);
    await s.snap(name, size);
    await _end(t);
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Circle: tabs, presence, states, every frame', (t) async {
    await _all(t, 'circle-activity', '/circle');
    await _all(t, 'circle-letters', '/circle?tab=letters');
    await _all(t, 'circle-shelves', '/circle?tab=shelves');
    await _all(t, 'circle-presence-reading', '/circle');
    await _all(t, 'circle-not-sharing', '/circle', repo: () => circleFake(sharing: false));
    await _all(t, 'circle-quiet', '/circle', repo: () => circleFake(members: const [], feed: const []));
    await _all(t, 'circle-only-you', '/circle', repo: () => circleFake(members: const [], feed: const []), extra: [circleServerAloneProvider.overrideWithValue(true)]);
    await _all(t, 'circle-loading', '/circle', extra: [circleMembersProvider.overrideWith(_Pending.new), circleFeedProvider.overrideWith(_PendingFeed.new)]);
    await _all(t, 'circle-offline', '/circle', repo: () => circleFake(fail: const NetworkError(message: 'down')), extra: [glassOfflineProvider.overrideWithValue(true)]);
    for (final size in _sizes) {
      final s = await _open(t, size, '/circle?tab=letters');
      await t.tap(find.text('Sent'));
      await s.settle(600);
      await s.snap('circle-letters-sent', size);
      await _end(t);
    }
  });

  testWidgets('Circle variants: reduced motion, solid, contrast, text scale 2', (t) async {
    var s = await _open(t, _phone, '/circle');
    s.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
    await s.settle(800);
    await s.snap('circle-reduced-motion', _phone);
    await _end(t);
    s = await _open(t, _phone, '/circle');
    s.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    await s.settle(800);
    await s.snap('circle-solid', _phone);
    await _end(t);
    s = await _open(t, _phone, '/circle');
    s.container.read(glassInAppPrefsProvider.notifier).setIncreaseContrast(true);
    await s.settle(800);
    await s.snap('circle-contrast', _phone);
    await _end(t);
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    s = await _open(t, _phone, '/circle');
    await s.snap('circle-text-scale-2', _phone);
    await _end(t);
  });

  testWidgets('the friend: sheet, window, not sharing, the orb flight mid-way', (t) async {
    for (final size in _sizes) {
      final s = await _open(t, size, '/circle');
      await t.tap(find.bySemanticsLabel('Aarav, reading Omniscient Reader now'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 220));
      await s.snap('orb-flight', size);
      await s.settle(900);
      await s.settle(600);
      await s.snap('friend-sheet', size);
      await _end(t);
    }
    await _all(t, 'friend-not-sharing', '/circle/2', repo: () => circleFake()..memberPage = null);
  });

  testWidgets('reactions: the bloom with one bubble magnified, the arc mid-flight, the strip guarded and unsealed', (t) async {
    Widget host({required bool sealed}) => _page(Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassReactionStrip(
              reactors: [StripReactor(kind: ReactionKind.hype, name: 'Aarav', preset: GlassAvatarPreset.violetSpark, sealed: sealed), StripReactor(kind: ReactionKind.tears, name: 'Mira', preset: GlassAvatarPreset.cyanRocket, sealed: sealed)],
              onSend: (_) {},
              sourceId: 's',
              seriesKey: 'or',
              chapterKey: '212',
              chapterLabel: 'Ch 212',
              mine: ReactionKind.loved,
            ),
            const SizedBox(height: 32),
            GlassReactionButton(onSend: (_) {}, onClear: () {}, chapterLabel: 'Ch 212'),
            const SizedBox(height: 120),
          ],
        ),);
    for (final size in _sizes) {
      await captureSkinWidget(t, name: 'reaction-strip-guarded', size: size, overrides: [_noSensor], child: host(sealed: true), settle: (t) => _ms(t, 700));
      await captureSkinWidget(t, name: 'reaction-strip-unsealed', size: size, overrides: [_noSensor], child: host(sealed: false), settle: (t) => _ms(t, 700));
      await captureSkinWidget(t, name: 'reaction-bloom', size: size, overrides: [_noSensor], child: host(sealed: false), settle: (t) async {
        await _ms(t, 400);
        final c = t.getCenter(find.byType(GlassReactionButton));
        final g = await t.startGesture(c);
        await _ms(t, 700);
        await g.moveTo(bubbleCentres(c)[1]);
        await _ms(t, 300);
        addTearDown(g.up);
      },);
      await captureSkinWidget(t, name: 'reaction-arc', size: size, overrides: [_noSensor], child: host(sealed: false), settle: (t) async {
        await _ms(t, 400);
        final c = t.getCenter(find.byType(GlassReactionButton));
        final g = await t.startGesture(c);
        await _ms(t, 700);
        await g.moveTo(bubbleCentres(c)[0]);
        await _ms(t, 300);
        await g.up();
        await _ms(t, 140);
      },);
      await t.pumpWidget(const SizedBox.shrink());
      await _ms(t, 1200);
    }
  });

  testWidgets('sheets: recommend, letter note, collection share; Circle and privacy', (t) async {
    await _all(t, 'recommend-sheet', '/circle?sheet=recommend&series=s:solo&title=Solo%20Leveling&to=2');
    await _all(t, 'letter-note-sheet', '/circle?sheet=letter-note&to=2&series=s:solo');
    await _all(t, 'collection-share-sheet', '/circle?sheet=collection-share&collection=7');
    await _all(t, 'settings-circle-privacy', '/settings/circle', extra: [sharingProvider.overrideWith(_Sharing.new)]);
  });

  testWidgets('recommend by drag: the orbs with one holding the poster, then the toast', (t) async {
    for (final size in _sizes) {
      // The lift is written to the lift store as GlassPoster writes it at 450 ms; the held orb swells to 1.2 (the magnet).
      final s = await _open(t, size, '/circle', extra: [
        recipientsProvider.overrideWith((ref, key) async => const [
              CircleMember(profileId: 2, name: 'Aarav', avatarKey: 'violet', canReceive: true),
              CircleMember(profileId: 3, name: 'Mira', avatarKey: 'cyan', canReceive: true),
              CircleMember(profileId: 4, name: 'Kai', avatarKey: 'rose', canReceive: true),
            ],),
      ],);
      s.container.read(liftProvider.notifier).state = const LiftState(sourceId: 's', seriesKey: 'solo', phase: LiftPhase.lifted, posterRect: Rect.fromLTWH(140, 180, 112, 168));
      s.container.read(magnetHeldProvider.notifier).state = 3;
      await s.settle(600);
      await s.snap('recommend-orbs-magnet', size);
      s.container.read(magnetHeldProvider.notifier).state = null;
      s.container.read(liftProvider.notifier).state = null;
      scheduleLetter(s.container, toProfileId: 3, toName: 'Mira', sourceId: 's', seriesKey: 'solo', onAddNote: () {});
      await s.settle(500);
      await s.snap('recommend-toast', size);
      for (final p in s.container.read(pendingLettersProvider)) {
        p.undo();
      }
      await _end(t);
    }
  });

  testWidgets('shared shelves: view only, and can add with the adder orbs', (t) async {
    const rows = [
      ShelfSeriesRow(sourceId: 's', seriesKey: 'solo', title: 'Solo Leveling', addedBy: aarav),
      ShelfSeriesRow(sourceId: 's', seriesKey: 'or', title: 'Omniscient Reader', addedBy: mira),
      ShelfSeriesRow(sourceId: 's', seriesKey: 'tog', title: 'Tower of God', addedBy: aarav),
      ShelfSeriesRow(sourceId: 's', seriesKey: 'bh', title: 'Blue Hour', addedBy: kai),
    ];
    CircleFake shelf(String role) => circleFake()..detail = SharedShelfDetail(shelf: SharedShelf(id: 7, name: 'Weekend reads', seriesCount: 4, owner: aarav, role: role), series: rows);
    await _all(t, 'shelf-view-only', '/library/collections/7', repo: () => shelf('view_only'));
    await _all(t, 'shelf-can-add-adder-orbs', '/library/collections/7', repo: () => shelf('can_add'));
  });

  testWidgets("the manga end card with the finished chapter's reactions", (t) async {
    for (final size in _sizes) {
      await captureSkinWidget(
        t,
        name: 'end-card-reactions',
        size: size,
        overrides: [_noSensor],
        child: _page(Center(
          child: CaughtUpCard(
            nextNumber: '213',
            inLibrary: true,
            onFollow: () {},
            reactions: GlassReactionStrip(
              // The chapter was just finished here: unsealed.
              reactors: const [StripReactor(kind: ReactionKind.hype, name: 'Aarav', preset: GlassAvatarPreset.violetSpark, sealed: false), StripReactor(kind: ReactionKind.tears, name: 'Mira', preset: GlassAvatarPreset.cyanRocket, sealed: false)],
              onSend: (_) {},
              sourceId: 's',
              seriesKey: 'or',
              chapterKey: '212',
              chapterLabel: 'Ch 212',
              mine: ReactionKind.loved,
            ),
          ),
        ),),
        settle: (t) => _ms(t, 700),
      );
    }
  });

  testWidgets('the series Circle row', (t) async {
    for (final size in _sizes) {
      await captureSkinWidget(
        t,
        name: 'series-circle-row',
        size: size,
        overrides: [
          circleSeriesProvider.overrideWith((ref, key) async => CircleSeriesData(
                readers: const [
                  CircleReader(member: ProfileRef(profileId: 2, name: 'Aarav', avatarKey: 'violet'), chapterKey: 'c212'),
                  CircleReader(member: ProfileRef(profileId: 3, name: 'Mira', avatarKey: 'cyan'), chapterKey: 'c88'),
                ],
                chapters: [
                  ChapterReactions(chapterKey: 'c212', chapterNumber: 212, counts: const {ReactionKind.hype: 1}, total: 1, by: [ReactionBy.of(const ProfileRef(profileId: 2, name: 'Aarav'), ReactionKind.hype)]),
                  ChapterReactions(chapterKey: 'c88', chapterNumber: 88, counts: const {ReactionKind.loved: 1}, total: 1, by: [ReactionBy.of(const ProfileRef(profileId: 3, name: 'Mira'), ReactionKind.loved)], sealed: false),
                ],
              ),),
          sourceProgressProvider.overrideWith(_NoProgress.new),
        ],
        child: Theme(
          data: ThemeData(),
          child: ColoredBox(
            color: const Color(0xFF000000),
            child: Padding(padding: const EdgeInsets.all(24), child: Align(alignment: Alignment.topLeft, child: DefaultTextStyle(style: TextStyle(color: glassTokens.colorLabel1), child: const SeriesCircleRow(sourceId: 's', seriesKey: 'or')))),
          ),
        ),
      );
    }
  });
}

class _Pending extends CircleMembersNotifier {
  @override
  Future<List<CircleMember>> build() => Completer<List<CircleMember>>().future;
}

class _PendingFeed extends CircleFeedNotifier {
  @override
  Future<CircleFeedState> build(String? arg) => Completer<CircleFeedState>().future;
}

final Override _noSensor = gravitySensorProvider.overrideWithValue(() => const Stream.empty());

Widget _page(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      builder: (context, home) => GlassRoot(child: home!),
      home: Material(type: MaterialType.transparency, child: ColoredBox(color: const Color(0xFF000000), child: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: child)))),
    );

Future<void> _ms(WidgetTester t, int ms) async {
  for (var left = ms; left > 0; left -= 16) {
    await t.pump(Duration(milliseconds: left < 16 ? left : 16));
  }
}
