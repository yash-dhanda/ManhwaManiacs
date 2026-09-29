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
}
