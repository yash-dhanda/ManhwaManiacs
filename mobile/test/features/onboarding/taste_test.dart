import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';

void main() {
  test('wire names', () {
    expect([for (final f in FormatId.values) f.wire], ['manhwa', 'manga', 'manhua', 'novel']);
    expect(StyleId.values.length, 11);
    expect(StyleId.values[3].wire, 'manhua-3d');
    expect([GenreMark.like.wire, GenreMark.love.wire, GenreMark.skip.wire], [1, 2, -1]);
  });

  test('OnboardingStep.parse', () {
    expect(OnboardingStep.parse(3), OnboardingStep.at(3));
    expect(OnboardingStep.parse('4'), OnboardingStep.at(4));
    expect(OnboardingStep.parse('done'), OnboardingStep.done);
    expect(OnboardingStep.parse(null), isNull);
    expect(OnboardingStep.parse(9), isNull);
    expect(OnboardingStep.done.toJson(), 'done');
    expect(OnboardingStep.at(2).toJson(), 2);
  });

  test('TasteUpdate writes step plus only touched fields', () {
    const t = Taste(formats: [FormatId.manga], genres: {'Romance': GenreMark.love, 'Drama': null}, styles: [StyleId.noir], seeds: [TasteSeed.anilist(7)]);
    expect(const TasteUpdate(step: OnboardingStep.done, partial: t).toJson(), {'step': 'done'});
    final j = TasteUpdate(step: OnboardingStep.at(3), partial: t, touched: {TasteField.genres, TasteField.seeds}).toJson();
    expect(j, {
      'step': 3,
      'genres': {'Romance': 2, 'Drama': 0},
      'seeds': [
        {'anilist_id': 7},
      ],
    });
  });

  test('Taste.fromJson is lenient', () {
    final t = Taste.fromJson({
      'formats': ['manga', 'bogus'],
      'genres': {'A': 1, 'B': 2, 'C': -1, 'D': 5},
      'styles': ['noir', 'x'],
      'seeds': [
        {'anilist_id': 1},
        {'source_id': 's', 'series_key': 'k'},
        {'x': 1},
      ],
    });
    expect(t.formats, [FormatId.manga]);
    expect(t.genres, {'A': GenreMark.like, 'B': GenreMark.love, 'C': GenreMark.skip});
    expect(t.styles, [StyleId.noir]);
    expect(t.seeds.length, 2);
  });

  test('catalog parses', () {
    final c = OnboardingCatalog.fromJson({
      'formats': [
        {'format': 'manhwa', 'covers': ['a', 'b']},
      ],
      'genres': [
        {'name': 'Action', 'weight': 3},
      ],
      'seeds': [
        {'anilist_id': 1, 'title': 'T'},
      ],
      'unavailable_reason': 'x',
    });
    expect(c.formats.single.covers, ['a', 'b']);
    expect(c.genres.single.name, 'Action');
    expect(c.seeds.single.anilistId, 1);
    expect(c.unavailableReason, 'x');
  });
}
