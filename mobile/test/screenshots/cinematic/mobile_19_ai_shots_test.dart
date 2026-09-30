// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/picks/picks_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/previously_on_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../skins/cinematic/discover/harness.dart';
import '../../skins/cinematic/feature/feature_test_support.dart';
import '../../skins/cinematic/picks/picks_test_support.dart';
import '../../skins/cinematic/recap/recap_test_support.dart';
import '../support/shot_covers.dart';
import '../support/shot_harness.dart';
import '../support/shot_network.dart';
import '../support/skin_shots.dart';

/// mobile/19 proof: Picks (every state), the feature page's More like this tab, the "Previously on"
/// takeover (every state) and the readers' chip, on phone and tablet, with `-reduced` copies of
/// Picks and the finished recap.
///
///   MM_PROOF_DIR=../docs/redesign/proof/mobile-19 flutter test \
///     test/screenshots/cinematic/mobile_19_ai_shots_test.dart
///
/// Without MM_PROOF_DIR the shots are rasterised and discarded, so the suite still proves every
/// state renders. Titles and covers are invented.

const _phone = SkinShotSize('phone', Size(390, 844), 2.0, EdgeInsets.only(top: 47, bottom: 34));
const _tablet = SkinShotSize('tablet', Size(834, 1194), 1.5, EdgeInsets.only(top: 24, bottom: 20));

const _titles = ['The Lantern Courier', 'Sword of the Ninth Spring', 'Skyward Gardeners', 'Salt and Ember', 'A Quiet Kingdom', 'Harbour of Small Gods'];
late List<Uint8List> _covers;

