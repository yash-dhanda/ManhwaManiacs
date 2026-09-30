// ignore_for_file: require_trailing_commas, directives_ordering, avoid_redundant_argument_values, unnecessary_import
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/flight_layer.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart' show cineLocationOf;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/shutter.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:manhwamaniacs/skins/contract.g.dart' show HapticEvent;
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../auth/auth_test_support.dart' show FakeProfiles, profile;
import '../feature/feature_test_support.dart' show featureMediaWrap, featureTheme;
import '../primitives/cine_harness.dart' show TestHaptics;
import '../tonight/tonight_test_support.dart' show FakeHomeFeed, kTonightNow, loadFeed, viewOf;

const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

List<WorldItem> seedItems([int n = 24]) => [
      for (var i = 1; i <= n; i++)
        WorldItem(
          title: 'Series $i',
          anilistId: i,
          coverUrl: 'https://img.test/$i.jpg',
          isAdult: i == 5,
          available: i.isOdd ? [WorldAvailability(sourceId: 'shelf', sourceName: 'Shelf', seriesKey: 'k$i')] : const [],
        ),
    ];

OnboardingCatalog catalogFixture({int genres = 34}) => OnboardingCatalog(
      formats: [
        for (final f in [FormatId.manhwa, FormatId.manga, FormatId.manhua, FormatId.novel]) FormatCovers(format: f, covers: ['https://img.test/${f.wire}1.jpg', 'https://img.test/${f.wire}2.jpg', 'https://img.test/${f.wire}3.jpg']),
      ],
      genres: [for (var i = 0; i < genres; i++) GenreWeight(name: i == 0 ? 'Romance' : 'Genre $i', weight: 100.0 - i)],
      seeds: seedItems(),
    );

class FakeOnboardingRepo implements OnboardingRepository {
  FakeOnboardingRepo({OnboardingCatalog? catalog}) : data = catalog ?? catalogFixture();
  OnboardingCatalog data;
  AppError? error;
  Completer<void>? hold;
  bool failPuts = false;
  Taste? taste;
  final List<Map<String, Object>> puts = [];
  final List<Map<String, Object>> catalogQueries = [];

  @override
  Future<Result<OnboardingCatalog>> catalog({List<String> formats = const [], List<String> genres = const [], List<String> styles = const []}) async {
    catalogQueries.add({'formats': formats, 'genres': genres, 'styles': styles});
    if (hold != null) await hold!.future;
    return error != null ? Err(error!) : Ok(data);
  }

  @override
  Future<Result<void>> saveTaste(int profileId, TasteUpdate body) async {
    puts.add(body.toJson());
    return failPuts ? const Err(NetworkError(message: 'down')) : const Ok(null);
  }

  @override
  Future<Result<Taste?>> getTaste(int profileId) async => Ok(taste);
}

class _Followed implements FollowedSeries {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class FakeLib implements LibraryRepository {
  final List<String> calls = [];
  final Set<String> failing = {};

  /// When set, every follow waits for it (the Printing state).
  Completer<void>? hold;
  int inFlight = 0, peak = 0;

