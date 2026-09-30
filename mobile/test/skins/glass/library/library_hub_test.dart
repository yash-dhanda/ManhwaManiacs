import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_hub.dart';

import '../../../features/library/shelf_fixtures.dart';
import '../../../screenshots/support/shot_harness.dart';
import 'library_rig.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a pager change replaces the location with the section path and keeps the hub State', (t) async {
    final rig = await pumpLibrary(t, FakeLib(series: [shelfSeries(1), shelfSeries(2)]));
    expect(rig.at, '/library');
    final before = t.state(find.byType(GlassLibraryHub));
    await t.tap(find.text('History').first);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(rig.at, '/library/history');
    expect(identical(t.state(find.byType(GlassLibraryHub)), before), isTrue);
  });

  testWidgets('/library?tab=bookmarks lands on /library/bookmarks', (t) async {
    final rig = await pumpLibrary(t, FakeLib(), start: '/library?tab=bookmarks');
    expect(rig.at, '/library/bookmarks');
  });

  testWidgets('the shelf lists its series and the Continue-free shelf shows the count line', (t) async {
    await pumpLibrary(t, FakeLib(series: [shelfSeries(1, title: 'Alpha'), shelfSeries(2, title: 'Beta')]));
    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Beta'), findsWidgets);
    expect(find.textContaining('2 series followed'), findsOneWidget);
  });

  testWidgets('an empty shelf says so and offers Sources', (t) async {
    await pumpLibrary(t, FakeLib());
    expect(find.text('Your shelf is empty'), findsOneWidget);
    expect(find.text('Browse sources'), findsOneWidget);
  });

  testWidgets('the Library dock badge reads 9+ for twelve active downloads', (t) async {
    await pumpLibrary(t, FakeLib(), downloads: 12);
    expect(find.text('9+'), findsWidgets);
  });
}
