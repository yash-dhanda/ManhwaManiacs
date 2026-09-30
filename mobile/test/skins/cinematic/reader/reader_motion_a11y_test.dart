import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_ui_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/manga_reader.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_chrome.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

Future<void> _toEnd(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await settleReader(tester, ms: 500);
  }
}

double _chromeDy(WidgetTester tester) {
  final t = tester.widget<Transform>(find.descendant(of: find.byType(ReaderChromeMotion).first, matching: find.byType(Transform)).first);
  return t.transform.getTranslation().y;
}

ProviderContainer _c(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

String _seed(Map<String, Object> m) => jsonEncode(m);

void main() {
  setUpAll(setUpShotCoverCache);

  group('reduced motion', () {
    for (final reduced in [false, true]) {
      testWidgets('the Letter set on the end title plans ${reduced ? 200 : 'its full'} ms', (tester) async {
        final rec = MotionRecorder.instance;
        final was = rec.recording;
        rec.recording = true;
        addTearDown(() => rec.recording = was);
        final before = rec.entries.length;
        final hold = Completer<void>();
        await pumpReader(tester, chapterKey: 'c3', reduced: reduced, holds: {'cx': hold.future}, prefsValues: {kReaderPrefsSeedKey: _seed({'autoNextChapter': false})});
        await settleReader(tester, ms: 600);
        await _toEnd(tester);
        hold.complete();
        await settleReader(tester);
        final set = rec.entries.skip(before).where((e) => e.label.contains('LETTER'));
        expect(set, isNotEmpty);
        if (reduced) {
          expect(set.map((e) => e.plannedMs), everyElement(200));
        } else {
          expect(set.map((e) => e.plannedMs), everyElement(greaterThan(200)));
        }
        await disposeReader(tester);
      });

      testWidgets('the pull caption ${reduced ? 'appears whole' : 'types at 50 ms a character'} and fades after 2000 ms', (tester) async {
        const text = 'CH 3 — The Return';
        final rec = MotionRecorder.instance;
        final was = rec.recording;
        rec.recording = true;
        addTearDown(() => rec.recording = was);
        final before = rec.entries.length;
        await pumpReader(tester, reduced: reduced, extra: [pendingChapterCaptionProvider.overrideWith((ref) => text)]);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(TypedHeadline), findsOneWidget);
        final typed = rec.entries.skip(before).where((e) => e.label == 'TYPE');
        if (reduced) {
          expect(typed, isEmpty, reason: 'the caption is whole from the first frame');
          expect(find.text(text), findsOneWidget);
        } else {
          expect(find.text(text), findsNothing, reason: 'still typing');
          await tester.pump(const Duration(milliseconds: 1000));
          expect(rec.entries.skip(before).where((e) => e.label == 'TYPE').map((e) => e.plannedMs), [50 * text.characters.length]);
        }
        await tester.pump(Duration(milliseconds: reduced ? 1500 : 500));
        expect(find.byType(TypedHeadline), findsOneWidget, reason: 'held for 2000 ms');
        await settleReader(tester, ms: 900);
        expect(find.byType(TypedHeadline), findsNothing, reason: 'gone after the hold');
        await disposeReader(tester);
      });
    }

    testWidgets('the chrome fades without the slide under reduced motion, and slides otherwise', (tester) async {
      await pumpReader(tester);
      await settleReader(tester, ms: 500);
      await tapSingle(tester);
      // tapSingle waits 400 ms: hidden. Bring it back and read the slide mid-way.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
      await tester.tapAt(const Offset(195, 422));
      await tester.pump(const Duration(milliseconds: 60));
      expect(_chromeDy(tester), isNot(0), reason: 'the 8 px slide');
      await disposeReader(tester);

      await pumpReader(tester, reduced: true);
      await settleReader(tester, ms: 500);
      await tapSingle(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
      await tester.tapAt(const Offset(195, 422));
      await tester.pump(const Duration(milliseconds: 60));
      expect(_chromeDy(tester), 0, reason: 'a fade only');
      await disposeReader(tester);
    });

    testWidgets('tap-to-scroll jumps under reduced motion and glides otherwise', (tester) async {
      double px() => tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
      final seed = {kReaderPrefsSeedKey: _seed({'stripTaps': 'scroll'})};
      await pumpReader(tester, prefsValues: seed);
      await settleReader(tester, ms: 800);
      final start = px();
      await tapSingle(tester, const Offset(195, 780));
      await tester.pump(const Duration(milliseconds: 16));
      final glide = px() - start;
      await settleReader(tester, ms: 1000);
      expect(px() - start, greaterThan(500));
      await disposeReader(tester);

      await pumpReader(tester, reduced: true, prefsValues: seed);
      await settleReader(tester, ms: 800);
      final start2 = px();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
      await tester.tapAt(const Offset(195, 780));
      await tester.pump(const Duration(milliseconds: 320));
      final jump = px() - start2;
      expect(jump, greaterThan(500), reason: 'the whole step at once (glide moved $glide in a frame)');
      await tester.pump(const Duration(milliseconds: 16));
      expect(px() - start2, jump, reason: 'and no further motion');
      await disposeReader(tester);
    });

    testWidgets('auto-scroll never starts by itself: not on open, not after a band', (tester) async {
      final hold = Completer<void>();
      await pumpReader(tester, reduced: true, holds: {'c3': hold.future});
      await settleReader(tester, ms: 800);
      expect(_c(tester).read(readerUiProvider).autoScrollEnabled, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await settleReader(tester, ms: 300);
      await _toEnd(tester);
      hold.complete();
      await settleReader(tester);
      expect(_c(tester).read(readerUiProvider).autoScrollEnabled, isFalse, reason: 'the band paused it and reduced motion leaves it paused');
      await disposeReader(tester);
    });
  });

  group('screen reader', () {
    testWidgets('the surface takes focus with its label; pages carry "Page 1 of 6" and their OCR text', (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpReader(tester, extra: [
        ocrChapterTextProvider.overrideWith((ref, id) async => const [PageText(page: 1, text: 'Hello from page one')]),
      ],);
      await pumpUntilCoversLoad(tester, rounds: 3);
      await settleReader(tester, ms: 800);
      expect(find.bySemanticsLabel(RegExp(r'^Chapter 2, page \d+ of 6')), findsOneWidget);
      final page = tester.getSemantics(find.bySemanticsLabel('Page 1 of 6').first);
      expect(page.hint, contains('Hello from page one'));
      handle.dispose();
      await disposeReader(tester);
    });

    testWidgets('the chapter is announced on entry and on a chapter change, never on a page change', (tester) async {
      final announced = <String>[];
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (message) async {
        if (message is Map && message['type'] == 'announce') announced.add((message['data'] as Map)['message'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
      final handle = tester.ensureSemantics();
      await pumpReader(tester);
      await settleReader(tester, ms: 800);
      expect(announced, ['Chapter 2 · Tower of Dawn']);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await settleReader(tester, ms: 800);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await settleReader(tester, ms: 800);
      expect(announced, hasLength(1), reason: 'page turns are silent');
      await _toEnd(tester);
      // The strip stitched c3 below and the reader crossed into it.
      final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      position.jumpTo(position.maxScrollExtent * 0.62);
      await settleReader(tester, ms: 800);
      expect(announced.length, greaterThan(1));
      for (var i = 1; i < announced.length; i++) {
        expect(announced[i], isNot(announced[i - 1]), reason: 'one announcement per change: $announced');
      }
      handle.dispose();
      await disposeReader(tester);
    });
  });
}
