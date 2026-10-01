import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart' show DownloadsStore;
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/panels.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart' show ReaderAnalysisReports, ReaderRepository;
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// Glass's side of the engine's ambient duties (glass 9.4.3): the page images the panel detector analyses one page ahead, the manifest's
/// `pages[].panels` first (and the saved copy's), and the exit report of each chapter's new panel results (`POST /reader/panels`). The page
/// tint is not sampled here: Glass takes it from the engine's `currentPageSample`. Skin-neutral logic, Glass-owned file.
class GlassAmbientBridge {
  GlassAmbientBridge({required this.ref, required this.engine, required this.sourceId, required this.seriesKey});

  final WidgetRef ref;
  final ReaderEngine engine;
  final String sourceId, seriesKey;

  final Set<String> _seeded = {};
  ReaderRepository? _repo;
  NetworkConnectivity? _net;
  DownloadsStore? _store;
  List<ReaderChapter> _chapters = const [];

  ImageProvider? resolve(String chapterId, int page) {
    final ch = _chapters.where((c) => c.id == chapterId).firstOrNull;
    if (ch == null || page < 1 || page > ch.pages.length) return null;
    final p = ch.pages[page - 1];
    if (p.localFile != null) return FileImage(p.localFile!);
    if (p.imageUrl.isEmpty) return null;
    final headers = apiImageHttpHeaders(ref.read(authTokenStoreProvider).token, profileId: ref.read(activeProfileProvider)?.id);
    return CachedNetworkImageProvider(p.imageUrl, headers: headers);
  }

  /// Idempotent: called from the reader's build.
  void sync({required List<ReaderChapter> chapters, required bool rtl}) {
    _chapters = chapters;
    _repo = ref.read(readerRepositoryProvider);
    _net = ref.read(networkConnectivityProvider);
    _store = ref.read(downloadsStoreProvider);
    engine.ambient
      ..resolver = resolve
      ..tintEnabled = false
      ..panelsWanted = true
      ..direction = rtl ? PanelDirection.rtl : PanelDirection.ltr;
    for (final ch in chapters) {
      if (!_seeded.add(ch.id)) continue;
      final panels = <int, List<Rect>?>{};
      for (final p in ch.pages) {
        if (p.panels != null) panels[p.number] = p.panels;
      }
      engine.ambient.seed(ch.id, panels: panels);
      if (ch.pages.isNotEmpty && ch.pages.first.localFile != null) unawaited(_seedFromSaved(ch.id));
    }
  }

  Future<void> _seedFromSaved(String chapterId) async {
    final store = ref.read(downloadsStoreProvider);
    if (store == null) return;
    try {
      final a = await store.readChapterAnalysis((sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterId));
      engine.ambient.seed(chapterId, panels: {for (final e in a.panels.entries) e.key: _parse(e.value)});
    } catch (_) {}
  }

  static List<Rect> _parse(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return [
      for (final r in list.cast<List<dynamic>>()) Rect.fromLTWH((r[0] as num).toDouble(), (r[1] as num).toDouble(), (r[2] as num).toDouble(), (r[3] as num).toDouble()),
    ];
  }

  /// The chapter's exit report: its new panel results, once, fire and forget; skipped offline and when nothing is new. A saved copy also
  /// keeps them on the device.
  Future<void> flush(String chapterId) async {
    if (chapterId.isEmpty) return;
    final report = engine.ambient.takeReport(chapterId);
    if (report.panels.isEmpty) return;
    final ch = _chapters.where((c) => c.id == chapterId).firstOrNull;
    final saved = ch != null && ch.pages.isNotEmpty && ch.pages.first.localFile != null;
    final id = (sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterId);
    if (saved) {
      try {
        await _store?.saveChapterAnalysis(
          id,
                    panels: {for (final e in report.panels.entries) e.key: jsonEncode([for (final r in e.value) [r.left, r.top, r.width, r.height]])},
        );
      } catch (_) {}
    }
    var online = true;
    try {
      online = await (_net?.isOnline() ?? Future.value(true));
    } catch (_) {}
    final repo = _repo;
    if (!online || repo is! ReaderAnalysisReports) return;
    unawaited((repo as ReaderAnalysisReports).postPanels(
      sourceId: sourceId,
      seriesKey: seriesKey,
      chapterKey: chapterId,
      pages: [for (final e in report.panels.entries) (page: e.key, panels: e.value)],
    ),);
  }
}
