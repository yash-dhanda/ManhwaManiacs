import 'dart:convert';
import 'dart:typed_data';

import 'package:manhwamaniacs/features/downloads/store/downloads_db.dart';
import 'package:manhwamaniacs/features/novels/novel_text/novel_text_tokens.dart';
import 'package:sqflite/sqflite.dart';

/// One matched paragraph.
class NovelTextHit {
  const NovelTextHit({required this.sourceId, required this.seriesKey, required this.chapterKey, required this.para, required this.text, required this.offsets, this.readAt});
  final String sourceId;
  final String seriesKey;
  final String chapterKey;

  /// The paragraph's 0-based index in its chapter.
  final int para;
  final String text;

  /// FTS4 `offsets()` of the paragraph: `column term byteOffset size` quadruples.
  final String offsets;
  final String? readAt;

  NovelTextSnippet get snippet => novelTextSnippet(text, offsets);
}

class NovelTextSearchResult {
  const NovelTextSearchResult({required this.hits, required this.capped});
  final List<NovelTextHit> hits;

  /// More than [kNovelTextShown] rows matched: the first 50 are shown.
  final bool capped;
  static const empty = NovelTextSearchResult(hits: [], capped: false);
}

const int kNovelTextShown = 50;

/// A window of a paragraph with the matched ranges (indices into [text]).
class NovelTextSnippet {
  const NovelTextSnippet(this.text, this.ranges);
  final String text;
  final List<({int start, int end})> ranges;
}

/// Byte offset -> string (UTF-16) index over `utf8.encode(text)`.
Int32List _byteToIndex(String text) {
  final bytes = utf8.encode(text).length;
  final map = Int32List(bytes + 1);
  var b = 0;
  var i = 0;
  for (final rune in text.runes) {
    final len = rune < 0x80 ? 1 : rune < 0x800 ? 2 : rune < 0x10000 ? 3 : 4;
    final units = rune > 0xFFFF ? 2 : 1;
    for (var k = 0; k < len; k++) {
      map[b + k] = i;
    }
    b += len;
    i += units;
  }
  map[bytes] = i;
  return map;
}

/// Converts the UTF-8 byte offsets of FTS4 `offsets()` (column 4, the text) to string indices, returns +-60 characters around the
/// first match trimmed to word boundaries, and the matched ranges inside that window.
NovelTextSnippet novelTextSnippet(String text, String offsets, {int radius = 60}) {
  final nums = [for (final p in offsets.split(' ')) if (p.isNotEmpty) int.tryParse(p) ?? 0];
  final map = _byteToIndex(text);
  final all = <({int start, int end})>[];
  for (var i = 0; i + 3 < nums.length; i += 4) {
    if (nums[i] != 4) continue;
    final s = nums[i + 2];
    final e = s + nums[i + 3];
    if (s < 0 || e >= map.length) continue;
    all.add((start: map[s], end: map[e]));
  }
  if (all.isEmpty) return NovelTextSnippet(text.length > radius * 2 ? '${text.substring(0, radius * 2).trimRight()}…' : text, const []);
  all.sort((a, b) => a.start.compareTo(b.start));
  final first = all.first;
  var from = first.start - radius;
  var to = first.end + radius;
  var head = '';
  var tail = '';
  if (from > 0) {
    // Trim to a word boundary: move forward to just after the next space.
    final sp = text.indexOf(RegExp(r'\s'), from);
    from = sp == -1 || sp >= first.start ? first.start : sp + 1;
    head = '…';
  } else {
    from = 0;
  }
  if (to < text.length) {
    final sp = text.lastIndexOf(RegExp(r'\s'), to);
    to = sp <= first.end ? first.end : sp;
    tail = '…';
  } else {
    to = text.length;
  }
  final body = text.substring(from, to);
  final shift = head.length - from;
  return NovelTextSnippet(
    '$head$body$tail',
    [
      for (final r in all)
        if (r.start >= from && r.end <= to) (start: r.start + shift, end: r.end + shift),
    ],
  );
}

/// The on-device novel-text index over a downloads database (`novel_text` FTS4 and `novel_text_chapters`).
class NovelTextIndex {
  NovelTextIndex(this.db);
  final Database db;

  Future<bool> isIndexed(String sourceId, String seriesKey, String chapterKey) async => (await db.query(
        DownloadsSchema.novelTextChapters,
        columns: ['source'],
        where: 'source = ? AND series = ? AND chapter = ?',
        whereArgs: [sourceId, seriesKey, chapterKey],
        limit: 1,
      ))
      .isNotEmpty;

