import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/milestone_card_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/authed_cover.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/streak_block.dart';
import 'package:manhwamaniacs/skins/cinematic/share/press_run.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

import '../../skins/cinematic/support/cine_harness.dart';
import '../../support/numbers_fixtures.dart';
import 'shot_covers.dart';
import 'shot_harness.dart';
import 'skin_shots.dart';

/// Proof captures of mobile/21 (docs/redesign/proof/mobile-21). Everything is
/// fixture data with covers painted in-repo; nothing is written without
/// MM_PROOF_DIR.

final kShotPhone = kSkinShotSizes[0];
final kShotTablet = kSkinShotSizes[1];

/// One in-repo cover per series key.
final Map<String, Uint8List> _covers = {};

Future<void> loadMobile21Covers(WidgetTester tester) async {
  if (_covers.isNotEmpty) return;
  await tester.runAsync(() async {
    for (var i = 0; i < 9; i++) {
      _covers['series-$i'] =
          await ShotCoverArt(title: 'Series $i', seed: i * 3 + 1)
              .toPng(width: 300, height: 450);
    }
  });
}

ImageProvider shotCover(String url, {double? width}) {
  final m = RegExp(r'series-\d').firstMatch(url);
  return MemoryImage(_covers[m?.group(0)] ?? _covers['series-0']!);
}

/// Pumps [router] at [size] under the fixture environment, lets [after] drive it,
/// then writes `<proofDir>/<name>-<size>.png`.
Future<void> mobile21Shot(
  WidgetTester tester,
  String name, {
  required SkinShotSize size,
  CineTestEnv? env,
  GoRouter? router,
  bool reduced = false,
  bool accessible = false,
  double textScale = 1.0,
  Future<void> Function(WidgetTester tester)? after,
  bool grid = false,
  String? suffix,
}) async {
  final dir = proofDir;
  if (dir == null) return;
  await loadMobile21Covers(tester);
  final key = GlobalKey(debugLabel: 'm21');
  await pumpCine(
    tester,
    env ?? CineTestEnv(),
    router: router,
    size: size.logical,
    padding: size.padding,
    reduced: reduced,
    accessible: accessible,
    textScale: textScale,
    boundaryKey: key,
    extra: [authedCoverProvider.overrideWithValue(shotCover)],
    wrap: grid
        ? (app) => Stack(textDirection: TextDirection.ltr, children: [
              app,
              const Positioned.fill(child: IgnorePointer(child: _GridOverlay())),
            ],)
        : null,
  );
  await tester.pump();
  if (after != null) {
    await after(tester);
  } else {
    await pumpMs(tester, 3000);
  }
  await writeShot(
      tester, find.byKey(key), '$dir/$name${suffix ?? ''}-${size.name}.png',
      pixelRatio: size.pixelRatio,);
}

/// The 4-column (phone) or 12-column (tablet) grid at 20 / 40 px margins.
class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 600;
          final cols = wide ? 12 : 4;
          final margin = wide ? 40.0 : 20.0;
          const gutter = 16.0;
          final colW = (box.maxWidth - 2 * margin - gutter * (cols - 1)) / cols;
          return Stack(
            children: [
              for (var i = 0; i < cols; i++)
                Positioned(
                    left: margin + i * (colW + gutter),
                    top: 0,
                    bottom: 0,
                    width: colW,
                    child: ColoredBox(
                        color: CineColors.spot.withValues(alpha: 0.10),),),
            ],
          );
        },
      );
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 300,
      scrollable: find.byType(Scrollable).last,);
  await pumpMs(tester, 800);
}

/// Streak tiers side by side (0, 3, 12, 45 and 120 days).
Widget streakTiersRow() => Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 8,
            runSpacing: 24,
            children: [
              for (final d in [0, 3, 12, 45, 120])
                SizedBox(
                  width: 110,
                  child: Column(
                    children: [
                      StreakFlame(
                          streak: HomeStreak(
                              currentDays: d,
                              longestDays: 200,
                              lastActiveDate:
                                  d == 0 ? null : DateTime(2026, 9, 29),),
                          size: 56,
                          now: DateTime(2026, 9, 29, 10),
                          ignite: false,),
                      Text('$d DAYS',
                          style: const TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 11,
                              color: CineColors.ink60,),),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

Widget streakAtRisk(DateTime now) => Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: StreakBlock(
                  streak: ReadingStreak(
                      currentDays: 12,
                      longestDays: 31,
                      lastActiveDate:
                          DateTime(now.year, now.month, now.day - 1),
                      atRisk: true,),
                  daily: const [],),),),
    );

