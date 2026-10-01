// ignore_for_file: require_trailing_commas
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/skins/glass/listen/audiobook_sheet.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paged_view.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/novel_reader_screen.dart';

import '../novel/novel_rig.dart';
import 'listen_rig.dart';

void main() {
  testWidgets('a narrated chapter shows the Listen button, the header capsule and no row until narrating', (t) async {
    final handle = t.ensureSemantics();
    final l = await pumpGlassListen(t);
    await settle(t);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 500);
    expect(find.byType(GlassNovelReader), findsOneWidget);
    expect(find.bySemanticsLabel('Listen'), findsWidgets);
    expect(find.textContaining('Listen · '), findsOneWidget);
    expect(find.byType(GlassListenRowBody), findsNothing);
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('narration started: the listen row sits with the chrome and its play button pauses', (t) async {
    final handle = t.ensureSemantics();
    final l = await pumpGlassListen(t);
    await settle(t);
    await l.startNarration();
    expect(l.state.status, NarrationStatus.playing);
    // The chrome is hidden at rest: the row lingers alone, then joins the bottom capsule with the chrome.
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 500);
    expect(find.byType(GlassListenRowBody), findsOneWidget);
    expect(find.text('Ch 12 · Voice 20'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Pause'));
    await l.settle();
    expect(l.state.isPlaying, isFalse);
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('?listen=1 starts reading aloud from the resume point when the first frame is laid out', (t) async {
    final l = await pumpGlassListen(t, pushed: false, query: '?listen=1');
    await settle(t);
    await l.settle(ms: 300);
    expect(l.state.active, isTrue);
    expect(l.state.key?.chapterKey, '1');
    await disposeGlassNovel(t);
  });

  testWidgets('the owner\'s Listen button on an un-narrated chapter opens the Audiobook sheet in Narrate mode, chapter selected', (t) async {
    final handle = t.ensureSemantics();
    final l = await pumpGlassListen(t, pushed: false, narrated: const {'1'}, chapterKey: '2');
    l.repo.seriesAudioResult = const Ok((rendered: {'1'}, narratable: {'1', '2', '3'}, canRender: true));
    l.repo.seriesAudioDetailResult = Ok((renderedAt: {'1': DateTime.utc(2026, 9)}, narratable: {'1', '2', '3'}, canRender: true, castChangedAt: null));
    await settle(t);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 500);
    await t.tap(find.bySemanticsLabel('Listen'));
    await settle(t, ms: 1500);
    expect(l.novel.location, contains('sheet=audiobook'));
    expect(l.novel.location, contains('mode=narrate'));
    expect(find.byType(GlassAudiobookBody), findsOneWidget);
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('narration on stale timing shows "Highlight paused: the text changed" and the header says it plays without follow-along', (t) async {
    final l = await pumpGlassListen(t, pushed: false, stale: true);
    await settle(t);
    expect(find.text('Audio plays without follow-along for this chapter'), findsOneWidget);
    await l.startNarration(stale: true);
    await settle(t, ms: 600);
    expect(find.text('Highlight paused: the text changed'), findsOneWidget);
    await disposeGlassNovel(t);
  });

  testWidgets('the narration moving to the next chapter swaps the reader\'s text in place', (t) async {
    final l = await pumpGlassListen(t, pushed: false);
    await settle(t);
    await l.startNarration();
    // Provider bodies run in the test's fake zone: pump, never `runAsync`, while they load.
    unawaited(l.container.read(glassNarrationActionsProvider).changeChapter(next: true));
    await settle(t, ms: 2000);
    await l.settle(ms: 500);
    expect(l.state.key?.chapterKey, '2');
    expect(find.textContaining('CHAPTER 2'), findsWidgets);
    await disposeGlassNovel(t);
  });

  testWidgets('stopping from the row and Undo resume at the same position', (t) async {
    final l = await pumpGlassListen(t, pushed: false);
    await settle(t);
    await l.startNarration(startMs: 12000);
    await t.runAsync(() => l.container.read(glassNarrationActionsProvider).stopWithUndo());
    await settle(t, ms: 400);
    expect(l.state.active, isFalse);
    expect(find.text('Stopped reading aloud'), findsOneWidget);
    await t.tap(find.text('Undo'));
    await l.settle(ms: 300);
    expect(l.state.active, isTrue);
    expect(l.narration.position.value, 12000);
    await disposeGlassNovel(t);
  });

  testWidgets('keys: ] steps a sentence, v opens the voices, < slows the narration', (t) async {
    final l = await pumpGlassListen(t, pushed: false);
    await settle(t);
    await l.startNarration();
    await t.sendKeyEvent(LogicalKeyboardKey.bracketRight);
    await l.settle();
    expect(l.player.seeks, isNotEmpty);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.comma);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await l.settle();
    expect(l.state.speed, closeTo(0.95, 1e-9));
    await t.sendKeyEvent(LogicalKeyboardKey.keyV);
    await settle(t, ms: 1500);
    expect(l.novel.location, contains('sheet=cast'));
    await disposeGlassNovel(t);
  });

  testWidgets('paged mode turns the page for the voice; a manual turn decouples and "Back to the voice" returns', (t) async {
    final l = await pumpGlassListen(t, prefs: {'mm.novel-settings.u1p1': jsonEncode({'layout': 'paged'})});
    await settle(t, ms: 1500);
    expect(find.byType(NovelPagedView), findsOneWidget);
    final view = t.state<NovelPagedViewState>(find.byType(NovelPagedView));
    expect(view.page, 0);
    await l.startNarration();
    // Past the first page's text: the last sentence of the fixture.
    await l.tick(55000);
    await settle(t, ms: 1500);
    expect(view.page, greaterThan(0));
    final voicePage = view.page;
    // A manual turn back decouples the page from the voice.
    await t.tapAt(const Offset(10, 500));
    await settle(t, ms: 900);
    expect(view.page, voicePage - 1);
    await t.tapAt(const Offset(195, 500));
    await settle(t, ms: 600);
    expect(find.bySemanticsLabel('Back to the voice'), findsOneWidget);
    await disposeGlassNovel(t);
  });
}
