import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';

/// Fixture data for the primitives gallery: invented titles, procedural demo covers, no 18+ art and
/// no real profile names.
const List<String> kGalleryCovers = [
  'assets/gallery/covers/01-salt-and-iron.webp',
  'assets/gallery/covers/02-ember-ledger.webp',
  'assets/gallery/covers/07-moonlit-bakery.webp',
  'assets/gallery/covers/13-night-ward.webp',
  'assets/gallery/covers/17-petal-almanac.webp',
  'assets/gallery/covers/23-white-room-protocol.webp',
];

const List<String> kGalleryTitles = [
  'Salt and Iron',
  'Ember Ledger',
  'Moonlit Bakery',
  'Night Ward',
  'Petal Almanac',
  'White Room Protocol',
];

String galleryCover(int i) => kGalleryCovers[i % kGalleryCovers.length];

String galleryTitle(int i) => kGalleryTitles[i % kGalleryTitles.length];

const List<String> kGalleryGenres = ['Romance', 'Action', 'Fantasy', 'Slice of life', 'Horror'];

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

/// The evening the streak gallery pretends it is (after 20:00, for the at-risk state).
final DateTime kGalleryEvening = DateTime(2026, 9, 30, 21);

/// Every streak flame tier and state: `(caption, streak, now)`.
final List<(String, HomeStreak, DateTime)> galleryStreaks = [
  ('NONE', const HomeStreak(longestDays: 31), kGalleryEvening),
  ('1-6 DAYS, READ TODAY', HomeStreak(currentDays: 3, longestDays: 3, lastActiveDate: DateTime(2026, 9, 30)), kGalleryEvening),
  ('7-29 DAYS, READ TODAY', HomeStreak(currentDays: 12, longestDays: 31, lastActiveDate: DateTime(2026, 9, 30)), kGalleryEvening),
  ('30-99 DAYS, READ TODAY', HomeStreak(currentDays: 45, longestDays: 45, lastActiveDate: DateTime(2026, 9, 30)), kGalleryEvening),
  ('100+ DAYS, READ TODAY', HomeStreak(currentDays: 120, longestDays: 120, lastActiveDate: DateTime(2026, 9, 30)), kGalleryEvening),
  ('ALIVE, NOT YET TODAY', HomeStreak(currentDays: 12, longestDays: 31, lastActiveDate: DateTime(2026, 9, 29)), DateTime(2026, 9, 30, 14)),
  ('AT RISK', HomeStreak(currentDays: 12, longestDays: 31, lastActiveDate: DateTime(2026, 9, 29)), kGalleryEvening),
];
