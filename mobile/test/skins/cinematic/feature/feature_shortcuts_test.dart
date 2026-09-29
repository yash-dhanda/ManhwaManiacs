// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_shortcuts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';

import 'feature_test_support.dart';

void main() {
  testWidgets('Feature keys (D10) call their commands', (tester) async {
    final calls = <String>[];
    final c = FeatureCommands();
    c.continueReading = () => calls.add('continue');
    c.readAll = () => calls.add('readAll');
    c.viewCover = () => calls.add('cover');
    c.favorite = () => calls.add('favorite');
    c.notify = () => calls.add('notify');
    c.toggleFollow = () => calls.add('follow');
    c.download = () => calls.add('download');
    c.select = () => calls.add('select');
    c.goTo = () => calls.add('goTo');
    c.toggleOrder = () => calls.add('order');
    c.move = () => calls.add('move');
    c.tab = (i) => calls.add('tab$i');
    c.tabBy = (d) => calls.add('tabBy$d');
    c.chapterBy = (d) => calls.add('chapter$d');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FeatureShortcuts(commands: c, child: const SizedBox.expand()))));
    await tester.pump();
    for (final k in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.numpadAdd,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.bracketRight,
      LogicalKeyboardKey.bracketLeft,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyX,
      LogicalKeyboardKey.slash,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyM,
    ]) {
      await tester.sendKeyEvent(k);
    }
    expect(calls, [
      'continue', 'continue', 'readAll', 'cover', 'favorite', 'notify', 'follow', 'download',
      'tab0', 'tab1', 'tabBy1', 'tabBy-1', 'chapter1', 'chapter-1', 'select', 'goTo', 'order', 'move',
    ]);
  });

  testWidgets('Book keys (E6) call theirs and ignore the Feature-only keys', (tester) async {
    final calls = <String>[];
    final c = FeatureCommands();
    c.continueReading = () => calls.add('continue');
    c.listen = () => calls.add('listen');
    c.viewCover = () => calls.add('cover');
    c.toggleFollow = () => calls.add('library');
    c.download = () => calls.add('download');
    c.goTo = () => calls.add('goTo');
    c.toggleOrder = () => calls.add('order');
    c.readAll = () => calls.add('WRONG');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FeatureShortcuts(book: true, commands: c, child: const SizedBox.expand()))));
    await tester.pump();
    for (final k in [
      LogicalKeyboardKey.enter, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyL, LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.numpadAdd, LogicalKeyboardKey.keyD, LogicalKeyboardKey.slash, LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyA,
    ]) {
      await tester.sendKeyEvent(k);
    }
    expect(calls, ['continue', 'continue', 'listen', 'cover', 'library', 'download', 'goTo', 'order']);
  });

  testWidgets('keys never fire while a text field has focus', (tester) async {
    final calls = <String>[];
    final c = FeatureCommands();
    c.readAll = () => calls.add('readAll');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FeatureShortcuts(commands: c, child: const Center(child: TextField(key: Key('field')))),
      ),
    ));
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(calls, isEmpty);
  });

  testWidgets('on the Feature page 1, 2, ] and [ switch the tabs', (tester) async {
    await pumpFeature(tester,
        size: const Size(390, 2000), child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    TabController tc() => tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(tc().index, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await frames(tester, 600);
    expect(tc().index, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
    await frames(tester, 600);
    expect(tc().index, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await frames(tester, 600);
    expect(tc().index, 1);
  });

  testWidgets('on the Feature page X starts select mode and D starts it too', (tester) async {
    await pumpFeature(tester, child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await frames(tester, 300);
    expect(find.text('Select chapters to download'), findsOneWidget);
  });

  testWidgets('on the Book page L is ignored without narration and V opens the cover', (tester) async {
    await pumpFeature(tester, novel: true, size: const Size(390, 2600), child: BookView(data: fixtureData('novel-short')));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await frames(tester, 700);
    expect(find.byKey(const Key('lightbox-caption')), findsOneWidget);
  });

  testWidgets('CineFocusRing paints for keyboard focus only', (tester) async {
    Future<void> pumpRing() async {
      await tester.pumpWidget(MaterialApp(
        theme: featureTheme(TargetPlatform.android),
        home: Scaffold(body: Center(child: CineFocusRing(child: TextButton(onPressed: () {}, child: const Text('go'))))),
      ));
    }

    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    await pumpRing();
    Focus.of(tester.element(find.text('go'))).requestFocus();
    await tester.pump();
    expect(find.byKey(const Key('cine-focus-ring')), findsNothing);

    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    await tester.pumpWidget(const SizedBox());
    await pumpRing();
    Focus.of(tester.element(find.text('go'))).requestFocus();
    await tester.pump();
    expect(find.byKey(const Key('cine-focus-ring')), findsOneWidget);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });
}
