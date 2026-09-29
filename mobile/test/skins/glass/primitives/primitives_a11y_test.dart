import 'package:flutter/material.dart' show ThemeData;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/dev/glass_gallery.dart';
import 'package:manhwamaniacs/skins/glass/dev/gallery_sections.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import 'support.dart';

Future<void> pumpSection(WidgetTester tester, String name, {TargetPlatform platform = TargetPlatform.iOS}) async {
  tester.view.physicalSize = const Size(390 * 3, 8000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(primHost(GlassBudgetScope(exempt: true, label: 'gallery', child: SingleChildScrollView(child: SizedBox(width: 390, child: GlassGallerySection(name: name)))), platform: platform, align: false));
  await pumpFor(tester, 400);
}

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final name in kGlassGallerySections) {
      testWidgets('$name on ${platform.name}: tap targets and labels', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpSection(tester, name, platform: platform);
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  }
}
