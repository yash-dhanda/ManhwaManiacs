import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reader_test_support.dart';

void main() {
  testWidgets('the running head and folio bar draw for chapter 2', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 600);
    expect(find.text('TOWER OF DAWN'), findsWidgets);
    expect(find.text('CH 2'), findsWidgets);
    expect(find.text('1 / 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
