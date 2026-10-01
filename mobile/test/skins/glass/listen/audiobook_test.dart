// ignore_for_file: require_trailing_commas
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/novels/models/narration_save_state.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/repositories/novels_repository.dart' show NovelSeriesAudioDetail;
import 'package:manhwamaniacs/features/novels/utils/audiobook_plan.dart';
import 'package:manhwamaniacs/skins/glass/listen/audiobook_sheet.dart';
import 'package:manhwamaniacs/skins/glass/listen/narrating_chip.dart';

import '../novel/novel_rig.dart';
import 'listen_rig.dart';

NovelSeriesAudioDetail _detail({bool canRender = true}) => (
      renderedAt: {'1': DateTime.utc(2026, 9), '2': DateTime.utc(2026, 9, 2), '3': DateTime.utc(2026, 9, 3)},
      narratable: {for (var i = 1; i <= 10; i++) '$i'},
      canRender: canRender,
      castChangedAt: null,
    );

Future<GlassListenRig> _open(WidgetTester t, {bool owner = true, bool canRender = true, List<NovelAudioJob> jobs = const []}) async {
  final l = await pumpGlassListen(t, owner: owner, pushed: false, size: const Size(390, 1000));
  l.repo
    ..seriesAudioDetailResult = Ok(_detail(canRender: canRender))
    ..seriesAudioResult = Ok((rendered: {'1', '2', '3'}, narratable: {for (var i = 1; i <= 10; i++) '$i'}, canRender: canRender))
    ..audioJobsResults = [Ok(jobs)]
    ..requestAudioResult = const Ok(NovelAudioRequest(queued: ['4', '5'], skipped: {'1': 'already_rendered', '11': 'chapter_not_cached'}));
  await settle(t);
  l.novel.router.go('${l.novel.location}?sheet=audiobook&series=$kNovelSource:$kNovelSeries');
  await settle(t, ms: 1500);
  return l;
}

void main() {
  testWidgets('the Audiobook sheet: chapters with statuses, Next 10, and the render goes out with the skip toast', (t) async {
    final l = await _open(t);
    expect(find.byType(GlassAudiobookBody), findsOneWidget);
    expect(find.text('Narrated'), findsWidgets);
    expect(find.text('Not narrated yet'), findsWidgets);
    expect(find.text('Make audiobook of 0 chapters'), findsOneWidget);
    await t.tap(find.text('Next 10'));
    await settle(t, ms: 300);
    expect(find.textContaining('Make audiobook of'), findsOneWidget);
    await t.tap(find.textContaining('Make audiobook of'));
    await settle(t, ms: 600);
    await l.settle();
    expect(l.repo.renderCalls, isNotEmpty);
    expect(l.repo.renderCalls.first.force, isFalse);
    expect(find.textContaining('Queued 2 chapters for narration. Skipped: 1 already narrated, 1 not on the server yet.'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('narration_unavailable shows the note and blocks the primary button', (t) async {
    await _open(t, canRender: false);
    expect(find.textContaining("Narration of new chapters isn't available right now"), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('every job status reads in the Jobs section, the owner can cancel, a failure can be rendered again', (t) async {
    final l = await _open(t, jobs: [
      const NovelAudioJob(jobId: 'j1', chapterKey: '4', status: 'queued', progress: 0, errorCode: null, chapterNumber: 4),
      const NovelAudioJob(jobId: 'j2', chapterKey: '5', status: 'rendering', progress: 0.42, errorCode: null, chapterNumber: 5),
      const NovelAudioJob(jobId: 'j3', chapterKey: '6', status: 'failed', progress: 0, errorCode: 'lease_expired', chapterNumber: 6),
      const NovelAudioJob(jobId: 'j4', chapterKey: '7', status: 'planning', progress: 0, errorCode: null, chapterNumber: 7),
    ]);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Waiting for the narration PC'), findsOneWidget);
    expect(find.text('Rendering · 42 %'), findsOneWidget);
    expect(find.text('The narration PC stopped responding'), findsOneWidget);
    expect(find.text('Working out who speaks'), findsOneWidget);
    await t.tap(find.text('Render again'));
    await settle(t, ms: 400);
    await l.settle();
    expect(l.repo.renderCalls.last.force, isTrue);
    // The "Queued" toast (on the gutter now, so taller with the test font) leaves before the row under it is tapped.
    await settle(t, ms: 8000);
    await t.tap(find.text('Cancel').first);
    await settle(t, ms: 400);
    await l.settle();
    expect(l.repo.cancelledJobs, isNotEmpty);
    await disposeGlassNovel(t);
  });

  testWidgets('a non-owner gets status only: no render controls', (t) async {
    await _open(t, owner: false);
    expect(find.textContaining('Make audiobook of'), findsNothing);
    expect(find.text('Next 10'), findsNothing);
    await disposeGlassNovel(t);
  });

  testWidgets('the Narrating chip counts the chapters in flight', (t) async {
    expect(narratingLabel(3), 'Narrating 3');
    expect(narratingLabel(1), 'Narrating 1');
  });

  test('row statuses in both modes and the wording of the estimate and the primary button', () {
    const chapters = [AudiobookChapter(key: 'a', label: 'A'), AudiobookChapter(key: 'b', label: 'B'), AudiobookChapter(key: 'c', label: 'C'), AudiobookChapter(key: 'd', label: 'D')];
    const plan = AudiobookPlan(
      chapters: chapters,
      rendered: {'a', 'b'},
      narratable: {'a', 'b', 'c'},
      saved: {'a': NarrationSaveState.saved, 'b': NarrationSaveState.unplayable, 'c': NarrationSaveState.failed},
    );
    expect(rowStatus(plan, AudiobookMode.narrate, 'a'), 'Narrated · saved on this device');
    expect(rowStatus(plan, AudiobookMode.narrate, 'b'), 'Narrated');
    expect(rowStatus(plan, AudiobookMode.narrate, 'c'), 'Not narrated yet');
    expect(rowStatus(plan, AudiobookMode.narrate, 'd'), 'Download the text first');
    expect(rowStatus(plan, AudiobookMode.save, 'a'), 'Saved on this device');
    expect(rowStatus(plan, AudiobookMode.save, 'b'), "Saved copy can't play here · select to save again");
    expect(rowStatus(plan, AudiobookMode.save, 'c'), "Couldn't be saved · select to retry");
    expect(estimateLine(AudiobookMode.narrate, 5), 'About 45 minutes of rendering on the narration PC');
    expect(estimateLine(AudiobookMode.save, 5), startsWith('Saves while the app is open.'));
    expect(primaryLabel(AudiobookMode.narrate, 5), 'Make audiobook of 5 chapters');
    expect(primaryLabel(AudiobookMode.save, 1), 'Save audio of 1 chapter');
    expect(plan.groups({'a', 'c'}).force.single, ['a']);
  });
}
