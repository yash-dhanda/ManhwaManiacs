import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/back_order.dart';

void main() {
  test('the highest priority wins, the latest on a tie', () {
    final a = Object(), b = Object(), c = Object();
    expect(cineBackWinner([]), isNull);
    expect(cineBackWinner([(token: a, priority: 1), (token: b, priority: 3), (token: c, priority: 2)]), b);
    expect(cineBackWinner([(token: a, priority: 2), (token: b, priority: 2)]), b);
  });

  test('priorities are the spec order', () {
    expect(CineBackPriority.selectMode, 1);
    expect(CineBackPriority.fullPlayer, 2);
    expect(CineBackPriority.settingsSearch, 3);
    expect(CineBackPriority.onboarding, 4);
  });

  testWidgets('only the highest active priority reacts; iOS-style canPop is false while active', (t) async {
    final hits = <String>[];
    var selectActive = true, searchActive = true;
    late StateSetter set;
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: StatefulBuilder(builder: (context, setState) {
          set = setState;
          return CineModalBack(
            priority: CineBackPriority.selectMode,
            active: selectActive,
            onBack: () => hits.add('select'),
            child: CineModalBack(
              priority: CineBackPriority.settingsSearch,
              active: searchActive,
              onBack: () => hits.add('search'),
              child: const Scaffold(body: Text('page')),
            ),
          );
        },),
      ),
    ),);
    await t.pump();
    await t.pump();

    // A route beneath so the pop is real.
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const Text('second'))));
    await t.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    nav.pop();
    await t.pumpAndSettle();

    await t.binding.handlePopRoute();
    await t.pump();
    expect(hits, ['search']);

    set(() => searchActive = false);
    await t.pump();
    await t.pump();
    await t.binding.handlePopRoute();
    await t.pump();
    expect(hits, ['search', 'select']);
  });
}
