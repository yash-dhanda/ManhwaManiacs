import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/glass/parts/ai/more_like_this_rail.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../picks/ai_rig.dart';
import '../primitives/support.dart' show primHost, pumpFor;

List<WorldItem> items(int n) => [for (var i = 0; i < n; i++) WorldItem.fromJson(itemJson('Like $i', id: i + 1))];

Future<void> pumpRail(WidgetTester t, SimilarResult ai, SimilarResult genres) => t.pumpWidget(
      primHost(
        const SizedBox(width: 390, height: 320, child: MoreLikeThisRail(sourceId: 's', seriesKey: 'k', title: 'Solo Leveling')),
        overrides: [similarProvider.overrideWith((ref, q) async => q.fallbackGenres ? genres : ai)],
      ),
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the AI rail reads More like {title} with its why lines and the sparkle', (t) async {
    await pumpRail(t, SimilarResult(items: items(3)), const SimilarResult());
    await pumpFor(t, 600);
    expect(find.text('More like Solo Leveling'), findsOneWidget);
    expect(find.textContaining('Because Like 0 fits.'), findsOneWidget);
    expect(find.text('Same genres'), findsNothing);
  });

  testWidgets('unavailable AI reloads with fallback=genres: Same genres, no why; fewer than 3 omit the rail', (t) async {
    await pumpRail(t, const SimilarResult(available: false, reason: 'not_configured'), SimilarResult(items: items(3), basis: 'genres'));
    await pumpFor(t, 600);
    expect(find.text('Same genres'), findsOneWidget);
  });

  testWidgets('fewer than 3 genre items omit the rail', (t) async {
    await pumpRail(t, const SimilarResult(available: false, reason: 'not_configured'), SimilarResult(items: items(2), basis: 'genres'));
    await pumpFor(t, 600);
    expect(find.byType(MoreLikeThisRail), findsOneWidget);
    expect(find.text('More like Solo Leveling'), findsNothing);
  });

  testWidgets('no similar items omits the rail', (t) async {
    await pumpRail(t, const SimilarResult(), const SimilarResult());
    await pumpFor(t, 600);
    expect(find.text('More like Solo Leveling'), findsNothing);
  });
}
