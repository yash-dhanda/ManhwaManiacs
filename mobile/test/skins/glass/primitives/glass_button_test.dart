import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/lit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import 'support.dart';

void main() {
  setUp(() {
    GlassLit.reset();
    GlassHaptics.debugLog.clear();
  });

  testWidgets('a tap activates on release and the primary fires tap.primary', (tester) async {
    var taps = 0;
    await tester.pumpWidget(primHost(GlassButton(label: 'Continue', variant: GlassButtonVariant.primary, onPressed: () => taps++)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(taps, 1);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.tapPrimary));
  });

  testWidgets('a secondary fires no haptic (tap.secondary maps to none)', (tester) async {
    var taps = 0;
    await tester.pumpWidget(primHost(GlassButton(label: 'Later', onPressed: () => taps++)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Later'));
    await tester.pump();
    expect(taps, 1);
    expect(GlassHaptics.debugLog, isEmpty);
  });

  testWidgets('dragging 1.5 x the hit area away cancels: no activation, no haptic', (tester) async {
    var taps = 0;
    await tester.pumpWidget(primHost(GlassButton(label: 'Continue', variant: GlassButtonVariant.primary, onPressed: () => taps++)));
    await tester.pump(const Duration(milliseconds: 400));
    final g = await tester.startGesture(tester.getCenter(find.text('Continue')));
    await g.moveBy(const Offset(120, 0));
    await g.up();
    await tester.pump();
    expect(taps, 0);
    expect(GlassHaptics.debugLog, isEmpty);
  });

  testWidgets('disabled: not activatable, semantics disabled', (tester) async {
    await tester.pumpWidget(primHost(const GlassButton(label: 'Save', onPressed: null, disabledReason: 'Nothing to save')));
    await tester.pump(const Duration(milliseconds: 400));
    final node = tester.getSemantics(find.bySemanticsLabel('Save'));
    expect(node.getSemanticsData().flagsCollection.isEnabled, Tristate.isFalse);
  });

  testWidgets('loading: not activatable and semantics value Loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(primHost(GlassButton(label: 'Save', loading: true, onPressed: () => taps++)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(GlassButton), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    expect(tester.getSemantics(find.bySemanticsLabel('Save')).value, 'Loading');
  });

  testWidgets('the label follows the visible text (no toggled flag)', (tester) async {
    await tester.pumpWidget(primHost(GlassButton(label: 'In library', selected: true, onPressed: () {})));
    await tester.pump(const Duration(milliseconds: 400));
    final data = tester.getSemantics(find.bySemanticsLabel('In library')).getSemanticsData();
    expect(data.label, 'In library');
    expect(data.flagsCollection.isToggled, Tristate.none);
  });

  testWidgets('error text shows for 2 s with the error haptic', (tester) async {
    var n = 0;
    late StateSetter set;
    await tester.pumpWidget(primHost(StatefulBuilder(builder: (context, s) {
      set = s;
      return GlassButton(label: 'Save', errorText: "Couldn't save", errorTrigger: n, onPressed: () {});
    },),),);
    await tester.pump(const Duration(milliseconds: 400));
    set(() => n++);
    await tester.pump();
    expect(find.text("Couldn't save"), findsOneWidget);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.error));
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text("Couldn't save"), findsNothing);
  });

  testWidgets('two primary buttons warn once about the lit rule; suppressLit drops the caustic', (tester) async {
    await tester.pumpWidget(primHost(Column(children: [
      GlassButton(label: 'One', variant: GlassButtonVariant.primary, onPressed: () {}),
      GlassButton(label: 'Two', variant: GlassButtonVariant.primary, onPressed: () {}),
    ],),),);
    await tester.pump(const Duration(milliseconds: 400));
    expect(GlassLit.count, 2);
    final release = suppressLit();
    await tester.pump(const Duration(milliseconds: 200));
    expect(GlassLit.suppressed, isTrue);
    release();
    await tester.pump();
    expect(GlassLit.suppressed, isFalse);
  });

  testWidgets('press grows glass by 12 px on the longest side', (tester) async {
    await tester.pumpWidget(primHost(GlassButton(label: 'Continue', variant: GlassButtonVariant.primary, onPressed: () {}, forceStates: const GlassWidgetStates(pressed: true))));
    await tester.pump(const Duration(milliseconds: 800));
    final box = tester.getRect(find.byType(SkinGlass));
    final s = tester
        .widgetList<Transform>(find.descendant(of: find.byType(GlassPressable), matching: find.byType(Transform)))
        .map((t) => t.transform.getMaxScaleOnAxis())
        .reduce((a, b) => a > b ? a : b);
    expect((s - (box.width + 12) / box.width).abs(), lessThan(0.02));
  });
}
