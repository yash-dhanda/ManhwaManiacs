import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast_host.dart';

import 'overlay_support.dart';
import 'support.dart';

Future<OverlayHost> _host(WidgetTester tester, {Size size = const Size(390, 844), bool reduced = false, List<Override> overrides = const []}) async {
  final h = OverlayHost(tester);
  await h.pump(size: size, reduced: reduced, overrides: overrides, page: const GlassToastHost(child: SizedBox.expand()));
  return h;
}

ProviderContainer _c(WidgetTester t) => primContainer(t);
void _show(WidgetTester t, String m, {GlassToastKind kind = GlassToastKind.info, VoidCallback? undo, String? action}) =>
    _c(t).read(glassToastProvider.notifier).show(GlassToastSpec(m, kind: kind, undo: undo, actionLabel: action, onAction: () {}));
Finder _toast(String m) => find.text(m);
double _top(WidgetTester t, String m) => t.getTopLeft(_toast(m)).dy;

void main() {
  setUp(GlassHaptics.debugLog.clear);

  testWidgets('falls in from 60 px above and rests at safe-top + 60 (under the nav row)', (tester) async {
    await _host(tester);
    _show(tester, 'Saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final early = _top(tester, 'Saved');
    await pumpFor(tester, 600);
    final rest = _top(tester, 'Saved');
    expect(early, lessThan(rest - 20));
    expect(rest, inInclusiveRange(60, 80)); // the capsule's own padding sits inside the 60 px anchor
    expect(_c(tester).read(glassToastShowingProvider), isTrue);
  });

  testWidgets('stacking: at most two, the older one 8 px down and scaled to 0.94', (tester) async {
    await _host(tester);
    _show(tester, 'first');
    await pumpFor(tester, 600);
    _show(tester, 'second');
    await pumpFor(tester, 600);
    final ids = _c(tester).read(glassToastProvider).map((e) => e.id).toList();
    final older = tester.widget<Transform>(find.byKey(ValueKey('glass-toast-scale-${ids.first}')));
    expect(older.transform.storage[0], closeTo(0.94, 0.001));
    final newest = tester.widget<Transform>(find.byKey(ValueKey('glass-toast-scale-${ids.last}')));
    expect(newest.transform.storage[0], 1);
    _show(tester, 'third');
    await pumpFor(tester, 900);
    expect(_toast('first'), findsNothing);
    expect(_c(tester).read(glassToastProvider).length, 2);
  });

  testWidgets('a plain toast lasts 4 s', (tester) async {
    await _host(tester);
    _show(tester, 'Saved');
    await pumpFor(tester, 3700);
    expect(_toast('Saved'), findsOneWidget);
    await pumpFor(tester, 1800);
    expect(_toast('Saved'), findsNothing);
    expect(_c(tester).read(glassToastShowingProvider), isFalse);
  });

  testWidgets('with Undo it lasts 10 s and the rim drains', (tester) async {
    await _host(tester);
    var undone = 0;
    _show(tester, 'Removed', undo: () => undone++);
    await pumpFor(tester, 5000);
    expect(_toast('Removed'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    await pumpFor(tester, 6200);
    expect(_toast('Removed'), findsNothing);
    expect(undone, 0);
  });

  testWidgets('a touch pauses the timer', (tester) async {
    await _host(tester);
    _show(tester, 'Saved');
    await pumpFor(tester, 800);
    final g = await tester.startGesture(tester.getCenter(_toast('Saved')));
    await pumpFor(tester, 6000);
    expect(_toast('Saved'), findsOneWidget);
    await g.up();
    await pumpFor(tester, 4200);
    expect(_toast('Saved'), findsNothing);
  });

  testWidgets('a hover pointer pauses the timer, and focus inside it does too', (tester) async {
    await _host(tester);
    _show(tester, 'Saved');
    await pumpFor(tester, 800);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(_toast('Saved')));
    await mouse.moveTo(tester.getCenter(_toast('Saved')) + const Offset(1, 0));
    await pumpFor(tester, 6000);
    expect(_toast('Saved'), findsOneWidget);
    await mouse.moveTo(const Offset(5, 500));
    await pumpFor(tester, 4200);
    expect(_toast('Saved'), findsNothing);
  });

  testWidgets('a screen reader keeps a toast until it is dismissed', (tester) async {
    await _host(tester, overrides: [glassAssistiveProvider.overrideWith((ref) => true)]);
    _show(tester, 'Saved');
    await pumpFor(tester, 12000);
    expect(_toast('Saved'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('glass-toast-close-${_c(tester).read(glassToastProvider).first.id}')));
    await pumpFor(tester, 900);
    expect(_toast('Saved'), findsNothing);
  });

  testWidgets('a 40 px projected flick up dismisses it; a drag down holds it', (tester) async {
    await _host(tester);
    _show(tester, 'Saved');
    await pumpFor(tester, 800);
    await tester.fling(_toast('Saved'), const Offset(0, -60), 900);
    await pumpFor(tester, 900);
    expect(_toast('Saved'), findsNothing);

    _show(tester, 'Again');
    await pumpFor(tester, 800);
    final rest = _top(tester, 'Again');
    final g = await tester.startGesture(tester.getCenter(_toast('Again')));
    await g.moveBy(const Offset(0, 30));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_top(tester, 'Again'), greaterThan(rest));
    await pumpFor(tester, 5000);
    expect(_toast('Again'), findsOneWidget); // held, timer paused
    await g.up();
    await pumpFor(tester, 700);
    expect(_top(tester, 'Again'), closeTo(rest, 1));
    expect(_toast('Again'), findsOneWidget);
  });

  testWidgets('a sideways flick dismisses it too', (tester) async {
    await _host(tester);
    _show(tester, 'Saved');
    await pumpFor(tester, 800);
    await tester.fling(_toast('Saved'), const Offset(120, 0), 900);
    await pumpFor(tester, 900);
    expect(_toast('Saved'), findsNothing);
  });

  testWidgets('a toast waits while a menu is open and falls back in when it closes', (tester) async {
    await _host(tester);
    final q = _c(tester).read(overlayQueueProvider.notifier);
    final close = q.registerBlocker();
    _show(tester, 'Saved');
    await pumpFor(tester, 800);
    expect(_c(tester).read(glassToastShowingProvider), isFalse);
    final hidden = tester.widget<Opacity>(find.ancestor(of: _toast('Saved'), matching: find.byType(Opacity)).first).opacity;
    expect(hidden, lessThan(0.05));
    close();
    await pumpFor(tester, 800);
    expect(tester.widget<Opacity>(find.ancestor(of: _toast('Saved'), matching: find.byType(Opacity)).first).opacity, 1);
    expect(_c(tester).read(glassToastShowingProvider), isTrue);
  });

  testWidgets('undoLast() runs the last undo while its toast shows and for 60 s after it leaves', (tester) async {
    await _host(tester);
    var a = 0, b = 0;
    _show(tester, 'Removed', undo: () => a++);
    await pumpFor(tester, 11000);
    expect(_toast('Removed'), findsNothing);
    await pumpFor(tester, 30000);
    expect(_c(tester).read(glassToastProvider.notifier).undoLast(), isTrue);
    expect(a, 1);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.undo));
    expect(_c(tester).read(glassToastProvider.notifier).undoLast(), isFalse);

    _show(tester, 'Removed 2', undo: () => b++);
    await pumpFor(tester, 11000);
    await pumpFor(tester, 61000);
    expect(_c(tester).read(glassToastProvider.notifier).undoLast(), isFalse);
    expect(b, 0);
  });

  testWidgets('the Undo button runs the undo and dismisses', (tester) async {
    await _host(tester);
    var a = 0;
    _show(tester, 'Removed', undo: () => a++);
    await pumpFor(tester, 800);
    await tester.tap(find.text('Undo'));
    await pumpFor(tester, 900);
    expect(a, 1);
    expect(_toast('Removed'), findsNothing);
  });

  testWidgets('Alt+N moves focus to the newest toast and Esc dismisses it and returns focus', (tester) async {
    final h = await _host(tester);
    h.trigger.requestFocus();
    await tester.pump();
    _show(tester, 'Saved');
    await pumpFor(tester, 800);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(_c(tester).read(glassToastProvider).first.focus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFor(tester, 900);
    expect(_toast('Saved'), findsNothing);
  });

  testWidgets('tablet: bottom-left beside the sidebar, 88 up while a bottom bar shows', (tester) async {
    await _host(tester, size: const Size(834, 1194));
    _c(tester).read(glassSidebarEdgeProvider.notifier).state = 76;
    _show(tester, 'Saved');
    await pumpFor(tester, 800);
    final r = tester.getRect(_toast('Saved'));
    expect(r.left, greaterThan(76 + 24));
    expect(r.bottom, lessThan(1194 - 24));
    final rest = r.bottom;
    _c(tester).read(glassBottomBarProvider.notifier).state = true;
    await pumpFor(tester, 100);
    expect(tester.getRect(_toast('Saved')).bottom, closeTo(rest - 64, 2));
  });

  testWidgets('in the readers: top-centre at 60 px', (tester) async {
    await _host(tester);
    _c(tester).read(glassReaderActiveProvider.notifier).state = true;
    _show(tester, 'Saved');
    await pumpFor(tester, 800);
    final r = tester.getRect(_toast('Saved'));
    expect(r.center.dx, closeTo(195, 30));
    expect(_top(tester, 'Saved'), inInclusiveRange(60, 90));
  });

  testWidgets('reduced motion: 150 ms fades, no fall', (tester) async {
    await _host(tester, reduced: true);
    _show(tester, 'Saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final early = _top(tester, 'Saved');
    await pumpFor(tester, 300);
    expect(_top(tester, 'Saved'), closeTo(early, 0.5));
  });
}
