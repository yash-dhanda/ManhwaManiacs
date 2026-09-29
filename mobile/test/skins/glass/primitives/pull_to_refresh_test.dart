import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';

import 'support.dart';

Iterable<HapticEvent> _events() => GlassHaptics.debugLog.map((e) => e.event);

Widget _view(Future<RefreshResult> Function() onRefresh, {GlassPullToRefreshController? controller, ScrollPhysics? physics}) => SizedBox(
      width: 390,
      height: 700,
      child: CustomScrollView(
        physics: physics ?? kGlassRefreshPhysics,
        slivers: [
          GlassPullToRefresh(onRefresh: onRefresh, controller: controller),
          SliverList.builder(itemCount: 30, itemBuilder: (context, i) => SizedBox(height: 56, child: Text('row $i'))),
        ],
      ),
    );

double _pullHeight(WidgetTester t) => t.getSize(find.byKey(const ValueKey('glass-pull'))).height;

Future<TestGesture> _pullTo(WidgetTester tester, double px) async {
  final g = await tester.startGesture(const Offset(195, 200));
  var y = 0.0;
  for (var i = 0; i < 60 && (!find.byKey(const ValueKey('glass-pull')).evaluate().isNotEmpty || _pullHeight(tester) < px); i++) {
    y += 12;
    await g.moveTo(Offset(195, 200 + y));
    await tester.pump(const Duration(milliseconds: 16));
  }
  return g;
}

void main() {
  setUp(GlassHaptics.debugLog.clear);

  testWidgets('the droplet grows to 16 px over the first 60 px and the neck thins with the pull', (tester) async {
    await tester.pumpWidget(primHost(_view(() async => RefreshResult.unchanged)));
    await tester.pump(const Duration(milliseconds: 50));
    final g = await _pullTo(tester, 30);
    final drop = tester.getSize(find.byKey(const ValueKey('glass-pull-droplet')));
    final pulled = _pullHeight(tester);
    expect(drop.width, closeTo(2 * 16 * (pulled / 60).clamp(0.0, 1.0), 1.5));
    expect(find.byKey(const ValueKey('glass-pull-neck')), findsOneWidget);
    await g.moveBy(const Offset(0, 0));
    await g.up();
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('released before 100 px it retracts and does not refresh', (tester) async {
    var refreshed = 0;
    await tester.pumpWidget(primHost(_view(() async {
      refreshed++;
      return RefreshResult.unchanged;
    })));
    await tester.pump(const Duration(milliseconds: 50));
    final g = await _pullTo(tester, 40);
    await g.up();
    await pumpFor(tester, 900);
    expect(refreshed, 0);
    expect(_events(), isNot(contains(HapticEvent.refreshArm)));
  });

  testWidgets('at 100 px the neck snaps (refresh.arm), the droplet rests at 60 px as a spinner while onRefresh runs, a check on changed', (tester) async {
    final gate = Completer<RefreshResult>();
    await tester.pumpWidget(primHost(_view(() => gate.future)));
    await tester.pump(const Duration(milliseconds: 50));
    final g = await _pullTo(tester, 100);
    await tester.pump(const Duration(milliseconds: 50));
    expect(_events(), contains(HapticEvent.refreshArm));
    await g.up();
    await pumpFor(tester, 800);
    expect(_pullHeight(tester), closeTo(60, 1)); // the rest line (`refresh.fire` maps to no haptic, so it is not in the log)
    expect(find.byType(GlassSpinner), findsOneWidget);
    expect(find.byKey(const ValueKey('glass-pull-neck')), findsNothing); // popped free
    gate.complete(RefreshResult.changed);
    await pumpFor(tester, 200);
    expect(_events(), contains(HapticEvent.refreshDone));
    expect(find.byType(GlassCheckPop), findsOneWidget);
    await pumpFor(tester, 1200);
    expect(find.byKey(const ValueKey('glass-pull')), findsNothing);
  });

  testWidgets('unchanged fades without a check or refresh.done', (tester) async {
    final gate = Completer<RefreshResult>();
    await tester.pumpWidget(primHost(_view(() => gate.future)));
    await tester.pump(const Duration(milliseconds: 50));
    final g = await _pullTo(tester, 100);
    await g.up();
    await pumpFor(tester, 800);
    gate.complete(RefreshResult.unchanged);
    await pumpFor(tester, 300);
    expect(find.byType(GlassCheckPop), findsNothing);
    expect(_events(), isNot(contains(HapticEvent.refreshDone)));
    await pumpFor(tester, 1200);
  });

  testWidgets('the controller refreshes without a pull (the R key and the menu item)', (tester) async {
    final c = GlassPullToRefreshController();
    var refreshed = 0;
    await tester.pumpWidget(primHost(_view(() async {
      refreshed++;
      return RefreshResult.changed;
    }, controller: c)));
    await tester.pump(const Duration(milliseconds: 50));
    unawaited(c.refresh());
    await pumpFor(tester, 700);
    expect(refreshed, 1);
    expect(_events(), contains(HapticEvent.refreshDone));
  });

  testWidgets('a scroll view that does not bounce trips the debug assert', (tester) async {
    await tester.pumpWidget(primHost(_view(() async => RefreshResult.unchanged, physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()))));
    await tester.pump(const Duration(milliseconds: 50));
    // Clamping physics never pulls the control open, so the builder never runs and nothing throws in normal use.
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion: a static spinner at the rest line once triggered', (tester) async {
    final gate = Completer<RefreshResult>();
    await tester.pumpWidget(primHost(_view(() => gate.future), reduced: true));
    bindReduced(tester);
    await tester.pump(const Duration(milliseconds: 50));
    final g = await _pullTo(tester, 100);
    await g.up();
    await pumpFor(tester, 300);
    expect(find.byType(GlassSpinner), findsOneWidget);
    gate.complete(RefreshResult.unchanged);
    await pumpFor(tester, 1500);
  });
}
