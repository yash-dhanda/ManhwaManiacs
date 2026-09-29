// ignore_for_file: require_trailing_commas, directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_swipe_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_hub.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/hub_shell_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/feature_test_support.dart' show featureTheme, sizeView;
import 'library_test_support.dart';

class _Unread extends UnreadCountNotifier {
  @override
  int build() => 3;
}

const _paths = ['/library', '/updates', '/library/collections', '/library/history', '/library/bookmarks'];
const _probe = Key('probe');

/// Five branches of the nested hub shell, each a [LibraryHub] with the same test content.
Future<GoRouter> _hub(WidgetTester t, {Size? size, bool reduced = false, List<Widget> extra = const [], TargetPlatform platform = TargetPlatform.android}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  sizeView(t, size: size);
  final router = GoRouter(
    initialLocation: '/library',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HubShellScope(shell: shell, child: shell),
        branches: [
          for (var i = 0; i < 5; i++)
            StatefulShellBranch(routes: [
              GoRoute(
                path: _paths[i],
                builder: (context, state) => Scaffold(
                  body: LibraryHub(
                    tab: HubTab.values[i],
                    masthead: (kicker: 'No. 0${i + 2}', title: HubTab.values[i].label, deck: 'test deck'),
                    slivers: [
                      SliverToBoxAdapter(child: Container(key: _probe, height: 80, color: const Color(0xFF223344))),
                      ...[for (final w in extra) SliverToBoxAdapter(child: w)],
                      SliverToBoxAdapter(child: Container(height: 2400)),
                    ],
                  ),
                ),
              ),
            ]),
        ],
      ),
    ],
  );
  await t.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs), unreadNotificationCountProvider.overrideWith(_Unread.new)],
    child: MaterialApp.router(
      routerConfig: router,
      theme: featureTheme(platform),
      builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: c!),
    ),
  ));
  await t.pump(const Duration(milliseconds: 100));
  await t.pump(const Duration(milliseconds: 100));
  return router;
}

String _at(GoRouter r) => r.routerDelegate.currentConfiguration.last.matchedLocation;

double _probeX(WidgetTester t) => t.getTopLeft(find.byKey(_probe).first).dx;

Rect _rule(WidgetTester t) => t.getRect(find.byKey(const Key('hub-tab-rule')).first);

Finder _tab(String label) => find.text(label);

/// Presses at [from], crosses the touch slop, then drags [dx] more and holds.
Future<TestGesture> _hold(WidgetTester t, Offset from, double dx) async {
  final g = await t.startGesture(from);
  final sign = dx < 0 ? -1.0 : 1.0;
  await g.moveBy(Offset(sign * 24, 0));
  await t.pump(const Duration(milliseconds: 20));
  await g.moveBy(Offset(dx, 0));
  await t.pump(const Duration(milliseconds: 50));
  return g;
}

