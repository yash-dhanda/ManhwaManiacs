// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_screen.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../feature/feature_test_support.dart';

/// The fixed evening of the Tonight tests: a Wednesday at 21:04.
final DateTime kTonightNow = DateTime(2026, 9, 30, 21, 4);

HomeFeed loadFeed(String name) =>
    HomeFeed.fromJson(jsonDecode(File('test/fixtures/home/$name.json').readAsStringSync()) as Map<String, dynamic>);

HomeFeedView viewOf(HomeFeed f, {HomeFeedOrigin origin = HomeFeedOrigin.server, bool offline = false, HomeFeedState? state}) => (
      state: state ?? HomeFeedState.ready,
      feed: f,
      origin: origin,
      offline: offline,
      retryAfter: null,
    );

class FakeHomeFeed extends HomeFeedController {
  FakeHomeFeed(this.view, {this.hold});
  final HomeFeedView? view;

  /// When set, `build` waits on it (the loading state).
  final Future<void>? hold;
  static int refreshed = 0;

  @override
  Future<HomeFeedView> build() async {
    if (hold != null) await hold;
    return view ?? (state: HomeFeedState.unavailable, feed: null, origin: HomeFeedOrigin.local, offline: false, retryAfter: null);
  }

  @override
  Future<void> refresh() async => refreshed++;
}

class TonightRig {
  TonightRig(this.rec);
  final Recorder rec;

  /// Every location the router was sent to, newest last.
  final List<String> visited = [];
}

const _stubPaths = [
  '/library', '/discover', '/downloads', '/updates', '/picks', '/numbers', '/circle', '/sources', '/sources/:sid', '/collections',
  '/sources/:sid/series/:kid', '/reader/:a/:b/:c', '/novels/:a/:b/:c', '/recap/:a/:b',
];

/// Pumps Tonight in a router of stub pages, with the providers the screen reads.
Future<TonightRig> pumpTonight(
  WidgetTester tester, {
  String? feed,
  HomeFeedView? view,
  bool wide = false,
  Size? size,
  double textScale = 1,
  bool reduced = false,
  TargetPlatform platform = TargetPlatform.android,
  DateTime? now,
  bool novel = false,
  Future<void>? hold,
  List<Override> extra = const [],
  Map<String, Object> prefs = const {},
}) async {
  ReaderPrefetch.reset();
  final rig = TonightRig(Recorder());
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  sizeView(tester, wide: wide, size: size);
  final v = view ?? (feed == null ? null : viewOf(loadFeed(feed)));
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const TonightScreen()),
      for (final path in _stubPaths)
        GoRoute(
          path: path,
          builder: (context, state) {
            rig.visited.add(state.uri.toString());
            return Scaffold(body: Center(child: Text('stub ${state.uri}')));
          },
        ),
    ],
  );
  router.routerDelegate.addListener(() => rig.visited.add(router.routerDelegate.currentConfiguration.uri.toString()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(p),
        apiBaseUrlOverride('http://example.test'),
        ...noDownloadsStoreOverrides(),
        ...contentModeOverrides(mode: novel ? ContentMode.novel : ContentMode.manga, novelsEnabled: true),
        authenticatedAuthOverride(),
        activeProfileOverride(),
        clockProvider.overrideWithValue(() => now ?? kTonightNow),
        homeFeedProvider.overrideWith(() => FakeHomeFeed(v, hold: hold)),
        readerRepositoryProvider.overrideWithValue(FakeReader(rig.rec)),
        skinHapticsProvider.overrideWithValue(RecordingHaptics(rig.rec)),
        sourcesListProvider.overrideWith((ref) async => const [
              SourceSummary(id: 'shelf', name: 'Shelf Scans', description: '', browsable: true, supportsImport: false),
            ]),
        ...extra,
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: featureTheme(platform),
        routerConfig: router,
        builder: (context, c) => featureMediaWrap(context, c, textScale: textScale, reduced: reduced),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return rig;
}

/// Lets entrance animations run: `pump` in 100 ms steps.
Future<void> settleTonight(WidgetTester tester, {Duration by = const Duration(seconds: 6)}) async {
  for (var t = 0; t < by.inMilliseconds; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
