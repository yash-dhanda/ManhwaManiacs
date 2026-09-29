import 'package:manhwamaniacs/features/downloads/models/storage_cap.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';

/// Every line of Downloads that more than one widget says (cinematic 8.23, 8.19).
const String kForegroundNote =
    'Downloads run while the app is open; leaving pauses them and coming back picks up where they stopped.';

const String kSavedNote =
    'Saved chapters live inside ManhwaManiacs and open from here. For a copy you can open elsewhere, use Save to Files.';

const String kFloorNote = "Downloads stop before the last 1.5 GB of this phone's space.";

String floorNote(String noun) => "Downloads stop before the last 1.5 GB of this $noun's space.";

String capFullNote(StorageCap cap) => 'Your ${cap.label} limit is full.';

/// The NOTE line under Activity for a pause, or null when the queue clears itself.
String? pauseLine(DownloadQueuePauseReason reason, {required StorageCap cap, String noun = 'phone'}) => switch (reason) {
      DownloadQueuePauseReason.userPaused =>
        'Paused by you. Nothing was lost; resuming carries on from the same page.',
      DownloadQueuePauseReason.freeSpaceFloor => 'Paused: this $noun is almost full. Downloads stop before the last 1.5 GB.',
      DownloadQueuePauseReason.cap => 'Paused: your ${cap.label} limit is full.',
      DownloadQueuePauseReason.backgrounded => 'Paused while the app is in the background.',
      DownloadQueuePauseReason.noScope || DownloadQueuePauseReason.none => null,
    };

/// `Show queue ⁽⁸⁾`: the count in superscript digits.
String superscript(int n) {
  const d = '⁰¹²³⁴⁵⁶⁷⁸⁹';
  return '$n'.split('').map((c) => d[int.parse(c)]).join();
}

String chaptersWord(int n) => n == 1 ? '1 chapter' : '$n chapters';

/// `CH 12 · PAGE 7 OF 40` and its neighbours.
String pageFolio({required String chapter, required int done, required int total, required bool novel, required bool audio}) {
  if (audio) return 'SAVING THE AUDIO…';
  if (novel) return 'SAVING THE TEXT…';
  if (total <= 0) return 'READING CHAPTER DETAILS…';
  return '$chapter · PAGE ${done.clamp(0, total)} OF $total';
}

String formatMb(int bytes) {
  const mb = 1024 * 1024;
  const gb = 1024 * mb;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(bytes >= 100 * mb ? 0 : 1)} MB';
  return '${(bytes / 1024).round()} KB';
}
