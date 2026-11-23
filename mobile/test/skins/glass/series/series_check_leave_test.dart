import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_detail.dart';

import '../shell/shell_rig.dart';
import 'series_rig.dart';

class _SlowUpdates implements UpdatesRepository {
  final gate = Completer<Result<UpdateRun>>();

  @override
  Future<Result<UpdateRun>> checkFollowed(int followedId) => gate.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('leaving the series page while "Check for new chapters" runs raises nothing, and the result still toasts', (t) async {
    final updates = _SlowUpdates();
    // The action runs through `fire`, which logs what it catches instead of throwing it.
    final logged = <String>[];
    final oldPrint = debugPrint;
    debugPrint = (m, {wrapWidth}) => logged.add(m ?? '');

    final r = await pumpGlassShell(t, start: '/sources/demo/series/k1000', extra: [...seriesOverrides(followed: [followRow()]), updatesRepositoryProvider.overrideWithValue(updates)]);
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.bySemanticsLabel('More').first);
    await _settle(t);
    await t.tap(find.text('Check for new chapters'));
    await _settle(t);

    // The check takes seconds; the reader goes back to Home meanwhile.
    r.router.go('/');
    await _settle(t);
    expect(find.byType(GlassSeriesPage), findsNothing);

    updates.gate.complete(const Ok(UpdateRun(id: 1, trigger: 'manual', status: 'done', seriesChecked: 1, newChaptersFound: 2)));
    await _settle(t);
    debugPrint = oldPrint;
    expect(t.takeException(), isNull);
    expect(logged.where((m) => m.startsWith('series:')), isEmpty);
    expect([for (final e in r.container.read(glassToastProvider)) e.spec.message], contains('Checked: 2 new chapters'));
  });
}
