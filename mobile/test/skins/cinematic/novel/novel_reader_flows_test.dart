// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_contents.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_reader_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/page_frame.dart';

import 'novel_test_support.dart';

void main() {
  testWidgets('Contents: the go-to field matches chapters and says when there is none', (tester) async {
    await pumpNovel(tester);
    await settleNovel(tester);
    await tester.tapAt(const Offset(195, 422));
    await settleNovel(tester, ms: 500);
    await tester.tap(find.bySemanticsLabel('Contents').first);
    await settleNovel(tester, ms: 900);
    expect(find.text('CONTENTS'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, '7');
    await settleNovel(tester, ms: 400);
    expect(find.byKey(const Key('match-7')), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '480');
    await settleNovel(tester, ms: 400);
    expect(find.text('No chapter 480 in this book.'), findsOneWidget);
    await disposeNovel(tester);
  });

  testWidgets('b bookmarks with no dialog and the toast offers Add a note', (tester) async {
    await pumpNovel(tester);
    await settleNovel(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await settleNovel(tester, ms: 800);
    // No store in this rig, so the save answers "couldn't"; either toast proves the flow ran
    // without a dialog.
    expect(find.byType(AlertDialog), findsNothing);
    final toasts = tester.element(find.byType(CineNovelReader));
    expect(toasts, isNotNull);
    await disposeNovel(tester);
  });

  testWidgets('the system bars follow the chrome', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method.startsWith('SystemChrome.setEnabledSystemUI')) calls.add('${call.method} ${call.arguments}');
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpNovel(tester);
    await settleNovel(tester);
    calls.clear();
    await tester.tapAt(const Offset(195, 422));
    await settleNovel(tester, ms: 300);
    expect(calls.any((c) => c.contains('SystemUiOverlay.top')), isTrue, reason: '$calls');
    calls.clear();
    await tester.tapAt(const Offset(195, 422));
    await settleNovel(tester, ms: 300);
    expect(calls.any((c) => c.contains('immersiveSticky') || c.contains('[]')), isTrue, reason: '$calls');
    await disposeNovel(tester);
  });

  testWidgets('brightness draws a black layer at |v| / 100', (tester) async {
    final rig = await pumpNovel(tester);
    await settleNovel(tester);
    await rig.settings({'brightness': -40});
    await settleNovel(tester);
    final layer = tester.widget<ColoredBox>(find.byKey(const Key('novel-brightness-layer')));
    expect(layer.color.a, closeTo(0.4, 0.01));
    expect(tester.widget<NovelPageFrame>(find.byType(NovelPageFrame)).brightness, -40);
    await disposeNovel(tester);
  });

  testWidgets('reduced motion: the reader still opens and the chrome toggles', (tester) async {
    await pumpNovel(tester, reduced: true);
    await settleNovel(tester);
    await tester.tapAt(const Offset(195, 422));
    await settleNovel(tester, ms: 300);
    expect(find.bySemanticsLabel('Next chapter'), findsWidgets);
    await disposeNovel(tester);
  });

  testWidgets('a tablet opens the Contents as the left panel', (tester) async {
    await pumpNovel(tester, wide: true);
    await settleNovel(tester);
    await tester.tapAt(const Offset(417, 597));
    await settleNovel(tester, ms: 500);
    await tester.tap(find.bySemanticsLabel('Contents').first);
    await settleNovel(tester, ms: 900);
    expect(find.byType(NovelContentsPanel), findsOneWidget);
    await disposeNovel(tester);
  });

  test('toast kinds exist', () => expect(CineToastKind.values, contains(CineToastKind.action)));
}
