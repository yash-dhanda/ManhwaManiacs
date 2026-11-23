// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/feature_overflow.dart';

import 'feature_test_support.dart';

class _SlowUpdates implements UpdatesRepository {
  final gate = Completer<Result<UpdateRun>>();

  @override
  Future<Result<UpdateRun>> checkFollowed(int followedId) => gate.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('leaving the series page while "Check for new chapters" runs raises nothing', (tester) async {
    final updates = _SlowUpdates();
    final data = fixtureData('manga-ongoing', followed: followedRow());
    final (:rig, :router) = await pumpFeatureRouter(
      tester,
      rig: FeatureRig(followed: followedRow()),
      extra: [updatesRepositoryProvider.overrideWithValue(updates)],
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => Scaffold(body: TextButton(onPressed: () => c.push('/page'), child: const Text('go'))),
        ),
        GoRoute(
          path: '/page',
          builder: (c, s) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showFeatureOverflow(context, ref, data, onCover: () {}),
                child: const Text('more'),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.tap(find.text('go'));
    await frames(tester, 500);
    await tester.tap(find.text('more'));
    await frames(tester, 500);
    await tester.tap(find.text('Check for new chapters'));
    await frames(tester, 500);

    // The check takes seconds; the reader goes back to the list meanwhile.
    router.pop();
    await frames(tester, 500);
    expect(find.text('more'), findsNothing);

    updates.gate.complete(const Ok(UpdateRun(id: 1, trigger: 'manual', status: 'done', seriesChecked: 1, newChaptersFound: 2)));
    await frames(tester, 200);
    expect(tester.takeException(), isNull);
    expect(rig.rec.patches, isEmpty);
  });
}
