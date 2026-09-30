import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reader_test_support.dart';

void main() {
  hitTargetTests();
  testWidgets('the running head and folio bar draw for chapter 2', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 600);
    expect(find.text('TOWER OF DAWN'), findsWidgets);
    expect(find.text('CH 2'), findsWidgets);
    expect(find.text('1 / 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _hits(WidgetTester tester, double min) {
  for (final label in ['Back to the series', 'Contents', 'Previous chapter', 'Next chapter', 'Auto-scroll']) {
    for (final e in find.bySemanticsLabel(RegExp('^$label')).evaluate()) {
      final box = e.renderObject! as RenderBox;
      expect(box.size.width, greaterThanOrEqualTo(min), reason: label);
      expect(box.size.height, greaterThanOrEqualTo(min), reason: label);
    }
  }
}

void hitTargetTests() {
  for (final (platform, min) in [(TargetPlatform.iOS, 44.0), (TargetPlatform.android, 48.0)]) {
    testWidgets('chrome hit targets on $platform', (tester) async {
      await pumpReader(tester, platform: platform);
      await settleReader(tester, ms: 600);
      _hits(tester, min);
    });
  }
  testWidgets('the folio field opens on a tap and jumps', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 600);
    await tester.tap(find.text('1 / 6'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '4');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleReader(tester, ms: 800);
    expect(find.byType(TextField), findsNothing);
  });
}
