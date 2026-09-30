// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/mini_player.dart';

import 'listen_test_support.dart';

Future<ListenRig> started(WidgetTester tester, {int probe = 206, bool owner = true}) async {
  final l = await pumpListen(
    tester,
    owner: owner,
    extra: [narrationProbeProvider.overrideWithValue((url, headers) async => (status: probe, retryAfter: const Duration(seconds: 1)))],
  );
  await settleNovel(tester, ms: 800);
  await tester.tap(find.byKey(const Key('opener-listen')));
  await l.settle();
  return l;
}

void main() {
  testWidgets('the mini player: 56 px, the kicker, the folio and the play button', (tester) async {
    final handle = tester.ensureSemantics();
    final l = await started(tester);
    expect(tester.getSize(find.byKey(const Key('mini-player'))).height, 56);
    expect(find.text('CHAPTER 1 · READ BY VOICE 20'), findsOneWidget);
    expect(find.text('-1:00'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('mini-play'))), const Size(36, 36));
    expect(find.bySemanticsLabel('Pause'), findsWidgets);
    await l.tick(30000);
    expect(find.text('-0:30'), findsOneWidget);
    final spoken = tester.getSemantics(find.text('-0:30')).label;
    expect(spoken, contains('30 seconds left'));
    handle.dispose();
    await leaveListen(l);
  });

  testWidgets('the progress rule: played in the ink, buffered at 35 % muted', (tester) async {
    final l = await started(tester);
    await l.tick(30000);
    l.player.buffer(45000);
    await l.settle();
    final rule = tester.getSize(find.byKey(const Key('mini-played')).first).width;
    final buffered = tester.getSize(find.byKey(const Key('mini-buffered')).first).width;
    expect(buffered / rule, closeTo(1.5, 0.05));
    final box = tester.widget<ColoredBox>(find.byKey(const Key('mini-buffered')));
    expect((box.color.a * 100).round(), 35);
    await leaveListen(l);
  });

  testWidgets('play toggles between play and pause', (tester) async {
    final l = await started(tester);
    await tester.tap(find.byKey(const Key('mini-play')));
    await l.settle();
    expect(l.state.status, NarrationStatus.paused);
    await tester.tap(find.byKey(const Key('mini-play')));
    await l.settle();
    expect(l.state.isPlaying, isTrue);
    await leaveListen(l);
  });

  testWidgets('preparing shows a dial in the play button', (tester) async {
    final l = await started(tester, probe: 503);
    expect(l.state.status, NarrationStatus.preparing);
    expect(find.byType(CineLeaderDialOnInk), findsOneWidget);
    await leaveListen(l);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('failed shows ! in proof and a tap retries', (tester) async {
    final l = await started(tester, probe: 500);
    expect(l.state.status, NarrationStatus.failed);
    expect(find.text('!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mini-play')));
    await l.settle();
    expect(l.state.status, NarrationStatus.failed, reason: 'the probe still fails, so the retry failed again');
    await leaveListen(l);
  });

  testWidgets('a sideways swipe changes chapter', (tester) async {
    final l = await started(tester);
    await tester.fling(find.byKey(const Key('mini-player')), const Offset(-200, 0), 1000);
    await settleNovel(tester, ms: 900);
    await l.settle();
    expect(l.state.key!.chapterKey, '2');
    await leaveListen(l);
  });

  testWidgets('a 450 ms press keeps the player visible; it then outlasts the linger', (tester) async {
    final l = await started(tester);
    await tester.longPress(find.text('CHAPTER 1 · READ BY VOICE 20'));
    await settleNovel(tester, ms: 300);
    expect(l.container.read(listenSettingsValueProvider).keepPlayerVisible, isTrue);
    await settleNovel(tester, ms: 6500);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('the player lingers 5000 ms after it starts with the chrome hidden, then goes', (tester) async {
    final l = await started(tester);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    await settleNovel(tester, ms: 4000);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    await settleNovel(tester, ms: 1500);
    expect(find.byKey(const Key('mini-player')), findsNothing);
    // The chrome brings it back.
    await tester.tapAt(const Offset(195, 400));
    await settleNovel(tester, ms: 500);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    await leaveListen(l);
  });

  testWidgets('the overflow holds Keep player visible, Sleep timer and Voices', (tester) async {
    final l = await started(tester);
    await tester.tap(find.bySemanticsLabel('More').first);
    await settleNovel(tester, ms: 500);
    expect(find.text('Keep player visible'), findsOneWidget);
    expect(find.text('Sleep timer…'), findsOneWidget);
    expect(find.text('Voices…'), findsOneWidget);
    await tester.tap(find.text('Keep player visible'));
    await settleNovel(tester, ms: 400);
    expect(l.container.read(listenSettingsValueProvider).keepPlayerVisible, isTrue);
    await leaveListen(l);
  });
}
