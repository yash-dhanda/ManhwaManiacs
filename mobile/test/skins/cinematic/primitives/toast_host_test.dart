import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

late ProviderContainer _box;

Future<void> _pump(WidgetTester t, {bool a11y = false, double banner = 0}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  _box = ProviderContainer();
  addTearDown(_box.dispose);
  await t.pumpWidget(UncontrolledProviderScope(
    container: _box,
    child: MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      builder: (c, a) => MediaQuery(data: MediaQuery.of(c).copyWith(accessibleNavigation: a11y), child: a!),
      home: Scaffold(body: CineToastHost(bannerHeight: banner, child: const SizedBox.expand())),
    ),
  ),);
}

CineToastsNotifier get _n => _box.read(cineToastsProvider.notifier);
int get _queue => _box.read(cineToastsProvider).length;

void main() {
  testWidgets('holds per kind: 3600, 6000, 8000, 10000', (t) async {
    await _pump(t);
    final n = _n;
    n.info('a');
    await t.pump();
    await t.pump(const Duration(milliseconds: 3550));
    expect(_queue, 1);
    await t.pump(const Duration(milliseconds: 100));
    expect(_queue, 0);
    await t.pumpAndSettle();

    n.error('e');
    await t.pump();
    await t.pump(const Duration(milliseconds: 5900));
    expect(_queue, 1);
    await t.pump(const Duration(milliseconds: 200));
    expect(_queue, 0);
    await t.pumpAndSettle();

    n.action('x', label: 'View', onAction: () {});
    await t.pump();
    await t.pump(const Duration(milliseconds: 7900));
    expect(_queue, 1);
    await t.pump(const Duration(milliseconds: 200));
    expect(_queue, 0);
    await t.pumpAndSettle();

    n.undo('u', onUndo: () {}, hold: const Duration(milliseconds: 10000));
    await t.pump();
    await t.pump(const Duration(milliseconds: 9900));
    expect(_queue, 1);
    await t.pump(const Duration(milliseconds: 200));
    expect(_queue, 0);
    await t.pumpAndSettle();
  });

  testWidgets('at most two visible; the older one moves up', (t) async {
    await _pump(t);
    _n.info('first');
    await t.pumpAndSettle(const Duration(milliseconds: 50));
    final y1 = t.getTopLeft(find.text('first')).dy;
    _n.info('second');
    await t.pumpAndSettle(const Duration(milliseconds: 50));
    expect(t.getTopLeft(find.text('first')).dy, lessThan(y1));
    _n.info('third');
    await t.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('third'), findsOneWidget);
  });

  testWidgets('a focused toast survives past its hold', (t) async {
    await _pump(t);
    _n.action('Saved', label: 'View', onAction: () {});
    await t.pump(const Duration(milliseconds: 400));
    CineToastHost.maybeOf(t.element(find.byType(SizedBox).first))?.focusNewestAction();
    await t.pump();
    await t.pump(const Duration(seconds: 20));
    expect(find.text('Saved'), findsOneWidget);
    expect(_queue, 1);
  });

  testWidgets('with accessibleNavigation an action toast never times out', (t) async {
    await _pump(t, a11y: true);
    _n.action('Saved', label: 'Retry', onAction: () {});
    await t.pump(const Duration(seconds: 30));
    expect(_queue, 1);
    _n.info('plain');
    await t.pump();
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(find.text('plain'), findsNothing);
  });

  testWidgets('swipe down dismisses', (t) async {
    await _pump(t);
    _n.info('bye');
    await t.pumpAndSettle(const Duration(milliseconds: 50));
    await t.drag(find.text('bye'), const Offset(0, 60));
    await t.pumpAndSettle();
    expect(_queue, 0);
  });

  testWidgets('a banner leaves one toast', (t) async {
    await _pump(t, banner: 40);
    _n.info('one');
    await t.pump(const Duration(milliseconds: 300));
    _n.info('two');
    await t.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.text('one'), findsNothing);
    expect(find.text('two'), findsOneWidget);
  });
}
