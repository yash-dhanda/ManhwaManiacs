import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/utils/genre_paragraph.dart';
import 'package:manhwamaniacs/features/onboarding/utils/onboarding_steps.dart';

void main() {
  OnboardingStep at(int n) => OnboardingStep.at(n);

  test('shown steps and folio', () {
    expect(shownSteps(false), [2, 3, 4, 5]);
    expect(shownSteps(true), [1, 2, 3, 4, 5]);
    expect(folioFor(2, false), (1, 4));
    expect(folioFor(5, false), (4, 4));
    expect(folioFor(2, true), (2, 5));
  });

  test('resumeStep', () {
    expect(resumeStep(OnboardingStep.done, false), OnboardingStep.done);
    expect(resumeStep(null, false), at(2));
    expect(resumeStep(null, true), at(1));
    expect(resumeStep(at(1), false), at(2));
    expect(resumeStep(at(4), false), at(4));
    expect(resumeStep(at(6), false), at(5));
    expect(resumeStep(at(7), true), at(5));
  });

  test('next and prev', () {
    expect(nextStep(2, false), 3);
    expect(nextStep(5, false), isNull);
    expect(prevStep(2, false), isNull);
    expect(prevStep(3, false), 2);
    expect(prevStep(2, true), 1);
  });

  test('entryStep never passes the resume step', () {
    expect(entryStep(1, at(4), false), 2);
    expect(entryStep(5, at(3), false), 3);
    expect(entryStep(4, at(5), false), 4);
    expect(entryStep(null, at(3), false), 2);
    expect(entryStep(5, OnboardingStep.done, false), 5);
  });

  List<GenreWeight> names(int n) => [for (var i = 0; i < n; i++) GenreWeight(name: 'G${i.toString().padLeft(2, '0')}', weight: 1)];

  test('genreParagraph sorts and caps', () {
    expect(genreParagraph([const GenreWeight(name: 'b', weight: 1), const GenreWeight(name: 'A', weight: 1), const GenreWeight(name: 'z', weight: 5)]), ['z', 'A', 'b']);
    expect(genreParagraph(names(29)).length, 29);
    expect(genreParagraph(names(30)).length, 30);
    expect(genreParagraph(names(40)).length, 40);
    expect(genreParagraph(names(45)).length, 40);
  });

  test('tap cycle, hold, menu, labels', () {
    expect(tapGenre(null), GenreMark.like);
    expect(tapGenre(GenreMark.like), GenreMark.love);
    expect(tapGenre(GenreMark.love), isNull);
    expect(tapGenre(GenreMark.skip), isNull);
    expect(holdGenre(), GenreMark.skip);
    expect(menuGenre(GenreMenuAction.clear), isNull);
    expect(menuGenre(GenreMenuAction.love), GenreMark.love);
    expect(genreLabel('Romance', GenreMark.love), 'Romance, loved');
    expect(genreLabel('Romance', GenreMark.like), 'Romance, liked');
    expect(genreLabel('Romance', GenreMark.skip), 'Romance, skipped');
    expect(genreLabel('Romance', null), 'Romance, not chosen');
    expect(likedGenres({'a': GenreMark.like, 'b': GenreMark.love, 'c': GenreMark.skip, 'd': null}), ['b', 'a']);
  });
}
