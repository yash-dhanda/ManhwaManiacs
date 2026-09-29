import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' show AdaptiveGlass;
import 'package:manhwamaniacs/skins/glass/glass/caustic.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import 'support.dart';

double _maxScale(WidgetTester tester) => tester
    .widgetList<Transform>(find.descendant(of: find.byType(GlassPressable), matching: find.byType(Transform)))
    .map((t) => t.transform.getMaxScaleOnAxis())
    .fold<double>(0, (a, b) => a > b ? a : b);

void main() {
  group('reduced motion', () {
    testWidgets('glass press is glow only: no growth', (tester) async {
      await tester.pumpWidget(primHost(GlassButton(label: 'Continue', onPressed: () {}, forceStates: const GlassWidgetStates(pressed: true)), reduced: true));
      await pumpFor(tester, 600);
      expect(_maxScale(tester), closeTo(1, 1e-6));
    });

    testWidgets('content press is a fill2 wash, not a sink', (tester) async {
      await tester.pumpWidget(primHost(GlassChip(label: 'Romance', onPressed: () {}, forceStates: const GlassWidgetStates(pressed: true)), reduced: true));
      await pumpFor(tester, 600);
      expect(_maxScale(tester), closeTo(1, 1e-6));
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_WashPainter'), findsOneWidget);
    });

    testWidgets('skeletons are static', (tester) async {
      await tester.pumpWidget(primHost(const GlassSkeletonGroup(child: GlassSkeleton(width: 100, height: 20)), reduced: true));
      await pumpFor(tester, 400);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('spinners pulse instead of turning, and liquid levels jump', (tester) async {
      var v = 0.2;
      late StateSetter set;
      await tester.pumpWidget(primHost(StatefulBuilder(builder: (context, s) {
        set = s;
        return Column(children: [const GlassSpinner(), SizedBox(width: 100, height: 20, child: LiquidProgress(value: v))]);
      },), reduced: true,),);
      await pumpFor(tester, 100);
      expect(tester.binding.hasScheduledFrame, isTrue);
      set(() => v = 0.8);
      await tester.pump();
      final p = tester.widget<CustomPaint>(find.descendant(of: find.byType(LiquidProgress), matching: find.byType(CustomPaint)).first).painter! as LiquidPainter;
      expect(p.level, 0.8);
    });
  });

  group('solid glass', () {
    testWidgets('the primary is #5B4AD1 with no caustic and no live glass', (tester) async {
      await tester.pumpWidget(primHost(GlassButton(label: 'Continue', variant: GlassButtonVariant.primary, onPressed: () {}), solid: true));
      await pumpFor(tester, 600);
      expect(find.byType(GlassCaustic), findsNothing);
      expect(find.byType(AdaptiveGlass), findsNothing);
      expect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == solidFill(GlassTierId.t2, GlassFinishKind.tinted)), findsOneWidget);
      expect(solidFill(GlassTierId.t2, GlassFinishKind.tinted, pressed: true), const Color(0xFF4A3CB0));
      expect(solidFill(GlassTierId.t2, GlassFinishKind.tinted), const Color(0xFF5B4AD1));
    });

    testWidgets('a secondary takes glassSolid1', (tester) async {
      await tester.pumpWidget(primHost(GlassButton(label: 'Later', onPressed: () {}), solid: true));
      await pumpFor(tester, 600);
      expect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == gt.glassSolid1), findsOneWidget);
    });
  });
}
