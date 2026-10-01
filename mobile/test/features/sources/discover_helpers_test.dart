import 'package:flutter/painting.dart' show HSLColor;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/fnv1a.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/utils/browse_freshness.dart';
import 'package:manhwamaniacs/features/sources/utils/discover_scope.dart';
import 'package:manhwamaniacs/features/sources/utils/genre_index.dart';
import 'package:manhwamaniacs/features/sources/utils/source_health.dart';
import 'package:manhwamaniacs/features/sources/utils/source_wash.dart';
import 'package:manhwamaniacs/features/sources/utils/trending.dart';

SourcePin pin(String id) => SourcePin(sourceId: id, sortOrder: 0, name: id);

SourceSeriesSummary series(String id, String title, String src) =>
    SourceSeriesSummary(
      id: id,
      sourceId: src,
      title: title,
      chapterCount: 1,
      genres: const [],
      coverUrl: '',
    );

void main() {
  group('parseDiscoverScope', () {
    DiscoverScope p(String? v, {bool ai = true, bool d = true}) =>
        parseDiscoverScope(v, aiAvailable: ai, dialogueAvailable: d);
    test('known values', () {
      expect(p('library'), DiscoverScope.library);
      expect(p('sources'), DiscoverScope.sources);
      expect(p('ask'), DiscoverScope.ask);
      expect(p('dialogue'), DiscoverScope.dialogue);
    });
    test('unknown, text and null are all', () {
      expect(p(null), DiscoverScope.all);
      expect(p('text'), DiscoverScope.all);
      expect(p('nope'), DiscoverScope.all);
    });
    test('unavailable ask and dialogue fall back to all', () {
      expect(p('ask', ai: false), DiscoverScope.all);
      expect(p('dialogue', d: false), DiscoverScope.all);
    });
  });

  group('describeHealth', () {
    final now = DateTime(2026, 9, 29, 12);
    test('ok', () {
      final h = SourceHealth(
        status: SourceHealthStatus.ok,
        lastCheckedAt: now.subtract(const Duration(minutes: 4)),
      );
      expect(describeHealth(h, now).label, 'OK · last checked 4 min ago');
      expect(describeHealth(h, now).state, HealthState.ok);
    });
    test('failing, dead, demoted, unknown', () {
      expect(
        describeHealth(
                const SourceHealth(
                    status: SourceHealthStatus.failing, consecutiveFailures: 3,),
                now,)
            .label,
        'FAILING · 3 errors',
      );
      expect(
        describeHealth(
                SourceHealth(
                    status: SourceHealthStatus.dead,
                    lastOkAt: DateTime(2026, 9, 12),),
                now,)
            .label,
        'DEAD since 12 Sep',
      );
      expect(
        describeHealth(
                const SourceHealth(
                    status: SourceHealthStatus.failing, demoted: true,),
                now,)
            .state,
        HealthState.demoted,
      );
      expect(describeHealth(null, now).state, HealthState.unknown);
    });
    test('sortWorstFirst', () {
      final rows = <(String, SourceHealth?)>[
        ('b', const SourceHealth(status: SourceHealthStatus.ok)),
        ('a', null),
        ('d', const SourceHealth(status: SourceHealthStatus.dead)),
        ('f', const SourceHealth(status: SourceHealthStatus.failing)),
        ('m', const SourceHealth(status: SourceHealthStatus.ok, demoted: true)),
      ];
      final sorted =
          sortWorstFirst(rows, (r) => r.$2, (r) => r.$1).map((r) => r.$1);
      expect(sorted, ['d', 'f', 'm', 'a', 'b']);
    });
  });

  test('buildGenreIndex merges case-insensitively and orders by weight', () {
    final idx = buildGenreIndex(
      [pin('a'), pin('b')],
      {
        'a': const [
          SourceGenre(id: '1', label: 'Romance'),
          SourceGenre(id: '2', label: 'Action'),
        ],
        'b': const [
          SourceGenre(id: '1', label: 'romance'),
          SourceGenre(id: '3', label: 'Zen'),
        ],
      },
      const [
        GenreWeight(genre: 'zen', weight: 0.9),
        GenreWeight(genre: 'ROMANCE', weight: 0.2),
      ],
    );
    expect(idx.map((e) => e.label), ['Zen', 'Romance', 'Action']);
    expect(idx[1].sourceIds, ['a', 'b']);
    expect(buildGenreIndex([], {}, []), isEmpty);
  });

  test('buildGenreIndex keeps each source\'s own genre id', () {
    final idx = buildGenreIndex(
      [pin('a'), pin('b')],
      {
        'a': const [SourceGenre(id: 'lianai', label: 'Romance')],
        'b': const [SourceGenre(id: 'romance-1', label: 'romance')],
      },
      const [],
    );
    expect(idx.single.idFor('a'), 'lianai');
    expect(idx.single.idFor('b'), 'romance-1');
  });

  test('buildTrending caps, dedupes and limits per source', () {
    final pages = {
      'a': [for (var i = 0; i < 5; i++) series('a$i', 'A$i', 'a')],
      'b': [
        series('b0', 'a0', 'b'),
        series('b1', 'B1', 'b'),
        series('b2', 'B2', 'b'),
      ],
    };
    final t = buildTrending([pin('a'), pin('b'), pin('none')], pages);
    expect(t.map((e) => e.title), ['A0', 'A1', 'B1', 'B2']);
    final many = buildTrending(
      [for (var i = 0; i < 8; i++) pin('s$i')],
      {
        for (var i = 0; i < 8; i++)
          's$i': [series('x$i', 'X$i', 's$i'), series('y$i', 'Y$i', 's$i')],
      },
    );
    expect(many.length, 10);
  });

  test('fnv1a wash vectors', () {
    expect(fnv1a32('asurascans'), 0x641F4639);
    expect(fnv1a32('mangadex'), 0x899A8380);
    expect(fnv1a32('weebcentral'), 0x88D2BCDB);
    expect(sourceWashHue('asurascans'), 33);
    expect(sourceWashHue('mangadex'), 40);
    expect(sourceWashHue('weebcentral'), 3);
    expect(sourceWash('asurascans'),
        const HSLColor.fromAHSL(1, 33, 0.35, 0.06).toColor(),);
  });

  test('browseFreshness buckets', () {
    final now = DateTime.utc(2026, 9, 29, 12);
    String? l(Duration ago, {bool stale = false}) => browseFreshness(
          {'stale': stale, 'fetched_at': now.subtract(ago).toIso8601String()},
          now,
        )?.text;
    expect(l(const Duration(seconds: 10)), 'UPDATED JUST NOW');
    expect(l(const Duration(minutes: 12)), 'UPDATED 12 MIN AGO');
    expect(l(const Duration(hours: 3), stale: true), 'SAVED COPY · 3 H');
    expect(l(const Duration(hours: 60)), 'UPDATED 2 D AGO');
    expect(browseFreshness(null, now), isNull);
  });
}
