import 'package:flutter/foundation.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest_window.dart';

/// The batch window the read-all feed asks for: one request carries at most this many keys.
const int kReadAllWindow = 20;

/// The current chapter's position in the series and the page offsets of the chapter boundaries
/// in the loaded window (engine state for ScreenId `readAll`, cinematic 8.14.4).
@immutable
class ReadAllState {
  const ReadAllState({required this.index, required this.total, this.boundaries = const []});

  /// 1-based position of the chapter under the reading line among all chapters of the series.
  final int index;
  final int total;

  /// The global page offset at which each loaded chapter after the first begins.
  final List<int> boundaries;

  @override
  bool operator ==(Object other) =>
      other is ReadAllState && other.index == index && other.total == total && listEquals(other.boundaries, boundaries);

  @override
  int get hashCode => Object.hash(index, total, Object.hashAll(boundaries));
}

enum ReadAllOutcome { ok, failed }

/// What a batch answer means for each requested key: a key that came back with a manifest is
/// [ReadAllOutcome.ok]; an `error` item or a key the answer left out is [ReadAllOutcome.failed] (a
/// retryable chapter inside the feed, never a failed feed).
Map<String, ReadAllOutcome> mapWindowOutcomes(List<String> requested, ChapterManifestWindow answer) => {
      for (final k in requested) k: answer.manifests.containsKey(k) ? ReadAllOutcome.ok : ReadAllOutcome.failed,
    };

/// The next request window: up to [max] keys in series order starting at [fromIndex] (0-based
/// into [keys]) that are not in [settled] (loaded or in flight).
List<String> nextWindow(List<String> keys, Set<String> settled, int fromIndex, {int max = kReadAllWindow}) {
  final out = <String>[];
  for (var i = fromIndex.clamp(0, keys.length); i < keys.length && out.length < max; i++) {
    if (!settled.contains(keys[i])) out.add(keys[i]);
  }
  return out;
}

/// Global page offsets at which each chapter starts, given per-chapter page counts.
List<int> chapterStarts(List<int> pageCounts) {
  final starts = <int>[];
  var n = 0;
  for (final c in pageCounts) {
    starts.add(n);
    n += c;
  }
  return starts;
}

/// (chapter index, 1-based page in that chapter) of a 0-based global page in the loaded window.
({int chapter, int page}) locateGlobalPage(List<int> pageCounts, int global) {
  var rest = global.clamp(0, pageCounts.fold<int>(0, (a, b) => a + b) - 1);
  for (var i = 0; i < pageCounts.length; i++) {
    if (rest < pageCounts[i]) return (chapter: i, page: rest + 1);
    rest -= pageCounts[i];
  }
  return (chapter: 0, page: 1);
}

/// The 1-based series position of chapter [loadedIndex] of the loaded window, whose first chapter
/// sits at series index [firstSeriesIndex] (0-based).
int seriesPosition(int firstSeriesIndex, int loadedIndex) => firstSeriesIndex + loadedIndex + 1;

/// The ruler folio while dragging in read-all: `CH 143 · p. 7`.
String readAllFlag(String chapterFolio, int page) => '${chapterFolio.toUpperCase()} · p. $page';
