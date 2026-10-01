import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';

import 'glass_reader_rig.dart';

void main() {
  testWidgets('the library manifest route opens GlassMangaReader with its chrome', (t) async {
    await pumpGlassReader(t);
    await settleReader(t, ms: 600);
    expect(find.byType(GlassMangaReader), findsOneWidget);
    expect(find.text('1 / 6'), findsWidgets);
    await disposeGlassReader(t);
  });

  testWidgets('the source-reader route opens GlassMangaReader too', (t) async {
    await pumpGlassReader(t, origin: GlassReaderOrigin.source);
    await settleReader(t, ms: 600);
    expect(find.byType(GlassMangaReader), findsOneWidget);
    await disposeGlassReader(t);
  });
}
