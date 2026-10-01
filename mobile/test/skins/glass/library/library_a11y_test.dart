import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';

import '../../../features/library/shelf_fixtures.dart';
import '../../../screenshots/support/shot_harness.dart';
import 'library_rig.dart';

FakeLib _lib() => FakeLib(
      series: [shelfSeries(1, title: 'Alpha'), shelfSeries(2, title: 'Beta'), shelfSeries(3, title: 'Gamma')],
      collections: const [Collection(id: 3, name: 'Weekend reads', seriesCount: 2, sortOrder: 0)],
    );

const _routes = ['/library', '/library/collections', '/library/collections/3', '/library/history', '/library/bookmarks', '/updates', '/downloads', '/downloads?tab=queue', '/downloads?tab=storage'];

void main() {
  setUpAll(loadAppFonts);

  for (final r in _routes) {
    testWidgets('$r meets the iOS tap-target guideline', (t) async {
      final h = t.ensureSemantics();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await pumpLibrary(t, _lib(), start: r);
      await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
      debugDefaultTargetPlatformOverride = null;
      h.dispose();
    });

    testWidgets('$r meets the Android tap-target guideline', (t) async {
      final h = t.ensureSemantics();
      await pumpLibrary(t, _lib(), start: r, android: true);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      debugDefaultTargetPlatformOverride = null;
      h.dispose();
    });
  }

  for (final r in ['/library', '/downloads?tab=queue']) {
    // On the tablet frame: each section is its own page there. On phones the sections sit inside the hub's PageView, whose
    // semantics rects the contrast guideline samples at the wrong place (it reads the strip and the nav edge, not the text).
    testWidgets('$r meets the text-contrast guideline', (t) async {
      final h = t.ensureSemantics();
      await pumpLibrary(t, _lib(), start: r, size: const Size(834, 1194));
      await expectLater(t, meetsGuideline(textContrastGuideline));
      h.dispose();
    });
  }
}
