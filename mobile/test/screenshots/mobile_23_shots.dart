// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/features/reader/services/soundscape_files.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart' show CineSheet;
import 'package:manhwamaniacs/skins/cinematic/screens/reader/auto_scroll_chip.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/house_sound.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:dio/dio.dart';

import '../skins/cinematic/novel/novel_test_support.dart' as novel;
import '../skins/cinematic/reader/reader_test_support.dart';
import '../skins/cinematic/settings/settings_rig.dart';
import 'support/series_shots.dart';
import 'support/shot_network.dart';
import 'support/skin_shots.dart';

/// A page of white gutters and three coloured panels (so panel detection finds them).
Future<Uint8List> _panelPage({required int seed, bool grey = false}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  const w = 400.0, h = 600.0;
  c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFFFFFFF));
  final tones = grey
      ? const [Color(0xFF444444), Color(0xFF777777), Color(0xFF999999)]
      : [
          HSLColor.fromAHSL(1, (seed * 47) % 360.0, 0.55, 0.35).toColor(),
          HSLColor.fromAHSL(1, (seed * 47 + 40) % 360.0, 0.5, 0.4).toColor(),
          HSLColor.fromAHSL(1, (seed * 47 + 80) % 360.0, 0.5, 0.3).toColor(),
        ];
  final rects = [const Rect.fromLTWH(30, 30, 340, 150), const Rect.fromLTWH(30, 220, 340, 150), const Rect.fromLTWH(30, 410, 340, 160)];
  for (var i = 0; i < 3; i++) {
    c.drawRect(rects[i], Paint()..color = tones[i]);
  }
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

ReaderChapter _chapter(String id, {int pages = 6, bool panels = true, bool tint = true}) {
  final base = readerChapter(id, pages: pages);
  return ReaderChapter(
    id: base.id,
    seriesId: base.seriesId,
    title: base.title,
    pageCount: base.pageCount,
    sourceId: base.sourceId,
    seriesTitle: base.seriesTitle,
    previousChapterId: base.previousChapterId,
    nextChapterId: base.nextChapterId,
    pages: [
      for (final p in base.pages)
        ReaderPage(
          id: p.id,
          number: p.number,
          imageUrl: p.imageUrl,
          width: 400,
          height: 600,
          tint: tint ? const ['#D9603F', '#3FA0D9', '#7FBF4F', '#B04FBF', '#D9B03F', '#4FBFA0'][(p.number - 1) % 6] : null,
          panels: panels
              ? const [Rect.fromLTWH(0.075, 0.05, 0.85, 0.25), Rect.fromLTWH(0.075, 0.367, 0.85, 0.25), Rect.fromLTWH(0.075, 0.683, 0.85, 0.267)]
              : null,
        ),
    ],
  );
}

class _NoPlayer implements LoopPlayer {
  @override
  Future<void> load(File file) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> setVolume(double v) async {}
  @override
  Future<void> dispose() async {}
}

class _Files extends SoundscapeFiles {
  _Files() : super(Dio());
  @override
  Future<File> soundscapeFile(String id) async => File('${Directory.systemTemp.path}/$id.ogg');
  @override
  Future<bool> isCached(String id) async => false;
}

class _Cfg implements SessionConfigurator {
  @override
  Future<void> configure(config) async {}
  @override
  Future<void> setActive(bool a) async {}
}

class _Cues implements CueEngine {
  @override
  Future<void> init() async {}
  @override
  Future<dynamic> loadAsset(String p) async => 1;
  @override
  Future<dynamic> play(dynamic s, {required double volume}) async => 1;
  @override
  void setRelativePlaySpeed(dynamic h, double r) {}
}

class _Offline implements NetworkConnectivity {
  @override
  Future<bool> isOnWifi() async => false;
  @override
  Future<bool> isOnline() async => false;
}

/// Drags the open sheet's body until [text] is on screen.
Future<void> scrollSheetTo(WidgetTester t, String text) async {
  final target = find.text(text, findRichText: true);
  final body = find.descendant(of: find.byType(CineSheet), matching: find.byType(Scrollable)).first;
  for (var i = 0; i < 14 && target.evaluate().isEmpty; i++) {
    await t.drag(body, const Offset(0, -260));
    await t.pump(const Duration(milliseconds: 200));
  }
  await t.pump(const Duration(milliseconds: 300));
}

