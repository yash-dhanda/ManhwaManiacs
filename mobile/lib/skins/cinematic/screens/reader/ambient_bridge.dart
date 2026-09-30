import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart' show DownloadsStore;
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/ocr/utils/ocr_boxes.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/panels.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_ambient.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/words.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart' show ReaderAnalysisReports, ReaderRepository;
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Cinematic's side of the engine's ambient duties: it feeds the skin-neutral [ReaderAmbient] and
/// the engine's auto-scroll controller their tokens and settings (the 600 ms tint sample, the
/// 400 ms `settle` ramp), the page images to analyse, the OCR words, and posts the exit reports.
class CineAmbientBridge {
  CineAmbientBridge({required this.ref, required this.engine, required this.sourceId, required this.seriesKey});

  final WidgetRef ref;
  final ReaderEngine engine;
  final String sourceId, seriesKey;

  final Set<String> _seeded = {};

  // Resolved in the build: `flush` also runs from `dispose`, where a widget ref cannot be read.
  ReaderRepository? _repo;
  NetworkConnectivity? _net;
  DownloadsStore? _store;
  String? _ocrFor;
  List<ReaderChapter> _chapters = const [];

  ImageProvider? _resolve(String chapterId, int page) {
    final ch = _chapters.where((c) => c.id == chapterId).firstOrNull;
    if (ch == null || page < 1 || page > ch.pages.length) return null;
    final p = ch.pages[page - 1];
    if (p.localFile != null) return FileImage(p.localFile!);
    if (p.imageUrl.isEmpty) return null;
    final headers = apiImageHttpHeaders(ref.read(authTokenStoreProvider).token, profileId: ref.read(activeProfileProvider)?.id);
    return CachedNetworkImageProvider(p.imageUrl, headers: headers);
  }

  /// Idempotent: called from the reader's build.
  void sync(
    BuildContext context, {
    required List<ReaderChapter> chapters,
    required bool tintOn,
    required bool paceByDialogue,
    required bool resumeAfterRelease,
    required bool rtl,
    required bool panelsWanted,
  }) {
    _chapters = chapters;
    _repo = ref.read(readerRepositoryProvider);
    _net = ref.read(networkConnectivityProvider);
    _store = ref.read(downloadsStoreProvider);
    final cine = context.cine;
    engine.ambient
      ..resolver = _resolve
      ..sampleInterval = cine.durSampleTint
      ..tintEnabled = tintOn
      ..panelsWanted = panelsWanted
      ..direction = rtl ? PanelDirection.rtl : PanelDirection.ltr;
    engine.autoScroll.configure(
      ramp: cine.durGlide,
      curve: CineCurves.settle.transform,
      resumeAfterRelease: resumeAfterRelease,
      paceByDialogue: paceByDialogue,
    );
    for (final ch in chapters) {
      if (!_seeded.add(ch.id)) continue;
      final tints = <int, String>{};
      final panels = <int, List<Rect>?>{};
      for (final p in ch.pages) {
        if (p.tint != null) tints[p.number] = p.tint!;
        if (p.panels != null) panels[p.number] = p.panels;
      }
      engine.ambient.seed(ch.id, tints: tints, panels: panels);
      if (ch.pages.isNotEmpty && ch.pages.first.localFile != null) unawaited(_seedFromSaved(ch.id));
    }
  }

  Future<void> _seedFromSaved(String chapterId) async {
    final store = ref.read(downloadsStoreProvider);
    if (store == null) return;
    try {
      final a = await store.readChapterAnalysis((sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterId));
      final panels = <int, List<Rect>?>{
        for (final e in a.panels.entries) e.key: _parsePanels(e.value),
      };
      engine.ambient.seed(chapterId, tints: a.tints, panels: panels);
    } catch (_) {}
  }

  static List<Rect> _parsePanels(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return [
      for (final r in list.cast<List<dynamic>>())
        Rect.fromLTWH((r[0] as num).toDouble(), (r[1] as num).toDouble(), (r[2] as num).toDouble(), (r[3] as num).toDouble()),
    ];
  }

  /// Loads the chapter's dialogue text into the engine (pace by dialogue and guided holds) once per
  /// chapter; a chapter without text leaves `wordsOnScreen` null.
  Future<void> loadOcr(String chapterId, {required bool wanted}) async {
    if (!wanted || chapterId.isEmpty || _ocrFor == chapterId) return;
    _ocrFor = chapterId;
    try {
      final texts = await ref.read(ocrChapterTextProvider((sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterId)).future);
      if (texts == null || _ocrFor != chapterId) {
        engine.ambient.setOcr(const {});
        return;
      }
      final byPage = <int, List<OcrWordBox>>{};
      for (final t in texts) {
        final boxes = <OcrWordBox>[];
        for (final b in t.boxes) {
          final r = boxFraction(b);
          if (r != null && b.text.trim().isNotEmpty) boxes.add(OcrWordBox(r, b.text));
        }
        if (boxes.isNotEmpty) byPage[t.page] = boxes;
      }
      engine.ambient.setOcr(byPage);
    } catch (_) {
      engine.ambient.setOcr(const {});
    }
  }

  /// Words on screen feed the auto-scroll pace while auto-scroll runs and pace by dialogue is on.
  void syncWords({required bool running, required bool paceByDialogue}) {
    engine.ambient.trackWords(
      enabled: running && paceByDialogue,
      toViewport: (page, f) => engine.pageToViewport(page, f.dx, f.dy),
      viewport: () => engine.viewportRect,
    );
    engine.ambient.wordsOnScreen.removeListener(_words);
    if (running && paceByDialogue) {
      engine.ambient.wordsOnScreen.addListener(_words);
    } else {
      engine.autoScroll.setWords(null);
    }
  }

  void _words() => engine.autoScroll.setWords(engine.ambient.wordsOnScreen.value);

  /// Exit report: posts the chapter's new samples once (`POST /reader/page-tints` and
  /// `POST /reader/panels`), fire and forget, skipped offline and when nothing is new. A chapter
  /// read from the saved copy also stores them on the device.
  Future<void> flush(String chapterId) async {
    if (chapterId.isEmpty) return;
    final report = engine.ambient.takeReport(chapterId);
    if (report.isEmpty) return;
    final ch = _chapters.where((c) => c.id == chapterId).firstOrNull;
    final saved = ch != null && ch.pages.isNotEmpty && ch.pages.first.localFile != null;
    final id = (sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterId);
    if (saved) {
      final store = _store;
      try {
        await store?.saveChapterAnalysis(
          id,
          tints: report.tints,
          panels: {
            for (final e in report.panels.entries)
              e.key: jsonEncode([for (final r in e.value) [r.left, r.top, r.width, r.height]]),
          },
        );
      } catch (_) {}
    }
    var online = true;
    try {
      online = await (_net?.isOnline() ?? Future.value(true));
    } catch (_) {}
    if (!online) return;
    final repo = _repo;
    if (repo is! ReaderAnalysisReports) return;
    final reports = repo as ReaderAnalysisReports;
    if (report.tints.isNotEmpty) {
      unawaited(reports.postPageTints(
        sourceId: sourceId,
        seriesKey: seriesKey,
        chapterKey: chapterId,
        tints: [for (final e in report.tints.entries) (page: e.key, hex: e.value)],
      ),);
    }
    if (report.panels.isNotEmpty) {
      unawaited(reports.postPanels(
        sourceId: sourceId,
        seriesKey: seriesKey,
        chapterKey: chapterId,
        pages: [for (final e in report.panels.entries) (page: e.key, panels: e.value)],
      ),);
    }
  }
}
