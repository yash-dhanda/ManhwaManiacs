import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart' show GlassColors;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';

import 'overlay_support.dart';
import 'support.dart';

Iterable<HapticEvent> _events() => GlassHaptics.debugLog.map((e) => e.event);

List<GlassMenuEntry> _entries(List<String> log) => [
      GlassMenuEntry(label: 'Read from the start', icon: GlassGlyph.bookOpen.regular, onSelected: () => log.add('start')),
      GlassMenuEntry(label: 'Read all', onSelected: () => log.add('all')),
      GlassMenuEntry(label: 'Pick a chapter', onSelected: () => log.add('pick')),
      GlassMenuEntry(label: 'Download next 10', icon: GlassGlyph.cloudArrowDown.regular, onSelected: () => log.add('dl'), separatorBefore: true),
    ];

Widget _trigger(List<String> log, {List<GlassMenuEntry>? entries}) => Center(
      child: GlassMenu(
        title: 'Series',
        entries: entries ?? _entries(log),
        builder: (context, menu) => GlassButton(label: 'More', onPressed: menu.open),
      ),
    );

Rect _surface(WidgetTester t) => t.getRect(find.byKey(const ValueKey('glass-menu-surface')));

void main() {
  setUp(GlassHaptics.debugLog.clear);

  testWidgets('the bloom starts at the trigger rect and ends at the menu rect', (tester) async {
    final log = <String>[];
    final h = OverlayHost(tester);
    await h.pump(page: _trigger(log));
    final trigger = tester.getRect(find.byType(GlassButton));
    await tester.tap(find.byType(GlassButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final first = _surface(tester);
    expect((first.center - trigger.center).distance, lessThan(30));
    expect(first.width, lessThan(trigger.width + 60));
    await pumpFor(tester, 700);
    final end = _surface(tester);
    expect(end.width, greaterThanOrEqualTo(220));
    expect(end.height, greaterThan(150));
    expect(find.text('Read all'), findsOneWidget);
  });

  testWidgets('the trigger hides while the menu is open and returns after it closes', (tester) async {
    final log = <String>[];
    final h = OverlayHost(tester);
    await h.pump(page: _trigger(log));
    await tester.tap(find.byType(GlassButton));
    await pumpFor(tester, 700);
    final op = tester.widget<Opacity>(find.ancestor(of: find.byType(GlassButton), matching: find.byType(Opacity)).first);
    expect(op.opacity, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFor(tester, 800);
    expect(find.text('Read all'), findsNothing);
    final op2 = tester.widget<Opacity>(find.ancestor(of: find.byType(GlassButton), matching: find.byType(Opacity)).first);
    expect(op2.opacity, 1);
  });

  testWidgets('keys: arrows move focus, Enter selects, Esc closes; type-ahead jumps to a row', (tester) async {
    final log = <String>[];
    final h = OverlayHost(tester);
    await h.pump(page: _trigger(log));
    await tester.tap(find.byType(GlassButton));
    await pumpFor(tester, 700);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, 800);
    expect(log, ['pick']);
    expect(find.text('Read all'), findsNothing);
  });

  testWidgets('type-ahead: a letter jumps to the next row starting with it', (tester) async {
    final log = <String>[];
    final h = OverlayHost(tester);
    await h.pump(page: _trigger(log));
    await tester.tap(find.byType(GlassButton));
    await pumpFor(tester, 700);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(tester, 800);
    expect(log, ['dl']);
  });

  testWidgets('a tap-opened menu stays open until a row is chosen; a row tap selects and closes', (tester) async {
    final log = <String>[];
    final h = OverlayHost(tester);
    await h.pump(page: _trigger(log));
    await tester.tap(find.byType(GlassButton));
    await pumpFor(tester, 2000);
    expect(find.text('Read all'), findsOneWidget);
    await tester.tap(find.text('Read all'));
    await pumpFor(tester, 800);
    expect(log, ['all']);
    expect(find.text('Read all'), findsNothing);
  });

  testWidgets('slide to select: long press, slide onto a row (select per row), release selects', (tester) async {
    final log = <String>[];
    final h = OverlayHost(tester);
    await h.pump(page: _trigger(log));
    final g = await tester.startGesture(tester.getCenter(find.byType(GlassButton)));
    await tester.pump(const Duration(milliseconds: 600));
    await pumpFor(tester, 600);
    expect(find.text('Read all'), findsOneWidget);
    await g.moveTo(tester.getCenter(find.text('Read all')));
    await tester.pump(const Duration(milliseconds: 100));
    await g.moveTo(tester.getCenter(find.text('Pick a chapter')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(GlassHaptics.debugLog.where((e) => e.event == HapticEvent.select).length, greaterThanOrEqualTo(2));
    await g.up();
    await pumpFor(tester, 900);
    expect(log, ['pick']);
  });

  testWidgets('a menu is a blocker: the overlay queue holds toasts while it is open', (tester) async {
    final log = <String>[];
    final h = OverlayHost(tester);
    await h.pump(page: _trigger(log));
    await tester.tap(find.byType(GlassButton));
    await pumpFor(tester, 700);
    final c = primContainer(tester);
    c.read(overlayQueueProvider.notifier).requestSlot(OverlayKind.toast);
    expect(c.read(overlaySlotVisibleProvider(OverlayKind.toast)), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFor(tester, 800);
    expect(c.read(overlaySlotVisibleProvider(OverlayKind.toast)), isTrue);
  });

  group('row states', () {
    testWidgets('loading keeps the menu open with a spinner until the action is done', (tester) async {
      final gate = Completer<void>();
      final log = <String>[];
      final h = OverlayHost(tester);
      await h.pump(page: _trigger(log, entries: [GlassMenuEntry(label: 'Refresh', run: () => gate.future, onSelected: () => log.add('never'))]));
      await tester.tap(find.byType(GlassButton));
      await pumpFor(tester, 700);
      await tester.tap(find.text('Refresh'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Refresh'), findsOneWidget);
      gate.complete();
      await pumpFor(tester, 900);
      expect(find.text('Refresh'), findsNothing);
    });

    testWidgets('an error swaps the label to the error for 2 s, led by the danger glyph, and announces it', (tester) async {
      final h = OverlayHost(tester);
      await h.pump(page: _trigger([], entries: [GlassMenuEntry(label: 'Refresh', run: () async => throw StateError('x'), errorText: "Couldn't refresh")]));
      await tester.tap(find.byType(GlassButton));
      await pumpFor(tester, 700);
      await tester.tap(find.text('Refresh'));
      await pumpFor(tester, 100);
      expect(find.text("Couldn't refresh"), findsOneWidget);
      expect(_events(), contains(HapticEvent.error));
      await pumpFor(tester, 2300);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('selected shows a trailing check; a toggle row carries checked; a disabled row is skipped by the keys', (tester) async {
      final handle = tester.ensureSemantics();
      final log = <String>[];
      final h = OverlayHost(tester);
      await h.pump(page: _trigger(log, entries: [
        GlassMenuEntry(label: 'Hide from my Circle', checked: true, onSelected: () => log.add('hide')),
        GlassMenuEntry(label: 'Off', enabled: false, onSelected: () => log.add('off')),
        GlassMenuEntry(label: 'Last', onSelected: () => log.add('last')),
      ]));
      await tester.tap(find.byType(GlassButton));
      await pumpFor(tester, 700);
      expect(find.byIcon(PhosphorBold.check), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpFor(tester, 800);
      expect(log, ['last']);
      handle.dispose();
    });

    testWidgets('a destructive row keeps the onGlass label and shows a danger glyph on the backing disc', (tester) async {
      final h = OverlayHost(tester);
      await h.pump(page: _trigger([], entries: [GlassMenuEntry(label: 'Delete download', icon: GlassGlyph.trash.regular, destructive: true, onSelected: () {})]));
      await tester.tap(find.byType(GlassButton));
      await pumpFor(tester, 700);
      final icon = tester.widget<Icon>(find.byIcon(GlassGlyph.trash.regular));
      expect(icon.color, GlassColors.danger);
    });
  });

  testWidgets('the menu route is named "{title} actions"', (tester) async {
    final handle = tester.ensureSemantics();
    final h = OverlayHost(tester);
    await h.pump(page: _trigger([]));
    await tester.tap(find.byType(GlassButton));
    await pumpFor(tester, 700);
    expect(find.bySemanticsLabel('Series actions'), findsAny);
    handle.dispose();
  });

  group('context menu', () {
    Widget poster(List<String> log, {ValueChanged<DragUpdateDetails>? drag}) => Center(
          child: Builder(
            builder: (context) => GlassPoster(
              cover: const ColoredBox(color: Color(0xFF334455)),
              title: 'Solo Leveling',
              width: 120,
              onTap: () {},
              onContextPreview: () {
                final box = context.findRenderObject()! as RenderBox;
                unawaited(showGlassContextMenu(
                  context,
                  sourceRect: box.localToGlobal(Offset.zero) & box.size,
                  preview: const ColoredBox(color: Color(0xFF334455), child: SizedBox(width: 120, height: 180)),
                  kind: GlassPreviewKind.poster,
                  entries: _entries(log),
                  title: 'Solo Leveling',
                  onPreviewDrag: drag,
                ));
              },
            ),
          ),
        );

    testWidgets('a poster long press lifts a copy 1.12x over dimContext and blooms a T4 menu', (tester) async {
      final log = <String>[];
      final h = OverlayHost(tester);
      await h.pump(page: poster(log));
      final src = tester.getRect(find.byType(GlassPoster));
      final g = await tester.startGesture(tester.getCenter(find.byType(GlassPoster)));
      await tester.pump(const Duration(milliseconds: 500));
      await pumpFor(tester, 700);
      expect(find.byKey(const ValueKey('glass-dim-context')), findsOneWidget);
      final preview = tester.getRect(find.byKey(const ValueKey('glass-context-preview')));
      expect(preview.width, closeTo(src.width * 1.12, 1));
      expect(find.text('Read all'), findsOneWidget);
      await g.up();
      await pumpFor(tester, 200);
      expect(find.text('Read all'), findsOneWidget); // the menu stays open after the finger lifts
    });

    testWidgets('a drag on the preview is forwarded and closes the menu', (tester) async {
      var moved = 0.0;
      final log = <String>[];
      final h = OverlayHost(tester);
      await h.pump(page: poster(log, drag: (d) => moved += d.delta.dy.abs()));
      final g = await tester.startGesture(tester.getCenter(find.byType(GlassPoster)));
      await tester.pump(const Duration(milliseconds: 500));
      await pumpFor(tester, 700);
      await g.up();
      await pumpFor(tester, 200);
      await tester.dragFrom(tester.getCenter(find.byKey(const ValueKey('glass-context-preview'))), const Offset(0, -80));
      await pumpFor(tester, 900);
      expect(moved, greaterThan(0));
      expect(find.text('Read all'), findsNothing);
    });

    testWidgets('Shift+F10 from a focused poster opens the menu', (tester) async {
      final log = <String>[];
      final h = OverlayHost(tester);
      await h.pump(page: poster(log));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await pumpFor(tester, 800);
      expect(find.text('Read all'), findsOneWidget);
    });

    testWidgets('a secondary click on a tablet opens the menu at the pointer; on a phone it does nothing', (tester) async {
      final log = <String>[];
      final h = OverlayHost(tester);
      await h.pump(size: const Size(834, 1194), page: Center(child: GlassContextRegion(entries: _entries(log), title: 'Row', child: const SizedBox(width: 300, height: 60, child: Text('row')))));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
      await mouse.addPointer(location: tester.getCenter(find.text('row')));
      await mouse.down(tester.getCenter(find.text('row')));
      await mouse.up();
      await pumpFor(tester, 800);
      expect(find.text('Read all'), findsOneWidget);
      final s = _surface(tester);
      expect((s.topLeft - tester.getCenter(find.text('row'))).distance, lessThan(80));
    });

    testWidgets('the period key opens a focused region anchored to the item', (tester) async {
      final log = <String>[];
      final h = OverlayHost(tester);
      await h.pump(page: Center(child: GlassContextRegion(entries: _entries(log), title: 'Row', child: Focus(autofocus: true, child: const SizedBox(width: 300, height: 60, child: Text('row'))))));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.period);
      await pumpFor(tester, 800);
      expect(find.text('Read all'), findsOneWidget);
    });
  });

  testWidgets('reduced motion: a 150 ms fade in place', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(page: _trigger([]), reduced: true);
    await tester.tap(find.byType(GlassButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final a = _surface(tester);
    await pumpFor(tester, 300);
    expect(_surface(tester), a);
  });
}
