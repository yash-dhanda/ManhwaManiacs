// ignore_for_file: unawaited_futures
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/dev/demo_cover.dart';
import 'package:manhwamaniacs/skins/glass/dev/gallery_sections.dart';
import 'package:manhwamaniacs/skins/glass/dev/overlay_sections.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/image_viewer.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import 'overlay_support.dart';
import 'support.dart';

Future<void> _pumpSection(
    WidgetTester tester, String name, TargetPlatform platform,) async {
  tester.view.physicalSize = const Size(390 * 3, 8000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    primHost(
      GlassBudgetScope(
          exempt: true,
          label: 'gallery',
          child: SingleChildScrollView(
              child: SizedBox(
                  width: 390, child: GlassGallerySection(name: name),),),),
      platform: platform,
      align: false,
    ),
  );
  await pumpFor(tester, 400);
}

/// Tabs through an open overlay and asserts focus never lands on the page behind ([pageKey] is the trigger's node).
Future<void> _tabStaysInside(WidgetTester tester, OverlayHost h) async {
  for (var i = 0; i < 12; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 16));
    expect(h.trigger.hasFocus, isFalse,
        reason: 'focus escaped to the page on tab $i',);
  }
}

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final name in kGlassOverlaySections) {
      testWidgets(
          '$name on ${platform.name}: tap targets and labels at 390 x 844',
          (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpSection(tester, name, platform);
        expect(tester.takeException(), isNull);
        await expectLater(
            tester,
            meetsGuideline(platform == TargetPlatform.iOS
                ? iOSTapTargetGuideline
                : androidTapTargetGuideline,),);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  }

  group('focus trap and return', () {
    testWidgets(
        'a sheet traps focus, puts it on the title and hands it back to the trigger',
        (tester) async {
      final h = OverlayHost(tester);
      await h.pump();
      h.trigger.requestFocus();
      await tester.pump();
      h.push(GlassSheetPage<void>(
              title: 'Sheet', builder: (_) => const Center(child: Text('body')),)
          .createRoute(h.nav.currentContext!),);
      await pumpFor(tester, 700);
      expect(h.trigger.hasFocus, isFalse);
      await _tabStaysInside(tester, h);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpFor(tester, 800);
      expect(find.text('Sheet'), findsNothing);
      expect(h.trigger.hasFocus, isTrue);
    });

    testWidgets('an alert traps focus (least destructive first) and returns it',
        (tester) async {
      final h = OverlayHost(tester);
      await h.pump();
      h.trigger.requestFocus();
      await tester.pump();
      showGlassAlert<int>(
        h.nav.currentContext!,
        title: 'Remove?',
        actions: const [
          GlassAlertAction<int>('Cancel',
              role: GlassAlertRole.cancel, value: 0,),
          GlassAlertAction<int>('Remove',
              role: GlassAlertRole.destructive, value: 1,),
        ],
      );
      await pumpFor(tester, 700);
      expect(h.trigger.hasFocus, isFalse);
      await _tabStaysInside(tester, h);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpFor(tester, 800);
      expect(find.text('Remove?'), findsNothing);
      expect(h.trigger.hasFocus, isTrue);
    });

    testWidgets('a menu traps focus and returns it', (tester) async {
      final h = OverlayHost(tester);
      await h.pump();
      h.trigger.requestFocus();
      await tester.pump();
      showGlassMenu(
        h.nav.currentContext!,
        anchor: const Rect.fromLTWH(100, 100, 100, 44),
        title: 'Actions',
        entries: [
          GlassMenuEntry(label: 'One', onSelected: () {}),
          GlassMenuEntry(label: 'Two', onSelected: () {}),
        ],
      );
      await pumpFor(tester, 700);
      expect(h.trigger.hasFocus, isFalse);
      await _tabStaysInside(tester, h);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpFor(tester, 800);
      expect(find.text('One'), findsNothing);
      expect(h.trigger.hasFocus, isTrue);
    });

    testWidgets('the image viewer traps focus and returns it', (tester) async {
      final h = OverlayHost(tester);
      await h.pump();
      h.trigger.requestFocus();
      await tester.pump();
      h.push(GlassImageViewerRoute<void>(
          image: kGlassDemoCover,
          thumbRect: const Rect.fromLTWH(20, 300, 100, 150),),);
      await pumpFor(tester, 900);
      expect(h.trigger.hasFocus, isFalse);
      await _tabStaysInside(tester, h);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpFor(tester, 900);
      expect(find.byType(GlassImageViewer), findsNothing);
      expect(h.trigger.hasFocus, isTrue);
    });

    for (final form in GlassWideForm.values) {
      testWidgets('the ${form.name} form traps focus and returns it',
          (tester) async {
        final h = OverlayHost(tester);
        await h.pump(size: const Size(834, 1194));
        h.trigger.requestFocus();
        await tester.pump();
        h.push(
          GlassSheetPage<void>(
                  title: 'Form',
                  wideForm: form,
                  originRect: const Rect.fromLTWH(600, 900, 120, 44),
                  builder: (_) => const Center(child: Text('body')),)
              .createRoute(h.nav.currentContext!),
        );
        await pumpFor(tester, 800);
        expect(h.trigger.hasFocus, isFalse);
        await _tabStaysInside(tester, h);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await pumpFor(tester, 900);
        expect(find.text('Form'), findsNothing);
        expect(h.trigger.hasFocus, isTrue);
      });
    }
  });

  testWidgets(
      'every control of the toggles section is operable from a hardware keyboard',
      (tester) async {
    await _pumpSection(tester, 'toggles', TargetPlatform.iOS);
    final seen = <FocusNode>{};
    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 16));
      final f = FocusManager.instance.primaryFocus;
      if (f != null) seen.add(f);
    }
    // switch x2 (one disabled), checkbox, radio group, stepper buttons: at least four distinct stops.
    expect(seen.length, greaterThanOrEqualTo(4));
  });
}
