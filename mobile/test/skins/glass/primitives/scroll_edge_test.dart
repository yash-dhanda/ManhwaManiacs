import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/fast_scroll.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scroll_edge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrollbar.dart';

import 'support.dart';

Widget _list({ScrollController? c, int count = 60, double topPlateau = 100}) => SizedBox(
      width: 390,
      height: 700,
      child: GlassScrollEdges(
        topPlateau: topPlateau,
        bottomPlateau: 85,
        child: ListView.builder(controller: c, itemExtent: 56, itemCount: count, itemBuilder: (context, i) => Text('row $i')),
      ),
    );

double _edgeOpacity(WidgetTester t, GlassEdge e) {
  final w = t.widgetList<GlassScrollEdge>(find.byType(GlassScrollEdge)).firstWhere((x) => x.edge == e);
  return w.opacity;
}

void main() {
  setUp(GlassHaptics.debugLog.clear);

  testWidgets('the edges fade in as content arrives under them: top clamp(pixels / 24), bottom clamp(extentAfter / 24)', (tester) async {
    final c = ScrollController();
    await tester.pumpWidget(primHost(_list(c: c)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_edgeOpacity(tester, GlassEdge.top), 0);
    expect(_edgeOpacity(tester, GlassEdge.bottom), 1);
    c.jumpTo(12);
    await tester.pump();
    expect(_edgeOpacity(tester, GlassEdge.top), closeTo(0.5, 1e-9));
    c.jumpTo(60);
    await tester.pump();
    expect(_edgeOpacity(tester, GlassEdge.top), 1);
    c.jumpTo(c.position.maxScrollExtent - 6);
    await tester.pump();
    expect(_edgeOpacity(tester, GlassEdge.bottom), closeTo(0.25, 1e-9));
    c.jumpTo(c.position.maxScrollExtent);
    await tester.pump();
    expect(_edgeOpacity(tester, GlassEdge.bottom), 0);
  });

  testWidgets('the soft edge is a tint, no blur: B8 over the device inset, 8C at the far edge of the bars, clear 16 px past them; a scrim', (tester) async {
    await tester.pumpWidget(primHost(_list()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getSize(find.byType(GlassScrollEdge).last).height, 101); // the bottom edge: bars 85 + a 16 px fade
    expect(find.descendant(of: find.byType(GlassScrollEdge), matching: find.byType(BackdropFilter)), findsNothing);
    final box = tester.widget<DecoratedBox>(find.byKey(const ValueKey('glass-edge-soft')).last);
    final g = (box.decoration as BoxDecoration).gradient! as LinearGradient;
    expect(g.colors.first, const Color(0xB8000000));
    expect(g.colors, const [Color(0xB8000000), Color(0xB8000000), Color(0x8C000000), Color(0x00000000)]);
    expect(g.stops![1], 0); // no device inset here
    expect(g.stops![2], closeTo(85 / 101, 1e-9)); // the bars' far edge
    final registry = primContainer(tester).read(glassRegistryProvider);
    expect(registry.scrims, greaterThanOrEqualTo(1));
    expect(registry.layers, 0);
  });

  testWidgets('the solid part of the soft edge covers only the device inset', (tester) async {
    await tester.pumpWidget(primHost(const Align(alignment: Alignment.bottomCenter, child: GlassScrollEdge(edge: GlassEdge.bottom, plateau: 119, solid: 34))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getSize(find.byType(GlassScrollEdge)).height, 135);
    final g = (tester.widget<DecoratedBox>(find.byKey(const ValueKey('glass-edge-soft'))).decoration as BoxDecoration).gradient! as LinearGradient;
    expect(g.stops![1], closeTo(34 / 135, 1e-9));
  });

  testWidgets('under Solid glass the edge becomes the hard edge: edgeHard with a 0.5 px separator, no blur', (tester) async {
    await tester.pumpWidget(primHost(_list(), solid: true));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('glass-edge-hard')), findsWidgets);
    expect(find.byKey(const ValueKey('glass-edge-soft')), findsNothing);
    final d = tester.widget<DecoratedBox>(find.byKey(const ValueKey('glass-edge-hard')).first).decoration as BoxDecoration;
    expect(d.color, GlassColors.edgeHard);
  });

  testWidgets('the hard edge is edgeHard with a separator line', (tester) async {
    await tester.pumpWidget(primHost(const GlassHardEdge(height: 44)));
    final d = tester.widget<DecoratedBox>(find.descendant(of: find.byType(GlassHardEdge), matching: find.byType(DecoratedBox)).first).decoration as BoxDecoration;
    expect(d.color, const Color(0xEB000000));
    expect((d.border! as Border).bottom.width, 0.5);
  });

  testWidgets('the scrollbar: thickness 3 (8 pressed), radius 1.5 (4), colour white at 28 %, a 200 ms press to drag', (tester) async {
    final c = ScrollController();
    await tester.pumpWidget(primHost(SizedBox(width: 390, height: 700, child: GlassScrollbar(controller: c, child: ListView.builder(controller: c, itemExtent: 56, itemCount: 60, itemBuilder: (context, i) => Text('row $i'))))));
    final sb = tester.widget<GlassScrollbar>(find.byType(GlassScrollbar));
    expect(sb.thickness, 3);
    expect(sb.thicknessWhileDragging, 8);
    expect(sb.radius, const Radius.circular(1.5));
    expect(sb.radiusWhileDragging, const Radius.circular(4));
    expect(sb.pressDuration, const Duration(milliseconds: 200));
    c.jumpTo(100);
    await tester.pump(const Duration(milliseconds: 100));
    // Shown while scrolling.
    await tester.pump(const Duration(milliseconds: 300));
  });

  group('fast scroll', () {
    Widget fast(ScrollController c, int count) => SizedBox(
          width: 390,
          height: 700,
          child: GlassFastScroll(
            controller: c,
            itemCount: count,
            labelAt: (i) => 'Chapter ${i + 1}',
            child: ListView.builder(controller: c, itemExtent: 56, itemCount: count, itemBuilder: (context, i) => Text('row $i')),
          ),
        );

    testWidgets('a list of 200 rows or fewer has no strip', (tester) async {
      final c = ScrollController();
      await tester.pumpWidget(primHost(fast(c, 200)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('over 200 rows a drag shows the bubble with the chapter and ticks per 10 chapters', (tester) async {
      final c = ScrollController();
      await tester.pumpWidget(primHost(fast(c, 400)));
      await tester.pump(const Duration(milliseconds: 50));
      final g = await tester.startGesture(const Offset(370, 10));
      await g.moveBy(const Offset(0, 25));
      await g.moveBy(const Offset(0, 100));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(const ValueKey('glass-fast-scroll-bubble')), findsOneWidget);
      final shown = RegExp(r'Chapter (\d+)').firstMatch(tester.widgetList<Text>(find.textContaining('Chapter ')).first.data!)!.group(1)!;
      expect(int.parse(shown), greaterThan(30));
      expect(GlassHaptics.debugLog.where((e) => e.event == HapticEvent.select).length, greaterThanOrEqualTo(2));
      await g.up();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const ValueKey('glass-fast-scroll-bubble')), findsNothing);
    });

    testWidgets('semantics: a slider with value "Chapter 120" whose actions jump by 10 rows', (tester) async {
      final handle = tester.ensureSemantics();
      final c = ScrollController(initialScrollOffset: 119 * 56);
      await tester.pumpWidget(primHost(fast(c, 400)));
      await tester.pump(const Duration(milliseconds: 50));
      final n = tester.getSemantics(find.bySemanticsLabel('Fast scroll')).getSemanticsData();
      expect(n.value, 'Chapter 120');
      expect(n.flagsCollection.isSlider, isTrue);
      tester.semantics.increase(find.semantics.byLabel('Fast scroll'));
      await tester.pump();
      expect(c.offset, closeTo(129 * 56, 1));
      handle.dispose();
    });
  });
}