/// The mobile-23 proof shots: auto-scroll, house sound, guided view and page-tinted chrome.
void mobile23Shots() {
  final phone = kSkinShotSizes[0];
  final tablet = kSkinShotSizes[1];

  Map<String, Object> seed({String layout = 'strip', String direction = 'ltr', Map<String, Object> device = const {}}) => {
        kReaderPrefsMigratedKey: true,
        kReaderPrefsSeedKey: jsonEncode({
          'seriesDefaults': {'layout': layout, 'direction': direction},
        }),
        ...device,
      };
  Map<String, Object> profile(Map<String, Object> r) => {
        'mm.reader-settings.u1p1': jsonEncode(r),
        'mm.reader-settings.device': jsonEncode(r),
      };

  Future<void> art(WidgetTester tester, {bool grey = false, int chapters = 3}) async {
    final png = await tester.runAsync(() async => {
          for (var i = 0; i < chapters; i++)
            for (var n = 1; n <= 6; n++)
              '/reader/page/${['c1', 'c2', 'c3'][i]}-$n/image': await _panelPage(seed: n + i * 3, grey: grey),
        });
    addShotCovers(png!);
  }

  Future<void> load(WidgetTester tester) async {
    await pumpUntilCoversLoad(tester, rounds: 12);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 900));
  }

  Future<void> showChrome(WidgetTester tester) async {
    if (!chromeVisible(tester)) await tapDouble(tester);
  }

  Future<void> reader(
    WidgetTester tester,
    String name, {
    List<SkinShotSize> sizes = const [],
    Map<String, Object> prefs = const {},
    bool panels = true,
    bool tint = true,
    bool grey = false,
    bool reduced = false,
    double textScale = 1,
    List<Override> extra = const [],
    Future<void> Function(WidgetTester t)? act,
    bool chrome = true,
    ReaderChapter? chapter,
  }) async {
    for (final size in sizes) {
      await art(tester, grey: grey);
      await pumpReader(
        tester,
        wide: size == tablet,
        reduced: reduced,
        textScale: textScale,
        prefsValues: prefs,
        extra: extra,
        chapters: {'c2': chapter ?? _chapter('c2', panels: panels, tint: tint)},
      );
      await load(tester);
      await settleReader(tester, ms: 300);
      if (act != null) await act(tester);
      if (chrome) await showChrome(tester);
      await captureSeriesShot(tester, name, size);
      await disposeReader(tester);
    }
  }

  Future<void> key(WidgetTester t, LogicalKeyboardKey k, {int ms = 700, bool shift = false}) async {
    if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(k);
    if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settleReader(t, ms: ms);
  }

  Future<void> scrollTo(WidgetTester t, int page) async {
    final p = t.state<ScrollableState>(find.byType(Scrollable).first).position;
    p.jumpTo(p.pixels + 585.0 * page);
    await settleReader(t, ms: 900);
  }

  testWidgets('mobile-23 page-tinted chrome', (tester) async {
    await reader(tester, 'tint-colour-page', sizes: [phone, tablet]);
    await reader(tester, 'tint-second-colour', sizes: [phone, tablet], act: (t) async {
      await scrollTo(t, 2);
      await scrollTo(t, 1);
    });
    await reader(tester, 'tint-greyscale-cover', sizes: [phone, tablet], grey: true, tint: false, act: (t) async {
      for (var i = 1; i <= 6; i++) {
        await scrollTo(t, 1);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
        await t.pump(const Duration(milliseconds: 900));
      }
    });
    await reader(tester, 'tint-off', sizes: [phone, tablet], prefs: profile({'pageTint': false}));
  });

  testWidgets('mobile-23 auto-scroll', (tester) async {
    Future<void> start(WidgetTester t) async {
      await key(t, LogicalKeyboardKey.keyP, ms: 500);
      await key(t, LogicalKeyboardKey.period, shift: true, ms: 900);
    }

    await reader(tester, 'autoscroll-chip-running', sizes: [phone, tablet], chrome: false, act: start);
    await reader(tester, 'autoscroll-chip-paused', sizes: [phone], chrome: false, act: (t) async {
      await start(t);
      await t.tap(find.byType(CineAutoScrollChip));
      await t.pump(const Duration(milliseconds: 500));
    });
    await reader(tester, 'autoscroll-chip-paced', sizes: [phone], chrome: false, prefs: profile({'paceByDialogue': true}), extra: [
      ocrChapterTextProvider.overrideWith((ref, id) async => [
            PageText(page: 1, text: List.filled(42, 'word').join(' '), boxes: [OcrTextBox(text: List.filled(42, 'word').join(' '), x: 0.05, y: 0.02, width: 0.9, height: 0.9)]),
          ]),
    ], act: (t) async {
      await start(t);
      await settleReader(t);
    });
    await reader(tester, 'autoscroll-ruler', sizes: [phone], chrome: false, act: (t) async {
      await start(t);
      await t.longPress(find.byType(CineAutoScrollChip));
      await settleReader(t, ms: 900);
    });
    await reader(tester, 'autoscroll-edge-hud', sizes: [phone], chrome: false, act: (t) async {
      await start(t);
      final g = await t.startGesture(const Offset(380, 500));
      await g.moveBy(const Offset(0, -60));
      await t.pump(const Duration(milliseconds: 300));
      await g.moveBy(const Offset(0, -30));
      await t.pump(const Duration(milliseconds: 300));
    });
    await reader(tester, 'text-scale-2-chip', sizes: [phone], chrome: false, textScale: 2, act: start);
  });

  testWidgets('mobile-23 guided view', (tester) async {
    await reader(tester, 'guided-panel', sizes: [phone, tablet], prefs: seed(layout: 'guided'), act: (t) async {
      await key(t, LogicalKeyboardKey.keyJ, ms: 900);
    });
    await reader(tester, 'guided-rtl', sizes: [phone, tablet], prefs: seed(layout: 'guided', direction: 'rtl'), act: (t) async {
      await key(t, LogicalKeyboardKey.keyJ, ms: 900);
    });
    await reader(tester, 'guided-finding-panels', sizes: [phone], panels: false, tint: false, prefs: seed(layout: 'guided'), chrome: false);
    await reader(tester, 'guided-whole-page', sizes: [phone], panels: false, tint: false, prefs: seed(layout: 'guided'), chrome: false, act: (t) async {
      await settleReader(t, ms: 13000);
    });
    await reader(tester, 'guided-auto-advance-hold', sizes: [phone], chrome: false, prefs: {
      ...seed(layout: 'guided'),
      ...profile({'guidedAutoAdvance': {'on': true, 'mode': 'FIXED', 'fixedMs': 3500}}),
    }, act: (t) async {
      await settleReader(t, ms: 1800);
    });
    await reader(tester, 'reduced-motion-guided', sizes: [phone], reduced: true, prefs: seed(layout: 'guided'), act: (t) async {
      await key(t, LogicalKeyboardKey.keyJ, ms: 300);
    });
  });

  testWidgets('mobile-23 setup and house sound', (tester) async {
    await reader(tester, 'setup-ambient-tab', sizes: [phone, tablet], chrome: false, act: (t) async {
      await key(t, LogicalKeyboardKey.comma, ms: 900);
      final tab = find.text('AMBIENT', findRichText: true).last;
      await t.tap(tab);
      await settleReader(t, ms: 700);
    });
    final audio = SkinAudio.forTest(_Cfg(), _Cues());
    HouseSound playing() => HouseSound(files: _Files(), playerFactory: _NoPlayer.new, audio: audio);
    late HouseSound house;
    await reader(tester, 'house-sound-waveform', sizes: [phone], extra: [
      houseSoundProvider.overrideWith((ref) {
        house = playing();
        unawaited(house.setLoop('rain-on-glass'));
        return house;
      }),
    ], act: (t) async {
      await settleReader(t);
    });
    await reader(tester, 'house-sound-offline-row', sizes: [phone], chrome: false, act: (t) async {
      await key(t, LogicalKeyboardKey.comma, ms: 900);
      await t.tap(find.text('AMBIENT', findRichText: true).last);
      await settleReader(t, ms: 700);
      await scrollSheetTo(t, 'Temple bells');
      await settleReader(t, ms: 300);
    }, extra: [networkConnectivityProvider.overrideWithValue(_Offline())]);
    await reader(tester, 'house-sound-hear-loading', sizes: [phone], chrome: false, act: (t) async {
      await key(t, LogicalKeyboardKey.comma, ms: 900);
      await t.tap(find.text('AMBIENT', findRichText: true).last);
      await settleReader(t, ms: 700);
      await scrollSheetTo(t, 'Rain on glass');
      await t.pump(const Duration(milliseconds: 100));
    });
  });

  testWidgets('mobile-23 settings ambient', (tester) async {
    await pumpSettings(tester, path: '/settings/ambient', boundaryKey: kSkinShotKey);
    await tester.pump(const Duration(milliseconds: 500));
    await captureSeriesShot(tester, 'settings-ambient', phone);
  });

  testWidgets('mobile-23 novel', (tester) async {
    Future<void> shot(String name, {Future<void> Function(WidgetTester t, novel.NovelRig rig)? act, List<Override> extra = const [], Map<String, Object> prefs = const {}}) async {
      final rig = await novel.pumpNovel(tester, extra: extra, prefsValues: prefs, boundaryKey: kSkinShotKey);
      await novel.settleNovel(tester, ms: 900);
      if (act != null) await act(tester, rig);
      await captureSeriesShot(tester, name, phone);
      await novel.disposeNovel(tester);
    }

    final pace = jsonEncode({
      'samples': [
        {'chapter_key': '1', 'wpm': 300.0},
        {'chapter_key': '2', 'wpm': 312.0},
        {'chapter_key': '3', 'wpm': 330.0},
      ],
    });
    final paceKeys = {'mm.novel-pace.u1p1': pace, 'mm.novel-pace.device': pace};
    await shot('novel-autoscroll-chip', prefs: paceKeys, act: (t, rig) async {
      await t.sendKeyEvent(LogicalKeyboardKey.keyA);
      await novel.settleNovel(t, ms: 1200);
    });
    final listening = StateProvider<bool>((ref) => false);
    await shot('novel-paused-for-listen', extra: [narrationActiveProvider.overrideWith((ref) => ref.watch(listening))], act: (t, rig) async {
      await t.sendKeyEvent(LogicalKeyboardKey.keyA);
      await novel.settleNovel(t, ms: 600);
      rig.container.read(listening.notifier).state = true;
      await novel.settleNovel(t, ms: 600);
    });
    await shot('type-sheet-ambient', prefs: paceKeys, act: (t, rig) async {
      await t.sendKeyEvent(LogicalKeyboardKey.keyT);
      await novel.settleNovel(t, ms: 900);
      await scrollSheetTo(t, 'Resume after I let go');
      await novel.settleNovel(t, ms: 400);
    });
  });
}
