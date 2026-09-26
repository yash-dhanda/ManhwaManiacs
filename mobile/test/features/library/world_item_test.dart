/// The worldwide-catalog payloads and the card rules computed from them.
///
/// Both endpoints stitch together two external catalogs, so a title arrives
/// with whatever those happened to know: nulls, missing keys, empty strings.
/// A card with no rating is still a card — one odd row must never fail the
/// parse and blank the page.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';

Map<String, dynamic> _full() => {
      'anilist_id': 105398,
      'title': 'Nano Machine',
      'alt_titles': ['Nano Mashin'],
      'format': 'Manhwa',
      'country': 'KR',
      'status': 'Ongoing',
      'chapters': 181,
      'rating': 8.1,
      'rating_count_hint': null,
      'genres': ['Action', 'Martial Arts', 'Sci-Fi', 'Drama', 'Comedy'],
      'cover_url': 'https://s4.anilist.co/file/anilistcdn/media/manga/cover/large/bx1.jpg',
      'is_adult': false,
      'platforms': [
        {'site': 'Webtoon', 'url': 'https://www.webtoons.com/nano'},
      ],
      'anilist_url': 'https://anilist.co/manga/105398',
      'available': [
        {
          'source_id': 'asurascans',
          'source_name': 'Asura Scans',
          'series_key': 'nano-machine-6f7fe6eb',
        },
        {
          'source_id': 'mangadex',
          'source_name': 'MangaDex',
          'series_key': 'abc',
        },
      ],
      'why': 'Same murim revenge arc as Nano Machine.',
    };

