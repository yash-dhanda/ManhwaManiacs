import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ruler.dart';

import '../feature/feature_test_support.dart';

Future<List<int>> _pump(WidgetTester tester, {int page = 18, bool rtl = false, int count = 40}) async {
  final seeks = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: featureTheme(TargetPlatform.android),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: ReaderRuler(page: page, pageCount: count, rtl: rtl, bookmarkPages: const [3, 30], onSeek: seeks.add),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return seeks;
}

void main() {
  testWidgets('the ruler exposes "Page 18 of 40" with increase and decrease that step one page', (tester) async {
    final handle = tester.ensureSemantics();
    final seeks = await _pump(tester);
    final node = tester.getSemantics(find.bySemanticsLabel('Page position'));
    expect(node.value, 'Page 18 of 40');
    expect(node.increasedValue, 'Page 19');
    expect(node.decreasedValue, 'Page 17');
    // ignore: deprecated_member_use
    expect(node.hasFlag(SemanticsFlag.isSlider), isTrue);
    final owner = node.owner!;
    owner.performAction(node.id, SemanticsAction.increase);
    owner.performAction(node.id, SemanticsAction.decrease);
    expect(seeks, [19, 17]);
    handle.dispose();
  });

  testWidgets('a single-page chapter has no actions', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, page: 1, count: 1);
    final node = tester.getSemantics(find.bySemanticsLabel('Page position'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isFalse);
    handle.dispose();
  });

  testWidgets('dragging seeks live, shows the p. 18 flag and hides it on release', (tester) async {
    final seeks = await _pump(tester, page: 1);
    final box = tester.getRect(find.byType(ReaderRuler));
    final g = await tester.startGesture(Offset(box.left + 170, box.center.dy));
    await tester.pump(const Duration(milliseconds: 200));
    expect(seeks.last, 18);
    expect(find.text('p. 18'), findsOneWidget);
    await g.moveTo(Offset(box.left + 340, box.center.dy));
    await tester.pump();
    expect(seeks.last, 35);
    expect(find.text('p. 35'), findsOneWidget);
    expect(seeks.length, greaterThan(1), reason: 'live, not only on release');
    await g.up();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('p. 35'), findsNothing);
  });

  testWidgets('RTL mirrors the ruler: the left edge is the last page', (tester) async {
    final seeks = await _pump(tester, page: 1, rtl: true);
    final box = tester.getRect(find.byType(ReaderRuler));
    await tester.tapAt(Offset(box.left + 1, box.center.dy));
    await tester.pump(const Duration(seconds: 1));
    expect(seeks.last, 40);
    await tester.tapAt(Offset(box.right - 1, box.center.dy));
    await tester.pump(const Duration(seconds: 1));
    expect(seeks.last, 1);
    final ltr = await _pump(tester, page: 1);
    await tester.tapAt(Offset(box.left + 1, box.center.dy));
    await tester.pump(const Duration(seconds: 1));
    expect(ltr.last, 1);
  });
}
