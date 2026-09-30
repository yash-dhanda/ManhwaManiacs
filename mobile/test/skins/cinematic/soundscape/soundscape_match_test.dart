import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/soundscape_match.dart';

void main() {
  test('first mapped genre wins, case-insensitive', () {
    expect(matchTheMood(['Unknown', 'FANTASY', 'Romance'], Mood.neutral), 'temple-bells');
    expect(matchTheMood(['Romance'], Mood.action), 'rain-on-glass');
    expect(matchTheMood(['sci-fi'], Mood.neutral), 'night-city');
    expect(matchTheMood(['Seinen'], Mood.neutral), 'afternoon-park');
  });
  test('no match falls back to the mood default', () {
    expect(matchTheMood(const [], Mood.neutral), 'projector-room');
    expect(matchTheMood(['Zzz'], Mood.horror), 'night-wind');
    expect(matchTheMood(const [], Mood.sliceOfLife), 'afternoon-park');
    expect(matchTheMood(const [], Mood.comedy), 'cafe');
    expect(matchTheMood(const [], Mood.action), 'low-drone');
    expect(matchTheMood(const [], Mood.romantic), 'rain-on-glass');
    expect(matchTheMood(const [], Mood.fantasy), 'temple-bells');
  });
}
