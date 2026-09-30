import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_page_image.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

Future<double> _stripWidth(WidgetTester tester, Object? stored) async {
  await pumpReader(
    tester,
    size: const Size(1024, 1366),
    prefsValues: {if (stored != null) 'mm.reader.device.stripWidthPx': stored},
  );
  await settleReader(tester, ms: 800);
  final w = tester.getSize(find.byType(ReaderPageImage).first).width;
  await disposeReader(tester);
  return w;
}

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('a 1024 wide tablet with strip width 860 paints an 860 dp column (E2), not the legacy 768 cap', (tester) async {
    expect(await _stripWidth(tester, 860), closeTo(860, 0.5));
  });

  testWidgets('the tablet strip width clamps to 480..860 and defaults to 720', (tester) async {
    expect(await _stripWidth(tester, 900), closeTo(860, 0.5));
    expect(await _stripWidth(tester, 300), closeTo(480, 0.5));
    expect(await _stripWidth(tester, null), closeTo(720, 0.5));
  });
}
