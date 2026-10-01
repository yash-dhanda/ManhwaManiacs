import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_actions.dart';

import '../../../features/library/shelf_fixtures.dart';
import '../../../screenshots/support/shot_harness.dart';
import 'library_rig.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the Reading chip asks the server for reading_status=reading', (t) async {
    final lib = FakeLib(series: [shelfSeries(1), shelfSeries(2)]);
    await pumpLibrary(t, lib);
    await t.tap(find.text('Reading').first);
    await t.pump(const Duration(milliseconds: 500));
    expect(lib.calls.any((c) => c.startsWith('listSeries:reading')), isTrue);
  });

  testWidgets('Remove from library then Undo restores the follow and its metadata', (t) async {
    final s = shelfSeries(1, fav: true, status: 'completed');
    final lib = FakeLib(series: [s]);
    final rig = await pumpLibrary(t, lib);
    await rig.container.read(glassShelfActionsProvider).remove(s);
    await t.pump(const Duration(milliseconds: 300));
    expect(lib.calls, contains('unfollow:1'));
  });
}
