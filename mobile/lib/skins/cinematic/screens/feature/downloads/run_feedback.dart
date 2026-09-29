import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_feedback.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Plays `download.done` (once, when the whole batch has settled and at least
/// one chapter was saved) and `download.fail` (once, on the first failed
/// chapter) for a run of chapter keys.
class RunFeedback {
  bool _done = false;
  bool _failed = false;

  void reset() {
    _done = false;
    _failed = false;
  }

  void check(WidgetRef ref, Set<String> run, Map<String, ChapterDownloadStatus> statuses) {
    if (run.isEmpty) return;
    final states = [for (final k in run) statuses[k]?.state];
    final failed = states.where((s) => s == DownloadChapterState.failed).length;
    final saved = states.where((s) => s == DownloadChapterState.complete).length;
    if (failed > 0 && !_failed) {
      _failed = true;
      feedback(ref, HapticEvent.downloadFail, SoundEvent.downloadFail);
    }
    if (!_done && saved > 0 && saved + failed == run.length) {
      _done = true;
      feedback(ref, HapticEvent.downloadDone, SoundEvent.downloadDone);
    }
  }
}
