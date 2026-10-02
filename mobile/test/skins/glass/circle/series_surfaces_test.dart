import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/skins/glass/parts/reactions/chapter_reactions.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_sheet.dart' show registerRecommendSheets;
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

import '../../../features/circle/fakes.dart';
import '../series/series_rig.dart';
import '../shell/shell_rig.dart';

const _loc = '/sources/demo/series/k1000';
const _all = CircleShares(activity: true, reactions: true, shelves: true, recommendations: true);

ChapterReactions _c3() => const ChapterReactions(
      chapterKey: 'c3',
      chapterNumber: 3,
      counts: {ReactionKind.hype: 2},
      total: 2,
      sealed: false,
    );

Future<ShellRig> _page(WidgetTester t, FakeCircleRepository repo) async {
  final r = await pumpGlassShell(t, start: _loc, extra: [...seriesOverrides(followed: [followRow()]), circleRepositoryProvider.overrideWithValue(repo)]);
  await _settle(t);
  return r;
}

String _loc2(ShellRig r) => Uri.decodeComponent(r.router.routerDelegate.currentConfiguration.uri.toString());

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

FakeCircleRepository _repo({bool accepting = true}) => FakeCircleRepository(
      membersList: [CircleMember(profileId: 2, name: 'Aarav', shares: accepting ? _all : const CircleShares(activity: true), canReceive: true)],
      sharingValue: const Sharing(activity: true),
      reactionList: [_c3()],
    );

void main() {
  // The shell registers the global sheets when it first mounts; a series route pumped cold has no shell beneath it.
  setUpAll(registerRecommendSheets);

  testWidgets('the series ⋯ offers Recommend to… and Hide from my Circle; Recommend opens the sheet for this series', (t) async {
    final rig = await _page(t, _repo());
    await t.tap(find.bySemanticsLabel('More').first);
    await _settle(t);
    expect(find.text('Recommend to…'), findsOneWidget);
    expect(find.text('Hide from my Circle'), findsOneWidget);
    await t.tap(find.text('Recommend to…'));
    await _settle(t);
    expect(_loc2(rig), contains('sheet=recommend'));
    expect(_loc2(rig), contains('series=demo:k1000'));
  });

  testWidgets('Hide from my Circle sends the whole excluded list with this series and toasts', (t) async {
    final repo = _repo();
    final rig = await _page(t, repo);
    await t.tap(find.bySemanticsLabel('More').first);
    await _settle(t);
    await t.tap(find.text('Hide from my Circle'));
    await _settle(t);
    final sent = repo.patches.last['excluded_series'] as List?;
    expect(sent, isNotNull);
    expect(sent!.single, containsPair('series_key', 'k1000'));
    expect(rig.container.read(glassToastProvider).map((e) => e.spec.message), contains('Hidden from your Circle'));
  });

  testWidgets('nobody taking recommendations: the row says so and is disabled', (t) async {
    await _page(t, _repo(accepting: false));
    await t.tap(find.bySemanticsLabel('More').first);
    await _settle(t);
    expect(find.text('Recommend to… (no one is taking recommendations yet)'), findsOneWidget);
  });

  testWidgets('while the Circle is still loading the row says so and is disabled', (t) async {
    final rig = await _page(t, _SlowMembers());
    await t.tap(find.bySemanticsLabel('More').first);
    await _settle(t);
    expect(find.text('Recommend to… (loading your Circle)'), findsOneWidget);
    await t.tap(find.text('Recommend to… (loading your Circle)'));
    await _settle(t);
    expect(_loc2(rig), isNot(contains('sheet=recommend')));
  });

  testWidgets('shift+R on the series page recommends this series', (t) async {
    final rig = await _page(t, _repo());
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyR);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await _settle(t);
    expect(_loc2(rig), contains('series=demo:k1000'));
  });

  testWidgets('the header carries the latest finished chapter\'s reactions; chapter rows carry the summary', (t) async {
    final rig = await _page(t, _repo());
    expect(find.byType(GlassChapterReactions), findsNothing, reason: 'nothing finished yet');
    rig.container.read(completedThisSessionProvider.notifier).markCompleted('demo', 'k1000', 'c3');
    await _settle(t);
    expect(find.byKey(const ValueKey('series-reactions-c3'), skipOffstage: false), findsOneWidget);
    expect(find.byType(ChapterReactionSummary, skipOffstage: false), findsWidgets);
  });
}

/// A Circle whose members never answer.
class _SlowMembers extends FakeCircleRepository {
  _SlowMembers() : super(sharingValue: const Sharing(activity: true), reactionList: [_c3()]);

  @override
  Future<Result<List<CircleMember>>> members({String? sourceId, String? seriesKey}) => Completer<Result<List<CircleMember>>>().future;
}
