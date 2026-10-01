import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_form_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/friend_sheet.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'circle_rig.dart';

void main() {
  setUpAll(loadAppFonts);

  Route<dynamic>? routeOfSheet(WidgetTester t) => ModalRoute.of(t.element(find.byType(FriendSheet, skipOffstage: false).first));

  testWidgets('phone: the friend opens as a large sheet at /circle/:profileId and a downward drag closes it', (t) async {
    final rig = await pumpCircle(t, circleFake());
    await t.tap(find.bySemanticsLabel('Aarav, reading Omniscient Reader now'));
    await settle(t);
    expect(rig.at, '/circle/2');
    expect(routeOfSheet(t), isA<GlassSheetRoute<dynamic>>());
    await t.fling(find.text('Aarav · @aarav'), const Offset(0, 200), 1600);
    await settle(t, 1000);
    expect(rig.at, '/circle');
    expect(find.byType(FriendSheet), findsNothing);
    await unmount(t);
  });

  testWidgets('desktop frame: the friend opens in the 560 px window', (t) async {
    final rig = await pumpCircle(t, circleFake(), size: const Size(1024, 1366));
    await t.tap(find.bySemanticsLabel('Aarav, reading Omniscient Reader now'));
    await settle(t);
    expect(rig.at, '/circle/2');
    expect(routeOfSheet(t), isA<GlassFormRoute<dynamic>>());
    expect(t.getSize(find.byType(FriendSheet)).width, lessThanOrEqualTo(560));
    await unmount(t);
  });
}