  /// Inserts one row per paragraph in one transaction and records the chapter; an already-indexed chapter is left alone.
  Future<void> indexChapter({required String sourceId, required String seriesKey, required String chapterKey, required List<String> paragraphs}) async {
    if (await isIndexed(sourceId, seriesKey, chapterKey)) return;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < paragraphs.length; i++) {
        if (paragraphs[i].trim().isEmpty) continue;
        batch.insert(DownloadsSchema.novelText, {'source': sourceId, 'series': seriesKey, 'chapter': chapterKey, 'para': '$i', 'text': paragraphs[i]});
      }
      batch.insert(
        DownloadsSchema.novelTextChapters,
        {'source': sourceId, 'series': seriesKey, 'chapter': chapterKey, 'indexed_at': DateTime.now().millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await batch.commit(noResult: true);
    });
  }

  /// Deletes the chapter's rows and record only when no `saved_chapters` row of any scope still names it as a novel. Runs on a
  /// [DatabaseExecutor] so a deletion transaction can call it after removing its own row.
  static Future<bool> dropChapterIfUnreferenced(DatabaseExecutor db, {required String sourceId, required String seriesKey, required String chapterKey}) async {
    final held = await db.rawQuery(
      'SELECT 1 FROM ${DownloadsSchema.savedChapters} WHERE source_id = ? AND series_key = ? AND chapter_key = ? AND kind = ? LIMIT 1',
      [sourceId, seriesKey, chapterKey, kNovelDownloadKind],
    );
    if (held.isNotEmpty) return false;
    await db.delete(DownloadsSchema.novelText, where: 'source = ? AND series = ? AND chapter = ?', whereArgs: [sourceId, seriesKey, chapterKey]);
    await db.delete(DownloadsSchema.novelTextChapters, where: 'source = ? AND series = ? AND chapter = ?', whereArgs: [sourceId, seriesKey, chapterKey]);
    return true;
  }

  Future<bool> dropChapter(String sourceId, String seriesKey, String chapterKey) =>
      dropChapterIfUnreferenced(db, sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey);

  /// Every word must match, in any order. Ranked: series being read, then more occurrences in the paragraph, then the chapter's most
  /// recent read. [readingSeries] holds `"source:series"` keys (at most 500 are used). While the 18+ gate is closed a chapter stamped
  /// mature is absent.
  Future<NovelTextSearchResult> search(String q, {required String scopeId, required bool gateOpen, Iterable<String> readingSeries = const []}) async {
    final match = novelTextMatchQuery(q);
    if (match == null) return NovelTextSearchResult.empty;
    final reading = readingSeries.take(500).toList();
    final args = <Object?>[scopeId, match, ...reading];
    final rows = await db.rawQuery(
      'SELECT novel_text.source AS source, novel_text.series AS series, novel_text.chapter AS chapter, novel_text.para AS para, '
      'novel_text.text AS text, offsets(novel_text) AS offs, c.read_at AS read_at '
      'FROM novel_text JOIN saved_chapters c ON c.source_id = novel_text.source AND c.series_key = novel_text.series '
      'AND c.chapter_key = novel_text.chapter AND c.scope_id = ? AND c.kind = \'novel\' '
      'WHERE novel_text MATCH ?${gateOpen ? '' : ' AND c.mature IS NOT 1'} '
      'ORDER BY ${reading.isEmpty ? '' : "((novel_text.source || ':' || novel_text.series) IN (${List.filled(reading.length, '?').join(',')})) DESC, "}'
      "((length(offs) - length(replace(offs, ' ', '')) + 1) / 4) DESC, c.read_at IS NULL, c.read_at DESC "
      'LIMIT ${kNovelTextShown + 1}',
      args,
    );
    final hits = [
      for (final r in rows)
        NovelTextHit(
          sourceId: r['source']! as String,
          seriesKey: r['series']! as String,
          chapterKey: r['chapter']! as String,
          para: int.tryParse('${r['para']}') ?? 0,
          text: r['text']! as String,
          offsets: (r['offs'] as String?) ?? '',
          readAt: r['read_at'] as String?,
        ),
    ];
    final capped = hits.length > kNovelTextShown;
    return NovelTextSearchResult(hits: capped ? hits.sublist(0, kNovelTextShown) : hits, capped: capped);
  }
}
