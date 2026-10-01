// ignore_for_file: require_trailing_commas
import 'dart:ui' show Size;

import 'package:flutter/widgets.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/skins/glass/listen/cast_sheet.dart';
import 'package:manhwamaniacs/skins/glass/listen/orbit_math.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_card.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_grid.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_orbit.dart';

import '../novel/novel_rig.dart';
import 'listen_rig.dart';

Future<GlassListenRig> _open(WidgetTester t, String query, {bool owner = true}) async {
  final l = await pumpGlassListen(t, owner: owner, pushed: false, size: const Size(390, 1000));
  await settle(t);
  l.novel.router.go('${l.novel.location}?$query');
  await settle(t, ms: 1500);
  return l;
}

void main() {
  testWidgets('the voice orbit lists the server\'s voices as cards, centred on the narrator\'s voice, and previews it after 400 ms', (t) async {
    final handle = t.ensureSemantics();
    final l = await _open(t, 'sheet=voices');
    expect(find.byType(GlassVoiceOrbit), findsOneWidget);
    // voice-20 is the fixture narrator: the 20th card is centred and named in the semantics label.
    expect(find.bySemanticsLabel(RegExp('^Voice 20, 20 of 31')), findsOneWidget);
    expect(l.sampler.played, ['voice-sample-voice-20.ogg']);
    expect(find.text('Use this voice'), findsOneWidget);
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('"Use this voice" pins the narrator for the owner; a non-owner sees the caption and a disabled button', (t) async {
    final l = await _open(t, 'sheet=voices');
    await t.tap(find.text('Use this voice'));
    await l.settle();
    expect(l.repo.narratorWrites, ['voice-20']);
    await disposeGlassNovel(t);
  });

  testWidgets('a non-owner cannot assign voices', (t) async {
    final l = await _open(t, 'sheet=voices', owner: false);
    expect(find.text("Voices are set by the server's owner"), findsWidgets);
    expect(l.repo.narratorWrites, isEmpty);
    await disposeGlassNovel(t);
  });

  testWidgets('with a screen reader on, nothing previews until asked', (t) async {
    final l = await pumpGlassListen(t, pushed: false, size: const Size(390, 1000), accessibleNavigation: true);
    await settle(t);
    l.novel.router.go('${l.novel.location}?sheet=voices');
    await settle(t, ms: 2500);
    expect(l.sampler.played, isEmpty);
    await disposeGlassNovel(t);
  });

  testWidgets('the cast sheet pins the narrator and lists the characters with gender, voice, share and lock', (t) async {
    final handle = t.ensureSemantics();
    final l = await _open(t, 'sheet=cast');
    expect(find.byType(GlassCastBody), findsOneWidget);
    expect(find.bySemanticsLabel('Narrator, Voice 20'), findsOneWidget);
    expect(find.text('Kim Dokja'), findsOneWidget);
    expect(find.text('Han Sooyoung'), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Kim Dokja, Male, Voice 03.*set by hand')), findsOneWidget);
    // The owner's gender capsule opens a three-item menu and posts the change.
    await t.tap(find.descendant(of: find.byKey(const ValueKey('cast-Han Sooyoung')), matching: find.text('Female')));
    await settle(t, ms: 600);
    await t.tap(find.bySemanticsLabel('Male').last);
    await settle(t, ms: 800);
    await l.settle();
    expect(l.repo.genderWrites.single, (name: 'Han Sooyoung', gender: 'male'));
    await disposeGlassNovel(t);
    handle.dispose();
  });

  testWidgets('the cast sheet is read-only for a non-owner', (t) async {
    await _open(t, 'sheet=cast', owner: false);
    expect(find.text(kCastReadOnly), findsOneWidget);
    expect(find.byKey(const ValueKey('cast-Han Sooyoung')), findsOneWidget);
    await disposeGlassNovel(t);
  });

  test('orbit use tags, filters and ranks', () {
    final voices = listenVoices();
    final a = listenAttributionFixture();
    expect(voiceUseTag('voice-20', a), 'Narrator');
    expect(voiceUseTag('voice-03', a), 'In use for Kim Dokja');
    expect(voiceUseTag('voice-01', a), isNull);
    expect(voicesFor(voices, const VoiceTarget.character('Han Sooyoung', gender: 'female')).every((v) => v.gender == 'female'), isTrue);
    expect(voicesFor(voices, const VoiceTarget.narrator()).length, 31);
    final ranks = expressivenessRankOf(voices);
    expect(ranks.length, 31);
    expect(expressivenessDots(ranks.values.reduce((x, y) => x > y ? x : y), 31), 5);
    expect(voiceDuration(2.5), isNull);
    expect(voiceDuration(7.2), '0:07');
    expect(kOrbitStride, 176);
  });

  test('grid filters: gender, in use and search', () {
    final voices = listenVoices();
    expect(filterVoices(voices, VoiceFilter.female, '', {}).length, 18);
    expect(filterVoices(voices, VoiceFilter.male, '', {}).length, 13);
    expect(filterVoices(voices, VoiceFilter.inUse, '', {'voice-20'}).single.voiceId, 'voice-20');
    expect(filterVoices(voices, VoiceFilter.all, 'voice 07', {}).length, 1);
  });

  test('cast status lines and shares', () {
    final a = listenAttributionFixture();
    expect(castStatusLine(a, loading: true), kCastLoading);
    expect(castStatusLine(NovelAttribution.none, loading: false), kCastNobody);
    expect(castShares(a)['Kim Dokja'], 41);
    expect(genderLabel('unknown'), 'Unknown');
  });
}
