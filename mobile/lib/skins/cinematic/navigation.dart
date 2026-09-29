import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';
import 'package:manhwamaniacs/features/reader/engine/prefetch_start.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// How a reader opens (cinematic 8.0.4): the Column wipe from Tonight, feature and book pages and
/// recaps opened from them; the Dip from everywhere else.
enum ReaderEntry { wipe, dip }

/// Where a reader route goes. Screens never build paths by string concatenation.
sealed class ReaderTarget {
  const ReaderTarget();

  /// The manifest reader: `/reader/:sourceId/:seriesKey/:chapterKey`.
  const factory ReaderTarget.manifest(String sourceId, String seriesKey, String chapterKey, {int? page, String? at}) =
      ManifestTarget;

  /// The source-native alias: `/sources/:sourceId/series/:seriesId/chapters/:chapterId/read`.
  const factory ReaderTarget.source(String sourceId, String seriesId, String chapterId, {int? page}) = SourceTarget;

  /// One long strip: `/read-all/:sourceId/:seriesKey`.
  const factory ReaderTarget.readAll(String sourceId, String seriesKey, {String? from}) = ReadAllTarget;

  /// The novel reader: `/novels/:sourceId/:seriesKey/:chapterKey`.
  const factory ReaderTarget.novel(String sourceId, String seriesKey, String chapterKey, {int? page, int? para, bool listen}) =
      NovelTarget;

  /// The typed location, percent-encoded by the generated builders.
  String get location;

  /// The chapter whose start is worth prefetching, when the target names one.
  ({String sourceId, String seriesKey, String chapterKey})? get chapter;
}

class ManifestTarget extends ReaderTarget {
  const ManifestTarget(this.sourceId, this.seriesKey, this.chapterKey, {this.page, this.at});
  final String sourceId, seriesKey, chapterKey;
  final int? page;
  final String? at;

  @override
  String get location => Routes.reader(sourceId, seriesKey, chapterKey, {'page': page, 'at': at});

  @override
  ({String sourceId, String seriesKey, String chapterKey})? get chapter =>
      (sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey);
}

class SourceTarget extends ReaderTarget {
  const SourceTarget(this.sourceId, this.seriesId, this.chapterId, {this.page});
  final String sourceId, seriesId, chapterId;
  final int? page;

  @override
  String get location {
    final path = '/sources/${Uri.encodeComponent(sourceId)}/series/${Uri.encodeComponent(seriesId)}'
        '/chapters/${Uri.encodeComponent(chapterId)}/read';
    return page == null ? path : '$path?page=$page';
  }

  @override
  ({String sourceId, String seriesKey, String chapterKey})? get chapter =>
      (sourceId: sourceId, seriesKey: seriesId, chapterKey: chapterId);
}

class ReadAllTarget extends ReaderTarget {
  const ReadAllTarget(this.sourceId, this.seriesKey, {this.from});
  final String sourceId, seriesKey;
  final String? from;

  @override
  String get location => Routes.readAll(sourceId, seriesKey, {'from': from});

  @override
  ({String sourceId, String seriesKey, String chapterKey})? get chapter =>
      from == null ? null : (sourceId: sourceId, seriesKey: seriesKey, chapterKey: from!);
}

class NovelTarget extends ReaderTarget {
  const NovelTarget(this.sourceId, this.seriesKey, this.chapterKey, {this.page, this.para, this.listen = false});
  final String sourceId, seriesKey, chapterKey;
  final int? page, para;

  /// Opens the novel with the narrator playing (`listen=1`).
  final bool listen;

  @override
  String get location => Routes.novel(sourceId, seriesKey, chapterKey, {'page': page, 'para': para, if (listen) 'listen': '1'});

  /// Novels have no page manifest to warm.
  @override
  ({String sourceId, String seriesKey, String chapterKey})? get chapter => null;
}

/// Pushes the typed reader route with `extra: {'entry': ...}`. `wipe` from Tonight, feature and
/// book pages and recaps opened from them; `dip` from everywhere else (8.0.4).
void enterReader(BuildContext context, ReaderTarget target, {required ReaderEntry entry}) {
  GoRouter.of(context).push<void>(target.location, extra: <String, String>{'entry': entry.name});
}

/// Warms a chapter start before the reader asks for it: on press at P1, after a 150 ms dwell
/// (keyboard focus, pointer hover) at P3, once per chapter.
class ReaderPrefetch {
  ReaderPrefetch(this._read);
  final ReadProvider _read;

  /// Forgets which chapters were warmed (tests).
  static void reset() => resetChapterStartPrefetch();

  void onPress(ReaderTarget target) => _warm(target, RequestPriority.p1);
  void onDwell(ReaderTarget target) => _warm(target, RequestPriority.p3);

  void _warm(ReaderTarget target, RequestPriority priority) {
    final c = target.chapter;
    if (c == null) return;
    prefetchChapterStart(_read, sourceId: c.sourceId, seriesKey: c.seriesKey, chapterKey: c.chapterKey, priority: priority);
  }
}

ReaderPrefetch readerPrefetchOf(WidgetRef ref) => ReaderPrefetch(ref.read);

/// Where the router is now, including a route pushed on top of the shell (the configuration's own
/// `uri` stays on the location that was navigated to; a push adds an imperative match).
String cineLocationOf(GoRouter router) {
  final cfg = router.routerDelegate.currentConfiguration;
  if (cfg.isEmpty) return '/';
  return cfg.last.matchedLocation;
}

/// Cross-branch link: `go` into the owning branch (the notch moves; never a duplicate push).
/// [branch]: 0 Tonight, 1 Library, 2 Discover, 3 Downloads, 4 Index.
void goSection(BuildContext context, int branch) {
  final path = switch (branch) {
    0 => Routes.tonight(),
    1 => Routes.library(),
    2 => Routes.discover(),
    3 => Routes.downloads(),
    _ => Routes.indexHub(),
  };
  GoRouter.of(context).go(path);
}

/// Incremented by the Discover tab's third tap and by `/`: the screen with a search field focuses
/// it (mobile/16 listens).
final focusSearchSignalProvider = StateProvider<int>((ref) => 0, name: 'focusSearchSignal');

/// Incremented on every section change: lists that run Set on entrance replay it.
final cineSectionEpochProvider = StateProvider<int>((ref) => 0, name: 'cineSectionEpoch');
