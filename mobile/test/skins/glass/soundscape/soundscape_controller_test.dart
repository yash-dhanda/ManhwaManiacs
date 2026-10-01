import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/features/reader/providers/soundscape_defaults_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/mixer.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_controller.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

import 'soundscape_fakes.dart';

List<String> toasts(SoundscapeRig r) => [for (final t in r.container.read(glassToastProvider)) t.spec.message];

Future<void> finish(WidgetTester tester, SoundscapeRig r) async {
  r.controller.stopNow();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('choosing Rain starts: loops via loadMem and looping play calls, bank loaded, 3 s fade in, session requested', (tester) async {
    final r = await SoundscapeRig.create();
    await r.controller.start(SoundScene.rain);
    expect(r.view.state, SoundscapeState.starting);
    expect(r.view.scene, SoundScene.rain);
    expect(r.audio.calls, containsAll(['loadMem glass-rain-bed', 'loadMem glass-rain-tone', 'play glass-rain-bed looping=true', 'play glass-rain-tone looping=true']));
    expect(r.audio.calls.where((c) => c.startsWith('loadMem glass-rain-detail')).length, 2);
    // Fade in over 3 s to mix x master: bed 0.8 x 0.251.
    final bed = r.audio.fades.firstWhere((f) => f.over == SoundscapeFades.fadeIn);
    expect(bed.to, closeTo(0.8 * 0.2512, 1e-3));
    expect(r.session.requests, [AudioSessionState.soundscape]);
    await tester.pump(const Duration(seconds: 3));
    await finish(tester, r);
  });

  testWidgets('with every file fetch failing the state is playingBuiltin after 2 s and the badge shows', (tester) async {
    final r = await SoundscapeRig.create();
    await r.controller.start(SoundScene.hearth);
    await tester.pump(const Duration(milliseconds: 500));
    expect(r.view.builtin, isFalse);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(r.view.state, SoundscapeState.playingBuiltin);
    expect(r.view.builtin, isTrue);
    expect(r.view.summary, 'Hearth · built-in');
    await finish(tester, r);
  });

  testWidgets('with a file for every layer the recorded layers cross-fade in over 2 s and the state is playingRecorded', (tester) async {
    final r = await SoundscapeRig.create();
    r.files.have.addAll(['deep-bed', 'deep-detail', 'deep-tone']);
    await r.controller.start(SoundScene.deep);
    await tester.pump(const Duration(seconds: 3));
    expect(r.audio.calls.where((c) => c.startsWith('loadFile')).length, 3);
    // Recorded fades up to the layer value over 2 s; the procedural bed fades to 0 over the same 2 s.
    final up = r.audio.fades.where((f) => f.over == SoundscapeFades.crossfade && f.to > 0);
    final down = r.audio.fades.where((f) => f.over == SoundscapeFades.crossfade && f.to == 0);
    expect(up, isNotEmpty);
    expect(down, isNotEmpty);
    expect(r.view.state, SoundscapeState.playingRecorded);
    expect(r.view.builtin, isFalse);
    expect(r.audio.stopped, isNotEmpty);
    await finish(tester, r);
  });

  testWidgets('narration ducks every voice by 12 dB over 400 ms and unducks; with Lower under narration off it pauses', (tester) async {
    final r = await SoundscapeRig.create();
    await r.controller.start(SoundScene.rain);
    await tester.pump(const Duration(seconds: 3));
    final start = r.audio.fades.length;
    r.narration.setPlaying(true);
    await tester.pump();
    final duck = r.audio.fades.sublist(start).where((f) => f.over == SoundscapeFades.duck).toList();
    expect(duck, isNotEmpty);
    expect(duck.first.to, closeTo(0.8 * 0.2512 * 0.2512, 1e-3));
    expect(r.view.state, SoundscapeState.ducked);
    r.narration.setPlaying(false);
    await tester.pump();
    expect(r.view.state, isNot(SoundscapeState.ducked));
    await r.container.read(soundscapeDefaultsRecordProvider.notifier).setLowerUnderNarration(false);
    r.narration.setPlaying(true);
    await tester.pump(const Duration(seconds: 2));
    expect(r.view.state, SoundscapeState.paused);
    expect(r.audio.paused, isNotEmpty);
    r.narration.setPlaying(false);
    await tester.pump();
    expect(r.audio.paused, isEmpty);
    await tester.pump();
    await finish(tester, r);
  });

  testWidgets('another app playing music starts it muted with the toast, and the action unmutes over 1 s', (tester) async {
    final r = await SoundscapeRig.create(musicOn: true);
    await r.controller.start(SoundScene.wind);
    await tester.pump(const Duration(seconds: 3));
    expect(r.view.state, SoundscapeState.muted);
    expect(toasts(r), contains('Your music is playing. Tap to mix the soundscape in.'));
    final entry = r.container.read(glassToastProvider).firstWhere((t) => t.spec.actionLabel != null);
    entry.spec.onAction!();
    await tester.pump();
    expect(r.audio.fades.last.over, SoundscapeFades.unmute);
    expect(r.view.state, isNot(SoundscapeState.muted));
    await finish(tester, r);
  });

  testWidgets('a start that cannot happen toasts "Couldn\'t start the soundscape" and returns to off', (tester) async {
    final r = await SoundscapeRig.create();
    r.audio.ready = false;
    await r.controller.start(SoundScene.rain);
    expect(r.view.state, SoundscapeState.off);
    expect(toasts(r), ["Couldn't start the soundscape"]);

    final r2 = await SoundscapeRig.create();
    r2.audio.throwOnPlay = true;
    await r2.controller.start(SoundScene.ocean);
    expect(r2.view.state, SoundscapeState.off);
    expect(toasts(r2), ["Couldn't start the soundscape"]);
  });

  testWidgets('leaving the reader fades and pauses; coming back resumes; lifecycle pause fades and resume resumes', (tester) async {
    final r = await SoundscapeRig.create();
    await r.controller.enterReader(const SoundscapeReaderContext(seriesRef: 's:1', rememberedScene: SoundScene.stream));
    await tester.pump(const Duration(seconds: 3));
    expect(r.view.scene, SoundScene.stream);
    r.controller.leaveReader();
    await tester.pump(const Duration(seconds: 2));
    expect(r.view.state, SoundscapeState.paused);
    expect(r.audio.paused, isNotEmpty);
    await r.controller.enterReader(const SoundscapeReaderContext(seriesRef: 's:1', rememberedScene: SoundScene.stream));
    expect(r.audio.paused, isEmpty);
    expect(r.view.state, isNot(SoundscapeState.paused));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    expect(r.view.state, SoundscapeState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(r.view.state, isNot(SoundscapeState.paused));
    await finish(tester, r);
  });

  testWidgets('in the background with narration playing the scene keeps going, ducked', (tester) async {
    final r = await SoundscapeRig.create();
    await r.controller.start(SoundScene.rain);
    r.narration.setPlaying(true);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    expect(r.view.state, SoundscapeState.ducked);
    await finish(tester, r);
  });

  testWidgets('a scene is chosen remembered, then matched (when the default scene is on), then the default; off starts nothing', (tester) async {
    var r = await SoundscapeRig.create();
    expect(await r.controller.enterReader(const SoundscapeReaderContext(seriesRef: 's:1', genres: ['Horror'])), isNull);
    expect(r.view.matchedScene, SoundScene.rain);
    await r.container.read(soundscapeDefaultsRecordProvider.notifier).setScene('wind');
    expect(await r.controller.enterReader(const SoundscapeReaderContext(seriesRef: 's:1', genres: ['Romance'])), SoundScene.hearth);
    await finish(tester, r);

    r = await SoundscapeRig.create();
    await r.container.read(soundscapeDefaultsRecordProvider.notifier).setScene('wind');
    await r.container.read(soundscapeDefaultsRecordProvider.notifier).setMatchStory(false);
    expect(await r.controller.enterReader(const SoundscapeReaderContext(seriesRef: 's:1', genres: ['Romance'])), SoundScene.wind);
    await finish(tester, r);

    r = await SoundscapeRig.create();
    expect(await r.controller.enterReader(const SoundscapeReaderContext(seriesRef: 's:1', genres: ['Romance'], rememberedScene: SoundScene.deep)), SoundScene.deep);
    await finish(tester, r);
  });

  testWidgets('the sleep timer\'s fade stops the scene over 8 s', (tester) async {
    final r = await SoundscapeRig.create();
    await r.controller.start(SoundScene.rain);
    await tester.pump(const Duration(seconds: 3));
    r.narration.sleep.value = const SleepState(fading: true, armed: true);
    await tester.pump();
    expect(r.view.state, SoundscapeState.off);
    expect(r.audio.fades.last.over, const Duration(seconds: 8));
    await tester.pump(const Duration(seconds: 10));
    expect(r.audio.stopped, isNotEmpty);
  });

  testWidgets('the 18+ purge style stop kills every voice at once and the session returns to idle', (tester) async {
    final r = await SoundscapeRig.create();
    await r.controller.start(SoundScene.rain);
    await tester.pump(const Duration(seconds: 1));
    r.controller.stopNow();
    await tester.pump();
    expect(r.view.state, SoundscapeState.off);
    expect(r.audio.stopped.length, greaterThanOrEqualTo(2));
    expect(r.session.requests.last, AudioSessionState.idle);
  });

  testWidgets('disposing the container stops and disposes every voice', (tester) async {
    final r = await SoundscapeRig.create();
    await r.controller.start(SoundScene.rain);
    await tester.pump(const Duration(seconds: 1));
    r.container.dispose();
    await tester.pump();
    expect(r.audio.stopped.length, greaterThanOrEqualTo(2));
    expect(r.audio.disposed, isNotEmpty);
  });

  testWidgets('mix and volume changes go through fadeVolume', (tester) async {
    final r = await SoundscapeRig.create();
    await r.controller.start(SoundScene.rain);
    r.controller.setMix(SoundLayer.bed, 0.4);
    expect(r.audio.fades.last.over, SoundscapeFades.edit);
    expect(r.audio.fades.last.to, closeTo(0.4 * 0.2512, 1e-3));
    r.controller.setVolume(-30);
    expect(r.audio.fades.last.to, closeTo(0.3 * 0.0316, 1e-3));
    await finish(tester, r);
  });
}