void main() {
  group('hub tabs', () {
    testWidgets('five labels with folios, the Updates count raised, no back arrow', (t) async {
      await _hub(t);
      for (final l in ['SHELF', 'UPDATES', 'COLLECTIONS', 'HISTORY', 'BOOKMARKS']) {
        expect(find.text(l), findsWidgets, reason: l);
      }
      for (final f in ['01', '02', '03', '04', '05']) {
        expect(find.text(f), findsOneWidget, reason: f);
      }
      expect(find.text('3'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CineIconButton && w.label == 'Back'), findsNothing);
    });

    testWidgets('the row is pinned under the running head while the page scrolls', (t) async {
      await _hub(t);
      final y = t.getTopLeft(find.text('01')).dy;
      // The tab row starts below the masthead; scrolling far pins it at the top.
      await t.drag(find.byType(CustomScrollView).first, const Offset(0, -900));
      await t.pump();
      final pinned = t.getTopLeft(find.text('01')).dy;
      expect(pinned, lessThan(y));
      await t.drag(find.byType(CustomScrollView).first, const Offset(0, -900));
      await t.pump();
      expect(t.getTopLeft(find.text('01')).dy, pinned);
    });

    testWidgets('a tap on a tab is a route change; the spot rule slides to it over 320 ms', (t) async {
      final router = await _hub(t);
      final before = _rule(t);
      await t.tap(_tab('UPDATES').first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 160));
      expect(_at(router), '/updates');
      final mid = _rule(t);
      expect(mid.left, greaterThan(before.left - 1), reason: 'the rule has left the first tab');
      await t.pump(const Duration(milliseconds: 400));
      final end = _rule(t);
      final label = t.getCenter(_tab('UPDATES').first).dx;
      expect(end.left, lessThan(label));
      expect(end.right, greaterThan(label));
    });
  });

  group('the swipe between tabs', () {
    testWidgets('a 100 px drag on the content commits to the neighbour tab', (t) async {
      final router = await _hub(t);
      await t.dragFrom(const Offset(300, 600), const Offset(-100, 0));
      await t.pump(const Duration(milliseconds: 100));
      expect(_at(router), '/updates');
    });

    testWidgets('a slow 40 px drag springs back and stays on the tab', (t) async {
      final router = await _hub(t);
      final x0 = _probeX(t);
      final g = await _hold(t, const Offset(300, 600), -40);
      expect(_probeX(t), closeTo(x0 - 40, 4), reason: 'the content follows the finger');
      await t.pump(const Duration(milliseconds: 600));
      await g.up();
      await t.pump();
      await t.pump(const Duration(milliseconds: 700));
      expect(_at(router), '/library');
      expect(_probeX(t), closeTo(x0, 1));
    });

    testWidgets('mid swipe the content and the rule follow the finger', (t) async {
      await _hub(t);
      final x0 = _probeX(t);
      final rule0 = _rule(t);
      final g = await _hold(t, const Offset(300, 600), -120);
      expect(_probeX(t), closeTo(x0 - 120, 4));
      expect(_rule(t).left, greaterThan(rule0.left));
      await g.up();
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('the ends rubber-band: no previous tab from SHELF', (t) async {
      final router = await _hub(t);
      final x0 = _probeX(t);
      final g = await _hold(t, const Offset(200, 600), 100);
      expect(_probeX(t), closeTo(x0 + 35, 4));
      await g.up();
      await t.pump(const Duration(seconds: 1));
      expect(_at(router), '/library');
    });

    testWidgets('a drag that starts on a swipe row never moves the hub', (t) async {
      final router = await _hub(t, extra: [
        CineSwipeRow(id: 'row', kind: CineSwipeKind.markRead, onCommit: () {}, child: const SizedBox(key: Key('swipe-row'), height: 72, width: double.infinity)),
      ]);
      final x0 = _probeX(t);
      final row = t.getCenter(find.byKey(const Key('swipe-row')));
      final g = await t.startGesture(row);
      await g.moveBy(const Offset(-160, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(_probeX(t), x0, reason: 'the row won the drag');
      await g.up();
      await t.pump(const Duration(seconds: 1));
      expect(_at(router), '/library');
    });

    testWidgets('a drag on a horizontal pager pages it and never moves the hub', (t) async {
      final router = await _hub(t, extra: [
        SizedBox(height: 200, child: PageView(key: const Key('rail'), children: [for (var i = 0; i < 3; i++) Center(child: Text('page $i'))])),
      ]);
      final x0 = _probeX(t);
      final g = await t.startGesture(t.getCenter(find.byKey(const Key('rail'))));
      await g.moveBy(const Offset(-150, 0));
      await t.pump(const Duration(milliseconds: 50));
      expect(_probeX(t), x0);
      await g.up();
      await t.pump(const Duration(seconds: 1));
      expect(_at(router), '/library');
    });

    testWidgets('reduced motion: the drag still follows the finger; release finishes without a spring', (t) async {
      final router = await _hub(t, reduced: true);
      final x0 = _probeX(t);
      final g = await _hold(t, const Offset(300, 600), -40);
      expect(_probeX(t), closeTo(x0 - 40, 4));
      await t.pump(const Duration(milliseconds: 600));
      await g.up();
      await t.pump();
      expect(_probeX(t), closeTo(x0, 1));
      await t.pump(const Duration(milliseconds: 300));
      expect(_at(router), '/library');
    });

    test('release rules: distance 72 or velocity 600 toward an existing neighbour', () {
      int r(double dx, double v, {bool prev = true, bool next = true}) => hubReleaseTarget(dx, v, hasPrevious: prev, hasNext: next);
      expect(r(-100, 0), 1);
      expect(r(100, 0), -1);
      expect(r(-40, 0), 0);
      expect(r(-10, -700), 1);
      expect(r(10, 700), -1);
      expect(r(-100, 0, next: false), 0);
      expect(r(100, 0, prev: false), 0);
      expect(r(-71, -599), 0);
    });
  });

  group('Android back from the hub', () {
    testWidgets('UPDATES goes back to SHELF, then to Tonight', (t) async {
      final rig = await pumpShelf(t, start: '/updates');
      expect(rig.at, '/updates');
      await t.binding.handlePopRoute();
      await settleShelf(t, by: const Duration(milliseconds: 500));
      expect(rig.at, '/library');
      await t.binding.handlePopRoute();
      await settleShelf(t, by: const Duration(milliseconds: 500));
      expect(rig.at, '/');
    });

    testWidgets('a real /library: 100 px swipe on the shelf goes to UPDATES', (t) async {
      final rig = await pumpShelf(t);
      await t.dragFrom(const Offset(300, 700), const Offset(-100, 0));
      await settleShelf(t, by: const Duration(milliseconds: 500));
      expect(rig.at, '/updates');
    });
  });
}
