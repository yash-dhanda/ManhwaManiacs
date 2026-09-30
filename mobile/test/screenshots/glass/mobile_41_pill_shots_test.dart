@Tags(['screenshots'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/skins/glass/parts/ai/more_like_this_rail.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/chapter_pill.dart';

import '../../skins/glass/picks/ai_rig.dart';
import '../../skins/glass/primitives/support.dart' show primHost;
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The mobile/41 chapter-pill capture. The manga reader is another step's screen, so the pill is shown in its top-centre slot on a
/// reader-dark page. Written only when `MM_PROOF_DIR` is set.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('the chapter pill in the reader slot', (t) async {
    const size = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
    await captureSkinWidget(
      t,
      name: 'chapter-pill',
      size: size,
      overrides: [recapAvailabilityProvider.overrideWith((ref, k) async => const RecapAvailability(available: true, estSeconds: 20))],
      child: primHost(
        const ColoredBox(color: Color(0xFF050507), child: Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: 60), child: RecapChapterPill(sourceId: 's', seriesKey: 'k', chapterKey: 'c')))),
        align: false,
      ),
    );
  });

  testWidgets('More like this, with and without the AI', (t) async {
    const size = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
    WorldItem w(String n, int i) => WorldItem.fromJson(itemJson(n, id: i));
    final items = [w('Tower Climb', 1), w('Gate Keeper', 2), w('Night Hunter', 3)];
    for (final (name, ai, genres) in [
      ('more-like-this', SimilarResult(items: items), const SimilarResult()),
      ('more-like-this-genres', const SimilarResult(available: false, reason: 'not_configured'), SimilarResult(items: items, basis: 'genres')),
    ]) {
      await captureSkinWidget(
        t,
        name: name,
        size: size,
        overrides: [similarProvider.overrideWith((ref, q) async => q.fallbackGenres ? genres : ai)],
        child: primHost(
          const RepaintBoundary(child: ColoredBox(color: Color(0xFF0B0B0F), child: SizedBox(width: 390, height: 320, child: MoreLikeThisRail(sourceId: 's', seriesKey: 'k', title: 'Solo Leveling')))),
          align: false,
        ),
      );
    }
  });
}
