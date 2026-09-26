/// The two kinds of world card: one a source of the reader's carries (opens
/// that series), and one nobody here carries (says so, offers a search and an
/// official link instead of a series page that does not exist).
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/interceptors/auth_interceptor.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/library/widgets/recommendations/world_title_card.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

import '../../support/test_overrides.dart';

const _carried = WorldItem(
  title: 'Nano Machine',
  format: 'Manhwa',
  status: 'Ongoing',
  chapters: 181,
  rating: 8.1,
  genres: ['Action', 'Martial Arts', 'Sci-Fi', 'Drama'],
  platforms: [WorldPlatform(site: 'Webtoon', url: 'https://www.webtoons.com/x')],
  available: [
    WorldAvailability(
      sourceId: 'asurascans',
      sourceName: 'Asura Scans',
      seriesKey: 'nano-machine/6f7fe6eb',
    ),
    WorldAvailability(
      sourceId: 'mangadex',
      sourceName: 'MangaDex',
      seriesKey: 'abc',
    ),
  ],
  why: 'Same murim revenge arc.',
);

const _uncarried = WorldItem(
  title: 'The Greatest Estate Developer',
  format: 'Manhwa',
  status: 'Completed',
  platforms: [WorldPlatform(site: 'Webtoon', url: 'https://www.webtoons.com/y')],
);

Future<void> _pump(WidgetTester tester, WorldItem item) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: SingleChildScrollView(child: WorldTitleCard(item: item)),
        ),
      ),
      GoRoute(
        path: '/sources/:sourceId/series/:seriesId',
        builder: (_, state) => Scaffold(
          body: Text(
            'SOURCE ${state.pathParameters['sourceId']} '
            '${state.pathParameters['seriesId']}',
          ),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => Scaffold(
          body: Consumer(
            builder: (_, ref, __) =>
                Text('SEARCH ${ref.watch(searchQueryProvider)}'),
          ),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a carried title shows its facts and opens the first source',
      (tester) async {
    await _pump(tester, _carried);

    expect(find.text('Nano Machine'), findsOneWidget);
    expect(find.text('Manhwa · Ongoing'), findsOneWidget);
    expect(find.text('181 ch · ★ 8.1'), findsOneWidget);
    // At most three genres.
    expect(find.text('Action · Martial Arts · Sci-Fi'), findsOneWidget);
    expect(find.text('On: Asura Scans (+1 more)'), findsOneWidget);
    expect(find.text('Same murim revenge arc.'), findsOneWidget);
    // It opens in the app; no search, no way out.
    expect(find.text('Not on your sources'), findsNothing);
    expect(find.text('Search'), findsNothing);
    expect(find.textContaining('Read on'), findsNothing);

    await tester.tap(find.text('Nano Machine'));
    await tester.pumpAndSettle();

    // The slash in the key survives the round trip through the route.
    expect(
      find.text('SOURCE asurascans nano-machine/6f7fe6eb'),
      findsOneWidget,
    );
  });

  testWidgets('an uncarried title offers a search, not a series page',
      (tester) async {
    await _pump(tester, _uncarried);

    expect(find.text('Not on your sources'), findsOneWidget);
    expect(find.text('Read on Webtoon'), findsOneWidget);
    expect(find.textContaining('On: '), findsNothing);
    // Unknown chapters and rating are hidden, not printed as "null".
    expect(find.textContaining(RegExp(r'\d+ ch')), findsNothing);
    expect(find.textContaining('★'), findsNothing);

    // Tapping the card itself goes nowhere.
    await tester.tap(find.text('The Greatest Estate Developer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SOURCE'), findsNothing);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(
      find.text('SEARCH The Greatest Estate Developer'),
      findsOneWidget,
    );
  });

  testWidgets('the external cover is fetched without the session token',
      (tester) async {
    // The cover lives on the catalog's CDN. The bearer token and profile id
    // are this server's; attached to a third-party request they are a leak.
    const cover = 'https://s4.anilist.co/file/anilistcdn/cover/bx1.jpg';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authTokenStoreProvider
              .overrideWithValue(AuthTokenStore()..token = 'secret-token'),
          activeProfileOverride(),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WorldTitleCard(
              item: WorldItem(title: 'Nano Machine', coverUrl: cover),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final image =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    // Untouched: no `?w=` bolted onto somebody else's URL.
    expect(image.imageUrl, cover);
    expect(image.httpHeaders, isNull);
  });

  testWidgets('no official platform means no outbound link', (tester) async {
    await _pump(tester, const WorldItem(title: 'Obscure One'));

    expect(find.text('Not on your sources'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.textContaining('Read on'), findsNothing);
  });
}
