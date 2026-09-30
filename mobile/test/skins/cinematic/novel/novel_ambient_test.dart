import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/auto_scroll_chip.dart';

import 'novel_test_support.dart';

final _listening = StateProvider<bool>((ref) => false);

Map<String, Object> _pace() {
  final samples = jsonEncode({
    'samples': [
      {'chapter_key': '1', 'wpm': 300.0},
      {'chapter_key': '2', 'wpm': 312.0},
      {'chapter_key': '3', 'wpm': 330.0},
    ],
  });
  return {'mm.novel-pace.u1p1': samples, 'mm.novel-pace.device': samples};
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key, {bool shift = false, int ms = 400}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await settleNovel(tester, ms: ms);
}

Finder _t(String s) => find.text(s, findRichText: true);

void main() {
  testWidgets('a starts auto-scroll: the chip reads 1.00×, > steps 0.25×, the long-press ruler shows the measured wpm, a stops it', (tester) async {
    await pumpNovel(tester, prefsValues: _pace());
    await settleNovel(tester, ms: 800);
    expect(find.byType(CineAutoScrollChip), findsNothing);
    await _key(tester, LogicalKeyboardKey.keyA);
    expect(find.byType(CineAutoScrollChip), findsOneWidget);
    expect(_t('1.00×'), findsWidgets);
    await _key(tester, LogicalKeyboardKey.period, shift: true);
    expect(_t('1.25×'), findsWidgets);
    await tester.longPress(find.byType(CineAutoScrollChip));
    await settleNovel(tester, ms: 800);
    expect(_t('≈ 390 WPM'), findsOneWidget, reason: '312 wpm x 1.25');
    await tester.tapAt(const Offset(195, 60));
    await settleNovel(tester, ms: 600);
    await _key(tester, LogicalKeyboardKey.keyA);
    expect(find.byType(CineAutoScrollChip), findsNothing);
    await disposeNovel(tester);
  });

  testWidgets('the paged layout answers with the scroll-layout notice', (tester) async {
    final rig = await pumpNovel(tester);
    await settleNovel(tester, ms: 600);
    await rig.settings({'layout': 'paged'});
    await settleNovel(tester, ms: 800);
    await _key(tester, LogicalKeyboardKey.keyA);
    expect(_t('Auto-scroll needs the scroll layout.'), findsOneWidget);
    expect(find.byType(CineAutoScrollChip), findsNothing);
    await disposeNovel(tester);
  });

  testWidgets('narration pauses a running auto-scroll: PAUSED FOR LISTEN', (tester) async {
    await pumpNovel(tester, extra: [narrationActiveProvider.overrideWith((ref) => ref.watch(_listening))]);
    await settleNovel(tester, ms: 600);
    await _key(tester, LogicalKeyboardKey.keyA);
    expect(find.byType(CineAutoScrollChip), findsOneWidget);
    ProviderScope.containerOf(tester.element(find.byType(CineAutoScrollChip))).read(_listening.notifier).state = true;
    await settleNovel(tester, ms: 500);
    expect(_t('PAUSED FOR LISTEN'), findsOneWidget);
    await disposeNovel(tester);
  });

  testWidgets('the per-book speed persists in the book record and reads back', (tester) async {
    final rig = await pumpNovel(tester);
    await settleNovel(tester, ms: 600);
    await rig.book((c) => c.setAutoScrollSpeedX(1.7));
    expect(rig.container.read(novelPreferencesControllerProvider('$kNovelSource:$kNovelSeries')).autoScrollSpeedX, 1.7);
    await rig.book((c) => c.setAutoScrollSpeedX(null));
    expect(rig.container.read(novelPreferencesControllerProvider('$kNovelSource:$kNovelSeries')).autoScrollSpeedX, isNull);
    expect(rig.container.read(novelSettingsProvider).novelSoundscape, 'off');
    await disposeNovel(tester);
  });
}