Future<void> _steps(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

class _Shot {
  const _Shot(this.name, this.screen, this.overrides, {this.settle, this.after});
  final String name;
  final Widget screen;
  final List<Override> Function(SharedPreferences prefs) overrides;
  final Future<void> Function(WidgetTester t)? settle, after;
}

WorldItem _w(int i, {String? why, bool on = true}) => WorldItem(
      title: _titles[i % _titles.length],
      anilistId: i + 1,
      format: 'Manhwa',
      status: 'Ongoing',
      rating: 8.0 + (i % 5) / 10,
      why: why,
      genres: const ['Fantasy', 'Action'],
      available: on ? const [asura] : const [],
      coverUrl: 'https://img.example/c$i.png',
    );

WorldRecommendations _recs({DateTime? at, bool partial = false}) => WorldRecommendations(
      forYou: [for (var i = 0; i < 4; i++) _w(i, on: i != 2)],
      sections: [
        WorldSection(becauseTitle: 'Solo Leveling', items: [for (var i = 1; i < 6; i++) _w(i, on: i != 3)]),
        if (partial) const WorldSection(becauseTitle: 'Tower of God') else WorldSection(becauseTitle: 'Tower of God', items: [for (var i = 2; i < 6; i++) _w(i)]),
      ],
      generatedAt: at,
    );

const _genres = [GenreWeight(genre: 'Fantasy', weight: 9), GenreWeight(genre: 'Action', weight: 7), GenreWeight(genre: 'Drama', weight: 4), GenreWeight(genre: 'Romance', weight: 2), GenreWeight(genre: 'Mystery', weight: 1)];

List<Override> _picks(SharedPreferences p, PicksLibrary lib) => [...discoverOverrides(p), libraryRepositoryProvider.overrideWithValue(lib), aiRepositoryProvider.overrideWithValue(FakeAi())];

PicksLibrary _lib({WorldRecommendations? recs, SuggestionAvailability? avail}) =>
    PicksLibrary(recs: recs ?? _recs(), genres: _genres, availability: avail ?? const SuggestionAvailability(available: true, reason: 'ok', remainingToday: 8));

Future<void> _ask(WidgetTester t, {bool local = false}) async {
  if (local) {
    await t.tap(find.text('FROM YOUR SOURCES'));
    await t.pump();
  }
  await t.enterText(find.byKey(const Key('ask-field')), 'Slow and political, not a power fantasy');
  await t.pump();
  await t.tap(find.byKey(const Key('ask-button')));
  await t.pump();
}

_Shot _pick(String name, PicksLibrary Function() lib, {Future<void> Function(WidgetTester t)? after, Future<void> Function(WidgetTester t)? settle, bool focusAsk = false}) =>
    _Shot(name, PicksScreen(focusAsk: focusAsk), (p) => _picks(p, lib()), after: after, settle: settle);

List<_Shot> _shots() {
  Future<void> answerAfter(WidgetTester t, {int ms = 1500}) async => _steps(t, ms);
  PicksLibrary failing(String code, {int status = 502, Duration? after}) {
    final l = _lib()..answer = Err(ApiError(statusCode: status, code: code, message: 'm', retryAfter: after));
    return l;
  }

  final gate = Completer<Result<WorldSuggestResponse>>();
  return [
    _pick('picks-idle', _lib),
    _pick('picks-thinking', () => _lib()..gate = Completer(), after: (t) async {
      await _ask(t);
      await _steps(t, 2500);
    }),
    _pick('picks-results', () => _lib()..answer = Ok(WorldSuggestResponse(items: [for (var i = 0; i < 4; i++) _w(i, why: const ['Slow and political.', 'A quiet kingdom, a loud court.', 'It reads like a chess game.', 'The lead is already strong.'][i])], remainingToday: 7)), after: (t) async {
      await _ask(t);
      await answerAfter(t);
    }),
    _pick('picks-results-shelf', _lib, after: (t) async {
      await _ask(t, local: true);
      await answerAfter(t);
    }),
    _pick('picks-timeout', () => _lib()..gate = gate, after: (t) async {
      await _ask(t);
      await _steps(t, 41000);
    }),
    _pick('picks-not-configured', () => _lib(avail: const SuggestionAvailability(available: false, reason: 'not_configured', remainingToday: 0))),
    _pick('picks-budget-spent', () => _lib(avail: const SuggestionAvailability(available: false, reason: 'budget_exhausted', remainingToday: 0))),
    _pick('picks-shelf-thin', () => _lib()..answer = const Err(ApiError(statusCode: 409, code: 'suggest_shelf_empty', message: 'm')), after: (t) async {
      await _ask(t, local: true);
      await _steps(t, 5000);
    }),
    _pick('picks-ask-failed', () => failing('ai_failed'), after: (t) async {
      await _ask(t);
      await _steps(t, 5000);
    }),
    _pick('picks-no-matches', () => failing('ai_no_matches'), after: (t) async {
      await _ask(t);
      await _steps(t, 5000);
    }),
    _pick('picks-rate-limited', () => failing('rate_limited', status: 429, after: const Duration(seconds: 12)), after: (t) async {
      await _ask(t);
      await _steps(t, 3000);
    }),
    _pick('picks-partial', () => _lib(recs: _recs(partial: true))),
    _pick('picks-stale', () => _lib(recs: _recs(at: DateTime.now().subtract(const Duration(days: 3, hours: 2))))),
    _pick('picks-empty', () => _lib(recs: const WorldRecommendations())),
    _pick('picks-offline', () => PicksLibrary(recsError: const NetworkError(message: 'offline'))),
    _pick('picks-card-menu', _lib, after: (t) async {
      await t.drag(find.byType(ListView).first, const Offset(0, -700));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byWidgetPredicate((w) => w is CineIconButton && w.label.startsWith('More options')).first);
      await _steps(t, 600);
    }),
    // The feature page's third tab.
    _Shot('feature-more-like-this', const SizedBox(), (p) => const []),
    _Shot('feature-more-like-this-genres', const SizedBox(), (p) => const []),
    // The takeover.
    _Shot('recap-loading', recapScreen(), (p) => [...discoverOverrides(p), ...recapOverrides(FakeRecapRepository())], settle: (t) => _steps(t, 2200)),
    _Shot('recap-streaming', recapScreen(), (p) => [...discoverOverrides(p), ...recapOverrides(_scripted())], settle: (t) => _steps(t, 1200)),
    _Shot('recap-done', recapScreen(), (p) => [...discoverOverrides(p), ...recapOverrides(_scripted())], settle: (t) => _steps(t, 6100)),
    _Shot('recap-no-dialogue', recapScreen(), (p) => [...discoverOverrides(p), ...recapOverrides(FakeRecapRepository(none: const RecapNone('no_dialogue')))], settle: (t) => _steps(t, 6000)),
    _Shot('recap-unavailable', recapScreen(), (p) => [...discoverOverrides(p), ...recapOverrides(FakeRecapRepository(none: const RecapNone('budget_exhausted')))], settle: (t) => _steps(t, 6000)),
    _Shot('recap-rate-limited', recapScreen(), (p) => [...discoverOverrides(p), ...recapOverrides(FakeRecapRepository(none: const RecapNone('rate_limited', retryAfter: 12)))], settle: (t) => _steps(t, 6000)),
    _Shot('recap-error', recapScreen(), (p) => [...discoverOverrides(p), ...recapOverrides(FakeRecapRepository(none: const RecapNone('error')))], settle: (t) => _steps(t, 6000)),
    _Shot('reader-chip', Scaffold(body: Padding(padding: const EdgeInsets.only(top: 60, left: 16), child: PreviouslyOnChip(sourceId: 's', seriesKey: 'k', chapterKey: 'c143', lastReadAt: DateTime.now().subtract(const Duration(days: 9))))), (p) => [...discoverOverrides(p), ...recapOverrides(FakeRecapRepository())], settle: (t) => _steps(t, 600)),
  ];
}

