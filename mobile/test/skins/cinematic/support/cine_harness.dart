import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/repositories/numbers_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cover.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/share/press_run.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/numbers_fixtures.dart';
import '../../../support/test_overrides.dart';

/// A 1 x 1 opaque PNG, the stand-in cover of the widget tests.
final Uint8List kTinyPng = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// The Numbers repository the tests drive: payloads by range, one Annual per
/// year, and a record of every request.
class FakeNumbersRepo implements NumbersRepository {
  FakeNumbersRepo({Map<int, LibraryStatistics>? stats, Map<int, Annual>? annuals, this.failWith}) : stats = stats ?? {for (final d in [7, 30, 90, 365]) d: statisticsFixture(days: d)}, annuals = annuals ?? {2026: annualFixture(), 2025: annualFixture(year: 2025, partial: false)};

  final Map<int, LibraryStatistics> stats;
  final Map<int, Annual> annuals;
  final List<int> statisticsDays = [];
  final List<int> annualYears = [];
  final List<int> marked = [];
  Object? failWith;

  @override
  Future<Result<LibraryStatistics>> statistics({required int days}) async {
    statisticsDays.add(days);
    if (failWith != null) return Err(failWith! as dynamic);
    return Ok(stats[days] ?? statisticsFixture(days: days));
  }

  @override
  Future<Result<Annual>> annual(int year) async {
    annualYears.add(year);
    if (failWith != null) return Err(failWith! as dynamic);
    final a = annuals[year];
    return a == null ? Err(failWith! as dynamic) : Ok(a);
  }

  @override
  Future<Result<void>> markMilestoneSeen(int days) async {
    marked.add(days);
    return const Ok(null);
  }
}

/// Records haptic events instead of playing them.
class RecordingHaptics extends SkinHaptics {
  RecordingHaptics() : super(skin: SkinId.cinematic, map: cinematicHaptics, enabled: true);
  final List<HapticEvent> events = [];

  @override
  Future<void> fire(HapticEvent event, {double velocity = 0, int depth = 1}) async => events.add(event);
}

class FakeShare implements ShareDelegate {
  FakeShare([this.status = ShareResultStatus.success, this.raw = '']);
  ShareResultStatus status;
  String raw;
  bool throwOnShare = false;
  final List<ShareParams> shared = [];

  @override
  Future<ShareResult> share(ShareParams params) async {
    shared.add(params);
    if (throwOnShare) throw Exception('no share sheet');
    return ShareResult(raw, status);
  }
}

class FakeMediaStore implements MediaStore {
  FakeMediaStore({this.can = true});
  bool can;
  final List<String> saved = [];

  @override
  Future<bool> canSaveImage() async => can;

  @override
  Future<bool> saveImage(Uint8List bytes, String name) async {
    saved.add(name);
    return true;
  }
}

class CineTestEnv {
  CineTestEnv({FakeNumbersRepo? repo, this.now, this.prefs = const {}}) : repo = repo ?? FakeNumbersRepo();
  final FakeNumbersRepo repo;
  final DateTime? now;
  final Map<String, Object> prefs;
  final RecordingHaptics haptics = RecordingHaptics();
  final FakeShare share = FakeShare();
  final FakeMediaStore media = FakeMediaStore();
  Uint8List? cardBytes;
  late SharedPreferences sp;
  int renders = 0;

  Future<List<Override>> overrides({List<Override> extra = const []}) async {
    SharedPreferences.setMockInitialValues(testPrefsDefaults(prefs));
    sp = await SharedPreferences.getInstance();
    return [
      sharedPrefsProvider.overrideWithValue(sp),
      authenticatedAuthOverride(),
      activeProfileOverride(),
      profileSessionReadyOverride(),
      ...contentModeOverrides(),
      numbersRepositoryProvider.overrideWithValue(repo),
      numbersNowProvider.overrideWithValue(() => now ?? DateTime(2026, 9, 29, 10)),
      skinHapticsProvider.overrideWithValue(haptics),
      shareDelegateProvider.overrideWithValue(share),
      mediaStoreProvider.overrideWithValue(media),
      coverImageProvider.overrideWithValue((url, {width}) => MemoryImage(kTinyPng)),
      ...extra,
    ];
  }
}

GoRouter cineRouter({String initial = '/library/statistics', Widget? home}) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/', builder: (_, __) => home ?? const Scaffold(body: Text('HOME'))),
        GoRoute(path: Routes.libraryPattern, builder: (_, __) => const Scaffold(body: Text('LIBRARY'))),
        GoRoute(path: ScreenId.indexHub.path, builder: (_, __) => const Scaffold(body: Text('INDEX'))),
        GoRoute(path: ScreenId.numbers.path, builder: (_, __) => const NumbersScreen()),
        GoRoute(path: ScreenId.annual.path, builder: (_, s) => AnnualScreen(yearParam: s.pathParameters['year'] ?? '')),
        GoRoute(path: '/sources/:sourceId/series/:seriesKey', builder: (_, __) => const Scaffold(body: Text('FEATURE'))),
      ],
    );

void setView(WidgetTester tester, Size size, {EdgeInsets padding = EdgeInsets.zero}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(left: padding.left, top: padding.top, right: padding.right, bottom: padding.bottom);
  addTearDown(tester.view.reset);
}

/// Pumps [router] under the Cinematic theme.
Future<void> pumpCine(
  WidgetTester tester,
  CineTestEnv env, {
  GoRouter? router,
  Widget? home,
  Size size = const Size(390, 844),
  EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  TargetPlatform platform = TargetPlatform.iOS,
  bool reduced = false,
  bool accessible = false,
  double textScale = 1.0,
  List<Override> extra = const [],
  ProviderContainer? sharedContainer,
  Key? boundaryKey,
  Widget Function(Widget app)? wrap,
}) async {
  setView(tester, size, padding: padding);
  final r = router ?? cineRouter();
  final overrides = await env.overrides(extra: extra);
  Widget app = MaterialApp.router(
    routerConfig: r,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(platform: platform, extensions: const [cinematicTokens], scaffoldBackgroundColor: const Color(0xFF000000), brightness: Brightness.dark),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced, accessibleNavigation: accessible, textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
  );
  if (wrap != null) app = wrap(app);
  if (boundaryKey != null) app = RepaintBoundary(key: boundaryKey, child: app);
  app = sharedContainer != null ? UncontrolledProviderScope(container: sharedContainer, child: app) : ProviderScope(overrides: overrides, child: app);
  await tester.pumpWidget(app);
}

/// Pumps [ms] in 50 ms frames (repeating animations never settle).
Future<void> pumpMs(WidgetTester tester, int ms) async {
  var left = ms;
  while (left > 0) {
    final step = left > 50 ? 50 : left;
    await tester.pump(Duration(milliseconds: step));
    left -= step;
  }
}

/// Every tappable [GestureDetector] must be at least 44 (iOS) or 48 (Android) both ways.
void expectHitTargets(WidgetTester tester, TargetPlatform platform, {Finder? within}) {
  final min = platform == TargetPlatform.iOS ? 44.0 : 48.0;
  final all = find.descendant(of: within ?? find.byType(Scaffold), matching: find.byType(GestureDetector));
  final small = <String>[];
  for (final e in all.evaluate()) {
    final w = e.widget as GestureDetector;
    if (w.onTap == null && w.onTapUp == null) continue;
    final box = e.renderObject! as RenderBox;
    if (!box.hasSize) continue;
    if (box.size.width < min - 0.01 || box.size.height < min - 0.01) small.add('${box.size} ${e.widget.key ?? ''}');
  }
  expect(small, isEmpty, reason: 'targets under $min');
}
