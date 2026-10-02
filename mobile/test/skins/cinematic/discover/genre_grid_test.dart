import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/repositories/ask_repository.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/genre_grid.dart';

import 'harness.dart';

class _MatureOff extends MatureContentController {
  @override
  Future<bool> build() async => false;
}

/// Page n holds titles n*10 .. n*10+9, plus one repeat of the page before.
class _Pages extends AskRepository {
  _Pages() : super(Dio());
  final cursors = <String?>[];
  bool fail = false;
  bool end = false;

  @override
  Future<Result<WorldGenrePage>> genrePage(String genre, {String? cursor, CancelToken? cancel}) async {
    cursors.add(cursor);
    if (fail) return const Err(UnknownError(message: 'down'));
    final n = int.parse(cursor ?? '0');
    return Ok(WorldGenrePage(
      items: [
        if (n > 0) WorldItem(title: 'Title ${n * 10 - 1}', anilistId: n * 10 - 1),
        for (var i = n * 10; i < n * 10 + 10; i++) WorldItem(title: 'Title $i', anilistId: i),
      ],
      nextCursor: end ? null : '${n + 1}',
    ),);
  }
}

Future<_Pages> _pump(WidgetTester tester, {bool fail = false}) async {
  final pages = _Pages()..fail = fail;
  await pumpScreen(
    tester,
    const GenreGridScreen(genre: 'Murim'),
    extra: [
      askRepositoryProvider.overrideWithValue(pages),
      matureContentProvider.overrideWith(_MatureOff.new),
    ],
  );
  await settle(tester, 800);
  return pages;
}

void main() {
  testWidgets('scrolling past 70 % fetches the next page', (tester) async {
    final pages = await _pump(tester);
    expect(pages.cursors, ['0']);
    expect(find.text('Title 0'), findsWidgets);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
    await settle(tester);
    expect(pages.cursors, ['0', '1']);

  });

  testWidgets('a short page fills the screen; repeats render once', (tester) async {
    final pages = _Pages();
    await pumpScreen(
      tester,
      const GenreGridScreen(genre: 'Murim'),
      size: const Size(390, 2400),
      extra: [
        askRepositoryProvider.overrideWithValue(pages),
        matureContentProvider.overrideWith(_MatureOff.new),
      ],
    );
    await settle(tester, 800);
    expect(pages.cursors, ['0', '1']);
    // Title 9 came twice (end of page 0, again on page 1). A card prints its
    // title more than once, so compare with a title that came once.
    expect(find.text('Title 9'), findsWidgets);
    expect(find.text('Title 9').evaluate().length, find.text('Title 8').evaluate().length);
  });

  testWidgets('pull to reprint swaps in a fresh batch', (tester) async {
    final pages = await _pump(tester);
    expect(find.text('Title 0'), findsWidgets);
    await tester.timedDrag(find.byType(CustomScrollView), const Offset(0, 400), const Duration(milliseconds: 600));
    await settle(tester, 2000);
    expect(pages.cursors, ['0', '1']);
    expect(find.text('Title 0'), findsNothing);
    expect(find.text('Title 10'), findsWidgets);
  });

  testWidgets('a failed page says so and retries', (tester) async {
    final pages = await _pump(tester, fail: true);
    expect(find.text('CORRECTION'), findsOneWidget);
    pages.fail = false;
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('Title 0'), findsWidgets);
  });

  testWidgets('pull to reprint works after the list has ended', (tester) async {
    final pages = _Pages()..end = true;
    await pumpScreen(
      tester,
      const GenreGridScreen(genre: 'Murim'),
      extra: [
        askRepositoryProvider.overrideWithValue(pages),
        matureContentProvider.overrideWith(_MatureOff.new),
      ],
    );
    await settle(tester, 800);
    expect(pages.cursors, ['0']);
    await tester.widget<CinePullToReprint>(find.byType(CinePullToReprint)).onRefresh();
    await settle(tester);
    expect(pages.cursors, ['0', '0']);
    expect(find.text('Title 0'), findsWidgets);
  });

  testWidgets('a search opened from the grid is not left underneath it', (tester) async {
    final router = GoRouter(initialLocation: '/search', routes: [
      GoRoute(
        path: '/search',
        builder: (context, s) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const GenreGridScreen(genre: 'Murim')),
            ),
            child: Text('at ${s.uri}'),
          ),
        ),
      ),
    ],);
    await pumpScreen(tester, const SizedBox(), router: router, extra: [
      askRepositoryProvider.overrideWithValue(_Pages()),
      matureContentProvider.overrideWith(_MatureOff.new),
    ],);
    await settle(tester);
    await tester.tap(find.text('at /search'));
    await settle(tester, 800);
    expect(find.byType(GenreGridScreen), findsOneWidget);
    router.go('/search?q=Solo');
    await settle(tester, 800);
    expect(find.byType(GenreGridScreen), findsNothing);
    expect(find.text('at /search?q=Solo'), findsOneWidget);
  });
}
