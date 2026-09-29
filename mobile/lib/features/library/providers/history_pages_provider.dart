import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// One page of the log is this many rows; a page that comes back full may have an earlier one.
const int kHistoryPageSize = 50;

/// The offset of the next page, or null when the last page came back short (nothing earlier).
int? nextHistoryOffset(List<List<ReadingHistoryItem>> pages) {
  if (pages.isEmpty || pages.last.length < kHistoryPageSize) return null;
  return pages.fold<int>(0, (n, p) => n + p.length);
}

/// The reading log, 50 rows at a time, `bySeries` true (one row per book) or false (one per
/// chapter). `loadEarlier()` appends the next page; there is no infinite scroll.
final historyPagesProvider = AsyncNotifierProvider.autoDispose
    .family<HistoryPagesNotifier, List<List<ReadingHistoryItem>>, bool>(
  HistoryPagesNotifier.new,
  name: 'historyPages',
);

class HistoryPagesNotifier extends AutoDisposeFamilyAsyncNotifier<List<List<ReadingHistoryItem>>, bool> {
  @override
  Future<List<List<ReadingHistoryItem>>> build(bool arg) async => [await _fetch(0)];

  Future<List<ReadingHistoryItem>> _fetch(int offset) async {
    final r = await ref.read(libraryRepositoryProvider).readingHistory(offset: offset, bySeries: arg);
    if (r.isErr) throw r.error;
    return r.value;
  }

  /// Whether an earlier page may exist.
  bool get hasEarlier => nextHistoryOffset(state.valueOrNull ?? const []) != null;

  /// Appends the next 50 rows; false when the request failed (the pages stay as they were).
  Future<bool> loadEarlier() async {
    final pages = state.valueOrNull;
    final offset = pages == null ? null : nextHistoryOffset(pages);
    if (pages == null || offset == null) return true;
    try {
      final more = await _fetch(offset);
      state = AsyncData([...pages, more]);
      return true;
    } catch (_) {
      return false;
    }
  }
}
