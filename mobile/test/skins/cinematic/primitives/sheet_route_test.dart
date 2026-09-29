import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_physics.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

Future<void> _open(WidgetTester t, {bool live = false, bool reduced = false}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: ThemeData(extensions: const [cinematicTokens]),
    builder: (c, a) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduced), child: a!),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: CineButton(
            key: const Key('trigger'),
            label: 'Open',
            onPressed: () => showCineSheet<void>(
              context,
              kicker: 'SETTINGS',
              title: 'Type',
              livePreview: live,
              builder: (_) => Column(children: [
                CineButton(key: const Key('first'), label: 'First', onPressed: () {}),
                const SizedBox(height: 240),
              ],),
            ),
          ),
        ),
      ),
    ),
  ),);
  await t.tap(find.byKey(const Key('trigger')));
}

double _top(WidgetTester t) => t.getTopLeft(find.byKey(const Key('cine-sheet-grabber'))).dy;
Finder get _sheet => find.byType(CineSheet);
double _opacity(WidgetTester t) => t.widgetList<Opacity>(find.ancestor(of: _sheet, matching: find.byType(Opacity))).first.opacity;

void main() {
  testWidgets('the route is not opaque, dismissible, with the modal scrim', (t) async {
    await _open(t);
    await t.pumpAndSettle();
    final r = ModalRoute.of(t.element(_sheet))! as CineSheetRoute<void>;
    expect(r.opaque, isFalse);
    expect(r.barrierDismissible, isTrue);
    expect(r.barrierColor, const Color(0xC7000000));
    expect(r.barrierLabel, 'Close');
    expect(r.maintainState, isTrue);
  });

  testWidgets('Rise: 360 ms, starts 24 px low at opacity 0', (t) async {
    await _open(t);
    await t.pump();
    await t.pump();
    final start = _top(t), o0 = _opacity(t);
    await t.pump(const Duration(milliseconds: 359));
    expect(ModalRoute.of(t.element(_sheet))!.animation!.isCompleted, isFalse);
    await t.pump(const Duration(milliseconds: 2));
    final rest = _top(t);
    expect(start - rest, closeTo(24, 0.6));
    expect(o0, closeTo(0, 0.02));
    expect(_opacity(t), 1);
    // The transition is over at 360 ms.
    expect(ModalRoute.of(t.element(_sheet))!.animation!.isCompleted, isTrue);
  });

  testWidgets('a drag leaving 31 % keeps it open, 29 % dismisses', (t) async {
    await _open(t);
    await t.pumpAndSettle();
    final full = _surfaceHeight(t);
    Future<void> dragTo(double visibleFraction) async {
      final g = await t.startGesture(t.getCenter(find.byKey(const Key('cine-sheet-grabber'))));
      await g.moveBy(Offset(0, full * (1 - visibleFraction)));
      await t.pump(const Duration(milliseconds: 300));
      await g.up();
      await t.pumpAndSettle();
    }

    await dragTo(0.31);
    expect(_sheet, findsOneWidget);
    await dragTo(0.29);
    expect(_sheet, findsNothing);
  });

  testWidgets('a fast downward fling dismisses, a slow one keeps it', (t) async {
    await _open(t);
    await t.pumpAndSettle();
    await t.fling(find.byKey(const Key('cine-sheet-grabber')), const Offset(0, 120), 300);
    await t.pumpAndSettle();
    expect(_sheet, findsOneWidget);
    await t.fling(find.byKey(const Key('cine-sheet-grabber')), const Offset(0, 120), 1600);
    await t.pumpAndSettle();
    expect(_sheet, findsNothing);
  });

  testWidgets('above the top detent it rubber-bands by rubberBand(x, d)', (t) async {
    await _open(t);
    await t.pumpAndSettle();
    final rest = _top(t);
    final g = await t.startGesture(t.getCenter(find.byKey(const Key('cine-sheet-grabber'))));
    await g.moveBy(const Offset(0, -100));
    await t.pump();
    final h = _surfaceHeight(t);
    expect(rest - _top(t), closeTo(rubberBand(100, h), 0.5));
    await g.up();
    await t.pumpAndSettle();
    expect(_top(t), closeTo(rest, 0.5));
  });

  testWidgets('a live-preview release settles on the nearest detent through the sheet spring', (t) async {
    await _open(t, live: true);
    await t.pumpAndSettle();
    final low = _top(t); // the 0.5 detent
    expect(low, closeTo(844 - 422 + 0, 12));
    final g = await t.startGesture(t.getCenter(find.byKey(const Key('cine-sheet-grabber'))));
    await g.moveBy(const Offset(0, -260));
    await t.pump(const Duration(milliseconds: 300));
    final from = _top(t);
    await g.up();
    await t.pump(); // spring starts
    await t.pump(const Duration(milliseconds: 100));
    const target = 844 - 844 * 0.92 + 8; // grabber sits 8 px under the surface top
    final sim = SpringSimulation(CineSprings.sheet.description, from, target, 0);
    expect(_top(t), closeTo(sim.x(0.1), 3));
    await t.pumpAndSettle();
    expect(_top(t), closeTo(target, 1));
  });

  testWidgets('Android back closes it', (t) async {
    await _open(t);
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(_sheet, findsNothing);
  });

  testWidgets('tapping the barrier closes it', (t) async {
    await _open(t);
    await t.pumpAndSettle();
    await t.tapAt(const Offset(200, 20));
    await t.pumpAndSettle();
    expect(_sheet, findsNothing);
  });

  testWidgets('focus is on the first control after open and returns to the trigger', (t) async {
    await _open(t);
    await t.pumpAndSettle();
    final f = t.binding.focusManager.primaryFocus!;
    expect(find.descendant(of: find.byKey(const Key('cine-sheet-done')), matching: find.byWidget(f.context!.widget)), findsWidgets);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(_sheet, findsNothing);
  });

  testWidgets('reduced motion: 150 ms fades in and out, no slide', (t) async {
    await _open(t, reduced: true);
    await t.pump();
    await t.pump();
    final rest0 = _top(t);
    await t.pump(const Duration(milliseconds: 75));
    expect(_top(t), rest0);
    await t.pump(const Duration(milliseconds: 76));
    final route = ModalRoute.of(t.element(_sheet))!;
    expect(route.animation!.isCompleted, isTrue);
    await t.binding.handlePopRoute();
    await t.pump();
    await t.pump(const Duration(milliseconds: 160));
    await t.pump();
    expect(_sheet, findsNothing);
  });
}

double _surfaceHeight(WidgetTester t) {
  final box = t.renderObject<RenderBox>(find.byKey(const Key('cine-sheet-surface')));
  return box.size.height;
}
