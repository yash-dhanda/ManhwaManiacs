import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const recentSearchesKey = 'manhwamaniacs:recent-searches';
const maxRecentSearches = 4;

/// Builds the SharedPreferences key for a profile's recent-search history.
///
/// Passing a null [profileId] returns the legacy global key so callers (and
/// tests) that predate profile scoping keep working; a non-null id namespaces
/// the history per profile so switching the active reading profile no longer
/// leaks profile A's terms onto profile B's Search screen.
String recentSearchesKeyFor(int? profileId) =>
    profileId == null ? recentSearchesKey : '$recentSearchesKey:$profileId';

const trendingSearchSuggestions = [
  'fantasy',
  'romance',
  'action',
  'manhwa',
  'manga',
  'webtoon',
  'horror',
  'sci-fi',
];

/// One remembered term and whether the 18+ gate was open when it was typed (Glass purges those when the gate closes).
class RecentSearch {
  const RecentSearch(this.q, {required this.gateOpen});
  final String q;
  final bool gateOpen;

  Map<String, Object> toJson() => {'q': q, 'gateOpen': gateOpen};
}

/// The stored entries. A legacy plain string predates the flag and counts as typed with the gate open, so the purge drops it.
List<RecentSearch> readRecentSearchEntries(SharedPreferences prefs, {int? profileId}) {
  final raw = prefs.getString(recentSearchesKeyFor(profileId));
  if (raw == null || raw.isEmpty) return [];

  try {
    final parsed = jsonDecode(raw);
    if (parsed is! List) return [];
    final out = <RecentSearch>[];
    for (final item in parsed) {
      if (item is String) {
        final t = item.trim();
        if (t.isNotEmpty) out.add(RecentSearch(t, gateOpen: true));
      } else if (item is Map && item['q'] is String) {
        final t = (item['q'] as String).trim();
        if (t.isNotEmpty) out.add(RecentSearch(t, gateOpen: item['gateOpen'] == true));
      }
    }
    return out.take(maxRecentSearches).toList();
  } catch (_) {
    return [];
  }
}

List<String> readRecentSearches(SharedPreferences prefs, {int? profileId}) =>
    [for (final e in readRecentSearchEntries(prefs, profileId: profileId)) e.q];

Future<void> _writeEntries(SharedPreferences prefs, List<RecentSearch> entries, int? profileId) =>
    prefs.setString(recentSearchesKeyFor(profileId), jsonEncode([for (final e in entries) e.toJson()]));

Future<void> writeRecentSearch(
  SharedPreferences prefs,
  String term, {
  int? profileId,
  bool gateOpen = false,
}) async {
  final trimmed = term.trim();
  if (trimmed.length < 2) return;

  final existing = readRecentSearchEntries(prefs, profileId: profileId)
      .where((item) => item.q.toLowerCase() != trimmed.toLowerCase())
      .toList();
  final next = [RecentSearch(trimmed, gateOpen: gateOpen), ...existing].take(maxRecentSearches).toList();
  await _writeEntries(prefs, next, profileId);
}

/// The 18+ purge: drops every term typed while the gate was open (and legacy plain strings).
Future<void> dropGateOpenRecentSearches(SharedPreferences prefs, {int? profileId}) async {
  final kept = [for (final e in readRecentSearchEntries(prefs, profileId: profileId)) if (!e.gateOpen) e];
  await _writeEntries(prefs, kept, profileId);
}

Future<void> clearRecentSearches(SharedPreferences prefs, {int? profileId}) =>
    prefs.setString(recentSearchesKeyFor(profileId), jsonEncode(<String>[]));
