import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/store/reaction_outbox.dart';
import 'package:manhwamaniacs/features/circle/utils/spoiler_guard.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/parts/reactions/chapter_reactions.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/circle/fakes.dart';
import '../../../support/test_overrides.dart' show activeProfileOverride;
import '../primitives/support.dart';

class _NoProgress extends SourceProgressNotifier {
  @override
  Map<String, SourceChapterProgress> build() => const {};
}

ChapterReactions _ch({bool sealed = true, ReactionKind? mine}) => ChapterReactions(
      chapterKey: 'c212',
      chapterNumber: 212,
      counts: {for (final k in ReactionKind.values) k: k == ReactionKind.hype ? 2 : (k == mine ? 1 : 0)},
      total: 2 + (mine == null ? 0 : 1),
      by: [ReactionBy.of(const ProfileRef(profileId: 4, name: 'Kai'), ReactionKind.hype), ReactionBy.of(const ProfileRef(profileId: 3, name: 'Mira'), ReactionKind.hype)],
      mine: mine,
      sealed: sealed,
    );

Future<(FakeCircleRepository, ProviderContainer)> pump(WidgetTester t, {bool sealed = true, ReactionKind? mine, bool sharing = true, AppError? fail, ReactionOutbox? outbox, bool offline = false}) async {
  final repo = FakeCircleRepository(reactionList: [_ch(sealed: sealed, mine: mine)], sharingValue: Sharing(activity: sharing))..failReact = fail;
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(primHost(
    const Padding(padding: EdgeInsets.only(top: 400, left: 16, right: 16), child: GlassChapterReactions(sourceId: 's', seriesKey: 'or', chapterKey: 'c212', chapterNumber: 212, mature: true)),
    align: false,
    overrides: [
      circleRepositoryProvider.overrideWithValue(repo),
      activeProfileOverride(),
      sourceProgressProvider.overrideWith(_NoProgress.new),
      reactionOutboxProvider.overrideWithValue(outbox),
      glassOfflineProvider.overrideWithValue(offline),
    ],
  ),);
  await pumpFor(t, 300);
  return (repo, ProviderScope.containerOf(t.element(find.byType(GlassChapterReactions))));
}

void main() {
  testWidgets('a touch tap sends Love; tapping your own removes it', (t) async {
    final (repo, _) = await pump(t);
    await t.tap(find.bySemanticsLabel('React to Ch 212'));
    await pumpFor(t, 400);
    expect(repo.log, contains('react c212 loved'));
    await t.tap(find.bySemanticsLabel('React to Ch 212'));
    await pumpFor(t, 400);
    expect(repo.log, contains('unreact c212'));
  });

  testWidgets('a mouse click opens the picker; clicking a bubble sends it', (t) async {
    final (repo, _) = await pump(t);
    await t.tap(find.bySemanticsLabel('React to Ch 212'), kind: PointerDeviceKind.mouse);
    await pumpFor(t, 500);
    expect(find.byKey(const ValueKey('glass-reaction-bubbles')), findsOneWidget);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.reactionBloom));
    await t.tap(find.bySemanticsLabel('Hype').last, kind: PointerDeviceKind.mouse);
    await pumpFor(t, 900);
    expect(repo.log, contains('react c212 hype'));
  });

  testWidgets('a guarded chapter shows orbs and "reacted to Ch 212", then unseals when the chapter completes', (t) async {
    final (_, c) = await pump(t);
    expect(find.text('reacted to Ch 212'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Hype, 2')), findsNothing);
    c.read(completedThisSessionProvider.notifier).markCompleted('s', 'or', 'c212');
    await pumpFor(t, 600);
    expect(find.text('reacted to Ch 212'), findsNothing);
  });

  testWidgets('sharing off keeps it private with the helper; your own reaction can be removed by a custom action', (t) async {
    final h = t.ensureSemantics();
    await pump(t, sharing: false, mine: ReactionKind.loved, sealed: false);
    expect(find.text('Only you see this. Turn on Circle sharing to show others.'), findsOneWidget);
    final ids = t.getSemantics(find.bySemanticsLabel('React to Ch 212')).getSemanticsData().customSemanticsActionIds!;
    expect(ids.map((id) => CustomSemanticsAction.getAction(id)!.label), contains('Remove my reaction'));
    h.dispose();
  });

  testWidgets('a refused send falls back with the toast', (t) async {
    final (_, c) = await pump(t, fail: const ApiError(statusCode: 422, code: 'bad', message: 'x'));
    await t.tap(find.bySemanticsLabel('React to Ch 212'));
    await pumpFor(t, 600);
    expect(c.read(glassToastProvider).map((e) => e.spec.message), contains("Couldn't send your reaction"));
  });

  testWidgets('offline: queued in the outbox with the mature flag and drawn at once', (t) async {
    SharedPreferences.setMockInitialValues({});
    final box = ReactionOutbox(await SharedPreferences.getInstance(), 'u1p1');
    final (_, c) = await pump(t, fail: const NetworkError(message: 'down'), outbox: box, offline: true);
    await t.tap(find.bySemanticsLabel('React to Ch 212'));
    await pumpFor(t, 600);
    expect(box.entries().single.mature, isTrue);
    expect(c.read(chapterReactionsProvider((sourceId: 's', seriesKey: 'or'))).value!.single.mine, ReactionKind.loved);
    expect(c.read(glassToastProvider), isEmpty);
  });
}
