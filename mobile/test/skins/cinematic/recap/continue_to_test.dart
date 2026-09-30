import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart' show RecapAvailability;
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/recap/repositories/recap_repository.dart';
import 'package:manhwamaniacs/skins/cinematic/recap/continue_to.dart';

import '../discover/harness.dart';

class _Setting extends RecapSettingNotifier {
  _Setting(this.value);
  final RecapSetting value;
  @override
  RecapSetting build() => value;
}

class _SlowRepo extends RecapRepository {
  _SlowRepo(this.delay, this.available) : super(Dio());
  final Duration delay;
  final bool available;
  int calls = 0;

  @override
  Future<RecapAvailability> availability(RecapKey k, {CancelToken? cancel}) async {
    calls++;
    await Future<void>.delayed(delay);
    return RecapAvailability(available: available);
  }
}

final _now = DateTime(2026, 9, 30, 12);

class _Host extends ConsumerWidget {
  const _Host({required this.recap, required this.lastReadAt, required this.origin});
  final RecapAvailability? recap;
  final DateTime? lastReadAt;
  final RecapEntry origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => unawaited(continueTo(context, ref, sourceId: 's', seriesKey: 'k', chapterKey: 'c9', lastReadAt: lastReadAt, recap: recap, origin: origin)),
            child: const Text('go'),
          ),
        ),
      );
}

Future<void> pumpHost(
  WidgetTester tester, {
  required RecapSetting setting,
  RecapAvailability? recap,
  DateTime? lastReadAt,
  RecapEntry origin = RecapEntry.wipe,
  RecapRepository? repo,
}) =>
    pumpScreen(
      tester,
      _Host(recap: recap, lastReadAt: lastReadAt, origin: origin),
      extra: [
        clockProvider.overrideWithValue(() => _now),
        recapSettingProvider.overrideWith(() => _Setting(setting)),
        if (repo != null) recapRepositoryProvider.overrideWithValue(repo),
      ],
    );

Future<String> tapAndRead(WidgetTester tester) async {
  await tester.tap(find.text('go'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').firstWhere((t) => t.startsWith('at '), orElse: () => 'stayed');
}

void main() {
  final away = _now.subtract(const Duration(days: 9));
  const ok = RecapAvailability(available: true);

  testWidgets('an item that carries recap.available opens the recap at once (AFTER N DAYS AWAY)', (tester) async {
    await pumpHost(tester, setting: const RecapSetting(), recap: ok, lastReadAt: away);
    expect(await tapAndRead(tester), startsWith('at /recap/s/k?to=c9'));
  });

  testWidgets('NEVER, a skipped series, a short gap or an unavailable recap read straight away', (tester) async {
    for (final c in [
      (const RecapSetting(mode: RecapMode.off), ok, away),
      (const RecapSetting(skipSeries: ['s:k']), ok, away),
      (const RecapSetting(), ok, _now.subtract(const Duration(days: 2))),
      (const RecapSetting(), const RecapAvailability(available: false), away),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await pumpHost(tester, setting: c.$1, recap: c.$2, lastReadAt: c.$3);
      expect(await tapAndRead(tester), startsWith('at /reader/s/k/c9'), reason: '$c');
    }
  });

  testWidgets('ALWAYS opens on a different local day', (tester) async {
    await pumpHost(tester, setting: const RecapSetting(mode: RecapMode.always), recap: ok, lastReadAt: _now.subtract(const Duration(days: 1)));
    expect(await tapAndRead(tester), startsWith('at /recap/'));
  });

  testWidgets('no recap field: asks the endpoint when the setting could open one', (tester) async {
    final fast = _SlowRepo(const Duration(milliseconds: 100), true);
    await pumpHost(tester, setting: const RecapSetting(), lastReadAt: away, repo: fast);
    expect(await tapAndRead(tester), startsWith('at /recap/'));
    expect(fast.calls, 1);
  });

  testWidgets('no recap field: gives up after 400 ms', (tester) async {
    final slow = _SlowRepo(const Duration(milliseconds: 900), true);
    await pumpHost(tester, setting: const RecapSetting(), lastReadAt: away, repo: slow);
    expect(await tapAndRead(tester), startsWith('at /reader/s/k/c9'));
  });

  testWidgets('NEVER never asks the endpoint', (tester) async {
    final never = _SlowRepo(const Duration(milliseconds: 10), true);
    await pumpHost(tester, setting: const RecapSetting(mode: RecapMode.off), lastReadAt: away, repo: never);
    expect(await tapAndRead(tester), startsWith('at /reader/'));
    expect(never.calls, 0);
  });

  testWidgets('an unavailable answer in time reads the chapter', (tester) async {
    final r = _SlowRepo(const Duration(milliseconds: 50), false);
    await pumpHost(tester, setting: const RecapSetting(), lastReadAt: away, repo: r);
    expect(await tapAndRead(tester), startsWith('at /reader/'));
  });
}
