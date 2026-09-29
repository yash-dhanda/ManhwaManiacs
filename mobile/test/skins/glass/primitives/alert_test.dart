import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/confirm_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';

import 'overlay_support.dart';
import 'support.dart';

BuildContext _ctx(OverlayHost h) => h.nav.currentContext!;

double _scale(WidgetTester tester) => tester.widget<Transform>(find.byKey(const ValueKey('glass-alert-scale'))).transform.storage[0];

void main() {
  setUp(GlassHaptics.debugLog.clear);

  testWidgets('blooms from its source control: 0.9 from that control, then 1 on springMorph', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    unawaited(confirmAlert(_ctx(h), title: 'Delete download?', confirmLabel: 'Delete', destructive: true, sourceRect: const Rect.fromLTWH(40, 700, 120, 44)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_scale(tester), lessThan(0.93));
    await pumpFor(tester, 600);
    expect(_scale(tester), closeTo(1, 0.002));
  });

  testWidgets('with no source it blooms from the centre, 0.94 to 1', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    unawaited(confirmAlert(_ctx(h), title: 'Sure?', confirmLabel: 'Yes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final s = _scale(tester);
    expect(s, greaterThan(0.93));
    expect(s, lessThan(0.99));
    await pumpFor(tester, 600);
    expect(_scale(tester), closeTo(1, 0.002));
  });

  testWidgets('two short labels sit side by side, the least destructive trailing', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    // (The test font is 1 em per glyph, so the labels are short.)
    unawaited(showGlassAlert<bool>(_ctx(h), title: 'Sure?', actions: const [
      GlassAlertAction('No', role: GlassAlertRole.cancel, value: false),
      GlassAlertAction('Go', role: GlassAlertRole.destructive, value: true),
    ],),);
    await pumpFor(tester, 500);
    final cancel = tester.getCenter(find.text('No'));
    final del = tester.getCenter(find.text('Go'));
    expect(cancel.dy, closeTo(del.dy, 1));
    expect(cancel.dx, greaterThan(del.dx));
  });

  testWidgets('a label that does not fit side by side stacks the buttons, least destructive on top, never truncated', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    unawaited(confirmAlert(_ctx(h), title: 'Sure?', confirmLabel: 'Remove now', destructive: true));
    await pumpFor(tester, 500);
    expect(tester.getCenter(find.text('Cancel')).dy, lessThan(tester.getCenter(find.text('Remove now')).dy));
    final t = tester.widget<Text>(find.text('Remove now'));
    expect(t.overflow == TextOverflow.ellipsis && tester.getSize(find.text('Remove now')).width < 100, isFalse);
  });

  testWidgets('three actions always stack', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    unawaited(showGlassAlert<int>(_ctx(h), title: 'Choose', actions: const [
      GlassAlertAction('Cancel', role: GlassAlertRole.cancel, value: 0),
      GlassAlertAction('A', value: 1),
      GlassAlertAction('B', value: 2),
    ],),);
    await pumpFor(tester, 500);
    expect(tester.getCenter(find.text('A')).dy, lessThan(tester.getCenter(find.text('B')).dy));
    expect(tester.getCenter(find.text('Cancel')).dy, lessThan(tester.getCenter(find.text('A')).dy));
  });

  testWidgets('initial focus is on the least destructive action; Esc cancels', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    bool? result;
    unawaited(confirmAlert(_ctx(h), title: 'Sure?', confirmLabel: 'Delete', destructive: true).then((v) => result = v));
    await pumpFor(tester, 500);
    final cancelFocus = FocusManager.instance.primaryFocus;
    expect(cancelFocus, isNotNull);
    expect(find.descendant(of: find.byWidget(cancelFocus!.context!.widget), matching: find.text('Cancel')), findsAny);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFor(tester, 600);
    expect(result, isFalse);
    expect(find.text('Sure?'), findsNothing);
  });

  testWidgets('the confirm button resolves true and fires delete.confirm for a destructive one', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    bool? result;
    unawaited(confirmAlert(_ctx(h), title: 'Sure?', confirmLabel: 'Delete', destructive: true).then((v) => result = v));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Delete'));
    await pumpFor(tester, 600);
    expect(result, isTrue);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.deleteConfirm));
    expect(find.text('Sure?'), findsNothing);
  });

  testWidgets('a barrier tap does not dismiss', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    unawaited(confirmAlert(_ctx(h), title: 'Sure?', confirmLabel: 'Yes'));
    await pumpFor(tester, 500);
    await tester.tapAt(const Offset(5, 5));
    await pumpFor(tester, 600);
    expect(find.text('Sure?'), findsOneWidget);
  });

  testWidgets('pending blocks dismissal: Esc and back do nothing until the action finishes', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final gate = Completer<void>();
    int? result;
    unawaited(showGlassAlert<int>(_ctx(h), title: 'Removing', actions: [
      const GlassAlertAction('Cancel', role: GlassAlertRole.cancel, value: 0),
      GlassAlertAction('Remove', role: GlassAlertRole.destructive, value: 1, run: () => gate.future),
    ],).then((v) => result = v),);
    await pumpFor(tester, 500);
    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    h.nav.currentState!.maybePop().ignore();
    await pumpFor(tester, 500);
    expect(find.text('Removing'), findsOneWidget);
    gate.complete();
    await pumpFor(tester, 800);
    expect(result, 1);
    expect(find.text('Removing'), findsNothing);
  });

  testWidgets('an error shows an inline line led by the danger glyph and shakes the confirm', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    unawaited(showGlassAlert<int>(_ctx(h), title: 'Removing', actions: [
      const GlassAlertAction('Cancel', role: GlassAlertRole.cancel, value: 0),
      GlassAlertAction('Remove', role: GlassAlertRole.destructive, value: 1, run: () async => throw StateError('no'), errorText: "Couldn't remove it"),
    ],),);
    await pumpFor(tester, 500);
    await tester.tap(find.text('Remove'));
    await pumpFor(tester, 100);
    expect(find.text("Couldn't remove it"), findsOneWidget);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.error));
    expect(find.text('Removing'), findsOneWidget);
    await pumpFor(tester, 600);
  });

  testWidgets('a phone alert blocks the overlay queue slot; a tablet one does not', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    unawaited(confirmAlert(_ctx(h), title: 'Sure?', confirmLabel: 'Yes'));
    await pumpFor(tester, 500);
    final c = primContainer(tester);
    c.read(overlayQueueProvider.notifier).requestSlot(OverlayKind.toast);
    expect(c.read(overlayQueueProvider).visible, {OverlayKind.alert});
  });

  testWidgets('a standalone hold-to-confirm click always reaches an explicit confirm button', (tester) async {
    final h = OverlayHost(tester);
    var confirmed = 0;
    await h.pump(page: Center(child: HoldToConfirm(label: 'Delete series', onConfirm: () => confirmed++)));
    await tester.tap(find.text('Delete series'));
    await pumpFor(tester, 600);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await pumpFor(tester, 600);
    expect(confirmed, 1);
  });

  testWidgets('reduced motion: a 150 ms fade in place', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(reduced: true);
    unawaited(confirmAlert(_ctx(h), title: 'Sure?', confirmLabel: 'Yes', sourceRect: const Rect.fromLTWH(40, 700, 120, 44)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_scale(tester), 1);
    await pumpFor(tester, 300);
    expect(find.text('Sure?'), findsOneWidget);
  });

  testWidgets('semantics: the route is named and scoped', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final handle = tester.ensureSemantics();
    unawaited(confirmAlert(_ctx(h), title: 'Delete download?', body: 'Frees 120 MB.', confirmLabel: 'Delete'));
    await pumpFor(tester, 500);
    expect(find.bySemanticsLabel('Delete download?'), findsAny);
    handle.dispose();
  });
}
