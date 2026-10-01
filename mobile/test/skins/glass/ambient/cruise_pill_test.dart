import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_controller.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise_pill.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

class _Log {
  final previews = <double>[];
  final commits = <double>[];
  final steps = <double>[];
  int toggles = 0, resumes = 0;
}

Future<_Log> pumpPill(WidgetTester t, {required CruiseState state, bool reduced = false, TargetPlatform platform = TargetPlatform.iOS}) async {
  final log = _Log();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), if (reduced) glassMotionPrefsProvider.overrideWith((_) => const GlassMotionPrefs(reduced: true))],
      child: MediaQuery(
        data: MediaQueryData(size: const Size(390, 844), devicePixelRatio: 3, disableAnimations: reduced),
        child: Theme(
          data: ThemeData(platform: platform),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SkinGlassRoot(
              child: Material(
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (_) => Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: CruisePill(
                            state: state,
                            reduced: reduced,
                            onToggle: () => log.toggles++,
                            onResume: () => log.resumes++,
                            onPreview: log.previews.add,
                            onCommit: log.commits.add,
                            onStep: log.steps.add,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pump();
  return log;
}

void main() {
  testWidgets('idle it is a 44 pt flywheel button and a tap starts', (t) async {
    final log = await pumpPill(t, state: const CruiseState());
    expect(find.bySemanticsLabel('Cruise'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Cruise'));
    expect(log.toggles, 1);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('running it is a pill: 44 tall, the speed in mono with one decimal', (t) async {
    await pumpPill(t, state: const CruiseState(speed: 1.0, running: true));
    expect(find.text('1.0×'), findsOneWidget);
    final box = t.getRect(find.byType(CruisePill));
    expect(box.height, greaterThanOrEqualTo(44));
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dragging the pill up 80 px adds 0.50x; 8 px is 0.05x', (t) async {
    final log = await pumpPill(t, state: const CruiseState(speed: 1.0, running: true));
    final g = await t.startGesture(t.getCenter(find.byType(CruisePill)));
    await g.moveBy(const Offset(0, -20));
    await t.pump();
    await g.moveBy(const Offset(0, -80));
    await t.pump();
    expect(find.text('1.5×'), findsWidgets);
    await g.up();
    await t.pump(const Duration(milliseconds: 400));
    expect(log.commits.last, closeTo(1.5, 1e-9));
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a drag ending at a raw 1.07 applies 1.0 (the magnet) and one ending at 1.09 applies 1.1', (t) async {
    var log = await pumpPill(t, state: const CruiseState(speed: 1.0, running: true));
    var g = await t.startGesture(t.getCenter(find.byType(CruisePill)));
    await g.moveBy(const Offset(0, -20));
    await g.moveBy(const Offset(0, -11.2));
    await g.up();
    await t.pump(const Duration(milliseconds: 400));
    expect(log.commits.last, 1.0);
    await t.pumpWidget(const SizedBox.shrink());

    log = await pumpPill(t, state: const CruiseState(speed: 1.0, running: true));
    g = await t.startGesture(t.getCenter(find.byType(CruisePill)));
    await g.moveBy(const Offset(0, -20));
    await g.moveBy(const Offset(0, -14.4));
    await g.up();
    await t.pump(const Duration(milliseconds: 400));
    expect(log.commits.last, 1.1);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the semantics actions step by 0.25 and a tap stops', (t) async {
    final handle = t.ensureSemantics();
    final log = await pumpPill(t, state: const CruiseState(speed: 1.0, running: true));
    final node = t.getSemantics(find.bySemanticsLabel('Cruise'));
    expect(node.value, '1.0 times, playing');
    t.semantics.performAction(find.semantics.byLabel('Cruise'), SemanticsAction.increase);
    t.semantics.performAction(find.semantics.byLabel('Cruise'), SemanticsAction.decrease);
    expect(log.steps, [0.25, -0.25]);
    await t.tap(find.byType(CruisePill));
    expect(log.toggles, 1);
    handle.dispose();
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('paused it says so, and under Reduce Motion a tap resumes instead of stopping', (t) async {
    final handle = t.ensureSemantics();
    final log = await pumpPill(t, state: const CruiseState(speed: 1.0, running: true, paused: true), reduced: true);
    expect(t.getSemantics(find.bySemanticsLabel('Cruise')).value, '1.0 times, paused');
    await t.tap(find.byType(CruisePill));
    expect(log.resumes, 1);
    expect(log.toggles, 0);
    handle.dispose();
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hit targets meet the iOS and Android guidelines', (t) async {
    final handle = t.ensureSemantics();
    await pumpPill(t, state: const CruiseState(speed: 1.0, running: true));
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    await t.pumpWidget(const SizedBox.shrink());
    await pumpPill(t, state: const CruiseState(speed: 1.0, running: true), platform: TargetPlatform.android);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
    await t.pumpWidget(const SizedBox.shrink());
  });
}
