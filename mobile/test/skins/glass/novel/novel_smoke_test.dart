import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/novel_reader_screen.dart';

import 'novel_rig.dart';

void main() {
  testWidgets('smoke: the Glass novel reader renders the chapter', (t) async {
    await pumpGlassNovel(t);
    await settle(t);
    expect(find.byType(GlassNovelReader), findsOneWidget);
    expect(find.text('CHAPTER 1'), findsOneWidget);
    expect(find.text('Down the Rabbit-Hole'), findsOneWidget);
    await disposeGlassNovel(t);
  });
}
