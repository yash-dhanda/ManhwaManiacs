// ignore_for_file: require_trailing_commas, directives_ordering, avoid_redundant_argument_values, unnecessary_import
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/skins/cinematic/flight.dart';
import 'package:manhwamaniacs/skins/cinematic/flight_layer.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/genre_word.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/shutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../skins/cinematic/feature/feature_test_support.dart' show featureTheme;
import '../../skins/cinematic/onboarding/onboarding_test_support.dart';
import '../support/shot_covers.dart';
import '../support/shot_harness.dart';
import '../support/shot_network.dart';
import '../support/skin_shots.dart';

/// mobile/20 proof: the Cinematic onboarding on phone and tablet, every state on the phone.
///
///   MM_PROOF_DIR=../docs/redesign/proof/mobile-20 flutter test \
///     test/screenshots/cinematic/mobile_20_onboarding_shots_test.dart
///
/// Without MM_PROOF_DIR the shots are rasterised and discarded. Titles and covers are invented.

const _phone = SkinShotSize('phone', Size(390, 844), 2.0, EdgeInsets.only(top: 47, bottom: 34));
const _tablet = SkinShotSize('tablet', Size(834, 1194), 1.5, EdgeInsets.only(top: 24, bottom: 20));
const _land = SkinShotSize('phone', Size(844, 390), 2.0, EdgeInsets.only(left: 47, right: 47, bottom: 21));

const _titles = ['The Lantern Courier', 'Sword of the Ninth Spring', 'Paper Tiger Academy', 'Moonlit Bakery', 'Salt and Ember', 'A Quiet Kingdom', 'Harbour of Small Gods'];
const _keys = ['the-lantern-courier', 'sword-of-the-ninth-spring', 'paper-tiger-academy', 'moonlit-bakery'];
late List<Uint8List> _covers;

