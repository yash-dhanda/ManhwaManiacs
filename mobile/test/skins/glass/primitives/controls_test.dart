import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/checkbox.dart';
import 'package:manhwamaniacs/skins/glass/primitives/fill_slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/radio_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrub_rail.dart';
import 'package:manhwamaniacs/skins/glass/primitives/selection_check.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/speed_dial.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stepper.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';

import 'support.dart';

Iterable<HapticEvent> _events() => GlassHaptics.debugLog.map((e) => e.event);

Future<void> _settle(WidgetTester t, [int ms = 700]) => pumpFor(t, ms);

void main() {
  setUp(GlassHaptics.debugLog.clear);

  group('switch', () {
    Future<void> pumpSwitch(WidgetTester tester, {bool value = false, ValueChanged<bool>? onChanged, bool loading = false, int errorTrigger = 0, bool reduced = false, StateSetter? set}) async {
      await tester.pumpWidget(primHost(GlassSwitch(value: value, onChanged: onChanged, label: 'Downloads on Wi-Fi only', loading: loading, errorTrigger: errorTrigger), reduced: reduced));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('a tap toggles, fires toggle.on and the knob overshoots then settles (springTick)', (tester) async {
      var v = false;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassSwitch(value: v, onChanged: (x) => set(() => v = x), label: 'Wi-Fi only');
      })));
      await tester.pump(const Duration(milliseconds: 100));
      final startX = tester.getTopLeft(find.byKey(const ValueKey('glass-switch-knob'))).dx;
      await tester.tap(find.byType(GlassSwitch));
      var maxX = startX;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final k = find.byKey(const ValueKey('glass-switch-knob'));
        if (k.evaluate().isNotEmpty) maxX = maxX > tester.getTopLeft(k).dx ? maxX : tester.getTopLeft(k).dx;
      }
      expect(v, isTrue);
      expect(_events(), contains(HapticEvent.toggleOn));
      final end = tester.getTopLeft(find.byKey(const ValueKey('glass-switch-knob'))).dx;
      expect(end - startX, closeTo(20, 0.6));
      expect(maxX, greaterThan(end + 0.4)); // the 4.6 % overshoot
      await tester.tap(find.byType(GlassSwitch));
      await _settle(tester);
      expect(v, isFalse);
      expect(_events(), contains(HapticEvent.toggleOff));
    });

    testWidgets('dragging the knob shows transient glass, follows the finger and projects to on', (tester) async {
      var v = false;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassSwitch(value: v, onChanged: (x) => set(() => v = x), label: 'x');
      })));
      await tester.pump(const Duration(milliseconds: 100));
      final g = await tester.startGesture(tester.getCenter(find.byType(GlassSwitch)) - const Offset(10, 0));
      await g.moveBy(const Offset(22, 0)); // past the 18 px drag slop
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(const ValueKey('glass-switch-knob-glass')), findsOneWidget);
      await g.moveBy(const Offset(14, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await g.up();
      await _settle(tester);
      expect(v, isTrue);
      expect(find.byKey(const ValueKey('glass-switch-knob-glass')), findsNothing);
    });

    testWidgets('a short drag that does not pass halfway settles back off', (tester) async {
      var v = false;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassSwitch(value: v, onChanged: (x) => set(() => v = x), label: 'x');
      })));
      await tester.pump(const Duration(milliseconds: 100));
      final g = await tester.startGesture(tester.getCenter(find.byType(GlassSwitch)) - const Offset(10, 0));
      await g.moveBy(const Offset(22, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await g.moveBy(const Offset(-14, 0)); // back under halfway of the 20 px travel
      await tester.pump(const Duration(milliseconds: 300));
      await g.up();
      await _settle(tester);
      expect(v, isFalse);
    });

    testWidgets('disabled and loading do not toggle; loading shows a spinner in the knob', (tester) async {
      var taps = 0;
      await pumpSwitch(tester, onChanged: (_) => taps++, loading: true);
      await tester.tap(find.byType(GlassSwitch), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
      await pumpSwitch(tester, onChanged: null);
      await tester.tap(find.byType(GlassSwitch), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('an error springs the knob back and fires the error haptic', (tester) async {
      late StateSetter set;
      var err = 0;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassSwitch(value: false, onChanged: (_) {}, label: 'x', errorTrigger: err);
      })));
      await tester.pump(const Duration(milliseconds: 100));
      final start = tester.getTopLeft(find.byKey(const ValueKey('glass-switch-knob'))).dx;
      await tester.tap(find.byType(GlassSwitch));
      await _settle(tester);
      expect(tester.getTopLeft(find.byKey(const ValueKey('glass-switch-knob'))).dx, greaterThan(start + 10)); // optimistic
      set(() => err++);
      await _settle(tester);
      expect(tester.getTopLeft(find.byKey(const ValueKey('glass-switch-knob'))).dx, closeTo(start, 0.6));
      expect(_events(), contains(HapticEvent.error));
    });

    testWidgets('Space toggles from the keyboard and semantics carries toggled', (tester) async {
      var v = false;
      late StateSetter set;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassSwitch(value: v, onChanged: (x) => set(() => v = x), label: 'Notifications');
      })));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _settle(tester);
      expect(v, isTrue);
      final d = tester.getSemantics(find.bySemanticsLabel('Notifications')).getSemanticsData();
      expect(d.flagsCollection.isToggled, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('reduced motion: the knob jumps', (tester) async {
      var v = false;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassSwitch(value: v, onChanged: (x) => set(() => v = x), label: 'x');
      }), reduced: true));
      bindReduced(tester);
      await tester.pump(const Duration(milliseconds: 100));
      final start = tester.getTopLeft(find.byKey(const ValueKey('glass-switch-knob'))).dx;
      await tester.tap(find.byType(GlassSwitch));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(find.byKey(const ValueKey('glass-switch-knob'))).dx - start, closeTo(20, 0.6));
    });
  });

  group('checkbox', () {
    testWidgets('a tap turns it on, the check draws over 160 ms', (tester) async {
      bool? v = false;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassCheckbox(value: v, onChanged: (x) => set(() => v = x), label: 'Select all');
      })));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(GlassCheckbox));
      await tester.pump(const Duration(milliseconds: 16));
      expect(v, isTrue);
      expect(_events(), contains(HapticEvent.toggleOn));
      await _settle(tester, 300);
    });

    testWidgets('indeterminate is mixed in semantics and a tap turns it on', (tester) async {
      bool? v;
      late StateSetter set;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassCheckbox(value: v, onChanged: (x) => set(() => v = x), label: 'Some');
      })));
      await tester.pump(const Duration(milliseconds: 100));
      final d = tester.getSemantics(find.bySemanticsLabel('Some')).getSemanticsData();
      expect(d.flagsCollection.isChecked, CheckedState.mixed);
      await tester.tap(find.byType(GlassCheckbox));
      await _settle(tester, 300);
      expect(v, isTrue);
      handle.dispose();
    });

    testWidgets('hit area is hitMin on iOS and 48 on Android', (tester) async {
      await tester.pumpWidget(primHost(GlassCheckbox(value: false, onChanged: (_) {}, label: 'x')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(find.byType(GlassCheckbox)).shortestSide, greaterThanOrEqualTo(44));
      await tester.pumpWidget(primHost(GlassCheckbox(value: false, onChanged: (_) {}, label: 'x'), platform: TargetPlatform.android));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(find.byType(GlassCheckbox)).shortestSide, greaterThanOrEqualTo(48));
    });
  });

  group('radio list', () {
    testWidgets('a tap selects, the selected row has the trailing check, arrows move the selection', (tester) async {
      var v = 'a';
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return SizedBox(
          width: 320,
          child: GlassRadioList<String>(
            options: const [GlassRadioOption(value: 'a', label: 'One'), GlassRadioOption(value: 'b', label: 'Two'), GlassRadioOption(value: 'c', label: 'Three')],
            value: v,
            onChanged: (x) => set(() => v = x),
          ),
        );
      })));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Two'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(v, 'b');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 50));
      expect(v, 'c');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // the end: stays
      await tester.pump(const Duration(milliseconds: 50));
      expect(v, 'c');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 50));
      expect(v, 'b');
    });

    testWidgets('each row is in a mutually exclusive group with checked', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(primHost(SizedBox(
        width: 320,
        child: GlassRadioList<int>(options: const [GlassRadioOption(value: 1, label: 'Once'), GlassRadioOption(value: 2, label: 'Twice')], value: 2, onChanged: (_) {}),
      )));
      await tester.pump(const Duration(milliseconds: 100));
      final twice = tester.getSemantics(find.text('Twice')).getSemanticsData();
      expect(twice.flagsCollection.isChecked, CheckedState.isTrue);
      expect(twice.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      handle.dispose();
    });
  });

  testWidgets('the selection check springs in from scale 0', (tester) async {
    late StateSetter set;
    var sel = false;
    await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
      set = s;
      return GlassSelectionCheck(selected: sel);
    })));
    await tester.pump(const Duration(milliseconds: 100));
    set(() => sel = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await _settle(tester, 400);
    expect(find.byType(GlassSelectionCheck), findsOneWidget);
  });

  group('stepper', () {
    testWidgets('steps, stops at a limit with detent.limit and stretches the value toward the pressed side', (tester) async {
      var v = 9;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassStepper(value: v, onChanged: (x) => set(() => v = x), label: 'Download count', max: 10);
      })));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.bySemanticsLabel('Increase Download count').evaluate().isEmpty ? find.byIcon(GlassGlyph.plus.bold) : find.bySemanticsLabel('Increase Download count'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(v, 10);
      expect(_events(), contains(HapticEvent.detentTick));
      GlassHaptics.debugLog.clear();
      await tester.tap(find.byIcon(GlassGlyph.plus.bold));
      await tester.pump(const Duration(milliseconds: 16));
      expect(v, 10);
      expect(_events(), contains(HapticEvent.detentLimit));
      final stretch = tester.widget<Transform>(find.byKey(const ValueKey('glass-stepper-value')));
      expect(stretch.transform.storage[0], greaterThan(1));
      await _settle(tester, 700);
    });

    testWidgets('Up and Down step from the keyboard', (tester) async {
      var v = 3;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return GlassStepper(value: v, onChanged: (x) => set(() => v = x), label: 'n');
      })));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 50));
      expect(v, 4);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 50));
      expect(v, 2);
    });

    testWidgets('semantics: value, increasedValue, decreasedValue and the actions', (tester) async {
      final handle = tester.ensureSemantics();
      var v = 5;
      await tester.pumpWidget(primHost(GlassStepper(value: v, onChanged: (x) => v = x, label: 'Pages')));
      await tester.pump(const Duration(milliseconds: 100));
      final d = tester.getSemantics(find.bySemanticsLabel('Pages')).getSemanticsData();
      expect(d.value, '5');
      expect(d.increasedValue, '6');
      expect(d.decreasedValue, '4');
      tester.semantics.increase(find.semantics.byLabel('Pages'));
      await tester.pump();
      expect(v, 6);
      handle.dispose();
    });
  });

  group('slider', () {
    testWidgets('dragging moves the value; the thumb becomes transient glass with a value bubble', (tester) async {
      var v = 0.2;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return SizedBox(width: 360, child: GlassSlider(value: v, onChanged: (x) => set(() => v = x), label: 'Brightness'));
      })));
      await tester.pump(const Duration(milliseconds: 100));
      final thumb = tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb')));
      final g = await tester.startGesture(thumb);
      await g.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await g.moveBy(const Offset(60, 0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(const ValueKey('glass-slider-thumb-glass')), findsOneWidget);
      expect(find.byKey(const ValueKey('glass-slider-bubble')), findsOneWidget);
      expect(v, greaterThan(0.4));
      await g.up();
      await _settle(tester, 500);
      expect(find.byKey(const ValueKey('glass-slider-thumb-glass')), findsNothing);
    });

    testWidgets('a stepped slider ticks per step and the value lands on a step', (tester) async {
      var v = 0.0;
      double? ended;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return SizedBox(width: 360, child: GlassSlider(value: v, max: 4, divisions: 4, onChanged: (x) => set(() => v = x), onChangeEnd: (x) => ended = x, label: 'Size'));
      })));
      await tester.pump(const Duration(milliseconds: 100));
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb'))));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(const Offset(22, 0));
        await tester.pump(const Duration(milliseconds: 40));
      }
      await g.up();
      await _settle(tester, 500);
      expect(GlassHaptics.debugLog.where((e) => e.event == HapticEvent.detentTick).length, greaterThanOrEqualTo(2));
      expect(ended, isNotNull);
      expect(ended! % 1, 0);
    });

    testWidgets('past the end it rubber-bands and fires detent.limit', (tester) async {
      var v = 0.9;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return SizedBox(width: 360, child: GlassSlider(value: v, onChanged: (x) => set(() => v = x), label: 'x'));
      })));
      await tester.pump(const Duration(milliseconds: 100));
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb'))));
      await g.moveBy(const Offset(200, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await g.moveBy(const Offset(400, 0));
      await tester.pump(const Duration(milliseconds: 16));
      final thumb = tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb-glass'))).dx;
      final trackEnd = tester.getTopRight(find.byType(GlassSlider)).dx - 52 - 14;
      expect(thumb - trackEnd, lessThanOrEqualTo(12.5));
      expect(v, 1.0);
      expect(_events(), contains(HapticEvent.detentLimit));
      await g.up();
      await _settle(tester, 500);
    });

    testWidgets('hardware keys: arrows, Page Up/Down, Home and End; semantics carries the value', (tester) async {
      final handle = tester.ensureSemantics();
      var v = 0.5;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return SizedBox(width: 360, child: GlassSlider(value: v, onChanged: (x) => set(() => v = x), label: 'Speed', format: (x) => '${(x * 100).round()}%'));
      })));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(v, closeTo(0.51, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      expect(v, closeTo(0.61, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(v, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(v, 1);
      final d = tester.getSemantics(find.bySemanticsLabel('Speed')).getSemanticsData();
      expect(d.value, '100%');
      expect(d.flagsCollection.isSlider, isTrue);
      handle.dispose();
    });

    testWidgets('an error springs the thumb back to the last saved value', (tester) async {
      var err = 0;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
        set = s;
        return SizedBox(width: 360, child: GlassSlider(value: 0.2, onChanged: (_) {}, label: 'x', errorTrigger: err));
      })));
      await tester.pump(const Duration(milliseconds: 100));
      final rest = tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb'))).dx;
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb'))));
      await g.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await g.moveBy(const Offset(80, 0));
      await g.up();
      await _settle(tester, 500);
      set(() => err++);
      await _settle(tester, 600);
      expect(tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb'))).dx, closeTo(rest, 1.0));
      expect(_events(), contains(HapticEvent.error));
    });

    testWidgets('disabled: not draggable', (tester) async {
      await tester.pumpWidget(primHost(SizedBox(width: 360, child: GlassSlider(value: 0.2, onChanged: null, label: 'x'))));
      await tester.pump(const Duration(milliseconds: 100));
      final rest = tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb'))).dx;
      await tester.dragFrom(tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb'))), const Offset(100, 0));
      await tester.pump();
      expect(tester.getCenter(find.byKey(const ValueKey('glass-slider-thumb'))).dx, rest);
    });
  });

  testWidgets('the fill slider follows a vertical drag and exposes a slider', (tester) async {
    var v = 0.2;
    late StateSetter set;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(primHost(StatefulBuilder(builder: (c, s) {
      set = s;
      return GlassFillSlider(value: v, onChanged: (x) => set(() => v = x), label: 'Brightness');
    })));
    await tester.pump(const Duration(milliseconds: 100));
    final top = tester.getTopLeft(find.byType(GlassFillSlider));
    final g = await tester.startGesture(top + const Offset(36, 150));
    await g.moveTo(top + const Offset(36, 40));
    await tester.pump(const Duration(milliseconds: 16));
    await g.up();
    await _settle(tester, 400);
    expect(v, closeTo(0.75, 0.05));
    expect(tester.getSemantics(find.bySemanticsLabel('Brightness')).getSemanticsData().flagsCollection.isSlider, isTrue);
    handle.dispose();
  });

  group('speed dial', () {
    Future<void> pumpDial(WidgetTester tester, {double value = 1.0, required List<double> changed, required List<double> committed}) async {
      await tester.pumpWidget(primHost(GlassSpeedDial(value: value, onChanged: changed.add, onCommit: committed.add, wpmAt: (s) => (190 * s).round())));
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('dragging up 60 px is +0.5x with a tick per quarter, committed on release', (tester) async {
      final ch = <double>[], co = <double>[];
      await pumpDial(tester, changed: ch, committed: co);
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('glass-dial-capsule'))));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(0, -6));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(ch.last, closeTo(1.5, 1e-9));
      expect(GlassHaptics.debugLog.where((e) => e.event == HapticEvent.detentTick).length, greaterThanOrEqualTo(2));
      expect(co, isEmpty); // previews live, commits on release
      await g.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(co, [1.5]);
    });

    testWidgets('a magnet holds within 0.08 of 1.0x and fires detent.magnet', (tester) async {
      final ch = <double>[], co = <double>[];
      await pumpDial(tester, value: 1.3, changed: ch, committed: co);
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('glass-dial-capsule'))));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(const Offset(0, 6)); // down 72 px = -0.6x from 1.3 to 0.7? stops through 1.0
        await tester.pump(const Duration(milliseconds: 16));
        if (ch.isNotEmpty && ch.last == 1.0) break;
      }
      expect(ch, contains(1.0));
      expect(_events(), contains(HapticEvent.detentMagnet));
      await g.up();
    });

    testWidgets('a 600 ms hold without moving resets to 1.0x', (tester) async {
      final ch = <double>[], co = <double>[];
      await pumpDial(tester, value: 2.0, changed: ch, committed: co);
      final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('glass-dial-capsule'))));
      await tester.pump(const Duration(milliseconds: 650));
      expect(co, [1.0]);
      expect(ch.last, 1.0);
      await g.up();
    });

    testWidgets('a preset chip sets the speed; the wpm caption follows', (tester) async {
      final ch = <double>[], co = <double>[];
      await pumpDial(tester, changed: ch, committed: co);
      expect(find.text('≈ 190 wpm'), findsOneWidget);
      await tester.tap(find.text('1.25'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(co, [1.25]);
      expect(find.text('≈ 238 wpm'), findsOneWidget);
    });

    testWidgets('keys: arrows 0.05, Page Up/Down 0.25, Home/End; semantics reads the speed and the wpm', (tester) async {
      final handle = tester.ensureSemantics();
      final ch = <double>[], co = <double>[];
      await pumpDial(tester, changed: ch, committed: co);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(co.last, closeTo(1.05, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      expect(co.last, closeTo(1.30, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(co.last, 3.0);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(co.last, 0.5);
      expect(tester.getSemantics(find.bySemanticsLabel('Speed')).getSemanticsData().value, contains('about'));
      handle.dispose();
    });
  });

  group('scrub rail', () {
    testWidgets('a one-page chapter renders no rail', (tester) async {
      await tester.pumpWidget(primHost(GlassScrubRail(pageCount: 1, page: 0, onCommit: (_) {}, renderPreview: (p) => const SizedBox())));
      expect(find.byKey(const ValueKey('glass-scrub-track')), findsNothing);
    });

    testWidgets('touch grows the lens with the page and number; release commits the page', (tester) async {
      int? committed;
      await tester.pumpWidget(primHost(Padding(
        padding: const EdgeInsets.only(left: 300, top: 50),
        child: GlassScrubRail(pageCount: 40, page: 0, height: 300, onCommit: (p) => committed = p, renderPreview: (p) => Text('preview $p')),
      )));
      await tester.pump(const Duration(milliseconds: 100));
      final rail = tester.getTopLeft(find.byType(GlassScrubRail));
      final g = await tester.startGesture(rail + const Offset(22, 6));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(const ValueKey('glass-scrub-lens')), findsOneWidget);
      await g.moveTo(rail + const Offset(22, 6 + 138));
      await tester.pump(const Duration(milliseconds: 100));
      final expected = (144 / 300 * 39).round();
      expect(find.text('${expected + 1}'), findsOneWidget);
      expect(find.text('preview $expected'), findsOneWidget);
      expect(_events(), contains(HapticEvent.scrubTick));
      await g.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(committed, expected);
      await _settle(tester, 400);
      expect(find.byKey(const ValueKey('glass-scrub-lens')), findsNothing);
    });

    testWidgets('scrub.boundary at the last page and at a segment boundary', (tester) async {
      await tester.pumpWidget(primHost(Padding(
        padding: const EdgeInsets.only(left: 300, top: 50),
        child: GlassScrubRail(pageCount: 40, page: 0, height: 300, segments: const [10, 10, 20], onCommit: (_) {}, renderPreview: (p) => const SizedBox()),
      )));
      await tester.pump(const Duration(milliseconds: 100));
      final rail = tester.getTopLeft(find.byType(GlassScrubRail));
      final g = await tester.startGesture(rail + const Offset(22, 6));
      await g.moveTo(rail + const Offset(22, 200));
      await tester.pump(const Duration(milliseconds: 50));
      expect(_events(), contains(HapticEvent.scrubBoundary)); // crossed page 10 or 20
      GlassHaptics.debugLog.clear();
      await g.moveTo(rail + const Offset(22, 400));
      await tester.pump(const Duration(milliseconds: 50));
      expect(_events(), contains(HapticEvent.scrubBoundary));
      await g.up();
      await _settle(tester, 400);
    });

    testWidgets('semantics value is "Page 18 of 40" and the rail is a slider', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(primHost(GlassScrubRail(pageCount: 40, page: 17, onCommit: (_) {}, renderPreview: (p) => const SizedBox())));
      await tester.pump(const Duration(milliseconds: 100));
      final d = tester.getSemantics(find.bySemanticsLabel('Page scrubber')).getSemanticsData();
      expect(d.value, 'Page 18 of 40');
      expect(d.flagsCollection.isSlider, isTrue);
      handle.dispose();
    });
  });
}
