import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_reader_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_sheet.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_paged_test.dart' show key, seedLayout;
import 'reader_test_support.dart';

Set<String> texts(WidgetTester tester) => {
      for (final e in find.byType(RichText).evaluate()) (e.widget as RichText).text.toPlainText().replaceAll('￼', ''),
    }..remove('');

ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Future<void> openSetup(WidgetTester tester) async {
  await key(tester, LogicalKeyboardKey.comma, ms: 900);
  expect(find.byType(CineSheet), findsOneWidget);
}

Future<void> tab(WidgetTester tester, String label) async {
  final f = find.text(label, findRichText: true).last;
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(f);
  await settleReader(tester, ms: 500);
}

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('every LAYOUT row is there, with the scope captions; Height and Original are disabled in the strip', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await openSetup(tester);
    final t = texts(tester);
    expect(t, contains('READING SETUP'));
    expect(t, containsAll(['Layout', 'Direction', 'Fit', 'Side margin', 'Zoom', 'Gap between pages', 'Page turn']));
    expect(t.any((s) => s.contains('Saved for this series')), isTrue);
    expect(t.any((s) => s.contains('Saved for this profile')), isTrue);
    final tips = [for (final e in find.byType(Tooltip).evaluate()) (e.widget as Tooltip).message];
    expect(tips, contains('Fit to height works in the paged layouts.'));
    expect(tips, contains('Original size works in the paged layouts.'));
    await disposeReader(tester);
  });

  testWidgets('the IMAGE, CONTROLS and AMBIENT tabs; the Android rows are there on Android', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await openSetup(tester);
    await tab(tester, 'IMAGE');
    expect(texts(tester), containsAll(['Brightness', 'Warmth', 'Colour', 'Ground']));
    expect(texts(tester).any((s) => s.contains("Dims below your screen's lowest setting.")), isTrue);
    await tab(tester, 'CONTROLS');
    expect(texts(tester), containsAll(['LEFT', 'CENTRE', 'RIGHT', 'Reset', 'Show zones', 'Strip taps', 'Swipe sideways to change chapter', 'Cinema mode', 'Keep screen awake', 'Auto next chapter', 'Lock controls', 'Volume keys turn pages', 'Refresh rate']));
    await tab(tester, 'AMBIENT');
    expect(texts(tester), containsAll(['Auto-scroll', 'Auto-scroll speed']));
    await disposeReader(tester);
  });

  testWidgets('the Android-only rows are absent on iOS', (tester) async {
    await pumpReader(tester, platform: TargetPlatform.iOS);
    await settleReader(tester, ms: 500);
    await openSetup(tester);
    await tab(tester, 'CONTROLS');
    final t = texts(tester);
    expect(t, contains('Keep screen awake'));
    expect(t, isNot(contains('Volume keys turn pages')));
    expect(t, isNot(contains('Refresh rate')));
    await disposeReader(tester);
  });

  testWidgets('changing Layout applies live under the sheet', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await openSetup(tester);
    expect(find.byType(ReaderEngineView), findsOneWidget);
    await tester.tap(find.text('SINGLE', findRichText: true).last);
    await settleReader(tester, ms: 900);
    expect(find.byType(PagedReaderView), findsOneWidget, reason: 'the page changes under the open sheet');
    expect(find.byType(CineSheet), findsOneWidget);
    // Fit is enabled now: HEIGHT selects.
    final prefs = container(tester).read(readerPrefsProvider('demo:k'));
    expect(prefs.layout, 'single');
    await disposeReader(tester);
  });

  testWidgets('in a paged layout Gap is disabled and Page turn is live; in read-all there is no Layout row', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single'));
    await settleReader(tester, ms: 500);
    await openSetup(tester);
    await tab(tester, 'AMBIENT');
    expect(texts(tester).any((s) => s.contains('Auto-scroll needs the strip.')), isTrue);
    await disposeReader(tester);
  });

  testWidgets('Reset reader settings arms for 1000 ms, then restores every default', (tester) async {
    await pumpReader(tester, prefsValues: {
      ...seedLayout('single', more: {'brightness': -40, 'gap': true}),
    },);
    await settleReader(tester, ms: 500);
    final ref = container(tester);
    await ref.read(readerSeriesPrefsProvider.notifier).setFor('demo:k', {'layout': 'double'});
    await settleReader(tester, ms: 300);
    await openSetup(tester);
    // Up to the full detent, then down the body to the footer.
    await tester.drag(find.text('READING SETUP', findRichText: true), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.ensureVisible(find.text('Reset reader settings', findRichText: true));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Reset reader settings', findRichText: true));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Cancel', findRichText: true), findsOneWidget);
    // Armed for 1000 ms (the primitive's own test pins the dead button and the `proof` rule); after
    // it a tap confirms.
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byKey(const Key('confirm-commit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-commit')));
    await settleReader(tester, ms: 700);
    expect(find.byKey(const Key('confirm-commit')), findsNothing, reason: 'the dialog closed');
    final prefs = ref.read(readerPrefsProvider('demo:k'));
    expect(prefs.layout, 'strip');
    expect(prefs.brightness, 0);
    expect(prefs.gap, isFalse);
    expect(ref.read(sharedPrefsProvider).getString(kReaderPrefsSeedKey), '{}');
    await disposeReader(tester);
  });

  testWidgets('closing the sheet hides the chrome; the phone footer names the page actions', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    await openSetup(tester);
    expect(texts(tester).any((s) => s.startsWith('Page actions for p. ')), isTrue);
    await tester.tap(find.text('Done', findRichText: true).last);
    await settleReader(tester, ms: 900);
    expect(find.byType(CineSheet), findsNothing);
    expect(chromeVisible(tester), isFalse);
    await disposeReader(tester);
  });

  for (final (platform, min) in [(TargetPlatform.iOS, 44.0), (TargetPlatform.android, 48.0)]) {
    testWidgets('every control in the setup sheet is at least $min on $platform', (tester) async {
      await pumpReader(tester, platform: platform);
      await settleReader(tester, ms: 500);
      await openSetup(tester);
      for (final name in ['LAYOUT', 'IMAGE', 'CONTROLS', 'AMBIENT']) {
        await tab(tester, name);
        final tappables = find.descendant(
          of: find.byType(CineSheet),
          matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.onTap != null && (w.properties.enabled ?? true)),
        );
        for (final e in tappables.evaluate()) {
          final box = e.renderObject! as RenderBox;
          if (!box.hasSize || box.size.isEmpty) continue;
          final label = (e.widget as Semantics).properties.label ?? 'unlabelled';
          expect(box.size.width, greaterThanOrEqualTo(min - 0.01), reason: '$name/$label width');
          expect(box.size.height, greaterThanOrEqualTo(min - 0.01), reason: '$name/$label height');
        }
      }
      await disposeReader(tester);
    });
  }
}
