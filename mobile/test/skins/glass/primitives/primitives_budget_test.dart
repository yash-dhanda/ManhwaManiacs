import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' show AdaptiveGlass;
import 'package:manhwamaniacs/skins/glass/dev/gallery_sections.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import 'support.dart';

void main() {
  // Chips (the choice droplet and a selected chip's glass included), posters, cards and rail arrows are
  // content twins: no live glass surface, no backdrop read (glass 2.4.1 rule 1).
  for (final name in ['chips', 'posters', 'cards', 'rails', 'badges', 'avatars', 'skeletons', 'progress']) {
    testWidgets('$name creates no live glass', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 8000 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(primHost(GlassBudgetScope(exempt: true, label: 'gallery', child: SingleChildScrollView(child: SizedBox(width: 390, child: GlassGallerySection(name: name)))), align: false));
      await pumpFor(tester, 500);
      expect(find.byType(AdaptiveGlass), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(primContainer(tester).read(glassRegistryProvider).layers, 0, reason: '$name registered a live surface');
    });
  }
}