  @override
  Future<Result<FollowedSeries>> follow({required String sourceId, required String seriesKey}) async {
    calls.add(seriesKey);
    inFlight++;
    if (inFlight > peak) peak = inFlight;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (hold != null) await hold!.future;
    inFlight--;
    return failing.contains(seriesKey) ? const Err(NetworkError(message: 'x')) : Ok(_Followed());
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class OnboardingRig {
  OnboardingRig(this.router, this.container, this.repo, this.lib, this.haptics);
  final GoRouter router;
  final ProviderContainer container;
  final FakeOnboardingRepo repo;
  final FakeLib lib;
  final List<HapticEvent> haptics;
  String get at => cineLocationOf(router);
}

/// The providers and router of one onboarding run: [pumpOnboarding] mounts them in a container,
/// the screenshot suite hands [overrides] to the harness.
class OnboardingParts {
  OnboardingParts(this.overrides, this.router, this.repo, this.lib, this.haptics);
  final List<Override> overrides;
  final GoRouter router;
  final FakeOnboardingRepo repo;
  final FakeLib lib;
  final List<HapticEvent> haptics;
}

Future<OnboardingParts> onboardingParts({
  int? step = 2,
  Object? profileStep,
  FakeOnboardingRepo? repo,
  FakeLib? lib,
  bool novels = true,
  Map<int, SimilarResult>? similar,
  Map<String, Object> prefs = const {},
  bool tonight = false,
  List<Override> extra = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final fakeRepo = repo ?? FakeOnboardingRepo();
  final fakeLib = lib ?? FakeLib();
  final haptics = <HapticEvent>[];
  final overrides = <Override>[
    sharedPrefsProvider.overrideWithValue(sp),
    apiBaseUrlOverride('http://example.test'),
    ...noDownloadsStoreOverrides(),
    authenticatedAuthOverride(),
    activeProfileOverride(),
    profilesRepositoryProvider.overrideWithValue(FakeProfiles([profile(1, 'Tester', step: profileStep?.toString())])),
    onboardingRepositoryProvider.overrideWithValue(fakeRepo),
    libraryRepositoryProvider.overrideWithValue(fakeLib),
    novelsEnabledProvider.overrideWithValue(novels),
    matureGateOpenProvider.overrideWithValue(false),
    skinHapticsProvider.overrideWithValue(TestHaptics(haptics)),
    similarSeedsProvider.overrideWith((ref, id) async => (similar ?? const {})[id] ?? const SimilarResult(items: [], available: true)),
    homeFeedProvider.overrideWith(() => FakeHomeFeed(viewOf(loadFeed('onboarded')))),
    if (tonight) ...[
      clockProvider.overrideWithValue(() => kTonightNow),
      ...contentModeOverrides(mode: ContentMode.manga, novelsEnabled: true),
      sourcesListProvider.overrideWith((ref) async => const [SourceSummary(id: 'shelf', name: 'Shelf Scans', description: '', browsable: true, supportsImport: false)]),
    ],
    ...extra,
  ];
  final router = GoRouter(
    initialLocation: step == null ? '/welcome' : '/welcome?step=$step',
    routes: [
      GoRoute(path: '/', pageBuilder: (context, state) => cineCutPage(state, tonight ? const TonightScreen() : const Scaffold(body: Text('TONIGHT')))),
      GoRoute(path: '/welcome', pageBuilder: (context, state) => cineDipPage(state, OnboardingScreen(requestedStep: int.tryParse(state.uri.queryParameters['step'] ?? '')))),
      GoRoute(path: '/profiles', builder: (_, __) => const Scaffold(body: Text('PICKER'))),
    ],
  );
  return OnboardingParts(overrides, router, fakeRepo, fakeLib, haptics);
}

/// Covers resolve to a 1 x 1 picture unless a test swaps the builder.
void stubCovers() {
  final prevProvider = CineImage.providerBuilder, prevProbe = CineImage.cacheProbe;
  CineImage.cacheProbe = (_) async => false;
  CineImage.providerBuilder = (url, headers) => MemoryImage(Uint8List.fromList(base64Decode(_png)));
  addTearDown(() {
    CineImage.providerBuilder = prevProvider;
    CineImage.cacheProbe = prevProbe;
  });
}

/// Pumps the Cinematic onboarding at `/welcome?step=[step]`, with Tonight (the real screen fed by
/// the `onboarded` fixture) at `/` and a stub at `/profiles`.
Future<OnboardingRig> pumpOnboarding(
  WidgetTester t, {
  int? step = 2,
  Object? profileStep,
  FakeOnboardingRepo? repo,
  FakeLib? lib,
  bool reduced = false,
  bool novels = true,
  TargetPlatform platform = TargetPlatform.android,
  Size size = const Size(390, 844),
  double scale = 1,
  Map<int, SimilarResult>? similar,
  Map<String, Object> prefs = const {},
  bool tonight = false,
  List<Override> extra = const [],
}) async {
  final parts = await onboardingParts(step: step, profileStep: profileStep, repo: repo, lib: lib, novels: novels, similar: similar, prefs: prefs, tonight: tonight, extra: extra);
  final c = ProviderContainer(overrides: parts.overrides);
  addTearDown(c.dispose);
  await c.read(profilesProvider.future);
  stubCovers();
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  addTearDown(parts.router.dispose);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(
      theme: featureTheme(platform),
      routerConfig: parts.router,
      builder: (context, child) => featureMediaWrap(context, CineShutterLayer(child: CineToastHost(child: FlightLayer(child: child!))), textScale: scale, reduced: reduced),
    ),
  ),);
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
  return OnboardingRig(parts.router, c, parts.repo, parts.lib, parts.haptics);
}

Future<void> settleFor(WidgetTester t, [int ms = 1000]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}
