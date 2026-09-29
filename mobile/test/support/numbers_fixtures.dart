import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';

/// Fixture payloads of `GET /library/statistics` and `GET /library/annual`
/// shared by the data-layer, widget and screenshot tests of mobile/21.

Map<String, dynamic> ambient(String duo) => {'duo': duo, 'tint': '#120C18', 'ink': '#F3F0E8'};

Map<String, dynamic> _series(String key, String title, {int seconds = 3600, int chapters = 10, String duo = '#B8B2A4'}) => {
      'source_id': 'shelf',
      'series_key': key,
      'title': title,
      'cover_url': '/sources/shelf/series/$key/cover',
      'seconds_read': seconds,
      'chapters_read': chapters,
      'pages_read': chapters * 20,
      'ambient': ambient(duo),
    };

/// [days] daily rows ending [end] (a local date), the last [activeTail] days read.
List<Map<String, dynamic>> dailyRows(DateTime end, int days, {int Function(int index)? chapters}) => [
      for (var i = 0; i < days; i++)
        () {
          final d = end.subtract(Duration(days: days - 1 - i));
          final c = chapters == null ? (i % 3 == 0 ? 0 : (i % 7) + 1) : chapters(i);
          return {
            'date': '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
            'sessions': c == 0 ? 0 : 1,
            'pages_read': c * 20,
            'chapters_read': c,
            'seconds_read': c * 420,
          };
        }(),
    ];

Map<String, dynamic> statisticsJson({
  int days = 30,
  int currentDays = 12,
  int longestDays = 31,
  bool atRisk = false,
  List<int> milestonesSeen = const [7],
  DateTime? today,
  bool withShareable = true,
  bool empty = false,
  bool neverRead = false,
}) {
  final now = today ?? DateTime(2026, 9, 29);
  final lastActive = now;
  final hasHistory = !empty && !neverRead;
  return {
    'followed_total': empty ? 0 : 212,
    'favorites': 3,
    'by_reading_status': {'reading': 40, 'plan_to_read': 90, 'on_hold': 12, 'completed': 60, 'dropped': 10},
    'chapters_completed': 1904,
    'range': {'days': days, 'since': '2026-08-30T00:00:00', 'until': '2026-09-29T00:00:00', 'timezone_offset_minutes': 330, 'session_cap_seconds': 1800},
    'totals': hasHistory
        ? {'sessions': 900, 'pages_read': 48221, 'chapters_read': 1240, 'series_read': 80, 'seconds_read': 412 * 3600, 'first_session_at': '2026-07-27T04:00:00Z', 'last_session_at': '2026-09-29T04:00:00Z'}
        : {},
    'window': hasHistory ? {'sessions': 60, 'pages_read': 6812, 'chapters_read': 184, 'series_read': 23, 'seconds_read': 31 * 3600} : {},
    'streak': {
      'current_days': hasHistory ? currentDays : 0,
      'longest_days': hasHistory ? longestDays : 0,
      'last_active_date': hasHistory && currentDays > 0 ? '${lastActive.year}-${lastActive.month.toString().padLeft(2, '0')}-${lastActive.day.toString().padLeft(2, '0')}' : null,
      'at_risk': atRisk,
      'milestones_seen': milestonesSeen,
    },
    'daily': hasHistory ? dailyRows(now, days) : const [],
    'by_hour': hasHistory ? [for (var h = 0; h < 24; h++) {'hour': h, 'sessions': 1, 'pages_read': 10, 'seconds_read': h >= 21 || h <= 1 ? 3 * 3600 + h * 60 : (h == 12 ? 900 : 0)}] : const [],
    'by_source': hasHistory
        ? [
            {'source_id': 'shelf', 'name': 'MangaDex', 'sessions': 40, 'pages_read': 812, 'chapters_read': 90, 'series_read': 12, 'seconds_read': 9 * 3600},
            {'source_id': 'asura', 'name': 'Asura', 'sessions': 20, 'pages_read': 400, 'chapters_read': 50, 'series_read': 8, 'seconds_read': 5 * 3600},
          ]
        : const [],
    'by_series': hasHistory
        ? [
            for (var i = 0; i < 5; i++)
              {
                'source_id': 'shelf',
                'series_key': 'series-$i',
                'title': 'Series number ${i + 1}',
                'cover_url': '/sources/shelf/series/series-$i/cover',
                'last_read_at': '2026-09-27T10:00:00Z',
                'sessions': 10,
                'pages_read': 412 - i * 30,
                'chapters_read': 38 - i * 3,
                'seconds_read': (6 - i) * 3600,
              },
          ]
        : const [],
    'recent_sessions': hasHistory
        ? [
            {'source_id': 'shelf', 'series_key': 'series-0', 'chapter_key': 'ch-142', 'chapter_number': 142.0, 'title': 'Series number 1', 'pages_read': 34, 'seconds_read': 1500, 'started_at': '2026-09-29T15:34:00Z', 'ended_at': '2026-09-29T15:59:00Z'},
            {'source_id': 'shelf', 'series_key': 'series-1', 'chapter_key': 'ch-9', 'chapter_number': 9.0, 'title': 'Series number 2', 'pages_read': 20, 'seconds_read': 600, 'started_at': '2026-09-28T15:34:00Z', 'ended_at': '2026-09-28T15:44:00Z'},
          ]
        : const [],
    if (withShareable)
      'shareable': {
        'genre_weights': hasHistory
            ? [
                {'genre': 'Fantasy', 'weight': 0.41},
                {'genre': 'Romance', 'weight': 0.22},
                {'genre': 'Action', 'weight': 0.15},
                {'genre': 'Drama', 'weight': 0.10},
                {'genre': 'Comedy', 'weight': 0.07},
                {'genre': 'Mystery', 'weight': 0.05},
              ]
            : const [],
        'top_series': hasHistory ? [_series('series-0', 'Series number 1', seconds: 6 * 3600, chapters: 38, duo: '#7FA6D6'), _series('series-1', 'Series number 2', duo: '#D68F7F')] : const [],
        'art_series': hasHistory
            ? [
                for (var i = 0; i < 9; i++) {'source_id': 'shelf', 'series_key': 'series-$i', 'cover_url': '/sources/shelf/series/series-$i/cover', 'ambient': ambient('#7FA6D6')},
              ]
            : const [],
        'top_sources': const [],
      },
  };
}

