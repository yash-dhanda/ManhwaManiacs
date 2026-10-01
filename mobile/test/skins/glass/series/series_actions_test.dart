import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_detail.dart';

import '../shell/shell_rig.dart';
import 'series_rig.dart';

const _loc = '/sources/demo/series/k1000';

Future<ShellRig> _page(WidgetTester t, {List<dynamic> followed = const [], bool platformAndroid = false, Map<String, SourceChapterProgress> progress = const {}, bool novel = false}) async {
  final r = await pumpGlassShell(t, start: _loc, platformAndroid: platformAndroid, extra: seriesOverrides(followed: followed.cast(), progress: progress, novel: novel));
  await t.pump(const Duration(seconds: 1));
  return r;
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('the ⋯ menu opens and Esc closes it; Reading status writes reading_status', (t) async {
    await _page(t, followed: [followRow()]);
    final more = find.bySemanticsLabel('More').first;
    await t.tap(more);
    await _settle(t);
    expect(find.text('Reading status…'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(t);
    expect(find.text('Reading status…'), findsNothing);
    expect(find.byType(GlassSeriesPage), findsOneWidget);
    await t.tap(more);
    await _settle(t);
    await t.tap(find.text('Reading status…'));
    await _settle(t);
    await t.tap(find.text('On hold'));
    await _settle(t);
    expect(calls, contains('patch:7:reading_status=on_hold'));
  });

  testWidgets('Content rating shows only with the gate open', (t) async {
    await _page(t, followed: [followRow()]);
    await t.tap(find.bySemanticsLabel('More').first);
    await _settle(t);
    expect(find.text('Content rating…'), findsNothing);
  });

  testWidgets('the keys: f follows, * favourites, n flips the order, shift+s copies the link', (t) async {
    final copied = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (m) async {
      if (m.method == 'Clipboard.setData') copied.add((m.arguments as Map)['text'] as String);
      return null;
    });
    await _page(t, followed: [followRow()]);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyDownEvent(LogicalKeyboardKey.digit8, character: '*');
    await t.sendKeyUpEvent(LogicalKeyboardKey.digit8);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await _settle(t);
    expect(calls, contains('patch:7:is_favorite=true'));
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyS);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await _settle(t);
    expect(copied.single, endsWith('/sources/demo/series/k1000'));
    final page = t.state<SeriesPageState>(find.byType(GlassSeriesPage));
    final before = page.chapters.order;
    await t.sendKeyEvent(LogicalKeyboardKey.keyN);
    await t.pump();
    expect(page.chapters.order, isNot(before));
    await t.pump(const Duration(seconds: 11));
  });

  testWidgets('Esc ends select mode before it closes the page', (t) async {
    await _page(t);
    final page = t.state<SeriesPageState>(find.byType(GlassSeriesPage));
    await t.sendKeyEvent(LogicalKeyboardKey.keyX);
    await t.pump();
    expect(page.chapters.selection.isActive, isTrue);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump();
    expect(page.chapters.selection.isActive, isFalse);
    expect(find.byType(GlassSeriesPage), findsOneWidget);
  });

  testWidgets('Continue reads the saved place', (t) async {
    await _page(t, progress: {'c142': SourceChapterProgress(page: 12, pageCount: 40, completed: false, updatedAt: DateTime(2026, 9, 20))});
    expect(find.text('Continue · Ch 142'), findsOneWidget);
  });

  testWidgets('hit targets meet the platform guidelines', (t) async {
    final handle = t.ensureSemantics();
    await _page(t);
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('android hit targets', (t) async {
    final handle = t.ensureSemantics();
    await _page(t, platformAndroid: true);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the book page: Literata front matter, contents and the go-to messages', (t) async {
    await _page(t, novel: true);
    expect(find.byKey(const ValueKey('book-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('book-plate')), findsOneWidget);
    expect(find.text('Start reading'), findsOneWidget);
    final field = find.byKey(const ValueKey('go-to-field'));
    await t.dragUntilVisible(field, find.byType(Scrollable).first, const Offset(0, -200));
    await t.pump();
    await t.enterText(find.descendant(of: field, matching: find.byType(EditableText)), '1900');
    await t.testTextInput.receiveAction(TextInputAction.go);
    await t.pump();
    expect(find.text('No chapter 1900 in this book.'), findsOneWidget);
    await t.enterText(find.descendant(of: field, matching: find.byType(EditableText)), '');
    await t.testTextInput.receiveAction(TextInputAction.go);
    await t.pump();
    expect(find.text('Type a chapter number.'), findsOneWidget);
    await t.enterText(find.descendant(of: field, matching: find.byType(EditableText)), '500');
    await t.testTextInput.receiveAction(TextInputAction.go);
    await _settle(t);
    expect(find.byKey(const ValueKey('toc-c500')), findsOneWidget);
  });
}
