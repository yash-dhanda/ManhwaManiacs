@Tags(['screenshots'])
library;

// ignore_for_file: require_trailing_commas

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/glass_novel_prefs_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_wakelock.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/glass_paragraph.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/novel_reader_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paged_view.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/selection_menu.dart';

import '../../skins/cinematic/novel/novel_test_support.dart' as cine;
import '../glass_shell_shots_support.dart';
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The mobile/36 proof captures (glass 8.15): the Glass novel reader through the real Glass router at `/novels/demo/k/1`, on the
/// `mobile/14` fixtures. Written only when `MM_PROOF_DIR` is set; otherwise rasterised and discarded.

const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
const _tablet = SkinShotSize('tablet', Size(834, 1194), 2.0, EdgeInsets.only(top: 24, bottom: 20));

class _Wake implements ReaderWakelock {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

class _InApp extends GlassInAppPrefsController {
  _InApp(this.prefs);
  final GlassInAppPrefs prefs;
  @override
  GlassInAppPrefs build() => prefs;
}

NovelAttribution _attr(String file) => NovelAttribution.fromJson(jsonDecode(File('test/fixtures/novel/$file').readAsStringSync()) as Map<String, dynamic>);

List<Override> _novel({
  NovelAttribution? attribution,
  bool offline = false,
  bool cacheStale = false,
  List<String>? paragraphs,
  Map<String, Object> failing = const {},
  Map<String, Future<void>> holds = const {},
  bool online = true,
}) =>
    [
      readerWakelockProvider.overrideWithValue(_Wake()),
      sourcesListProvider.overrideWith((ref) async => const [SourceSummary(id: 'demo', name: 'Demo Source', description: '', browsable: true, supportsImport: false)]),
      sourceSeriesDetailProvider.overrideWith((ref, k) async => SourceSeriesDetailData(series: cine.loadSeriesFixture('manga-ongoing').series, chapters: cine.novelChapters())),
      resolvedNovelChapterProvider.overrideWith((ref, key) async {
        final hold = holds[key.chapterKey];
        if (hold != null) await hold;
        final fail = failing[key.chapterKey];
        if (fail != null) throw fail;
        return cine.novelChapterFor(key.chapterKey, offline: offline, cacheStale: cacheStale, paragraphs: paragraphs);
      }),
      novelChapterNeighboursProvider.overrideWith((ref, key) async {
        final n = int.tryParse(key.chapterKey) ?? 1;
        return (previousChapterKey: n > 1 ? '${n - 1}' : null, nextChapterKey: n < 12 ? '${n + 1}' : null);
      }),
      novelAttributionProvider.overrideWith((ref, key) async => attribution ?? NovelAttribution.none),
      playableNovelAudioProvider.overrideWith((ref, key) async => null),
      seriesAudioProvider.overrideWith((ref, k) async => (rendered: <String>{'2', '3'}, narratable: <String>{'2', '3'}, canRender: null)),
      seriesChapterDownloadStatusProvider.overrideWith((ref, k) async => const {}),
      deviceOnlineProvider.overrideWith((ref) => Stream.value(online)),
    ];

Future<ShotSession> _open(WidgetTester t, SkinShotSize size, {String chapter = '1', List<Override> extra = const [], List<Override> novel = const [], Map<String, dynamic>? settings, bool settle = true}) async {
  final s = await openShell(t, size, start: '/novels/demo/k/$chapter', extra: [...(novel.isEmpty ? _novel() : novel), ...extra], settle: false);
  if (settings != null) await s.container.read(novelSettingsProvider.notifier).put(settings);
  if (settle) {
    for (var i = 0; i < 6; i++) {
      await s.settle(300);
    }
  }
  return s;
}

Future<void> _frames(WidgetTester t, int ms) async {
  for (var e = 0; e < ms; e += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// Leaves the reader first (its open-chapter claim is released while the providers live), then tears the app down.
Future<void> _end(WidgetTester t, [ShotSession? s]) async {
  if (s != null) {
    s.router.go('/library');
    await _frames(t, 1500);
  }
  await t.pumpWidget(const SizedBox.shrink());
  await t.pump(const Duration(seconds: 11));
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey k, {bool shift = false}) async {
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(k);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _chrome(WidgetTester t, SkinShotSize size) async {
  await t.tapAt(Offset(size.logical.width / 2, size.logical.height * 0.55));
  await _frames(t, 600);
}

/// A capture whose file name ends in `-desktop-frame` is written as `-tablet-wide` (the harness's size name).
String _name(String n) => n.endsWith('-desktop-frame') ? n.substring(0, n.length - '-desktop-frame'.length) : n;

Future<void> _snap(ShotSession s, String name, SkinShotSize size) => s.snap(_name(name), size);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('papers', (t) async {
    for (final p in const ['void', 'ink', 'night-paper', 'dusk', 'moss', 'rosewood', 'glass']) {
      final s = await _open(t, _phone, settings: {'paper': p});
      if (p == 'void' || p == 'glass') await _chrome(t, _phone);
      await _snap(s, 'paper-$p', _phone);
      await _end(t, s);
    }
    var s = await _open(t, _tablet, settings: {'paper': 'void'});
    await _chrome(t, _tablet);
    await _snap(s, 'paper-void', _tablet);
    await _end(t, s);
    s = await _open(t, kSkinShotTabletWide, settings: {'paper': 'glass'});
    await _chrome(t, kSkinShotTabletWide);
    await _snap(s, 'paper-glass-desktop-frame', kSkinShotTabletWide);
    await _end(t, s);
  });

  testWidgets('body', (t) async {
    var s = await _open(t, _phone);
    // Auto next off for this session, so the held pull below is not overtaken by the 900 ms timer.
    await s.container.read(readerSettingsProvider.notifier).put({'autoNextChapter': false});
    await _snap(s, 'header-dropcap', _phone);
    final scene = cine.fixtureChapter().paragraphs.indexWhere((p) => p.trim().length <= 12);
    t.state<GlassNovelReaderState>(find.byType(GlassNovelReader)).jumpToParagraph(scene < 0 ? 5 : scene - 3);
    await _frames(t, 300);
    await _snap(s, 'scene-break', _phone);
    await _key(t, LogicalKeyboardKey.end);
    await _frames(t, 600);
    await _snap(s, 'end-matter', _phone);
    // Pull to the 72 px lock and hold.
    final g = await t.startGesture(const Offset(195, 600));
    for (var i = 0; i < 30; i++) {
      await g.moveBy(const Offset(0, -30));
      await t.pump(const Duration(milliseconds: 16));
    }
    await _frames(t, 200);
    await _snap(s, 'next-locked', _phone);
    await g.cancel();
    await _end(t, s);

    s = await _open(t, _phone, novel: _novel(attribution: _attr('attribution.json')));
    await _snap(s, 'speaker-bands', _phone);
    final piece = find.byWidgetPredicate((w) => w is GlassTextPiece && w.runs.isNotEmpty && w.runs.first.start >= w.start && w.runs.first.start < w.endOffset).first;
    final para = t.widget<GlassTextPiece>(piece);
    final ro = t.renderObjectList<RenderParagraph>(find.descendant(of: piece, matching: find.byType(RichText))).first;
    final off = para.runs.first.start - para.start;
    final box = ro.getBoxesForSelection(TextSelection(baseOffset: off + 2, extentOffset: off + 5)).first;
    await t.tapAt(ro.localToGlobal(box.toRect().center));
    await _frames(t, 500);
    await _snap(s, 'run-chip', _phone);
    await _end(t, s);

    s = await _open(t, _phone, novel: _novel(attribution: _attr('attribution-eleven.json')));
    t.state<GlassNovelReaderState>(find.byType(GlassNovelReader)).jumpToParagraph(9);
    await _frames(t, 300);
    await _snap(s, 'speaker-eleventh-dashed', _phone);
    await _end(t, s);

    for (final f in const ['literata', 'sans', 'atkinson']) {
      s = await _open(t, _phone);
      await s.container.read(glassNovelPrefsProvider((sourceId: 'demo', seriesKey: 'k'))).setBook({'glassFace': f});
      await _frames(t, 400);
      await _snap(s, 'faces-$f', _phone);
      await _end(t, s);
    }

    s = await _open(t, _phone, settings: {'lineGuide': true});
    await _snap(s, 'line-guide', _phone);
    await _end(t, s);
  });

  testWidgets('paged and turns', (t) async {
    for (final size in [_phone, _tablet]) {
      final s = await _open(t, size, settings: {'layout': 'paged'});
      await _frames(t, 600);
      await _chrome(t, size);
      await _snap(s, 'paged', size);
      await _end(t, s);
    }
    var s = await _open(t, _phone, settings: {'layout': 'paged'});
    await _frames(t, 600);
    var g = await t.startGesture(const Offset(300, 500));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(-30, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await _snap(s, 'slide-midturn', _phone);
    await g.up();
    await _end(t, s);

    s = await _open(t, _phone, settings: {'layout': 'paged', 'glassPageTurn': 'lift'});
    await _frames(t, 600);
    g = await t.startGesture(const Offset(300, 500));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(-30, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await _snap(s, 'lift-midturn', _phone);
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(-25, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await _snap(s, 'lift-backface', _phone);
    await g.cancel();
    await _end(t, s);

    s = await _open(t, _phone, settings: {'layout': 'paged', 'tapZones': 'oneHand'});
    await _frames(t, 600);
    await t.tapAt(const Offset(195, 40));
    await _frames(t, 600);
    await _snap(s, 'taps-one-hand', _phone);
    await _end(t, s);

    s = await _open(t, _phone);
    final a = await t.startGesture(const Offset(150, 420), pointer: 7);
    final b = await t.startGesture(const Offset(240, 420), pointer: 8);
    await a.moveTo(const Offset(110, 420));
    await b.moveTo(const Offset(280, 420));
    await _frames(t, 300);
    await _snap(s, 'pinch-capsule', _phone);
    await a.cancel();
    await b.cancel();
    await _end(t, s);
  });

  testWidgets('sheets, panels, popovers', (t) async {
    var s = await _open(t, _phone);
    await _key(t, LogicalKeyboardKey.comma);
    await _frames(t, 900);
    await _snap(s, 'type-sheet', _phone);
    final orb = find.byKey(const ValueKey('paper-orb-moss'));
    if (orb.evaluate().isEmpty) await t.drag(find.text('Measure').first, const Offset(0, -500));
    await _frames(t, 400);
    if (orb.evaluate().isNotEmpty) {
      await t.tap(orb.first, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 180));
      await _snap(s, 'paper-ripple-mid', _phone);
    }
    await _end(t, s);

    s = await _open(t, _phone);
    await _key(t, LogicalKeyboardKey.keyT);
    await _frames(t, 900);
    await _snap(s, 'contents', _phone);
    await t.enterText(find.byType(EditableText).first, '480');
    await _frames(t, 300);
    await _snap(s, 'contents-no-match', _phone);
    await _end(t, s);

    s = await _open(t, _phone);
    await _key(t, LogicalKeyboardKey.keyG);
    await _frames(t, 700);
    await _snap(s, 'go-to-percent', _phone);
    await _end(t, s);

    s = await _open(t, kSkinShotTabletWide);
    await _key(t, LogicalKeyboardKey.comma);
    await _frames(t, 700);
    await _snap(s, 'type-panel-desktop-frame', kSkinShotTabletWide);
    await _end(t, s);

    s = await _open(t, kSkinShotTabletWide);
    await _key(t, LogicalKeyboardKey.keyT);
    await _frames(t, 700);
    await _snap(s, 'contents-panel-desktop-frame', kSkinShotTabletWide);
    await _key(t, LogicalKeyboardKey.comma);
    await _frames(t, 700);
    await _snap(s, 'panels-both-desktop-frame', kSkinShotTabletWide);
    await _end(t, s);

    s = await _open(t, kSkinShotDesktop);
    await _key(t, LogicalKeyboardKey.keyT);
    await _frames(t, 500);
    await _key(t, LogicalKeyboardKey.comma);
    await _frames(t, 700);
    await _snap(s, 'panels-both', kSkinShotDesktop);
    await _end(t, s);

    s = await _open(t, _phone);
    t.state<SelectionAreaState>(find.byType(SelectionArea)).selectableRegion.selectAll();
    await _frames(t, 200);
    await _key(t, LogicalKeyboardKey.f10, shift: true);
    await _frames(t, 600);
    await _snap(s, 'selection-menu', _phone);
    if (find.text('React to this chapter').evaluate().isNotEmpty) {
      await t.tap(find.text('React to this chapter'));
      await _frames(t, 600);
    }
    await _snap(s, 'reaction-picker', _phone);
    expect(find.byType(GlassSelectionMenu), findsOneWidget);
    await _end(t, s);
  });

  testWidgets('states', (t) async {
    final never = Completer<void>();
    var s = await _open(t, _phone, novel: _novel(holds: {'1': never.future}));
    await _snap(s, 'state-loading', _phone);
    await _end(t, s);

    s = await _open(t, _phone, novel: _novel(failing: {'1': const NetworkError(message: 'offline')}, online: false));
    await _snap(s, 'state-offline', _phone);
    await _end(t, s);

    s = await _open(t, _phone, novel: _novel(failing: {'1': Exception('boom')}));
    await _snap(s, 'state-error', _phone);
    await _end(t, s);

    s = await _open(t, _phone, novel: _novel(paragraphs: const []));
    await _snap(s, 'state-empty', _phone);
    await _end(t, s);

    s = await _open(t, _phone, novel: _novel(cacheStale: true));
    await _chrome(t, _phone);
    await _snap(s, 'state-saved-copy', _phone);
    await _end(t, s);

    s = await _open(t, _phone, novel: _novel(offline: true, online: false, failing: {'2': const NetworkError(message: 'offline')}));
    await _key(t, LogicalKeyboardKey.end);
    await _frames(t, 600);
    await _snap(s, 'state-end-of-download', _phone);
    await _end(t, s);

    s = await _open(t, _phone, novel: _novel(failing: {'2': const ApiError(code: 'rate_limited', message: 'busy', statusCode: 429, retryAfter: Duration(seconds: 12))}));
    await _frames(t, 600);
    await _snap(s, 'state-rate-limited', _phone);
    await _end(t, s);

    s = await _open(t, _phone, novel: _novel(failing: {'1': const ApiError(code: 'source_not_found', message: 'gone', statusCode: 404)}));
    await _snap(s, 'state-unavailable', _phone);
    await _end(t, s);
    never.complete();
  });

  testWidgets('accessibility and frames', (t) async {
    var s = await _open(t, _phone, extra: [glassInAppPrefsProvider.overrideWith(() => _InApp(const GlassInAppPrefs(reduceMotion: true)))]);
    await _chrome(t, _phone);
    await _snap(s, 'reduced-motion', _phone);
    await _end(t, s);

    s = await _open(t, _phone, extra: [glassInAppPrefsProvider.overrideWith(() => _InApp(const GlassInAppPrefs(solidGlass: true)))]);
    await _chrome(t, _phone);
    await _snap(s, 'solid', _phone);
    await _end(t, s);

    s = await _open(t, _phone, extra: [glassInAppPrefsProvider.overrideWith(() => _InApp(const GlassInAppPrefs(increaseContrast: true)))]);
    await _chrome(t, _phone);
    await _snap(s, 'contrast', _phone);
    await _end(t, s);

    s = await _open(t, kSkinShotLandscape);
    await _chrome(t, kSkinShotLandscape);
    await _snap(s, 'landscape', kSkinShotLandscape);
    await _end(t, s);
    expect(find.byType(NovelPagedView), findsNothing);
  });

  testWidgets('Cinematic novel reader, unchanged', (t) async {
    setSkinShotView(t, _phone);
    await cine.pumpNovel(t, boundaryKey: kSkinShotKey, size: _phone.logical);
    await cine.settleNovel(t, ms: 1500);
    final dir = proofDir;
    if (dir != null) {
      await writeShot(t, find.byKey(kSkinShotKey), '$dir/cinematic-novel-phone.png', pixelRatio: _phone.pixelRatio);
    } else {
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(kSkinShotKey));
      await t.runAsync(() async => (await boundary.toImage()).dispose());
    }
    await cine.disposeNovel(t);
  });
}