Map<String, dynamic> annualJson({
  int year = 2026,
  bool partial = true,
  int recordedDays = 120,
  bool circle = false,
  bool voices = true,
  bool withShareable = true,
  int streakDays = 31,
}) =>
    {
      'year': year,
      'partial': partial,
      'since': '$year-01-01T00:00:00',
      'until': '$year-09-29T00:00:00',
      'recorded_days': recordedDays,
      'seconds_read': 212 * 3600,
      'chapters_read': 4812,
      'pages_read': 96000,
      'chapters_by_month': [300, 420, 510, 380, 600, 450, 700, 800, 652, 0, 0, 0],
      'top_series': [
        _series('series-0', 'Solo Leveling', seconds: 12 * 3600, chapters: 38, duo: '#7FA6D6'),
        _series('series-1', 'Tower of God', seconds: 10 * 3600, chapters: 30, duo: '#D68F7F'),
        _series('series-2', 'Omniscient Reader', seconds: 8 * 3600, chapters: 25),
        _series('series-3', 'The Beginning After The End', seconds: 6 * 3600, chapters: 20),
        _series('series-4', 'Lookism', seconds: 4 * 3600, chapters: 12),
      ],
      'genres': [
        {'genre': 'Fantasy', 'weight': 0.5},
        {'genre': 'Romance', 'weight': 0.3},
        {'genre': 'Action', 'weight': 0.2},
      ],
      'by_hour': [for (var h = 0; h < 24; h++) {'hour': h, 'seconds_read': h >= 22 || h <= 3 ? 7000 : 800}],
      'longest_streak': {'days': streakDays, 'month': 3, 'start': '$year-03-01', 'end': '$year-03-31'},
      'top_sources': [
        {'source_id': 'shelf', 'name': 'MangaDex', 'share': 0.41},
        {'source_id': 'asura', 'name': 'Asura', 'share': 0.33},
        {'source_id': 'flame', 'name': 'Flame', 'share': 0.26},
      ],
      'busiest_day': null,
      'firsts_lasts': null,
      'circle': circle
          ? [
              {'profile_id': 2, 'name': 'Riya', 'avatar_key': null, 'finished_together': ['Solo Leveling']},
            ]
          : null,
      'top_voices': voices
          ? [
              {'voice_id': 'v1', 'name': 'Marlowe', 'seconds': 7200},
              {'voice_id': 'v2', 'name': 'Isolde', 'seconds': 3600},
            ]
          : const [],
      'available_years': [2026, 2025],
      if (withShareable)
        'shareable': {
          'genre_weights': [
            {'genre': 'Fantasy', 'weight': 0.5},
            {'genre': 'Romance', 'weight': 0.3},
            {'genre': 'Action', 'weight': 0.2},
          ],
          'top_series': [_series('series-0', 'Solo Leveling', seconds: 12 * 3600, chapters: 38, duo: '#7FA6D6')],
          'art_series': [
            for (var i = 0; i < 9; i++) {'source_id': 'shelf', 'series_key': 'series-$i', 'cover_url': '/sources/shelf/series/series-$i/cover', 'ambient': ambient('#7FA6D6')},
          ],
          'top_sources': const [],
        },
    };

LibraryStatistics statisticsFixture({int days = 30, int currentDays = 12, bool atRisk = false, List<int> milestonesSeen = const [7], DateTime? today, bool empty = false, bool neverRead = false}) =>
    LibraryStatistics.fromJson(statisticsJson(days: days, currentDays: currentDays, atRisk: atRisk, milestonesSeen: milestonesSeen, today: today, empty: empty, neverRead: neverRead));

Annual annualFixture({int year = 2026, bool partial = true, int recordedDays = 120, bool circle = false, bool voices = true, bool withShareable = true, int streakDays = 31}) =>
    Annual.fromJson(annualJson(year: year, partial: partial, recordedDays: recordedDays, circle: circle, voices: voices, withShareable: withShareable, streakDays: streakDays));
