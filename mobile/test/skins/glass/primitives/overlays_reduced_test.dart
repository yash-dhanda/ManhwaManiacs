// ignore_for_file: unawaited_futures
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';

import 'overlay_support.dart';
import 'support.dart';

/// The glass 4.10 last column for the surfaces of mobile/27: a fade in place instead of a bloom, fall or
/// recession; the finger still tracks 1:1.
void main() {
  testWidgets(
      'a sheet presents with a fade and a small translate, and the page behind does not recede',
      (tester) async {
    final h = OverlayHost(tester);
    await h.pump(reduced: true);
    h.push(GlassSheetPage<void>(
            title: 'Sheet', builder: (_) => const Center(child: Text('body')),)
        .createRoute(h.nav.currentContext!),);
    await pumpFor(tester, 900);
    expect(find.text('Sheet'), findsOneWidget);
    expect(find.byKey(const ValueKey('glass-recede-scale')), findsNothing);
    expect(find.byKey(const ValueKey('glass-recede-blur')), findsNothing);
  });

  testWidgets('an alert fades in place: its centre does not move',
      (tester) async {
    final h = OverlayHost(tester);
    await h.pump(reduced: true);
    showGlassAlert<int>(
      h.nav.currentContext!,
      title: 'Remove?',
      sourceRect: const Rect.fromLTWH(20, 700, 100, 44),
      actions: const [
        GlassAlertAction<int>('Cancel', role: GlassAlertRole.cancel, value: 0),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    final early = tester.getCenter(find.text('Remove?'));
    await pumpFor(tester, 700);
    final end = tester.getCenter(find.text('Remove?'));
    expect((early - end).distance, lessThan(3));
  });

  testWidgets('a menu fades in place at its final rect', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(reduced: true);
    showGlassMenu(h.nav.currentContext!,
        anchor: const Rect.fromLTWH(100, 300, 100, 44),
        title: 'Actions',
        entries: [GlassMenuEntry(label: 'One', onSelected: () {})],);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    final early =
        tester.getRect(find.byKey(const ValueKey('glass-menu-surface')));
    await pumpFor(tester, 700);
    final end =
        tester.getRect(find.byKey(const ValueKey('glass-menu-surface')));
    expect(early.size, end.size);
    expect((early.center - end.center).distance, lessThan(3));
  });

  testWidgets(
      'a toast appears at its resting place instead of falling from 60 px',
      (tester) async {
    final h = OverlayHost(tester);
    await h.pump(
        reduced: true, page: const GlassToastHost(child: SizedBox.expand()),);
    primContainer(tester)
        .read(glassToastProvider.notifier)
        .show(const GlassToastSpec('Saved'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    final early = tester.getTopLeft(find.text('Saved'));
    await pumpFor(tester, 700);
    final end = tester.getTopLeft(find.text('Saved'));
    expect((early - end).distance, lessThan(3));
  });

  testWidgets('the finger still tracks a sheet 1:1 under reduced motion',
      (tester) async {
    final h = OverlayHost(tester);
    await h.pump(reduced: true);
    h.push(GlassSheetPage<void>(
            title: 'Sheet', builder: (_) => const Center(child: Text('body')),)
        .createRoute(h.nav.currentContext!),);
    await pumpFor(tester, 900);
    final y0 = tester.getTopLeft(find.text('Sheet')).dy;
    final g = await tester.startGesture(tester.getCenter(find.text('Sheet')));
    await g.moveBy(const Offset(0, -20));
    await g.moveBy(const Offset(0, -50));
    await tester.pump(const Duration(milliseconds: 16));
    expect(y0 - tester.getTopLeft(find.text('Sheet')).dy, closeTo(70, 6));
    await g.up();
    await pumpFor(tester, 600);
  });
}
