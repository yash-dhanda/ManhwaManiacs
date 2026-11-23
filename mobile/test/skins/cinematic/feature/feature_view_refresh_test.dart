// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';

import 'feature_test_support.dart';

void main() {
  testWidgets('a refetch that fails keeps the loaded series page and says so in a toast', (tester) async {
    final f = loadSeriesFixture('manga-ongoing');
    var calls = 0;
    await pumpFeature(
      tester,
      child: const FeatureView(sourceId: 'demo', seriesKey: 'k'),
      rig: FeatureRig(extra: [
        sourceSeriesDetailProvider.overrideWith((ref, key) async {
          if (++calls > 1) throw const NetworkError(message: 'down');
          return SourceSeriesDetailData(series: f.series, chapters: f.chapters);
        }),
      ]),
    );
    await frames(tester, 300);
    expect(find.byType(MangaFeatureView), findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(find.byType(FeatureView)));
    container.invalidate(sourceSeriesDetailProvider((sourceId: 'demo', seriesId: 'k')));
    await frames(tester, 300);

    expect(calls, 2);
    expect(find.byType(MangaFeatureView), findsOneWidget);
    expect(find.text("Couldn't load this series."), findsNothing);
    expect(container.read(cineToastsProvider).map((t) => t.text), contains("Couldn't refresh this series."));
  });

  testWidgets('a first load that fails still shows the error state', (tester) async {
    await pumpFeature(
      tester,
      child: const FeatureView(sourceId: 'demo', seriesKey: 'k'),
      rig: FeatureRig(extra: [
        sourceSeriesDetailProvider.overrideWith((ref, key) async => throw const NetworkError(message: 'down')),
      ]),
    );
    await frames(tester, 300);
    expect(find.byType(MangaFeatureView), findsNothing);
  });
}
