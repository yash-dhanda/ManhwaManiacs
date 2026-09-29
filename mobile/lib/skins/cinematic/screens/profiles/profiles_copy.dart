import 'package:manhwamaniacs/core/error/app_error.dart';

/// Pure copy for the picker, the profile form and Manage profiles (cinematic 8.5, 8.6).

/// The time-aware question: 05:00-11:59 morning, 12:00-17:59 afternoon, otherwise tonight.
String pickerQuestion(DateTime now) {
  final h = now.hour;
  final part = h >= 5 && h < 12
      ? 'this morning'
      : h >= 12 && h < 18
          ? 'this afternoon'
          : 'tonight';
  return "Who's reading $part?";
}

const String kNameEmpty = 'Give this profile a name.';
const String kProfileNotFound = 'This profile no longer exists.';
const String kLimitLine = '5 profiles is the limit.';
const String kMoodHelper = 'Grades the top of the app while this profile is active. Never the reader.';
const String kEditionCaption = 'The look of the whole app for this profile.';
const String kEmptyHouseDeck = 'Profiles keep follows, progress and moods apart for everyone on this account.';

String savedToast(String name) => 'Saved $name';
String deletedToast(String name) => 'Deleted $name.';
String readingAsToast(String name) => 'Reading as $name';
String deleteTitle(String name) => 'Delete $name?';
const String kDeleteBody = "Its library, progress, bookmarks and collections go with it. This can't be undone.";
String deleteBody(String name) => '${deleteTitle(name)} $kDeleteBody';
String matureHiddenToast(String name) => '18+ content hidden on $name';

/// Save failures by code; other server errors carry the API message.
String profileSaveError(AppError e) {
  if (e is ApiError) {
    switch (e.code) {
      case 'profile_limit_reached':
        return kLimitLine;
      case 'invalid_profile_name':
        return 'Use 1 to 30 characters for the name.';
    }
    return "Couldn't save this profile. ${e.message}".trim();
  }
  return "Couldn't save this profile. ${e.userMessage}".trim();
}

/// Mood labels for the form chips (Default first).
const List<(String id, String label)> kMoodChips = [
  ('default', 'Default'),
  ('romantic', 'Romantic'),
  ('action', 'Action'),
  ('comedy', 'Comedy'),
  ('horror', 'Horror'),
  ('slice_of_life', 'Slice of life'),
  ('fantasy', 'Fantasy'),
];

/// The grade colour with every sRGB channel x 3 (the square before each chip); null for default.
const Map<String, int> kMoodSquares = {
  'romantic': 0xFF4E2130,
  'action': 0xFF4E2718,
  'comedy': 0xFF45391E,
  'horror': 0xFF2D1E27,
  'slice_of_life': 0xFF2D3624,
  'fantasy': 0xFF362448,
};

String moodLabel(String wire) => kMoodChips.firstWhere((m) => m.$1 == wire, orElse: () => kMoodChips.first).$2;

/// "Romantic mood · 18+ on".
String manageCaption({required String mood, required bool adult}) =>
    '${moodLabel(mood)} mood · 18+ ${adult ? 'on' : 'off'}';