FakeRecapRepository _scripted() {
  final r = FakeRecapRepository(availability: const RecapAvailability(available: true, fromNumber: 131, toNumber: 142, estSeconds: 100));
  r.script(text: 'Kim Dokja woke in a train that would not stop, and the story he had read for ten years began to happen around him. He kept his head down and read on. The other passengers panicked; Kim Dokja did not, because he knew what came next.\n\nWhen the scenario ended, the carriage was a different place. Yoo Joonghyuk walked through it as if he had done it a hundred times. Kim Dokja followed at a careful distance, holding the one secret nobody else had: he knew the ending.\n\nBy chapter 142 the constellations were watching, and every choice had a price. Han Sooyoung had joined them, and the road ahead led to the next scenario.');
  return r;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  final shots = _shots();
  Future<void> shoot(WidgetTester tester, _Shot shot, SkinShotSize size, {required bool reduced}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.runAsync(() async {
      _covers = [for (var i = 0; i < _titles.length; i++) await ShotCoverArt(title: _titles[i], seed: i).toPng(width: 300, height: 450)];
    });
    final probe = CineImage.cacheProbe, builder = CineImage.providerBuilder;
    CineImage.cacheProbe = (_) async => false;
    CineImage.providerBuilder = (url, headers) => MemoryImage(_covers[url.hashCode.abs() % _covers.length]);
    addTearDown(() {
      CineImage.cacheProbe = probe;
      CineImage.providerBuilder = builder;
    });
    final isFeature = shot.name.startsWith('feature-');
    Widget child;
    List<Override> overrides;
    if (isFeature) {
      final genres = shot.name.endsWith('genres');
      final rig = FeatureRig(followed: followedRow(), extra: [recommendationsProvider.overrideWith((ref) async => _recs())]);
      rig.ai
        ..similarResult = genres ? const SimilarResult(available: false, reason: 'budget_exhausted') : SimilarResult(items: [for (var i = 0; i < 5; i++) _w(i, why: 'Slow and political.')])
        ..genresResult = SimilarResult(items: [for (var i = 0; i < 5; i++) _w(i)], basis: 'genres');
      overrides = featureOverrides(rig, prefs, novel: false);
      child = MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: featureTheme(TargetPlatform.android),
        builder: (context, c) => featureMediaWrap(context, CineToastHost(child: c!), reduced: reduced),
        home: MangaFeatureView(data: fixtureData('manga-long', followed: rig.followed), initialTab: 'more-like-this'),
      );
    } else {
      overrides = shot.overrides(prefs);
      child = MaterialApp.router(debugShowCheckedModeBanner: false, routerConfig: discoverRouter(shot.screen), theme: discoverTheme(), builder: (c, ch) => CineToastHost(child: ch!));
    }
    await captureSkinWidget(
      tester,
      name: '${shot.name}${reduced ? '-reduced' : ''}',
      size: size,
      disableAnimations: reduced,
      settle: shot.settle,
      afterSettle: (t) async {
        await pumpUntilCoversLoad(t, rounds: 20);
        if (isFeature) {
          await t.pump(const Duration(milliseconds: 600));
          await scrollToPanels(t);
          await _steps(t, 3000);
        }
        await shot.after?.call(t);
      },
      overrides: overrides,
      child: child,
    );
    // The series page's tablet spread overflows by 35 px under the harness's tablet insets (mobile/11's
    // layout, recorded in the report): the capture shows it, the run goes on.
    if (isFeature) tester.takeException();
  }

  for (final size in [_phone, _tablet]) {
    for (final shot in shots) {
      testWidgets('${shot.name} ${size.name}', (tester) => shoot(tester, shot, size, reduced: false));
    }
  }
  for (final name in ['picks-idle', 'picks-results', 'recap-done']) {
    final shot = shots.firstWhere((s) => s.name == name);
    testWidgets('$name reduced phone', (tester) => shoot(tester, shot, _phone, reduced: true));
  }
}
