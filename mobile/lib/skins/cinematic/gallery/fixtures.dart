import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';

/// Invented gallery data for the series-page primitives.
const List<(String, DownloadMarkState)> galleryMarks = [
  ('NONE', MarkNone()),
  ('QUEUED', MarkQueued()),
  ('30%', MarkDownloading(0.3)),
  ('SAVED', MarkSaved()),
  ('FAILED', MarkFailed()),
  ('PAUSED', MarkPaused()),
  ('STALE', MarkStale()),
];

const String galleryBlurb =
    'A salt trader walks the old road between two drowned cities, and every well she passes '
    'has a different story about what the sea took. She keeps a ledger of them. The ledger, '
    'she slowly realises, is keeping her.';
