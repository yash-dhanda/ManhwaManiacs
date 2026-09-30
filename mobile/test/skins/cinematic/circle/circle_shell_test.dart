// ignore_for_file: directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

import '../../../features/circle/fakes.dart';
import '../library/library_test_support.dart';

Future<LibRig> _pump(WidgetTester t, FakeCircleRepository repo, {String start = '/more'}) =>
    pumpShelf(t, start: start, extra: [circleRepositoryProvider.overrideWithValue(repo)]);

void main() {
  testWidgets('circle and circleMember left the PENDING set and the routes serve the real screens', (t) async {
    expect(cinePendingIds, isEmpty);
    expect(cineIsPending(ScreenId.circle), isFalse);
    final repo = FakeCircleRepository(membersList: [member(riya)], memberPage: const MemberPage(profile: riya));
    final rig = await _pump(t, repo, start: '/circle');
    expect(rig.at, '/circle');
    expect(find.text('NO. 11 — THE CIRCLE'), findsOneWidget);
    rig.router.go('/circle/2');
    await settleShelf(t);
    expect(find.text('NO. 11 · CIRCLE / RIYA'), findsOneWidget);
  });

  testWidgets('the Index row and the thumb-index badge read the new-letter count, hidden at zero', (t) async {
    final repo = FakeCircleRepository(letterList: [letter(1), letter(2), letter(3, state: LetterState.read)]);
    await _pump(t, repo);
    expect(find.text('2 NEW'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Index, 2 new')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await _pump(t, FakeCircleRepository(letterList: [letter(1, state: LetterState.read)]));
    expect(find.textContaining('NEW'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'Index, \d+ new')), findsNothing);
  });
}
