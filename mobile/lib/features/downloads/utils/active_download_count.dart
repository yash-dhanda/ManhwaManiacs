import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the Downloads badge and lists filter rows: the profile's 18+ gate, then the content mode (glass 8.22).
class DownloadRowFilter {
  const DownloadRowFilter({required this.gateOpen, required this.mode});
  final bool gateOpen;
  final ContentMode mode;

  /// A row is visible when the gate hides none of it (an unstamped row counts as visible) and it belongs to the mode; narration
  /// audio follows its novel.
  bool allows(SavedChapter c) {
    if (!gateOpen && (c.mature ?? false)) return false;
    final novel = c.kind.isNovel || c.kind.isAudio;
    return mode == ContentMode.novel ? novel : !novel;
  }
}

/// Queued + downloading + failed chapters after the mature and content-mode filters. [state] is accepted so a caller that holds it
/// can pass it (the count itself reads the rows: a queue restart leaves rows `downloading` with nothing running).
int activeDownloadCount(DownloadQueueState state, List<SavedChapter> rows, DownloadRowFilter filter) => rows
    .where((c) =>
        (c.state == DownloadChapterState.queued || c.state == DownloadChapterState.downloading || c.state == DownloadChapterState.failed) &&
        filter.allows(c))
    .length;

/// The dock badge text: null for 0, the number up to 9, `9+` above.
String? badgeText(int n) => n <= 0 ? null : (n <= 9 ? '$n' : '9+');

/// The Library badge and the Downloading accessory count (glass 7.15, 7.20). Separate from [activeDownloadCountProvider], which
/// Cinematic's tab badge reads unchanged.
final glassActiveDownloadCountProvider = Provider.autoDispose<int>((ref) {
  final rows = ref.watch(activeDownloadQueueProvider).valueOrNull ?? const <SavedChapter>[];
  final state = ref.watch(downloadQueueControllerProvider);
  return activeDownloadCount(state, rows, DownloadRowFilter(gateOpen: ref.watch(matureGateOpenProvider), mode: ref.watch(contentModeControllerProvider)));
}, name: 'glassActiveDownloadCount');
