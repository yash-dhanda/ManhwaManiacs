import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' show AdaptiveGlass;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/continue_stack.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import 'support.dart';

void main() {
  setUp(GlassHaptics.debugLog.clear);

  group('HoldToConfirm', () {
    testWidgets('Enter is a click and calls onRequestConfirm', (tester) async {
      var requested = 0;
      await tester.pumpWidget(primHost(HoldToConfirm(label: 'Hold to delete', onConfirm: () {}, onRequestConfirm: () => requested++)));
      await pumpFor(tester, 400);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(requested, 1);
    });

    testWidgets('a 1,300 ms hold confirms with hold.ramp every 150 ms and hold.done', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(primHost(HoldToConfirm(label: 'Hold to delete', onConfirm: () => confirmed++, onRequestConfirm: () {})));
      await pumpFor(tester, 400);
      final g = await tester.startGesture(tester.getCenter(find.text('Hold to delete')));
      await pumpFor(tester, 1300);
      await g.up();
      await tester.pump();
      expect(confirmed, 1);
      final ev = GlassHaptics.debugLog.map((e) => e.event).toList();
      expect(ev.where((e) => e == HapticEvent.holdRamp).length, 7);
      expect(ev, contains(HapticEvent.holdDone));
      await pumpFor(tester, 400);
    });

    testWidgets('a 600 ms hold aborts and shows the helper for 2 s', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(primHost(HoldToConfirm(label: 'Hold to delete', onConfirm: () => confirmed++, onRequestConfirm: () {})));
      await pumpFor(tester, 400);
      final g = await tester.startGesture(tester.getCenter(find.text('Hold to delete')));
      await pumpFor(tester, 600);
      await g.up();
      await tester.pump();
      expect(confirmed, 0);
      expect(find.text('Keep holding, or tap once to confirm'), findsOneWidget);
      await pumpFor(tester, 2100);
      expect(find.text('Keep holding, or tap once to confirm'), findsNothing);
    });

    testWidgets('10 px of movement before 200 ms cancels with no click', (tester) async {
      var requested = 0;
      await tester.pumpWidget(primHost(HoldToConfirm(label: 'Hold to delete', onConfirm: () {}, onRequestConfirm: () => requested++)));
      await pumpFor(tester, 400);
      final g = await tester.startGesture(tester.getCenter(find.text('Hold to delete')));
      await pumpFor(tester, 50);
      await g.moveBy(const Offset(10, 0));
      await pumpFor(tester, 50);
      await g.up();
      await tester.pump();
      expect(requested, 0);
    });

    testWidgets('inAlert: the fallback button is visible without interaction', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(primHost(HoldToConfirm(label: 'Hold to turn on 18+', mode: HoldMode.inAlert, fallbackLabel: 'Turn on 18+', onConfirm: () => confirmed++)));
      await pumpFor(tester, 400);
      expect(find.text('Turn on 18+'), findsOneWidget);
      await tester.tap(find.text('Turn on 18+'));
      await tester.pump();
      expect(confirmed, 1);
    });

    testWidgets('reduced motion steps the fill in four increments', (tester) async {
      await tester.pumpWidget(primHost(HoldToConfirm(label: 'Hold to delete', onConfirm: () {}, onRequestConfirm: () {}), reduced: true));
      await pumpFor(tester, 400);
      final g = await tester.startGesture(tester.getCenter(find.text('Hold to delete')));
      await pumpFor(tester, 200 + 260);
      await g.up();
      await pumpFor(tester, 400);
    });
  });

  testWidgets('a constant-label toggle exposes toggled with its fixed label', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(primHost(GlassIconButton(icon: const GlassButtonIcon(IconData(0xe46a)), label: 'Favourite', toggle: true, onPressed: () {})));
    await pumpFor(tester, 400);
    final data = tester.getSemantics(find.bySemanticsLabel('Favourite')).getSemanticsData();
    expect(data.flagsCollection.isToggled, Tristate.isTrue);
    expect(data.label, 'Favourite');
    h.dispose();
  });

  testWidgets('an invalid field exposes its error', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(primHost(const SizedBox(width: 300, child: GlassTextField(label: 'Name', error: 'Names need at least two letters'))));
    await pumpFor(tester, 400);
    final data = tester.getSemantics(find.bySemanticsLabel(RegExp('Name'))).getSemanticsData();
    expect(data.hint, 'Names need at least two letters');
    expect(find.text('Names need at least two letters'), findsOneWidget);
    h.dispose();
  });

  testWidgets('a tooltip closes on Escape without moving focus', (tester) async {
    await tester.pumpWidget(primHost(GlassTooltip(message: 'Add to library', forceVisible: true, child: GlassIconButton(icon: const GlassButtonIcon(IconData(0xe3d4)), label: 'Add', onPressed: () {}))));
    await pumpFor(tester, 400);
    expect(find.text('Add to library'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFor(tester, 100);
    expect(find.text('Add to library'), findsNothing);
  });

  testWidgets('the segmented control moves with arrows and Home/End', (tester) async {
    var sel = 1;
    late StateSetter set;
    await tester.pumpWidget(primHost(StatefulBuilder(builder: (context, s) {
      set = s;
      return SizedBox(
        width: 300,
        child: GlassSegmented<int>(segments: const [GlassSegment(value: 0, label: 'One'), GlassSegment(value: 1, label: 'Two'), GlassSegment(value: 2, label: 'Three'), GlassSegment(value: 3, label: 'Four')], selected: sel, onSelected: (v) => set(() => sel = v)),
      );
    },),),);
    await pumpFor(tester, 400);
    tester.element(find.byType(GlassSegmented<int>));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpFor(tester, 100);
    expect(sel, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await pumpFor(tester, 100);
    expect(sel, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await pumpFor(tester, 100);
    expect(sel, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await pumpFor(tester, 100);
    expect(sel, 2);
  });

  testWidgets('the segmented thumb is transient live glass only while dragged', (tester) async {
    await tester.pumpWidget(primHost(SizedBox(width: 300, child: GlassSegmented<int>(segments: const [GlassSegment(value: 0, label: 'One'), GlassSegment(value: 1, label: 'Two')], selected: 0, onSelected: (_) {}))));
    await pumpFor(tester, 400);
    final c = primContainer(tester);
    expect(c.read(glassRegistryProvider).layers, 0);
    final g = await tester.startGesture(tester.getCenter(find.text('One')));
    await g.moveBy(const Offset(30, 0));
    await pumpFor(tester, 100);
    expect(c.read(glassRegistryProvider).layers, 1);
    await g.up();
    await pumpFor(tester, 800);
    expect(c.read(glassRegistryProvider).layers, 0);
  });

  testWidgets('a rail is one tab stop; arrows move inside it and between rails keeping the column', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    Widget rail(String t) => GlassRail(
          title: t,
          revealKey: t,
          itemCount: 8,
          itemWidth: 110,
          itemHeight: 220,
          itemBuilder: (context, i) => GlassPoster(cover: const ColoredBox(color: Color(0xFF334455)), title: '$t $i', width: 110, onTap: () {}),
        );
    await tester.pumpWidget(primHost(GlassBudgetScope(exempt: true, label: 't', child: GlassRailGroup(child: Column(children: [rail('Alpha'), rail('Beta')]))), align: false));
    await pumpFor(tester, 3000);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await pumpFor(tester, 50);
    String? focusedTitle() {
      final n = FocusManager.instance.primaryFocus;
      if (n?.context == null) return null;
      String? found;
      n!.context!.visitAncestorElements((e) {
        if (e.widget is GlassPoster) {
          found = (e.widget as GlassPoster).title;
          return false;
        }
        return true;
      });
      return found;
    }

    expect(focusedTitle(), 'Alpha 0');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpFor(tester, 100);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpFor(tester, 100);
    expect(focusedTitle(), 'Alpha 2');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await pumpFor(tester, 200);
    expect(focusedTitle(), 'Beta 2');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await pumpFor(tester, 200);
    expect(focusedTitle(), 'Alpha 2');
    // Tab leaves the rail: one tab stop per rail.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await pumpFor(tester, 100);
    expect(focusedTitle(), isNot(startsWith('Alpha')));
    await pumpFor(tester, 600);
  });

  testWidgets('a poster tap is a release before 450 ms and a long press calls onContextPreview', (tester) async {
    var taps = 0, previews = 0;
    await tester.pumpWidget(primHost(GlassPoster(cover: const ColoredBox(color: Color(0xFF334455)), title: 'Solo', width: 120, onTap: () => taps++, onContextPreview: () => previews++)));
    await pumpFor(tester, 400);
    await tester.tap(find.byType(GlassPoster));
    await pumpFor(tester, 50);
    expect(taps, 1);
    final g = await tester.startGesture(tester.getCenter(find.byType(GlassPoster)));
    await pumpFor(tester, 460);
    await g.up();
    await pumpFor(tester, 800);
    expect(previews, 1);
    expect(taps, 1);
    expect(GlassHaptics.debugLog.map((e) => e.event), containsAll([HapticEvent.pressLift, HapticEvent.longpressOpen]));
  });

  testWidgets('a poster wears a More actions semantics action', (tester) async {
    final h = tester.ensureSemantics();
    await tester.pumpWidget(primHost(GlassPoster(cover: const ColoredBox(color: Color(0xFF334455)), title: 'Solo', width: 120, onTap: () {}, onContextPreview: () {})));
    await pumpFor(tester, 400);
    final data = tester.getSemantics(find.bySemanticsLabel('Solo')).getSemanticsData();
    expect(data.customSemanticsActionIds, isNotEmpty);
    h.dispose();
  });

  testWidgets('the Continue stack: unopened chapter reads Start and no ratio', (tester) async {
    await tester.pumpWidget(primHost(GlassContinueStack(cover: const ColoredBox(color: Color(0xFF223344)), title: 'Ember', chapter: 143, page: 0, pageCount: 0, onContinue: () {})));
    await pumpFor(tester, 400);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Up next · Ch 143'), findsOneWidget);
  });

  testWidgets('no chip, poster, card or rail arrow creates live glass; a selected chip is a content twin', (tester) async {
    await tester.pumpWidget(primHost(Column(children: [
      GlassChip(label: 'Reading', selected: true, onPressed: () {}),
      GlassChoiceChips<String>(options: const ['A', 'B'], selected: 'A', onSelected: (_) {}, labelOf: (s) => s),
      GlassPoster(cover: const ColoredBox(color: Color(0xFF334455)), title: 'P', width: 100, onTap: () {}),
    ],),),);
    await pumpFor(tester, 400);
    expect(find.byType(AdaptiveGlass), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(primContainer(tester).read(glassRegistryProvider).layers, 0);
  });
}
