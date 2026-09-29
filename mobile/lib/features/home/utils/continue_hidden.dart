import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// "Remove from row": a Continue row hidden until a new chapter brings the series back.
typedef HiddenContinue = ({String sourceId, String seriesKey, String chapterKey});

HiddenContinue hiddenOf(ContinueReadingItem row) => (sourceId: row.sourceId, seriesKey: row.seriesKey, chapterKey: row.chapterKey);

/// Drops a row while its `chapter_key` is still the stored one.
List<ContinueReadingItem> filterHidden(Iterable<ContinueReadingItem> rows, Iterable<HiddenContinue> hidden) => [
      for (final r in rows)
        if (!hidden.any((h) => h.sourceId == r.sourceId && h.seriesKey == r.seriesKey && h.chapterKey == r.chapterKey)) r,
    ];

List<HiddenContinue> decodeHidden(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final list = jsonDecode(raw);
    return [
      if (list is List<dynamic>)
        for (final e in list)
          if (e is Map<String, dynamic> && e['source_id'] is String && e['series_key'] is String && e['chapter_key'] is String)
            (sourceId: e['source_id'] as String, seriesKey: e['series_key'] as String, chapterKey: e['chapter_key'] as String),
    ];
  } catch (_) {
    return const [];
  }
}

String encodeHidden(List<HiddenContinue> hidden) => jsonEncode([
      for (final h in hidden) {'source_id': h.sourceId, 'series_key': h.seriesKey, 'chapter_key': h.chapterKey},
    ]);

const _prefix = 'mm.continue.hidden.';

class ContinueHiddenController extends Notifier<List<HiddenContinue>> {
  @override
  List<HiddenContinue> build() =>
      decodeHidden(ref.watch(sharedPrefsProvider).getString(profileScopedKey(ref, prefix: _prefix, deviceKey: '${_prefix}device', watch: true)));

  void _save(List<HiddenContinue> next) {
    state = next;
    ref.read(sharedPrefsProvider).setString(profileScopedKey(ref, prefix: _prefix, deviceKey: '${_prefix}device', watch: false), encodeHidden(next));
  }

  void hide(ContinueReadingItem row) {
    final h = hiddenOf(row);
    // A newer chapter of the same series replaces the older entry.
    _save([...state.where((e) => !(e.sourceId == h.sourceId && e.seriesKey == h.seriesKey)), h]);
  }

  void unhide(ContinueReadingItem row) {
    final h = hiddenOf(row);
    _save([...state.where((e) => e != h)]);
  }
}

final continueHiddenProvider = NotifierProvider<ContinueHiddenController, List<HiddenContinue>>(ContinueHiddenController.new, name: 'continueHidden');

typedef ReadFn = T Function<T>(ProviderListenable<T> provider);

void hideContinue(ReadFn read, ContinueReadingItem row) => read(continueHiddenProvider.notifier).hide(row);

void unhideContinue(ReadFn read, ContinueReadingItem row) => read(continueHiddenProvider.notifier).unhide(row);