Future<void> _ms(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

List<WorldItem> _seeds() => [
      for (var i = 1; i <= 24; i++)
        WorldItem(
          title: i <= _titles.length ? _titles[i - 1] : 'Series $i',
          anilistId: i,
          coverUrl: 'https://img.test/$i.jpg',
          isAdult: false,
          available: i <= 10 && i != 5 ? [WorldAvailability(sourceId: 'shelf', sourceName: 'Shelf', seriesKey: i <= 4 ? _keys[i - 1] : 'x$i')] : const [],
        ),
    ];

OnboardingCatalog _catalog() => OnboardingCatalog(
      formats: [for (final f in FormatId.values) FormatCovers(format: f, covers: ['https://img.test/${f.index * 3 + 1}.jpg', 'https://img.test/${f.index * 3 + 2}.jpg', 'https://img.test/${f.index * 3 + 3}.jpg'])],
      genres: [
        for (final n in ['Romance', 'Fantasy', 'Action', 'Drama', 'Comedy', 'Slice of Life', 'Supernatural', 'Mystery', 'Adventure', 'Psychological', 'Sci-Fi', 'Horror', 'Sports', 'Historical', 'Thriller', 'School Life', 'Martial Arts', 'Isekai', 'Mecha', 'Music', 'Cooking', 'Medical', 'Military', 'Reincarnation', 'Time Travel', 'Villainess', 'Revenge', 'Survival', 'Tragedy', 'Workplace', 'Gyaru', 'Crime', 'Ghosts', 'Magic'])
          GenreWeight(name: n, weight: 40.0 - n.length),
      ],
      seeds: _seeds(),
    );

class _Shot {
  const _Shot(this.name, this.run, {this.coversAfter = true, this.reduced = false, this.scale = 1.0, this.tonight = false, this.repo, this.lib, this.similar});
  final String name;
  final Future<void> Function(WidgetTester t, ProviderContainer c) run;
  final bool reduced, tonight, coversAfter;
  final double scale;
  final FakeOnboardingRepo Function()? repo;
  final FakeLib Function()? lib;
  final Map<int, SimilarResult>? similar;
}

Future<void> _next(WidgetTester t, int n) async {
  for (var i = 0; i < n; i++) {
    await t.tap(find.text('Next'));
    await _ms(t, 700);
  }
}

Future<void> _pick(WidgetTester t, List<int> ids) async {
  for (final id in ids) {
    await t.tap(find.bySemanticsLabel(RegExp('^${_seedTitle(id)}(, picked)?\$')));
    await _ms(t, 250);
  }
}

String _seedTitle(int id) => id <= _titles.length ? _titles[id - 1] : 'Series $id';

Future<void> _print(WidgetTester t) async {
  await t.tap(find.text('Print my first issue'));
  await t.pump();
}

Map<int, SimilarResult> _sim() => {
      2: SimilarResult(items: [for (final i in [31, 32, 33]) WorldItem(title: 'Similar $i', anilistId: i, coverUrl: 'https://img.test/$i.jpg')]),
    };

List<_Shot> _shots() => [
      _Shot('formats', (t, c) async => _ms(t, 1800)),
      _Shot('formats-selected', (t, c) async {
        await t.tap(find.bySemanticsLabel('Manga'));
        await t.tap(find.bySemanticsLabel('Manhua'));
        await _ms(t, 1800);
      }),
      _Shot('formats-grid', (t, c) async => _ms(t, 1800)),
      _Shot('genres', (t, c) async {
        await _next(t, 1);
        await _ms(t, 1800);
      }),
      _Shot('genres-marked', (t, c) async {
        await _next(t, 1);
        await t.tap(find.bySemanticsLabel('Romance, not chosen'));
        await t.tap(find.bySemanticsLabel('Fantasy, not chosen'));
        await t.pump();
        await t.tap(find.bySemanticsLabel('Fantasy, liked'));
        final g = await t.startGesture(t.getCenter(find.bySemanticsLabel('Horror, not chosen')));
        await _ms(t, 600);
        await g.up();
        await _ms(t, 1800);
      }),
      _Shot('genres-menu', (t, c) async {
        await _next(t, 1);
        await _ms(t, 1500);
        Focus.of(t.element(find.descendant(of: find.byType(GenreWord).at(3), matching: find.byType(CustomPaint)).first)).requestFocus();
        await t.pump();
        await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await t.sendKeyEvent(LogicalKeyboardKey.f10);
        await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await _ms(t, 500);
      }),
      _Shot('styles', (t, c) async {
        await _next(t, 2);
        await t.tap(find.bySemanticsLabel(RegExp('^Noir')));
        await _ms(t, 1800);
      }),
      _Shot('seeds', (t, c) async {
        await _next(t, 3);
        await _ms(t, 2200);
      }, similar: _sim()),
      _Shot('seeds-picked', (t, c) async {
        await _next(t, 3);
        await _ms(t, 1500);
        await _pick(t, [2, 1, 3]);
        await _ms(t, 1200);
      }, similar: _sim()),
      _Shot('printing', (t, c) async {
        await _next(t, 3);
        await _ms(t, 1200);
        await _pick(t, [1, 2, 3]);
        await _print(t);
        await _ms(t, 900);
      }, lib: () => FakeLib()..hold = Completer<void>()),
      _Shot('flight-mid', (t, c) async {
        await _next(t, 3);
        await _ms(t, 1200);
        await _pick(t, [1, 2, 3, 4]);
        await pumpUntilCoversLoad(t, rounds: 10);
        await _print(t);
        for (var i = 0; i < 80 && c.read(cineFlightProvider).status != FlightStatus.flying; i++) {
          await t.pump(const Duration(milliseconds: 25));
        }
        await _ms(t, 300);
      }, tonight: true, coversAfter: false),
      _Shot('tonight-landed', (t, c) async {
        await _next(t, 3);
        await _ms(t, 1200);
        await _pick(t, [1, 2, 3, 4]);
        await _print(t);
        await _ms(t, 4800);
      }, tonight: true),
    ];

List<_Shot> _phoneOnly() => [
      _Shot('loading-formats', (t, c) async => _ms(t, 400), repo: () => FakeOnboardingRepo(catalog: _catalog())..hold = Completer<void>()),
      _Shot('loading-genres', (t, c) async {
        await _next(t, 1);
        await _ms(t, 500);
      }, repo: () => FakeOnboardingRepo(catalog: _catalog())..hold = Completer<void>()),
      _Shot('loading-seeds', (t, c) async {
        await _next(t, 3);
        await _ms(t, 500);
      }, repo: () => FakeOnboardingRepo(catalog: _catalog())..hold = Completer<void>()),
      _Shot('unreachable-formats', (t, c) async => _ms(t, 1800), repo: () => FakeOnboardingRepo()..error = const ApiError(statusCode: 500, code: 'x', message: 'x')),
      _Shot('unreachable-genres', (t, c) async {
        await _next(t, 1);
        await _ms(t, 3200);
      }, repo: () => FakeOnboardingRepo()..error = const ApiError(statusCode: 500, code: 'x', message: 'x')),
      _Shot('unreachable-seeds', (t, c) async {
        await _next(t, 3);
        await _ms(t, 3200);
      }, repo: () => FakeOnboardingRepo()..error = const ApiError(statusCode: 500, code: 'x', message: 'x')),
      _Shot('ai-unavailable', (t, c) async {
        await _next(t, 3);
        await _ms(t, 1500);
        await _pick(t, [1]);
        await _ms(t, 800);
      }, similar: {1: const SimilarResult(items: [], available: false, reason: 'budget_exhausted')}),
      _Shot('offline', (t, c) async => _ms(t, 3200), repo: () => FakeOnboardingRepo()..error = const NetworkError(message: 'offline')),
      _Shot('follow-partial-toast', (t, c) async {
        await _next(t, 3);
        await _ms(t, 400);
        await _pick(t, [1, 2, 3, 6]);
        await _print(t);
        await _ms(t, 2200);
      }, reduced: true, tonight: true, lib: () => FakeLib()..failing.add('x6')),
      _Shot('reduced-motion-genres', (t, c) async {
        await _next(t, 1);
        await t.tap(find.bySemanticsLabel('Romance, not chosen'));
        await t.pump();
        await t.tap(find.bySemanticsLabel('Romance, liked'));
        await _ms(t, 600);
      }, reduced: true),
      _Shot('text-scale-2-genres', (t, c) async {
        await _next(t, 1);
        await _ms(t, 1800);
      }, scale: 2.0),
      _Shot('landscape-genres', (t, c) async {
        await _next(t, 1);
        await _ms(t, 1800);
      }),
    ];

class _GridGuides extends StatelessWidget {
  const _GridGuides({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = CineGrid.of(context);
    return Stack(children: [
      child,
      IgnorePointer(
        child: Stack(children: [
          for (var i = 0; i < g.columns; i++) Positioned(left: g.col(i), top: 0, bottom: 0, width: g.colWidth, child: const ColoredBox(color: Color(0x22FF5B4A))),
        ]),
      ),
    ],);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  Future<void> shoot(WidgetTester tester, _Shot shot, SkinShotSize size) async {
    await tester.runAsync(() async {
      _covers = [for (var i = 0; i < _titles.length; i++) await ShotCoverArt(title: _titles[i], seed: i).toPng(width: 300, height: 450)];
    });
    ui.Image? flightImage;
    await tester.runAsync(() async {
      final c = await ui.instantiateImageCodec(_covers.first);
      flightImage = (await c.getNextFrame()).image;
    });
    final probe = CineImage.cacheProbe, builder = CineImage.providerBuilder, loader = OnboardingScreen.imageLoader;
    CineImage.cacheProbe = (_) async => false;
    CineImage.providerBuilder = (url, headers) => MemoryImage(_covers[url.hashCode.abs() % _covers.length]);
    OnboardingScreen.imageLoader = (_) async => flightImage!.clone();
    addTearDown(() {
      CineImage.cacheProbe = probe;
      CineImage.providerBuilder = builder;
      OnboardingScreen.imageLoader = loader;
    });
    final repo = shot.repo?.call() ?? FakeOnboardingRepo(catalog: _catalog());
    final parts = await onboardingParts(repo: repo, lib: shot.lib?.call(), similar: shot.similar, tonight: shot.tonight);
    addTearDown(parts.router.dispose);
    late ProviderContainer container;
    Widget app = MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: parts.router,
      theme: featureTheme(TargetPlatform.android),
      builder: (context, child) {
        container = ProviderScope.containerOf(context);
        return CineShutterLayer(child: CineToastHost(child: FlightLayer(child: child!)));
      },
    );
    if (shot.name == 'formats-grid') app = _GridGuides(child: app);
    await captureSkinWidget(
      tester,
      name: shot.name,
      size: size,
      disableAnimations: shot.reduced,
      textScale: shot.scale,
      overrides: parts.overrides,
      settle: (t) => _ms(t, 300),
      afterSettle: (t) async {
        await shot.run(t, container);
        if (shot.coversAfter) await pumpUntilCoversLoad(t, rounds: 20);
      },
      child: app,
    );
    tester.takeException();
  }

  for (final size in [_phone, _tablet]) {
    for (final shot in _shots()) {
      testWidgets('${shot.name} ${size.name}', (tester) => shoot(tester, shot, size));
    }
  }
  for (final shot in _phoneOnly()) {
    testWidgets('${shot.name} phone', (tester) => shoot(tester, shot, shot.name == 'landscape-genres' ? _land : _phone));
  }
}
