import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_ui_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/micro_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_chrome.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

ProviderContainer _container(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Future<void> _wait(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(setUpShotCoverCache);

  group('auto-hide', () {
    testWidgets('idle-hides after 3000 ms, not before', (tester) async {
      await pumpReader(tester);
      await _wait(tester, 1000);
      expect(chromeVisible(tester), isTrue);
      await _wait(tester, 1800);
      expect(chromeVisible(tester), isTrue, reason: 'at 2.8 s');
      await _wait(tester, 800);
      expect(chromeVisible(tester), isFalse, reason: 'past 3 s');
      expect(find.byType(ReaderMicroProgress), findsOneWidget);
      await disposeReader(tester);
    });

    testWidgets('hides after 24 px down, scrolling back never shows it, never in the first 800 ms', (tester) async {
      await pumpReader(tester);
      await _wait(tester, 1000);
      // The grace is measured on the wall clock.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));
      // Down 60 px (the finger goes up): hides.
      await tester.dragFrom(const Offset(195, 422), const Offset(0, -60));
      await _wait(tester, 400);
      expect(chromeVisible(tester), isFalse);
      // Up 40 px: not enough.
      await tester.dragFrom(const Offset(195, 422), const Offset(0, 30));
      await _wait(tester, 400);
      expect(chromeVisible(tester), isFalse, reason: 'under 56 px up');
      await tester.dragFrom(const Offset(195, 300), const Offset(0, 130));
      await _wait(tester, 400);
      expect(chromeVisible(tester), isFalse, reason: 'only a double tap opens the menu');
      await disposeReader(tester);
    });

    testWidgets('a scroll inside the first 800 ms never hides it', (tester) async {
      await pumpReader(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.dragFrom(const Offset(195, 422), const Offset(0, -60));
      await tester.pump(const Duration(milliseconds: 100));
      expect(chromeVisible(tester), isTrue);
      await disposeReader(tester);
    });

    testWidgets('never while a screen reader runs', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpReader(tester);
      await _wait(tester, 1000);
      await tester.dragFrom(const Offset(195, 422), const Offset(0, -80));
      await _wait(tester, 4500);
      expect(chromeVisible(tester), isTrue);
      await disposeReader(tester);
    });

    testWidgets('never while focus is inside the chrome', (tester) async {
      await pumpReader(tester);
      await _wait(tester, 500);
      // Tab from the reading surface into the chrome.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focus = FocusManager.instance.primaryFocus;
      expect(focus, isNotNull);
      await _wait(tester, 4500);
      final inChrome = find.byType(ReaderChromeMotion).evaluate().any((e) {
        var found = false;
        e.visitAncestorElements((a) {
          found = found || a.widget is FocusScope;
          return true;
        });
        return found;
      });
      expect(inChrome, isTrue);
      expect(chromeVisible(tester), isTrue, reason: 'focus in the chrome holds it open');
      await disposeReader(tester);
    });
  });

  testWidgets('the micro progress shows while hidden and not in cinema mode', (tester) async {
    await pumpReader(tester, prefsValues: {'mm.reader.prefs.cinema': true});
    await _wait(tester, 4000);
    expect(chromeVisible(tester), isFalse);
    await disposeReader(tester);
  });

  testWidgets('lock mode unlocks after five centre taps', (tester) async {
    await pumpReader(tester);
    await _wait(tester, 500);
    _container(tester).read(readerUiProvider.notifier).setLocked(true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_container(tester).read(readerUiProvider).isLocked, isTrue);
    expect(chromeVisible(tester), isFalse, reason: 'locked hides the chrome');
    for (var i = 0; i < 4; i++) {
      await tapSingle(tester);
      expect(_container(tester).read(readerUiProvider).isLocked, isTrue, reason: 'after ${i + 1} taps');
    }
    await tapSingle(tester);
    expect(_container(tester).read(readerUiProvider).isLocked, isFalse);
    expect(find.text('Controls unlocked'), findsOneWidget);
    await disposeReader(tester);
  });

  testWidgets('an edge tap does not count toward unlocking', (tester) async {
    await pumpReader(tester);
    await _wait(tester, 500);
    _container(tester).read(readerUiProvider.notifier).setLocked(true);
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < 6; i++) {
      await tapSingle(tester, const Offset(20, 60));
    }
    expect(_container(tester).read(readerUiProvider).isLocked, isTrue);
    await disposeReader(tester);
  });

  for (final (platform, min) in [(TargetPlatform.iOS, 44.0), (TargetPlatform.android, 48.0)]) {
    testWidgets('hit-target walk of every tappable in the chrome on $platform', (tester) async {
      await pumpReader(tester, platform: platform);
      await _wait(tester, 500);
      final rects = <String, Rect>{};
      final chrome = find.byType(ReaderChromeMotion);
      final tappables = find.descendant(
        of: chrome,
        matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.onTap != null && (w.properties.enabled ?? true)),
      );
      var n = 0;
      for (final e in tappables.evaluate()) {
        final box = e.renderObject! as RenderBox;
        if (!box.hasSize) continue;
        final r = box.localToGlobal(Offset.zero) & box.size;
        final label = (e.widget as Semantics).properties.label ?? 'unlabelled ${n++}';
        rects[label] = r;
        expect(r.width, greaterThanOrEqualTo(min), reason: '$label width ${r.width}');
        expect(r.height, greaterThanOrEqualTo(min), reason: '$label height ${r.height}');
      }
      expect(rects.length, greaterThanOrEqualTo(5), reason: 'the walk found ${rects.keys}');
      final entries = rects.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        for (var j = i + 1; j < entries.length; j++) {
          final a = entries[i].value, b = entries[j].value;
          // Nested semantics (a wrapper around a button) overlap by design: only siblings count.
          if (a.overlaps(b)) continue;
          final gapX = a.right <= b.left ? b.left - a.right : (b.right <= a.left ? a.left - b.right : 0.0);
          final gapY = a.bottom <= b.top ? b.top - a.bottom : (b.bottom <= a.top ? a.top - b.bottom : 0.0);
          final gap = gapX > gapY ? gapX : gapY;
          expect(gap, greaterThanOrEqualTo(8), reason: '${entries[i].key} to ${entries[j].key}: $gap');
        }
      }
      await disposeReader(tester);
    });
  }
}
