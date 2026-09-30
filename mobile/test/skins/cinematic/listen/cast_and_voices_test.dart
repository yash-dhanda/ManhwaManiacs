// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/cast_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/voice_row.dart';

import 'listen_test_support.dart';

Future<ListenRig> openCast(WidgetTester tester, {bool owner = true, Size? size, bool wide = false, List<Override> extra = const [], Set<String> narrated = const {'1', '2', '3'}}) async {
  final l = await pumpListen(tester, owner: owner, size: size, wide: wide, extra: extra, narrated: narrated);
  await settleNovel(tester, ms: 800);
  await tester.tapAt(const Offset(195, 400));
  await settleNovel(tester, ms: 500);
  await tester.tap(find.bySemanticsLabel('Voices').first);
  await settleNovel(tester, ms: 700);
  return l;
}

Finder voiceAction(String voice, String label) => find.descendant(of: find.widgetWithText(VoiceRow, voice), matching: find.text(label));

Future<void> press(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(f);
}

Future<void> openPicker(ListenRig l, String row) async {
  await l.tester.tap(find.text(row));
  await settleNovel(l.tester, ms: 700);
}

void main() {
  test('expressiveness bars are the rank among the loaded voices in fifths', () {
    final all = [for (var i = 1; i <= 10; i++) i / 10];
    expect(expressivenessBars(all, 0.1), 1);
    expect(expressivenessBars(all, 0.2), 1);
    expect(expressivenessBars(all, 0.3), 2);
    expect(expressivenessBars(all, 0.6), 3);
    expect(expressivenessBars(all, 1.0), 5);
    expect(expressivenessBars(const [], 1), 0);
    expect(expressivenessBars(const [0.5], 0.5), 5);
  });

  test('cast rows go by line count with their share', () {
    final rows = castRows(listenAttribution());
    expect(rows.map((r) => r.member.name), ['Alice', 'White Rabbit']);
    expect(rows.map((r) => r.share), [74, 26]);
  });

  testWidgets('the cast sheet: the narrator first, rows by lines with share and lock, from the top bar', (tester) async {
    final l = await openCast(tester);
    expect(find.text('THE CAST'), findsOneWidget);
    expect(find.text('Narrator'), findsOneWidget);
    expect(find.text('Voice 20'), findsOneWidget);
    expect(find.text('Voice 21 · 74 %'), findsOneWidget);
    expect(find.text('Voice 03 · 26 %'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    final narratorY = tester.getTopLeft(find.text('Narrator')).dy;
    expect(tester.getTopLeft(find.text('Alice').last).dy, greaterThan(narratorY));
    expect(find.text('Narrated by Iris: their own lines use the narrator\'s voice.'), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('a reader who is not the owner sees the cast read-only', (tester) async {
    final l = await openCast(tester, owner: false);
    expect(find.text('Voice 21 · 74 %'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    await tester.tap(find.text('Narrator'));
    await settleNovel(tester, ms: 500);
    expect(find.text('A VOICE FOR THE NARRATOR'), findsNothing);
    await leaveListen(l);
  });

  testWidgets('the picker: filters with server counts, one column on phones, Automatic first', (tester) async {
    final l = await openCast(tester, size: const Size(390, 1600));
    await openPicker(l, 'Alice');
    expect(find.text('A VOICE FOR ALICE'), findsOneWidget);
    expect(find.text('FEMALE'), findsWidgets);
    // The counts come from the server: 18 female, 13 male.
    expect(find.textContaining('18'), findsWidgets);
    expect(find.textContaining('13'), findsWidgets);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Assigned by gender and speaking order'), findsOneWidget);
    // The character's gender filter is preselected: only female voices (Voice 14 .. 31).
    expect(find.widgetWithText(VoiceRow, 'Voice 20'), findsOneWidget);
    expect(find.widgetWithText(VoiceRow, 'Voice 05'), findsNothing);
    expect(find.byKey(const Key('voices-male')), findsNothing);
    expect(find.text('Chapters already rendered keep the voice they were made with until they\'re rendered again.'), findsOneWidget);
    await tester.tap(find.text('ALL'));
    await settleNovel(tester, ms: 400);
    expect(find.widgetWithText(VoiceRow, 'Voice 05'), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('the narrator picker offers Book default; a tablet shows MALE and FEMALE side by side', (tester) async {
    final l = await openCast(tester, wide: true);
    await openPicker(l, 'Narrator');
    expect(find.text('A VOICE FOR THE NARRATOR'), findsOneWidget);
    expect(find.text('Book default'), findsOneWidget);
    await tester.tap(find.text('ALL'));
    await settleNovel(tester, ms: 400);
    expect(find.byKey(const Key('voices-male')), findsOneWidget);
    expect(find.byKey(const Key('voices-female')), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('search narrows the list', (tester) async {
    final l = await openCast(tester, size: const Size(390, 1600));
    await openPicker(l, 'Alice');
    await tester.tap(find.text('ALL'));
    await settleNovel(tester, ms: 300);
    await tester.enterText(find.byType(EditableText), 'Voice 27');
    await settleNovel(tester, ms: 500);
    expect(find.widgetWithText(VoiceRow, 'Voice 27'), findsOneWidget);
    expect(find.widgetWithText(VoiceRow, 'Voice 26'), findsNothing);
    await leaveListen(l);
  });

  testWidgets('Cast posts the voice, reads CAST, and a refusal says why', (tester) async {
    final l = await openCast(tester, size: const Size(390, 1600));
    await openPicker(l, 'Alice');
    Finder action(String voice, String label) => voiceAction(voice, label);
    await press(tester, action('Voice 25', 'Cast'));
    await l.settle();
    expect(l.repo.castWrites.last, (name: 'Alice', voiceId: 'voice-25'));
    await settleNovel(tester, ms: 300);
    expect(action('Voice 25', 'CAST'), findsOneWidget);

    l.repo.setCastVoiceResult = const Err(ApiError(statusCode: 403, code: 'forbidden', message: 'Administrator access required.'));
    await press(tester, action('Voice 26', 'Cast'));
    await l.settle();
    await settleNovel(tester, ms: 300);
    expect(find.textContaining("That voice couldn't be saved."), findsOneWidget);
    expect(action('Voice 26', 'CAST'), findsNothing);
    await tester.pump(const Duration(seconds: 7));
    await leaveListen(l);
  });

  testWidgets('Hear fetches the sample through the client, plays it with a pulse band and shows its transcript', (tester) async {
    final l = await openCast(tester, size: const Size(390, 1600));
    await openPicker(l, 'Alice');
    await press(tester, voiceAction('Voice 22', 'Hear'));
    await l.settle();
    await settleNovel(tester, ms: 300);
    expect(l.repo.voiceSampleRequests, ['voice-22']);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.byKey(const Key('voice-pulse-band')), findsOneWidget);
    expect(find.byKey(const Key('voice-progress-rule')), findsOneWidget);
    expect(find.text('Voice 22 here, and this is how I sound.'), findsOneWidget);
    await tester.tap(find.text('Stop'));
    await settleNovel(tester, ms: 400);
    expect(find.byKey(const Key('voice-pulse-band')), findsNothing);
    expect(find.text('Voice 22 here, and this is how I sound.'), findsNothing);
    await leaveListen(l);
  });

  testWidgets('with no voices installed the picker says so', (tester) async {
    final l = await openCast(tester, extra: [emptyVoicesOverride()]);
    await openPicker(l, 'Alice');
    expect(find.text("No voices are installed on the server, so characters can't be cast from here yet."), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('the owner\'s row menu sets a gender and merges an alias', (tester) async {
    final l = await openCast(tester);
    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await settleNovel(tester, ms: 400);
    await tester.tap(find.text('Set gender'));
    await settleNovel(tester, ms: 400);
    await tester.tap(find.text('FEMALE'));
    await l.settle();
    expect(l.repo.genderWrites.last, (name: 'White Rabbit', gender: 'female'));

    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await settleNovel(tester, ms: 400);
    await tester.tap(find.text('Same character as…'));
    await settleNovel(tester, ms: 400);
    await tester.tap(find.text('Alice').last);
    await l.settle();
    expect(l.repo.aliasWrites.last, (alias: 'White Rabbit', canonical: 'Alice'));
    await leaveListen(l);
  });

  testWidgets('after a cast change the owner sees Re-narrate N chapters, which opens the Audiobook sheet with RE-VOICE', (tester) async {
    final detail = seriesDetailWithStale();
    final l = await openCast(tester, extra: [seriesAudioDetailProvider.overrideWith((ref, k) async => detail)]);
    expect(find.text('Re-narrate 2 chapters'), findsOneWidget);
    await tester.tap(find.text('Re-narrate 2 chapters'));
    await settleNovel(tester, ms: 900);
    expect(find.text('AUDIOBOOK'), findsOneWidget);
    expect(find.textContaining('RE-VOICE'), findsWidgets);
    expect(find.text('Narrate 2 chapters'), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('RE-VOICING shows on a recast row while a render created after the change is active', (tester) async {
    final l = await pumpListen(tester, size: const Size(390, 1600));
    l.repo.activeJobsResult = Ok([renderingJob()]);
    await settleNovel(tester, ms: 800);
    await tester.tapAt(const Offset(195, 400));
    await settleNovel(tester, ms: 500);
    await tester.tap(find.bySemanticsLabel('Voices').first);
    await settleNovel(tester, ms: 700);
    expect(find.text('RE-VOICING'), findsNothing);
    await openPicker(l, 'Alice');
    await press(tester, voiceAction('Voice 25', 'Cast'));
    await l.settle();
    await settleNovel(tester, ms: 300);
    await tester.tap(find.text('Done').last);
    await settleNovel(tester, ms: 900);
    expect(find.text('RE-VOICING'), findsOneWidget);
    await leaveListen(l);
  });
}
