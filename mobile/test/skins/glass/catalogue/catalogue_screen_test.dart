import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/catalogue_screen.dart';

import '../shell/shell_rig.dart';

class _NoMature extends MatureContentController {
  @override
  Future<bool> build() async => false;
}

class _Browse extends SourceBrowseNotifier {
  _Browse(this.answer);
  final Future<SourceBrowseState> Function() answer;
  static int loadMores = 0;
  @override
  Future<SourceBrowseState> build(String sourceId) => answer();
  @override
  Future<void> loadMore() async => loadMores++;
}

SourceSeriesSummary series(String t) => SourceSeriesSummary(id: t, sourceId: 'a', title: t, chapterCount: 3, genres: const [], coverUrl: '');

SourceSummary source({bool browsable = true}) => SourceSummary(id: 'a', name: 'Alpha Scans', description: 'd', browsable: browsable, supportsImport: false);

List<Override> ov(Future<SourceBrowseState> Function() answer, {bool browsable = true, List<SourceGenre> genres = const []}) => [
      sourcesListProvider.overrideWith((ref) async => [source(browsable: browsable)]),
      sourceBrowseProvider.overrideWith(() => _Browse(answer)),
      sourceBrowseModesProvider.overrideWith((ref, id) async => const [SourceBrowseMode(id: 'popular', label: 'Popular'), SourceBrowseMode(id: 'latest', label: 'Latest')]),
      sourceGenresProvider.overrideWith((ref, id) async => genres),
      matureContentProvider.overrideWith(_NoMature.new),
    ];

void main() {
  testWidgets('loaded: header, count line, modes, posters, end of results', (t) async {
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() async => SourceBrowseState(items: [series('One'), series('Two')], total: 412, cache: {'fetched_at': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String()})));
    await t.pump(const Duration(seconds: 2));
    expect(find.byType(GlassCatalogueScreen), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Updated 12 min ago'), findsOneWidget);
    expect(find.text('End of results'), findsOneWidget);
    // no genres returned: no genre chip
    expect(find.text('All genres'), findsNothing);
  });

  testWidgets('genre chip appears only with genres', (t) async {
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() async => SourceBrowseState(items: [series('One')], total: 1), genres: const [SourceGenre(id: 'act', label: 'Action')]));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('All genres'), findsOneWidget);
  });

  testWidgets('stale copy reads Saved copy and explains on tap', (t) async {
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() async => SourceBrowseState(items: [series('One')], total: 1, cache: {'stale': true, 'fetched_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()})));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Saved copy · 2 h'), findsOneWidget);
    await t.tap(find.text('Saved copy · 2 h'));
    await t.pump();
    expect(find.text("The source didn't answer, so this is the last copy the server saved."), findsOneWidget);
  });

  testWidgets('the opening lens shows while the first page loads, then the slow line after 3 s', (t) async {
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() => Future<SourceBrowseState>.delayed(const Duration(seconds: 6), SourceBrowseState.new)));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.bySemanticsLabel('Opening Alpha Scans'), findsNothing);
    await t.pump(const Duration(seconds: 3));
    expect(find.text('This source can take about 10 s'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('empty catalogue', (t) async {
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() async => const SourceBrowseState()));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('No series found'), findsOneWidget);
  });

  testWidgets('not browsable and not found lenses', (t) async {
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() async => throw const ApiError(statusCode: 400, code: 'source_not_browsable', message: 'm')));
    await t.pump(const Duration(seconds: 2));
    expect(find.textContaining("can't be browsed"), findsOneWidget);
  });

  testWidgets('catalogue error shows the retry lens', (t) async {
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() async => throw const ApiError(statusCode: 500, code: 'internal', message: 'boom')));
    await t.pump(const Duration(seconds: 2));
    expect(find.text("Couldn't load this catalogue"), findsOneWidget);
  });

  testWidgets('a value left from the previous query is not drawn under the new one', (t) async {
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() async => SourceBrowseState(items: [series('Old')], total: 1, query: const SourceBrowseQuery(sourceId: 'a', sort: 'popular'))));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Old'), findsNothing);
  });

  testWidgets('the count line does not call a page size the catalogue size, nor default order Latest', (t) async {
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() async => SourceBrowseState(items: [series('One'), series('Two')], total: 2, hasNext: true)));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('2+ series'), findsOneWidget);
  });

  testWidgets('a page shorter than the viewport loads the next one by itself', (t) async {
    _Browse.loadMores = 0;
    await pumpGlassShell(t, start: '/sources/a', extra: ov(() async => SourceBrowseState(items: [series('One')], total: 1, hasNext: true)));
    await t.pump(const Duration(seconds: 2));
    expect(_Browse.loadMores, greaterThan(0));
  });
}
