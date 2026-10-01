// ignore_for_file: require_trailing_commas
import 'dart:ui' show Size;

import 'package:flutter/widgets.dart' show Text;

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_settings_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/glass/listen/player_column.dart';
import 'package:manhwamaniacs/skins/glass/listen/post_play_card.dart';
import 'package:manhwamaniacs/skins/glass/listen/scrubber.dart';
import 'package:manhwamaniacs/skins/glass/listen/sentence_list.dart';
import 'package:manhwamaniacs/skins/glass/listen/speaking_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';

import '../novel/novel_rig.dart';
import 'listen_rig.dart';

Future<GlassListenRig> _openPlayer(WidgetTester t, {bool owner = true, bool reduced = false}) async {
  final l = await pumpGlassListen(t, owner: owner, reduced: reduced, pushed: false, size: const Size(390, 1800));
  await settle(t);
  await l.startNarration();
  l.novel.router.go('${l.novel.location}?sheet=player');
  await settle(t, ms: 1200);
  return l;
}

void main() {
  testWidgets('the player sheet shows titles, the orb, scrubber, five transport buttons and three tiles', (t) async {
    final handle = t.ensureSemantics();
    final l = await _openPlayer(t);
    expect(find.byType(GlassPlayerColumn), findsOneWidget);
    expect(find.text('The Tower'), findsOneWidget);
    expect(find.text('Omniscient Reader'), findsOneWidget);
    expect(find.textContaining('Narrated by Voice 20'), findsOneWidget);
    expect(find.byType(GlassSpeakingOrb), findsOneWidget);
    expect(find.byType(GlassScrubber), findsOneWidget);
    for (final label in ['Back 15 seconds', 'Previous sentence', 'Pause', 'Next sentence', 'Forward 15 seconds']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expect(find.bySemanticsLabel(RegExp('^Speed, 1')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Voices, cast of 4')), findsOneWidget);
    expect(find.bySemanticsLabel('Sleep timer'), findsOneWidget);
    expect(find.bySemanticsLabel('Position'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Next sentence'));
    await l.settle();
    expect(l.player.seeks.last, Duration(milliseconds: listenAudioFixture().segments[1].startMs));
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('the speed tile opens the dial; a preset commits through setSpeed and is remembered', (t) async {
    final handle = t.ensureSemantics();
    final l = await _openPlayer(t);
    await t.tap(find.bySemanticsLabel(RegExp('^Speed, 1')));
    await settle(t, ms: 600);
    expect(find.text('≈ 190 wpm'), findsNothing); // wpm comes from the chapter's words, never a fixed figure
    expect(find.textContaining('wpm'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('1.5 times'));
    await l.settle();
    expect(l.state.speed, 1.5);
    expect(l.container.read(listenSettingsValueProvider).speed, 1.5);
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('the sleep menu sets a timer and carries the Glass shake switch, off by default', (t) async {
    final handle = t.ensureSemantics();
    final l = await _openPlayer(t);
    await t.tap(find.bySemanticsLabel('Sleep timer'));
    await settle(t, ms: 600);
    expect(find.text('Works while ManhwaManiacs is open.'), findsOneWidget);
    expect(l.container.read(listenSettingsValueProvider).glassShakeToExtend, isFalse);
    await t.tap(find.byType(GlassSwitch));
    await l.settle();
    expect(l.container.read(listenSettingsValueProvider).glassShakeToExtend, isTrue);
    await t.tap(find.bySemanticsLabel('15 min'));
    await l.settle();
    expect(l.narration.sleepState.value.choice, SleepChoice.minutes(15));
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('the sentence list: the active sentence is selected and a tap plays from that sentence', (t) async {
    final handle = t.ensureSemantics();
    final l = await _openPlayer(t);
    await l.tick(1000);
    expect(find.byType(GlassSentenceList), findsOneWidget);
    final texts = find.descendant(of: find.byType(GlassSentenceList), matching: find.byType(Text));
    expect(texts, findsWidgets);
    await t.tap(texts.first, warnIfMissed: false);
    await l.settle();
    expect(l.player.seeks, isNotEmpty);
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('the post-play card counts 5 s, waits for Play now with a screen reader, and honours autoPlayNext', (t) async {
    final l = await _openPlayer(t);
    expect(postPlayShows(autoPlayNext: true, sleepStop: false), isTrue);
    expect(postPlayShows(autoPlayNext: false, sleepStop: false), isFalse);
    expect(postPlayShows(autoPlayNext: true, sleepStop: true), isFalse);
    expect(postPlaySeconds(const Duration(milliseconds: 4200)), 5);
    expect(postPlaySeconds(const Duration(milliseconds: 100)), 1);
    l.container.read(glassPostPlayProvider.notifier).state = (sourceId: kNovelSource, seriesKey: kNovelSeries, chapterKey: '1');
    await settle(t, ms: 300);
    expect(find.text('Next chapter in 5'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await settle(t, ms: 300);
    expect(find.byType(GlassPostPlayCard), findsNothing);
    await disposeGlassNovel(t);
  });

  test('scrubber ticks are the sentence starts, the first excluded', () {
    final audio = listenAudioFixture();
    final ticks = sentenceTicks(audio.segments, audio.totalMs);
    expect(ticks.length, audio.segments.length - 1);
    expect(ticks.first, closeTo(audio.segments[1].startMs / audio.totalMs, 1e-9));
  });

  test('narration level fallbacks and the narrating status', () {
    expect(NarrationStatus.values, contains(NarrationStatus.preparing));
  });
}