void main() {
  group('WorldItem.fromJson', () {
    test('reads every field of the contract example', () {
      final item = WorldItem.fromJson(_full());

      expect(item.anilistId, 105398);
      expect(item.title, 'Nano Machine');
      expect(item.altTitles, ['Nano Mashin']);
      expect(item.format, 'Manhwa');
      expect(item.country, 'KR');
      expect(item.status, 'Ongoing');
      expect(item.chapters, 181);
      expect(item.rating, 8.1);
      expect(item.genres, hasLength(5));
      expect(item.coverUrl, startsWith('https://s4.anilist.co/'));
      expect(item.isAdult, isFalse);
      expect(item.platforms.single.site, 'Webtoon');
      expect(item.platforms.single.url, 'https://www.webtoons.com/nano');
      expect(item.anilistUrl, 'https://anilist.co/manga/105398');
      expect(item.available, hasLength(2));
      expect(item.available.first.sourceId, 'asurascans');
      expect(item.available.first.sourceName, 'Asura Scans');
      expect(item.available.first.seriesKey, 'nano-machine-6f7fe6eb');
      expect(item.why, 'Same murim revenge arc as Nano Machine.');
    });

    test('explicit nulls everywhere still parse', () {
      final item = WorldItem.fromJson({
        'anilist_id': null,
        'title': 'Omniscient Reader',
        'alt_titles': null,
        'format': null,
        'country': null,
        'status': null,
        'chapters': null,
        'rating': null,
        'genres': null,
        'cover_url': null,
        'is_adult': null,
        'platforms': null,
        'anilist_url': null,
        'available': null,
        'why': null,
      });

      expect(item.title, 'Omniscient Reader');
      expect(item.anilistId, 0);
      expect(item.altTitles, isEmpty);
      expect(item.format, isNull);
      expect(item.status, isNull);
      expect(item.chapters, isNull);
      expect(item.rating, isNull);
      expect(item.genres, isEmpty);
      expect(item.coverUrl, isNull);
      expect(item.isAdult, isFalse);
      expect(item.platforms, isEmpty);
      expect(item.available, isEmpty);
      expect(item.why, isNull);
    });

    test('an empty object still parses', () {
      final item = WorldItem.fromJson(const {});
      expect(item.title, 'Untitled');
      expect(item.available, isEmpty);
      expect(item.platforms, isEmpty);
    });

    test('numbers of the other kind are accepted', () {
      final item = WorldItem.fromJson({
        'title': 'x',
        'chapters': 181.0,
        'rating': 8,
      });
      expect(item.chapters, 181);
      expect(item.rating, 8.0);
    });

    test('blank strings are absent, not empty', () {
      final item = WorldItem.fromJson({
        'title': 'x',
        'status': '  ',
        'why': '',
        'cover_url': '',
        'genres': ['Action', '', null, 3],
      });
      expect(item.status, isNull);
      expect(item.why, isNull);
      expect(item.coverUrl, isNull);
      expect(item.genres, ['Action']);
    });

    test('rows that cannot be opened or followed are dropped', () {
      final item = WorldItem.fromJson({
        'title': 'x',
        'available': [
          {'source_id': 'asurascans', 'source_name': 'Asura Scans'},
          {'series_key': 'orphan'},
          {'source_id': 'mangadex', 'series_key': 'abc'},
          'not a map',
        ],
        'platforms': [
          {'site': 'Webtoon'},
          {'url': 'https://tapas.io/x'},
        ],
      });

      // Without both ids there is no series page to go to.
      expect(item.available.single.sourceId, 'mangadex');
      // A missing display name falls back to the id rather than a blank.
      expect(item.available.single.sourceName, 'mangadex');
      expect(item.platforms.single.url, 'https://tapas.io/x');
    });
  });

  group('card rules', () {
    test('a carried title opens its FIRST source and names the rest', () {
      final item = WorldItem.fromJson(_full());

      expect(item.openTarget?.sourceId, 'asurascans');
      expect(item.openTarget?.seriesKey, 'nano-machine-6f7fe6eb');
      expect(item.availabilityLabel, 'On: Asura Scans (+1 more)');
      // It opens in the app, so no way out of it is offered.
      expect(item.readElsewhere, isNull);
    });

    test('a single source has no "+N more"', () {
      final item = WorldItem.fromJson(
        _full()..['available'] = [(_full()['available'] as List<dynamic>).first],
      );
      expect(item.availabilityLabel, 'On: Asura Scans');
    });

    test('an uncarried title opens nothing and links out when it can', () {
      final item = WorldItem.fromJson(_full()..['available'] = <Object>[]);

      expect(item.openTarget, isNull);
      expect(item.availabilityLabel, isNull);
      expect(item.readElsewhere?.site, 'Webtoon');
    });

    test('an uncarried title with no platforms has no outbound link', () {
      final item = WorldItem.fromJson(
        _full()
          ..['available'] = <Object>[]
          ..['platforms'] = <Object>[],
      );
      expect(item.openTarget, isNull);
      expect(item.readElsewhere, isNull);
    });

    test('labels', () {
      const item = WorldItem(
        title: 'x',
        format: 'Manhwa',
        status: 'Ongoing',
        chapters: 181,
        rating: 8.1,
        genres: ['Action', 'Martial Arts', 'Sci-Fi', 'Drama'],
      );
      expect(item.badgeLine, 'Manhwa · Ongoing');
      expect(item.chaptersLabel, '181 ch');
      expect(item.ratingLabel, '★ 8.1');
      expect(item.cardGenres, ['Action', 'Martial Arts', 'Sci-Fi']);
    });

    test('a whole rating keeps its one decimal', () {
      expect(const WorldItem(title: 'x', rating: 8).ratingLabel, '★ 8.0');
    });

    test('unknown values hide their label instead of printing null', () {
      const bare = WorldItem(title: 'x');
      expect(bare.badgeLine, isNull);
      expect(bare.chaptersLabel, isNull);
      expect(bare.ratingLabel, isNull);
      expect(bare.cardGenres, isEmpty);

      expect(const WorldItem(title: 'x', format: 'Manga').badgeLine, 'Manga');
      expect(
        const WorldItem(title: 'x', status: 'Completed').badgeLine,
        'Completed',
      );
    });
  });

  group('WorldRecommendations.fromJson', () {
    test('reads for_you, sections and the reason', () {
      final recs = WorldRecommendations.fromJson({
        'for_you': [_full()],
        'sections': [
          {
            'because': {
              'title': 'Nano Machine',
              'source_id': 'asurascans',
              'series_key': 'nano-machine-6f7fe6eb',
            },
            'items': [
              {'title': 'Return of the Mount Hua Sect', 'why': null},
            ],
          },
        ],
        'unavailable_reason': null,
      });

      expect(recs.forYou.single.title, 'Nano Machine');
      expect(recs.sections.single.becauseTitle, 'Nano Machine');
      expect(
        recs.sections.single.items.single.title,
        'Return of the Mount Hua Sect',
      );
      expect(recs.unavailableReason, isNull);
      expect(recs.isEmpty, isFalse);
    });

    test('an empty object is the "no reading yet" answer', () {
      final recs = WorldRecommendations.fromJson(const {});
      expect(recs.forYou, isEmpty);
      expect(recs.sections, isEmpty);
      expect(recs.unavailableReason, isNull);
      expect(recs.isEmpty, isTrue);
    });

    test('sections with no items do not count as content', () {
      final recs = WorldRecommendations.fromJson({
        'for_you': null,
        'sections': [
          {'because': null, 'items': null},
        ],
        'unavailable_reason': 'AniList could not be reached.',
      });
      expect(recs.isEmpty, isTrue);
      expect(recs.sections.single.becauseTitle, 'your library');
      expect(recs.unavailableReason, 'AniList could not be reached.');
    });
  });

  group('WorldSuggestResponse.fromJson', () {
    test('reads the contract example', () {
      final response = WorldSuggestResponse.fromJson({
        'items': [_full()],
        'dropped': 2,
        'model': 'deepseek-flash',
        'remaining_today': 57,
      });
      expect(response.items.single.why, isNotNull);
      expect(response.dropped, 2);
      expect(response.model, 'deepseek-flash');
      expect(response.remainingToday, 57);
    });

    test('nulls and missing keys fall back to empty', () {
      final response = WorldSuggestResponse.fromJson({
        'items': null,
        'dropped': null,
      });
      expect(response.isEmpty, isTrue);
      expect(response.dropped, 0);
      expect(response.model, '');
      expect(response.remainingToday, 0);
    });
  });
}
