import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Per-profile, per-series chapter order: `"source:series" -> newest|oldest`.
/// Default: newest for manga, oldest (first to last) for novels.
const String kChapterSortPrefix = 'mm.chapter-sort.';

String chapterSortKey(String? profileId) => '$kChapterSortPrefix${profileId ?? '_'}';

String chapterSortFor(
  SharedPreferences prefs, {
  required String? profileId,
  required String sourceId,
  required String seriesKey,
  required bool novel,
}) {
  try {
    final m = jsonDecode(prefs.getString(chapterSortKey(profileId)) ?? '{}');
    final v = m is Map ? m['$sourceId:$seriesKey'] : null;
    if (v == 'newest' || v == 'oldest') return v as String;
  } catch (_) {}
  return novel ? 'oldest' : 'newest';
}

Future<void> saveChapterSort(
  SharedPreferences prefs, {
  required String? profileId,
  required String sourceId,
  required String seriesKey,
  required String order,
}) async {
  Map<String, dynamic> m;
  try {
    final d = jsonDecode(prefs.getString(chapterSortKey(profileId)) ?? '{}');
    m = d is Map ? Map<String, dynamic>.from(d) : {};
  } catch (_) {
    m = {};
  }
  m['$sourceId:$seriesKey'] = order;
  await prefs.setString(chapterSortKey(profileId), jsonEncode(m));
}
