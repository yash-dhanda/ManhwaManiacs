import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/cine_grain.dart';

Widget _host({bool reduced = false}) => MaterialApp(
      builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: app!),
      home: const Scaffold(body: CineGrain(child: SizedBox(width: 100, height: 100, key: Key('art')))),
    );

void main() {
  final oldLoader = CineGrain.loader;
  setUp(CineGrain.resetForTest);
  tearDown(() {
    CineGrain.loader = oldLoader;
    CineGrain.resetForTest();
  });

  testWidgets('the program loads and a pumped CineGrain paints without exception', (t) async {
    await t.runAsync(() async {
      await t.pumpWidget(_host());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump(const Duration(milliseconds: 200));
    expect(t.takeException(), isNull);
    expect(find.byKey(const Key('art')), findsOneWidget);
    // The grain layer is mounted only once the program loaded.
    expect(find.descendant(of: find.byType(CineGrain), matching: find.byType(CustomPaint)), findsWidgets);
  });

  testWidgets('a failing loader renders the child alone', (t) async {
    CineGrain.loader = () async => throw StateError('no shader');
    await t.pumpWidget(_host());
    await t.pump();
    await t.pump();
    expect(find.byKey(const Key('art')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('reduced motion holds the offset still', (t) async {
    await t.runAsync(() async {
      await t.pumpWidget(_host(reduced: true));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump(const Duration(milliseconds: 500));
    expect(t.takeException(), isNull);
  });

  testWidgets('the grain steps at 12 fps only while it can be seen: not covered, not backgrounded', (t) async {
    // The program loads on real async, so the timer the load starts is a real one; a lifecycle round trip restarts it on fake time.
    Widget host({bool ticking = true}) => TickerMode(enabled: ticking, child: _host());
    await t.runAsync(() async {
      await t.pumpWidget(host());
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    await t.binding.delayed(const Duration(milliseconds: 500));
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'backgrounded: no steps');
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.binding.delayed(const Duration(milliseconds: 90));
    expect(t.binding.hasScheduledFrame, isTrue, reason: 'resumed: a step landed and asked for a paint');
    await t.pump();

    await t.pumpWidget(host(ticking: false));
    await t.pump();
    await t.binding.delayed(const Duration(milliseconds: 500));
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'covered (tickers off): no steps');
    expect(t.takeException(), isNull);
  });
}