/// Writes the six templates in both formats as the real captured PNGs.
Future<void> writeCards(WidgetTester tester, {required String dir}) async {
  await loadMobile21Covers(tester);
  late BuildContext ctx;
  final env = CineTestEnv();
  await pumpCine(
    tester,
    env,
    router: cineRouter(
      initial: '/',
      home: Scaffold(
        body: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
    extra: [authedCoverProvider.overrideWithValue(shotCover)],
  );
  final templates = shareTemplates(ShareInput.annual(annualFixture(), 'Yash'));
  for (final t in templates) {
    for (final f in ShareFormat.values) {
      final bytes = await captureCard(tester, ctx, t, f);
      final file = File('$dir/card-${t.id.fileKey}-${f.name}.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
    }
  }
}

class _TonightStandIn extends ConsumerWidget {
  const _TonightStandIn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(numbersStatisticsProvider(30)).valueOrNull?.data;
    return Scaffold(
        body: MilestoneCardHost(
            streak: s?.streak,
            shareable: s?.shareable,
            child: const SizedBox.expand(),),);
  }
}

/// The `mobile-21` proof group (marketing_screenshots_test.dart).
void mobile21Group() {
  for (final size in [kShotPhone, kShotTablet]) {
    final tag = size.name;
    testWidgets('mobile-21 numbers $tag', (tester) async {
      await mobile21Shot(tester, 'numbers-30', size: size);
      await mobile21Shot(tester, 'numbers-grid', size: size, grid: true);
      await mobile21Shot(tester, 'numbers-year-heatmap',
          size: size, env: CineTestEnv(prefs: {'mm.stats.range.u1p1': 365}),);
      await mobile21Shot(
        tester,
        'numbers-selected-day',
        size: size,
        after: (t) async {
          await pumpMs(t, 2500);
          final box = t.getRect(find
              .byType(CustomPaint)
              .evaluate()
              .map((e) => find.byWidget(e.widget))
              .firstWhere((f) =>
                  t.getSize(f).height > 150 && t.getSize(f).width > 300,),);
          await t.tapAt(Offset(box.left + box.width * 0.62, box.top + 60));
          await pumpMs(t, 500);
        },
      );
      await mobile21Shot(
        tester,
        'numbers-clock-radar',
        size: size,
        after: (t) async {
          await pumpMs(t, 2500);
          await scrollTo(t, find.text('When you read'));
          await t.drag(find.byType(Scrollable).last, const Offset(0, -140));
          await pumpMs(t, 3000);
        },
      );
      await mobile21Shot(
        tester,
        'numbers-lists',
        size: size,
        after: (t) async {
          await pumpMs(t, 2500);
          await scrollTo(t, find.text('Where you read'));
          await t.drag(find.byType(Scrollable).last, const Offset(0, -260));
          await pumpMs(t, 1500);
        },
      );
    });

    testWidgets('mobile-21 milestone and press run $tag', (tester) async {
      final env = CineTestEnv(
          repo:
              FakeNumbersRepo(stats: {30: statisticsFixture(currentDays: 30)}),);
      await mobile21Shot(tester, 'milestone-card',
          size: size,
          env: env,
          router: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const _TonightStandIn()),
          ],),
          after: (t) => pumpMs(t, 3200),);
      await mobile21Shot(
        tester,
        'press-run-sheet',
        size: size,
        router: cineRouter(
          initial: '/',
          home: Scaffold(
            body: Builder(
              builder: (c) {
                WidgetsBinding.instance.addPostFrameCallback((_) =>
                    showPressRun(
                        c, ShareInput.annual(annualFixture(), 'Yash'),),);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
        after: (t) => pumpMs(t, 2500),
      );
    });

    testWidgets('mobile-21 annual pages $tag', (tester) async {
      final pages = [
        'cover',
        'time',
        'chapters',
        'no1',
        'genres',
        'clock',
        'streak',
        'sources',
        'circle',
        'colophon-mid',
        'press-run',
      ];
      for (var i = 0; i < pages.length; i++) {
        final env = CineTestEnv(
            repo:
                FakeNumbersRepo(annuals: {2026: annualFixture(circle: true)}),);
        await mobile21Shot(
          tester,
          'annual-${pages[i]}',
          size: size,
          env: env,
          router: cineRouter(initial: '/library/statistics/annual/2026'),
          after: (t) async {
            await pumpMs(t, 300);
            for (var k = 0; k < i; k++) {
              await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
              await pumpMs(t, 350);
            }
            await pumpMs(t, i == 9 ? 5000 : 3500);
          },
        );
      }
    });
  }

  testWidgets('mobile-21 phone-only states', (tester) async {
    final phone = kShotPhone;
    CineTestEnv stats(LibraryStatistics Function(int d) f,
            {AppError? fail, Map<String, Object> prefs = const {},}) =>
        CineTestEnv(
            repo: FakeNumbersRepo(stats: {
              for (final d in [7, 30, 90, 365]) d: f(d),
            }, failWith: fail,),
            prefs: prefs,);
    await mobile21Shot(tester, 'numbers-loading',
        size: phone, after: (t) => pumpMs(t, 250),);
    await mobile21Shot(tester, 'numbers-empty',
        size: phone,
        env: stats((d) => statisticsFixture(days: d, empty: true)),);
    await mobile21Shot(tester, 'numbers-never-read',
        size: phone,
        env: stats((d) => statisticsFixture(days: d, neverRead: true)),);
    await mobile21Shot(tester, 'numbers-offline',
        size: phone,
        env: CineTestEnv(
            repo:
                FakeNumbersRepo(failWith: const NetworkError(message: 'down')),
            prefs: {'mm.numbers.last.30.u1p1': jsonEncode(statisticsJson())},),);
    await mobile21Shot(tester, 'numbers-error',
        size: phone,
        env: CineTestEnv(
            repo: FakeNumbersRepo(failWith: const UnknownError(message: 'x')),),);
    await mobile21Shot(tester, 'streak-tiers',
        size: phone,
        router: cineRouter(initial: '/', home: streakTiersRow()),
        after: (t) => pumpMs(t, 1200),);
    await mobile21Shot(tester, 'streak-at-risk',
        size: phone,
        env: CineTestEnv(now: DateTime(2026, 9, 29, 21)),
        router: cineRouter(
            initial: '/', home: streakAtRisk(DateTime(2026, 9, 29, 21)),),
        after: (t) => pumpMs(t, 1200),);
    await mobile21Shot(tester, 'annual-thin',
        size: phone,
        env: CineTestEnv(
            repo: FakeNumbersRepo(
                annuals: {2026: annualFixture(recordedDays: 5)},),),
        router: cineRouter(initial: '/library/statistics/annual/2026'),
        after: (t) => pumpMs(t, 1500),);
    await mobile21Shot(tester, 'annual-loading',
        size: phone,
        router: cineRouter(initial: '/library/statistics/annual/2026'),
        after: (t) => pumpMs(t, 300),);
    await mobile21Shot(tester, 'annual-offline',
        size: phone,
        env: CineTestEnv(
            repo:
                FakeNumbersRepo(failWith: const NetworkError(message: 'down')),),
        router: cineRouter(initial: '/library/statistics/annual/2026'),
        after: (t) => pumpMs(t, 1500),);
    await mobile21Shot(tester, 'annual-screen-reader',
        size: phone,
        accessible: true,
        router: cineRouter(initial: '/library/statistics/annual/2026'),
        after: (t) => pumpMs(t, 3000),);
    await mobile21Shot(tester, 'reduced-motion-numbers',
        size: phone, reduced: true, after: (t) => pumpMs(t, 500),);
    await mobile21Shot(tester, 'text-scale-2-numbers',
        size: phone, textScale: 2.0,);
    await mobile21Shot(tester, 'annual-landscape',
        size: kSkinShotLandscape,
        router: cineRouter(initial: '/library/statistics/annual/2026'),
        after: (t) => pumpMs(t, 3000),);
  });

  testWidgets('mobile-21 share cards', (tester) async {
    final dir = proofDir;
    if (dir == null) return;
    await writeCards(tester, dir: dir);
  });
}
