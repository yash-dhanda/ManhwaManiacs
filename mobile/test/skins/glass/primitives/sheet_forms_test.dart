import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';

import 'overlay_support.dart';
import 'support.dart';

const _tablet = Size(834, 1194);

Route<void> _route(GlassWideForm form, {Rect? origin, String title = 'Recap'}) => GlassSheetPage<void>(
      title: title,
      wideForm: form,
      originRect: origin,
      builder: (context) => const Center(child: Text('body')),
    ).createRoute(_ctx!);

BuildContext? _ctx;

Rect _panel(WidgetTester t) => t.getRect(find.byKey(const ValueKey('glass-form-surface')));

void main() {
  testWidgets('panel: 440 wide, inset 12, from the right, over dimSheet; Esc closes', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(size: _tablet);
    _ctx = h.nav.currentContext;
    h.push(_route(GlassWideForm.panel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final early = _panel(tester);
    await pumpFor(tester, 700);
    final r = _panel(tester);
    expect(early.left, greaterThan(r.left + 20)); // entering from the right
    expect(r.width, 440);
    expect(r.right, closeTo(834 - 12, 0.5));
    expect(r.top, closeTo(12, 0.5));
    expect(r.bottom, closeTo(1194 - 12, 0.5));
    expect(find.text('Recap'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFor(tester, 800);
    expect(find.text('Recap'), findsNothing);
  });

  testWidgets('window: 560 wide, centred on the content column, top max(12 %, 48), a barrier tap closes', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(size: _tablet);
    _ctx = h.nav.currentContext;
    primContainer(tester).read(glassSidebarEdgeProvider.notifier).state = 76;
    h.push(_route(GlassWideForm.window, origin: const Rect.fromLTWH(600, 900, 120, 44)));
    await tester.pump();
    await pumpFor(tester, 700);
    final r = _panel(tester);
    expect(r.width, 560);
    expect(r.center.dx, closeTo(76 + (834 - 76) / 2, 1));
    expect(r.top, closeTo(0.12 * 1194, 1));
    expect(r.height, lessThanOrEqualTo(880));
    await tester.tapAt(const Offset(5, 5));
    await pumpFor(tester, 900);
    expect(find.text('Recap'), findsNothing);
  });

  testWidgets('window: blooms from its trigger (scaled and translated toward it at the start)', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(size: _tablet);
    _ctx = h.nav.currentContext;
    h.push(_route(GlassWideForm.window, origin: const Rect.fromLTWH(700, 1000, 80, 40)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final early = tester.widget<Transform>(find.byKey(const ValueKey('glass-form-bloom')));
    expect(early.transform.storage[0], lessThan(0.6));
    await pumpFor(tester, 900);
    expect(tester.widget<Transform>(find.byKey(const ValueKey('glass-form-bloom'))).transform.storage[0], closeTo(1, 0.01));
  });

  testWidgets('detail window: 960 wide, top 24, a materialThick slab, and the page behind recedes to 0.97 / blur 8 / 50 %', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(size: const Size(1024, 1366));
    _ctx = h.nav.currentContext;
    h.push(_route(GlassWideForm.detailWindow, title: 'Series'));
    await tester.pump();
    await pumpFor(tester, 900);
    final r = tester.getRect(find.byKey(const ValueKey('glass-detail-slab')));
    expect(r.width, 960);
    expect(r.top, closeTo(24, 0.5));
    expect(r.height, closeTo(1366 - 48, 1));
    final slab = tester.widget<ColoredBox>(find.byKey(const ValueKey('glass-detail-slab')));
    expect(slab.color.a, closeTo(0.84, 0.01));
    final scale = tester.widget<Transform>(find.byKey(const ValueKey('glass-recede-scale')));
    expect(scale.transform.storage[0], closeTo(0.97, 0.002));
    final dim = tester.widget<ColoredBox>(find.byKey(const ValueKey('glass-recede-dim')));
    expect(dim.color.a, closeTo(0.5, 0.01));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFor(tester, 900);
    expect(find.byKey(const ValueKey('glass-recede-scale')), findsNothing);
  });

  testWidgets('popover: 420 wide, anchored to its trigger', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(size: _tablet);
    _ctx = h.nav.currentContext;
    const trigger = Rect.fromLTWH(600, 200, 120, 44);
    h.push(_route(GlassWideForm.popover, origin: trigger, title: 'Offer'));
    await tester.pump();
    await pumpFor(tester, 700);
    final r = _panel(tester);
    expect(r.width, 420);
    expect(r.top, closeTo(trigger.bottom + 8, 1));
    expect(r.right, closeTo(trigger.right, 1));
  });

  testWidgets('a panel opened from inside the detail window stacks over it', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(size: const Size(1024, 1366));
    _ctx = h.nav.currentContext;
    h.push(_route(GlassWideForm.detailWindow, title: 'Series'));
    await tester.pump();
    await pumpFor(tester, 900);
    h.push(_route(GlassWideForm.panel, title: 'Filters'));
    await tester.pump();
    await pumpFor(tester, 900);
    expect(find.text('Series'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    final s = tester.getRect(find.byKey(const ValueKey('glass-detail-slab')));
    final p = tester.getRect(find.byKey(const ValueKey('glass-form-surface')));
    expect(p.left, greaterThan(s.left));
  });

  testWidgets('on a phone the same page is a drag sheet, not a form', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    _ctx = h.nav.currentContext;
    h.push(_route(GlassWideForm.panel));
    await tester.pump();
    await pumpFor(tester, 700);
    expect(find.byKey(const ValueKey('glass-sheet-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('glass-form-surface')), findsNothing);
  });
}
