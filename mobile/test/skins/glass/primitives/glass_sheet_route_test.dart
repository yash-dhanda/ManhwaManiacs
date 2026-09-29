import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'overlay_support.dart';
import 'support.dart';

const double _medium = 0.52 * 844;
const double _large = 844 - 47 * 0 - 10; // no safe area in the test host

GlassSheetRoute<void> _route({List<GlassDetent> detents = const [GlassDetent.medium, GlassDetent.large], Widget? body, GlassDetent opening = GlassDetent.medium}) =>
    GlassSheetRoute<void>(
      GlassSheetPage<void>(
        title: 'Filters',
        detents: detents,
        opening: opening,
        builder: (context) => body ?? const Center(child: Text('content')),
      ),
    );

Iterable<HapticEvent> _events() => GlassHaptics.debugLog.map((e) => e.event);

Future<GlassSheetRoute<void>> _open(WidgetTester tester, OverlayHost h, {GlassSheetRoute<void>? route}) async {
  final r = route ?? _route();
  h.push(r);
  await tester.pump();
  await pumpFor(tester, 520);
  return r;
}

double _barrierAlpha(WidgetTester tester) {
  final b = tester.widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier).last);
  return b.color.value?.a ?? 0;
}

void main() {
  setUp(GlassHaptics.debugLog.clear);

  testWidgets('the present reaches medium in 447 ms of fake time', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = _route();
    h.push(r);
    await tester.pump();
    await pumpFor(tester, 100);
    final early = r.sheetController.value!;
    expect(early, greaterThan(0));
    expect(early, lessThan(_medium));
    await pumpFor(tester, 380);
    expect(r.sheetController.value!, closeTo(_medium, 1.5));
    expect(find.text('Filters'), findsOneWidget);
  });

  testWidgets('a touch during the present catches it and tracks the finger 1:1', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = _route();
    h.push(r);
    await tester.pump();
    await pumpFor(tester, 160);
    final g = await tester.startGesture(tester.getCenter(find.text('Filters')));
    await g.moveBy(const Offset(0, -20)); // past the slop
    await tester.pump(const Duration(milliseconds: 16));
    expect(_events(), contains(HapticEvent.motionCatch));
    final a = r.sheetController.value!;
    await g.moveBy(const Offset(0, -30));
    await tester.pump(const Duration(milliseconds: 16));
    expect(r.sheetController.value! - a, closeTo(30, 1.0));
    await g.up();
    await pumpFor(tester, 600);
  });

  testWidgets('a fling down at 1,600 px/s from the lowest detent dismisses and pops', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h);
    await tester.fling(find.text('Filters'), const Offset(0, 200), 1600);
    await pumpFor(tester, 900);
    expect(find.text('Filters'), findsNothing);
  });

  testWidgets('a slow drag that ends 30 % below the lowest detent settles back', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h);
    final g = await tester.startGesture(tester.getCenter(find.text('Filters')));
    await g.moveBy(const Offset(0, 60));
    await g.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(milliseconds: 400)); // velocity decays to rest
    await g.up();
    await pumpFor(tester, 900);
    expect(find.text('Filters'), findsOneWidget);
    expect(r.sheetController.value!, closeTo(_medium, 1.5));
  });

  testWidgets('the close button animates to 0 and then pops', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h);
    await tester.tap(find.byKey(const ValueKey('glass-sheet-close')));
    await tester.pump();
    await pumpFor(tester, 120);
    expect(find.text('Filters'), findsOneWidget);
    expect(r.sheetController.value!, lessThan(_medium));
    await pumpFor(tester, 600);
    expect(find.text('Filters'), findsNothing);
  });

  testWidgets('a touch during the button dismiss catches the sheet', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h);
    await tester.tap(find.byKey(const ValueKey('glass-sheet-close')));
    await tester.pump();
    await pumpFor(tester, 40);
    final g = await tester.startGesture(tester.getCenter(find.text('Filters')));
    await g.moveBy(const Offset(0, -20));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_events(), contains(HapticEvent.motionCatch));
    await g.up();
    await pumpFor(tester, 900);
    expect(find.text('Filters'), findsOneWidget);
    expect(r.sheetController.value!, greaterThan(50));
  });

  testWidgets('Android back runs to completion: the sheet animates to 0 while the route reverses', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h);
    h.nav.currentState!.maybePop().ignore(); // what WidgetsApp does on Android back
    await tester.pump();
    await pumpFor(tester, 100);
    expect(find.text('Filters'), findsOneWidget);
    expect(r.sheetController.value!, lessThan(_medium));
    await pumpFor(tester, 500);
    expect(find.text('Filters'), findsNothing);
  });

  testWidgets('the barrier colour follows the offset, not time', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h);
    expect(_barrierAlpha(tester), closeTo(0x47 / 255, 0.01));
    final g = await tester.startGesture(tester.getCenter(find.text('Filters')));
    await g.moveBy(const Offset(0, 60));
    await g.moveBy(const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 16));
    final frac = r.sheetController.value! / _medium;
    expect(_barrierAlpha(tester), closeTo(0x47 / 255 * frac, 0.01));
    await g.up();
    await pumpFor(tester, 900);
  });

  testWidgets('sheet.pass, sheet.detent and threshold.cross / back appear at the right moments', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h);
    final g = await tester.startGesture(tester.getCenter(find.text('Filters')));
    // up across nothing (medium -> large is a detent boundary at large only): drag up 200 px
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await pumpFor(tester, 900);
    expect(_events(), contains(HapticEvent.sheetDetent));
    GlassHaptics.debugLog.clear();
    final g2 = await tester.startGesture(tester.getCenter(find.text('Filters')));
    for (var i = 0; i < 12; i++) {
      await g2.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_events(), contains(HapticEvent.sheetPass));
    expect(_events(), contains(HapticEvent.thresholdCross));
    for (var i = 0; i < 20; i++) {
      await g2.moveBy(const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(_events(), contains(HapticEvent.thresholdBack));
    await g2.up();
    await pumpFor(tester, 900);
  });

  testWidgets('focus moves to the title on open and back to the trigger on close', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    h.trigger.requestFocus();
    await tester.pump();
    expect(h.trigger.hasPrimaryFocus, isTrue);
    await _open(tester, h);
    expect(h.trigger.hasPrimaryFocus, isFalse);
    final title = tester.widget<Focus>(find.ancestor(of: find.text('Filters'), matching: find.byType(Focus)).first);
    expect(title.focusNode?.hasPrimaryFocus ?? false, isTrue);
    await tester.tap(find.byKey(const ValueKey('glass-sheet-close')));
    await pumpFor(tester, 1000);
    await tester.pump();
    expect(h.trigger.hasPrimaryFocus, isTrue);
  });

  testWidgets('a focused field moves the sheet to large', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final field = FocusNode();
    final ctl = TextEditingController();
    final r = await _open(
      tester,
      h,
      route: _route(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: EditableText(
            controller: ctl,
            focusNode: field,
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFFFFFFFF),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      ),
    );
    expect(r.sheetController.value!, closeTo(_medium, 1.5));
    field.requestFocus();
    await pumpFor(tester, 500);
    expect(r.sheetController.value!, closeTo(_large, 1.5));
  });

  testWidgets('a 1,000-row list hands a downward drag at its top to the sheet, and an upward drag at medium expands the sheet first', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    double scrollPx() => tester.state<ScrollableState>(find.byType(Scrollable).last).position.pixels;
    final r = await _open(
      tester,
      h,
      route: _route(
        body: ListView.builder(itemCount: 1000, itemExtent: 44, itemBuilder: (c, i) => Text('row $i')),
      ),
    );
    // Up at medium: the sheet expands before the list scrolls.
    final g = await tester.startGesture(const Offset(195, 600));
    await g.moveBy(const Offset(0, -20));
    await g.moveBy(const Offset(0, -60));
    await tester.pump(const Duration(milliseconds: 16));
    expect(r.sheetController.value!, greaterThan(_medium + 30));
    expect(scrollPx(), 0);
    await g.up();
    await pumpFor(tester, 900);
    expect(r.sheetController.value!, closeTo(_medium, 2)); // a slow release settles on the nearest detent
    r.sheetController.animateTo(const SheetOffset(1), duration: const Duration(milliseconds: 300)).ignore();
    await pumpFor(tester, 500);
    // Scroll the list down 100, then a downward drag scrolls it back before the sheet moves.
    await tester.dragFrom(const Offset(195, 500), const Offset(0, -200));
    await pumpFor(tester, 700);
    expect(scrollPx(), greaterThan(100));
    await tester.dragFrom(const Offset(195, 500), const Offset(0, 100));
    await pumpFor(tester, 700);
    expect(r.sheetController.value!, closeTo(_large, 2));
    tester.state<ScrollableState>(find.byType(Scrollable).last).position.jumpTo(0);
    await tester.pump();
    final g2 = await tester.startGesture(const Offset(195, 400));
    await g2.moveBy(const Offset(0, 30));
    await g2.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 16));
    expect(r.sheetController.value!, lessThan(_large - 30));
    await g2.up();
    await pumpFor(tester, 900);
  });

  testWidgets('predictive back scales the sheet 1 -> 0.94 and lifts it 12 px by progress', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(platform: TargetPlatform.android);
    final r = await _open(tester, h);
    r.handleStartBackGesture(progress: 1);
    r.handleUpdateBackGestureProgress(progress: 0.5);
    await tester.pump();
    final scale = tester.widget<Transform>(find.byKey(const ValueKey('glass-sheet-back')));
    expect(scale.transform.storage[0], closeTo(0.97, 0.001));
    final lift = tester.widgetList<Transform>(find.ancestor(of: find.byKey(const ValueKey('glass-sheet-back')), matching: find.byType(Transform))).first;
    expect(lift.transform.getTranslation().y, closeTo(-6, 0.01));
    r.handleCancelBackGesture();
    await pumpFor(tester, 600);
    expect(r.backProgress.value, closeTo(0, 0.01));
    expect(find.text('Filters'), findsOneWidget);
  });

  testWidgets('at large the page behind is at scale 0.94, radius 12, blur 8 and 60 % brightness', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h);
    r.sheetController.animateTo(const SheetOffset(1), duration: const Duration(milliseconds: 300)).ignore();
    await pumpFor(tester, 500);
    final scale = tester.widget<Transform>(find.byKey(const ValueKey('glass-recede-scale')));
    expect(scale.transform.storage[0], closeTo(0.94, 0.002));
    final clip = tester.widget<ClipRSuperellipse>(find.byKey(const ValueKey('glass-recede-clip')));
    expect((clip.borderRadius as BorderRadius).topLeft.x, closeTo(12, 0.1));
    final blur = tester.widget<ImageFiltered>(find.byKey(const ValueKey('glass-recede-blur')));
    expect(blur.imageFilter.toString(), contains('8.0'));
    final dim = tester.widget<ColoredBox>(find.byKey(const ValueKey('glass-recede-dim')));
    expect(dim.color.a, closeTo(0.4, 0.01));
  });

  testWidgets('at medium only the dimSheet barrier shows: no recession', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h);
    expect(find.byKey(const ValueKey('glass-recede-scale')), findsNothing);
  });

  testWidgets('two stacked sheets: the lower one at large shows 0.9165 / 2 % / 70 %, only the lowest recedes the page', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final a = await _open(tester, h);
    a.sheetController.animateTo(const SheetOffset(1), duration: const Duration(milliseconds: 300)).ignore();
    await pumpFor(tester, 500);
    final b = _route(opening: GlassDetent.medium);
    h.push(b);
    await tester.pump();
    await pumpFor(tester, 520);
    final s = tester.widget<Transform>(find.byKey(const ValueKey('glass-sheet-under-scale')));
    expect(s.transform.storage[0], closeTo(0.9165, 0.001));
    final dim = tester.widget<ColoredBox>(find.byKey(const ValueKey('glass-sheet-under-dim')));
    expect(dim.color.a, closeTo(0.3, 0.01));
    final scale = tester.widget<Transform>(find.byKey(const ValueKey('glass-recede-scale')));
    expect(scale.transform.storage[0], closeTo(0.94, 0.002)); // still the lowest sheet's
    final lift = tester.widgetList<Transform>(find.ancestor(of: find.byKey(const ValueKey('glass-sheet-under-scale')), matching: find.byType(Transform))).first;
    expect(lift.transform.getTranslation().y, closeTo(-0.02 * 844, 0.5));
  });

  testWidgets('reduced motion presents with a 150 ms fade and 16 px and no recession', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(reduced: true);
    h.push(_route(opening: GlassDetent.large));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final op = tester.widget<Opacity>(find.ancestor(of: find.text('Filters'), matching: find.byType(Opacity)).first);
    expect(op.opacity, lessThan(1));
    await pumpFor(tester, 200);
    final op2 = tester.widget<Opacity>(find.ancestor(of: find.text('Filters'), matching: find.byType(Opacity)).first);
    expect(op2.opacity, 1);
    expect(find.byKey(const ValueKey('glass-recede-scale')), findsNothing); // dim only
    expect(find.byKey(const ValueKey('glass-recede-dim')), findsOneWidget);
  });

  testWidgets('material: at large the surface goes to glassSolid1', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h);
    r.sheetController.animateTo(const SheetOffset(1), duration: const Duration(milliseconds: 300)).ignore();
    await pumpFor(tester, 500);
    final solid = tester.widget<ColoredBox>(find.byKey(const ValueKey('glass-sheet-solid')));
    expect(solid.color, isSameColorAs(const Color(0xFF1C1C22)));
  });

}
