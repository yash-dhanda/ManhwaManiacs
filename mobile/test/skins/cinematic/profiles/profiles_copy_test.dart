import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/profiles/profiles_copy.dart';

void main() {
  test('the picker question follows the local clock', () {
    expect(pickerQuestion(DateTime(2026, 9, 29, 4, 59)), "Who's reading tonight?");
    expect(pickerQuestion(DateTime(2026, 9, 29, 5)), "Who's reading this morning?");
    expect(pickerQuestion(DateTime(2026, 9, 29, 8)), "Who's reading this morning?");
    expect(pickerQuestion(DateTime(2026, 9, 29, 12)), "Who's reading this afternoon?");
    expect(pickerQuestion(DateTime(2026, 9, 29, 17, 59)), "Who's reading this afternoon?");
    expect(pickerQuestion(DateTime(2026, 9, 29, 18)), "Who's reading tonight?");
    expect(pickerQuestion(DateTime(2026, 9, 29, 21)), "Who's reading tonight?");
  });

  test('save errors by code', () {
    ApiError e(String c) => ApiError(statusCode: 400, code: c, message: 'Nope');
    expect(profileSaveError(e('profile_limit_reached')), '5 profiles is the limit.');
    expect(profileSaveError(e('invalid_profile_name')), 'Use 1 to 30 characters for the name.');
    expect(profileSaveError(e('invalid_mood')), "Couldn't save this profile. Nope");
    expect(profileSaveError(const TimeoutError()), startsWith("Couldn't save this profile."));
  });

  test('toasts, captions and squares', () {
    expect(savedToast('Yash'), 'Saved Yash');
    expect(deletedToast('Yash'), 'Deleted Yash.');
    expect(readingAsToast('Yash'), 'Reading as Yash');
    expect(matureHiddenToast('Yash'), '18+ content hidden on Yash');
    expect(manageCaption(mood: 'slice_of_life', adult: true), 'Slice of life mood · 18+ on');
    expect(manageCaption(mood: 'default', adult: false), 'Default mood · 18+ off');
    expect(kMoodSquares.length, 6);
    expect(kMoodSquares['romantic'], 0xFF4E2130);
    expect(kMoodChips.first.$1, 'default');
  });
}
