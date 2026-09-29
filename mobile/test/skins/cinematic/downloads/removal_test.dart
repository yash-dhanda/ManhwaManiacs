// ignore_for_file: directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/utils/pending_removals.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:mocktail/mocktail.dart';

import 'downloads_rig.dart';

Future<Rig> pumpWithChapters(WidgetTester tester, MockStore store) async {
  final r = await pumpDownloads(
    tester,
    rig: Rig(
      store: store,
      bytes: 3 * 1024 * 1024,
      groups: [
        series([chapter(1, '11'), chapter(2, '12')]),
      ],
    ),
  );
  await tester.tap(find.bySemanticsLabel('Expand chapters'));
  await settle(tester, ms: 400);
  return r;
}

MockStore stubStore() {
  final store = MockStore();
  when(() => store.deleteDownload(any())).thenAnswer((_) async {});
  return store;
}

void main() {
  setUpAll(() => registerFallbackValue((sourceId: '', seriesKey: '', chapterKey: '')));

  testWidgets('swipe left removes: REMOVING… and an 8 s Undo toast, then expiry deletes', (tester) async {
    final store = stubStore();
    final r = await pumpWithChapters(tester, store);
    await tester.drag(find.byKey(const ValueKey('swipe-2')), const Offset(-320, 0));
    await settle(tester, ms: 700);
    expect(find.text('REMOVING…'), findsOneWidget);
    final toast = r.container.read(cineToastsProvider).single;
    expect(toast.text, 'Removed chapter 12.');
    expect(toast.actionLabel, 'Undo');
    expect(toast.hold, const Duration(milliseconds: 8000));
    verifyNever(() => store.deleteDownload(any()));

    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    verify(() => store.deleteDownload((sourceId: 'asura', seriesKey: 'solo', chapterKey: '12'))).called(1);
  });

  testWidgets('Undo keeps the chapter: nothing is deleted and the row stops reading REMOVING…', (tester) async {
    final store = stubStore();
    final r = await pumpWithChapters(tester, store);
    await tester.tap(find.bySemanticsLabel('Remove chapter 11 from this phone'));
    await settle(tester, ms: 300);
    expect(find.text('REMOVING…'), findsOneWidget);
    r.container.read(cineToastsProvider).single.onAction!();
    await settle(tester, ms: 300);
    expect(find.text('REMOVING…'), findsNothing);
    expect(r.haptics, contains('undo'));
    await tester.pump(const Duration(seconds: 9));
    verifyNever(() => store.deleteDownload(any()));
  });

  testWidgets('flushAll (the shell calls it when the app pauses) runs the removal at once', (tester) async {
    final store = stubStore();
    final r = await pumpWithChapters(tester, store);
    await tester.tap(find.bySemanticsLabel('Remove chapter 11 from this phone'));
    await settle(tester, ms: 300);
    verifyNever(() => store.deleteDownload(any()));
    await r.container.read(pendingRemovalsProvider).flushAll();
    await tester.pump();
    verify(() => store.deleteDownload((sourceId: 'asura', seriesKey: 'solo', chapterKey: '11'))).called(1);
    await tester.pump(const Duration(seconds: 9));
  });

  testWidgets('the Delete key removes the focused chapter', (tester) async {
    final store = stubStore();
    final r = await pumpWithChapters(tester, store);
    final node = tester.widget<Focus>(find.descendant(of: find.byKey(const ValueKey('chapter-2')), matching: find.byType(Focus)).first).focusNode!;
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester, ms: 300);
    expect(find.text('REMOVING…'), findsOneWidget);
    expect(r.container.read(cineToastsProvider).single.text, 'Removed chapter 12.');
    await tester.pump(const Duration(seconds: 9));
  });
}
