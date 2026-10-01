import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart';

import 'stats_rig.dart';

Future<void> _settle(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  testWidgets('closing the gate deletes the statistics and Wrapped snapshots; Statistics then shows its offline state', (t) async {
    final repo = FakeNumbers();
    final rig = await pumpStats(t, repo);
    final prefs = rig.container.read(sharedPrefsProvider);
    // A Wrapped snapshot from an earlier visit.
    await rig.container.read(numbersSnapshotProvider).writeAnnual(2026, {'year': 2026});
    Set<String> saved() => prefs.getKeys().where((k) => k.startsWith('mm.numbers.last.') || k.startsWith('mm.annual.last.')).toSet();
    expect(saved().where((k) => k.startsWith('mm.numbers.last.30.')), isNotEmpty);
    expect(saved().where((k) => k.startsWith('mm.annual.last.2026.')), isNotEmpty);
    repo.failWith = const NetworkError(message: 'offline');
    rig.container.read(glassPurgeProbeProvider)();
    await _settle(t);
    expect(saved(), isEmpty, reason: 'the purge reads SharedPreferences clean');
    expect(find.text("You're offline"), findsOneWidget, reason: 'the payload was dropped, nothing saved to fall back on');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('Wrapped offline: plays the cached year, else "Wrapped needs a connection"; error and loading', (t) async {
    // Cached: open once online, then go offline.
    final repo = FakeNumbers();
    final rig = await pumpStats(t, repo, start: '/library/statistics/annual/2026');
    await _settle(t);
    expect(find.bySemanticsLabel('Wrapped 2026'), findsOneWidget);
    repo.failWith = const NetworkError(message: 'offline');
    rig.container.invalidate(annualProvider(2026));
    await _settle(t);
    expect(find.bySemanticsLabel('Wrapped 2026'), findsOneWidget, reason: 'the cached mm.annual.last.2026 plays');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('Wrapped offline with nothing cached', (t) async {
    await pumpStats(t, FakeNumbers(failWith: const NetworkError(message: 'offline')), start: '/library/statistics/annual/2026');
    await _settle(t);
    expect(find.text('Wrapped needs a connection'), findsOneWidget);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('Wrapped error and loading', (t) async {
    await pumpStats(t, FakeNumbers(failWith: const UnknownError(message: 'boom')), start: '/library/statistics/annual/2026');
    await _settle(t);
    expect(find.text("Couldn't put your year together"), findsOneWidget);
    expect(find.text('Try again'), findsWidgets);
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('Wrapped loading', (t) async {
    final repo = FakeNumbers()..gate = Completer<void>();
    await pumpStats(t, repo, start: '/library/statistics/annual/2026', settle: false);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Putting your year together'), findsWidgets);
    repo.gate!.complete();
    await _settle(t);
    await t.pump(const Duration(minutes: 11));
  });
}
