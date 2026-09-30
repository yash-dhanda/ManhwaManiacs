import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/utils/mature_filter.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// The offline edition (cinematic 8.8 "Offline"): what the device can show with no server. The
/// last feed's continue rows are kept per profile and content kind, each stamped `mature` with
/// [isMatureLocal] (the server's `resolve_series_rating` order), so a closed gate hides a mature
/// row without a trace (7.24).

const _prefix = 'mm.home.last.';

String _key(Ref ref, String contentKind, {required bool watch}) => profileScopedKey(
      ref,
      prefix: '$_prefix$contentKind.',
      deviceKey: '$_prefix$contentKind.device',
      watch: watch,
    );

/// The stored JSON of [feed]'s continue rows. [sourceMature] is the source's own 18+ flag.
String encodeLastFeed(HomeFeed feed, {required bool Function(String sourceId) sourceMature, required DateTime savedAt}) {
  final ratings = <String, ({String rating, bool? override, String content})>{};
  for (final s in feed.sections) {
    for (final it in s.items) {
      if (it is HomeSeriesItem) {
        ratings['${it.series.sourceId}|${it.series.seriesKey}'] = (rating: it.series.rating, override: it.series.matureOverride, content: it.series.contentRating);
      }
    }
  }
  final rows = <Map<String, Object?>>[];
  for (final s in feed.sections) {
    if (s.type != HomeSectionType.continueReading) continue;
    for (final it in s.items.whereType<HomeContinueItem>()) {
      final r = it.row;
      final known = ratings['${r.sourceId}|${r.seriesKey}'];
      rows.add({
        'source_id': r.sourceId,
        'series_key': r.seriesKey,
        'chapter_key': r.chapterKey,
        'chapter_number': r.chapterNumber,
        'last_page': r.lastPage,
        'page_count': r.pageCount,
        'last_read_at': r.lastReadAt?.toUtc().toIso8601String(),
        'title': r.title,
        'cover_url': r.coverUrl,
        if (r.ambient != null) 'ambient': r.ambient!.toJson(),
        'mature': isMatureLocal(
          resolvedRating: known?.rating,
          matureOverride: known?.override,
          contentRating: known?.content,
          sourceMature: sourceMature(r.sourceId),
        ),
      });
    }
  }
  return jsonEncode({'saved_at': savedAt.toUtc().toIso8601String(), 'issue_no': feed.issueNo, 'continue': rows});
}

/// A feed holding only the stored `continue` section, or null for junk.
HomeFeed? decodeLastFeed(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final j = jsonDecode(raw);
    if (j is! Map<String, dynamic>) return null;
    final items = <Object>[];
    for (final e in (j['continue'] as List<dynamic>? ?? const [])) {
      if (e is! Map<String, dynamic>) continue;
      items.add(HomeContinueItem(row: ContinueReadingItem.fromJson(e), mature: e['mature'] as bool? ?? false));
    }
    return HomeFeed(
      issueNo: (j['issue_no'] as num?)?.toInt() ?? 1,
      headline: '',
      deck: '',
      generatedAt: DateTime.tryParse(j['saved_at'] as String? ?? ''),
      sections: [HomeSection(type: HomeSectionType.continueReading, title: 'Continue reading', items: items)],
    );
  } catch (_) {
    return null;
  }
}

/// Stores [feed]'s continue rows for this profile and [contentKind].
void saveLastFeed(Ref ref, String contentKind, HomeFeed feed, {required bool Function(String sourceId) sourceMature, DateTime? now}) {
  ref.read(sharedPrefsProvider).setString(
        _key(ref, contentKind, watch: false),
        encodeLastFeed(feed, sourceMature: sourceMature, savedAt: now ?? DateTime.now()),
      );
}

/// Deletes the cached feeds of the active profile for both content kinds (a closing 18+ gate, glass 8.0.8 step 5).
void clearLastFeeds(Ref ref) {
  final prefs = ref.read(sharedPrefsProvider);
  for (final kind in const ['manga', 'novel']) {
    prefs.remove(_key(ref, kind, watch: false));
  }
}

HomeFeed? readLastFeed(Ref ref, String contentKind) => decodeLastFeed(ref.read(sharedPrefsProvider).getString(_key(ref, contentKind, watch: false)));

bool _groupMature(DownloadedSeriesGroup g) => g.chapters.any((c) => c.mature ?? false);

/// The offline edition: "Offline edition." over the saved series and the continue rows whose
/// chapter is saved here. Every row goes through the 18+ gate on the device.
HomeFeed composeOfflineEdition({
  HomeFeed? lastFeed,
  required List<DownloadedSeriesGroup> saved,
  required bool matureEnabled,
  required DateTime now,
}) {
  final groups = filterMature(saved, gateOpen: matureEnabled, isMature: _groupMature)
      .where((g) => g.chapters.any((c) => c.state == DownloadChapterState.complete))
      .toList();
  final complete = <String>{
    for (final g in groups)
      for (final c in g.chapters)
        if (c.state == DownloadChapterState.complete) '${c.sourceId}|${c.seriesKey}|${c.chapterKey}',
  };
  final lastRows = lastFeed?.section(HomeSectionType.continueReading)?.items.whereType<HomeContinueItem>() ?? const <HomeContinueItem>[];
  final rows = filterMature(lastRows, gateOpen: matureEnabled, isMature: (r) => r.mature)
      .where((r) => complete.contains('${r.row.sourceId}|${r.row.seriesKey}|${r.row.chapterKey}'))
      .toList();

  HomeCover? cover;
  if (rows.isNotEmpty) {
    final r = rows.first.row;
    cover = HomeCover(
      sourceId: r.sourceId,
      seriesKey: r.seriesKey,
      chapterKey: r.chapterKey,
      reason: HomeCoverReason.inProgress,
      ambient: r.ambient,
      title: r.title ?? '',
      coverUrl: r.coverUrl,
      chapterNumber: r.chapterNumber,
      lastPage: r.lastPage,
      pageCount: r.pageCount,
    );
  } else if (groups.isNotEmpty) {
    final g = groups.first;
    final c = g.chapters.firstWhere((c) => c.state == DownloadChapterState.complete);
    cover = HomeCover(
      sourceId: g.sourceId,
      seriesKey: g.seriesKey,
      chapterKey: c.chapterKey,
      reason: HomeCoverReason.firstPick,
      title: g.seriesTitle ?? '',
      chapterNumber: c.chapterNumber,
      pageCount: c.pageCount,
    );
  }

  return HomeFeed(
    headline: 'Offline edition.',
    deck: "Only what's saved on this device is here.",
    issueNo: lastFeed?.issueNo ?? 1,
    cover: cover,
    generatedAt: now,
    sections: [
      if (groups.isNotEmpty)
        HomeSection(
          type: HomeSectionType.saved,
          title: 'Saved on this device',
          items: [
            for (final g in groups)
              HomeSavedItem(
                sourceId: g.sourceId,
                seriesKey: g.seriesKey,
                title: g.seriesTitle ?? g.seriesKey,
                chapters: g.chapters.where((c) => c.state == DownloadChapterState.complete).length,
              ),
          ],
        ),
      if (rows.isNotEmpty) HomeSection(type: HomeSectionType.continueReading, title: 'Continue (saved chapters)', items: rows),
    ],
  );
}
