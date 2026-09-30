import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manhwamaniacs/skins/cinematic/screens/reader/contents_list.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/running_head.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

Finder _folio() => find.descendant(of: find.byType(ReaderRunningHead), matching: find.text('CH 2'));

List<String> _order(WidgetTester t) => [for (final r in t.widgetList<ContentsRow>(find.byType(ContentsRow))) r.chapter.id];

bool _panelOn(WidgetTester t) {
  final f = find.text('CONTENTS', findRichText: true);
  return f.evaluate().isNotEmpty && t.getTopLeft(f.first).dx >= 0 && t.getTopLeft(f.first).dx < 800;
}

Finder _row(String chapter) => find.bySemanticsLabel(RegExp('Chapter $chapter.*'));

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('phone: the folio opens the Contents sheet; the current chapter is marked; a row opens its chapter', (tester) async {
    final handle = tester.ensureSemantics();
    final rig = await pumpReader(tester);
    await settleReader(tester, ms: 600);
    await tester.tap(_folio());
    await settleReader(tester, ms: 900);
    expect(find.text('CONTENTS', findRichText: true), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'current chapter')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Chapter 2.*current chapter')), findsOneWidget);
    expect(find.text('NEWEST', findRichText: true), findsOneWidget);
    expect(find.text('OLDEST', findRichText: true), findsOneWidget);
    await tester.tap(_row('3').first);
    await settleReader(tester, ms: 900);
    expect(rig.router.state.uri.path, contains('/reader/demo/k/c3'));
    handle.dispose();
    await disposeReader(tester);
  });

  testWidgets('the sort flips and a chapter number flashes its row', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 600);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await settleReader(tester, ms: 900);
    expect(_order(tester).first, 'cx', reason: 'newest first: ${_order(tester)}');
    await tester.tap(find.text('OLDEST', findRichText: true));
    await settleReader(tester, ms: 600);
    expect(_order(tester).first, 'c1', reason: 'oldest first');
    await tester.enterText(find.byType(TextField), '3');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleReader(tester, ms: 900);
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settleReader(tester, ms: 900);
    await disposeReader(tester);
  });

  testWidgets('tablet: the folio and [ open the left column panel, not a sheet', (tester) async {
    await pumpReader(tester, wide: true);
    await settleReader(tester, ms: 800);
    expect(_panelOn(tester), isFalse);
    await tester.tap(_folio());
    await settleReader(tester, ms: 900);
    expect(_panelOn(tester), isTrue);
    expect(find.text('Contents'), findsNothing, reason: 'no sheet title');
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await settleReader(tester, ms: 900);
    expect(_panelOn(tester), isFalse, reason: 'toggled off');
    await disposeReader(tester);
  });
}
