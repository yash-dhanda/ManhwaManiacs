import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/locked_until.dart';
import 'package:manhwamaniacs/features/library/models/known_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest_window.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/utils/notification_grouping.dart';

Map<String, dynamic> _note(Map<String, dynamic> extra) => {
      'id': 1,
      'followed_series_id': 2,
      'source_id': 'asurascans',
      'series_key': 's',
      'chapter_key': 'c370',
      'chapter_title': 'Chapter 370',
      'chapter_number': 370,
      'is_read': false,
      'created_at': '2026-11-23T10:00:00',
      ...extra,
    };

void main() {
  final now = DateTime.utc(2026, 11, 23, 10);

  group('lockedUntilOf', () {
    test('parses a Z instant as UTC', () {
      expect(lockedUntilOf('2026-11-23T14:15:24Z'), DateTime.utc(2026, 11, 23, 14, 15, 24));
    });
    test('null, absent and malformed are null', () {
      expect(lockedUntilOf(null), isNull);
      expect(lockedUntilOf(''), isNull);
      expect(lockedUntilOf('soon'), isNull);
      expect(lockedUntilOf(12), isNull);
    });
  });

  test('isLockedAt: only a future instant locks', () {
    expect(isLockedAt(DateTime.utc(2026, 11, 23, 11), now), isTrue);
    expect(isLockedAt(DateTime.utc(2026, 11, 23, 9), now), isFalse);
    expect(isLockedAt(now, now), isFalse);
    expect(isLockedAt(null, now), isFalse);
  });

  group('formatting', () {
    test('countdown', () {
      expect(formatCountdown(const Duration(hours: 3, minutes: 27, seconds: 14)), '3:27:14');
      expect(formatCountdown(const Duration(minutes: 27, seconds: 14)), '27:14');
      expect(formatCountdown(const Duration(seconds: 5)), '00:05');
      expect(formatCountdown(const Duration(hours: 1)), '1:00:00');
      expect(formatCountdown(const Duration(milliseconds: 100)), '00:01');
      expect(formatCountdown(const Duration(seconds: -4)), '00:00');
    });
    test('spoken', () {
      expect(spokenRemaining(const Duration(hours: 3, minutes: 27, seconds: 14)), '3 hours 28 minutes');
      expect(spokenRemaining(const Duration(hours: 3, minutes: 27)), '3 hours 27 minutes');
      expect(spokenRemaining(const Duration(hours: 1)), '1 hour');
      expect(spokenRemaining(const Duration(minutes: 1)), '1 minute');
      expect(spokenRemaining(const Duration(seconds: 20)), '1 minute');
      expect(spokenRemaining(Duration.zero), 'under a minute');
    });
    test('compact', () {
      expect(compactRemaining(const Duration(hours: 3, minutes: 27)), '3 h 27 min');
      expect(compactRemaining(const Duration(hours: 2)), '2 h');
      expect(compactRemaining(const Duration(minutes: 27)), '27 min');
      expect(compactRemaining(Duration.zero), '<1 min');
    });
  });

  group('models', () {
    test('notification: present, null, absent, malformed', () {
      expect(UpdateNotification.fromJson(_note({'locked_until': '2026-11-23T14:15:24Z'})).lockedUntil, DateTime.utc(2026, 11, 23, 14, 15, 24));
      expect(UpdateNotification.fromJson(_note({'locked_until': null})).lockedUntil, isNull);
      expect(UpdateNotification.fromJson(_note({})).lockedUntil, isNull);
      expect(UpdateNotification.fromJson(_note({'locked_until': 'x'})).lockedUntil, isNull);
    });

    test('past instants parse but are not locked', () {
      final n = UpdateNotification.fromJson(_note({'locked_until': '2020-01-01T00:00:00Z'}));
      expect(n.lockedUntil, isNotNull);
      expect(isLockedAt(n.lockedUntil), isFalse);
    });

    test('grouping carries lockedUntil to the chapter', () {
      final n = UpdateNotification.fromJson(_note({'locked_until': '2099-01-01T00:00:00Z'}));
      final days = groupNotifications([n], DateTime.utc(2026, 11, 23, 12));
      final ch = days.single.groups.single.chapters.single;
      expect(ch.lockedUntil, DateTime.utc(2099));
      expect(ch.isLocked(), isTrue);
    });

    test('source chapter and known chapter', () {
      final c = SourceChapterSummary.fromJson({'id': 'a', 'source_id': 's', 'series_id': 'x', 'title': 't', 'page_count': 0, 'locked_until': '2099-01-01T00:00:00Z'});
      expect(c.lockedUntil, DateTime.utc(2099));
      expect(c.isLocked(), isTrue);
      expect(SourceChapterSummary.fromJson({'id': 'a', 'source_id': 's', 'series_id': 'x', 'title': 't', 'page_count': 0}).lockedUntil, isNull);
      expect(KnownChapter.fromJson({'key': 'k', 'locked_until': 'nope'}).lockedUntil, isNull);
      final k = KnownChapter.fromJson({'key': 'k', 'locked_until': '2099-01-01T00:00:00Z'});
      expect(KnownChapter.fromJson(k.toJson()).lockedUntil, DateTime.utc(2099));
    });
  });

  group('errors', () {
    test('chapter_locked carries details.locked_until', () {
      const e = ApiError(statusCode: 423, code: 'chapter_locked', message: 'm', details: {'locked_until': '2026-11-23T14:15:24Z'});
      expect(e.isChapterLocked, isTrue);
      expect(e.isNotFound, isFalse);
      expect(e.lockedUntil, DateTime.utc(2026, 11, 23, 14, 15, 24));
    });
    test('null or missing details give a null instant', () {
      expect(const ApiError(statusCode: 423, code: 'chapter_locked', message: 'm', details: {'locked_until': null}).lockedUntil, isNull);
      expect(const ApiError(statusCode: 423, code: 'chapter_locked', message: 'm').lockedUntil, isNull);
      expect(const ApiError(statusCode: 404, code: 'x', message: 'm', details: {'locked_until': '2099-01-01T00:00:00Z'}).lockedUntil, isNull);
    });
    test('bulk window item', () {
      final w = ChapterManifestWindow.fromJson({
        'max_chapters': 20,
        'items': [
          {'chapter_key': 'a', 'status': 'error', 'manifest': null, 'error': {'code': 'chapter_locked', 'status': 423, 'message': 'Early access.', 'locked_until': '2026-11-23T14:15:24Z'}},
          {'chapter_key': 'b', 'status': 'error', 'manifest': null, 'error': {'code': 'chapter_locked', 'status': 423, 'message': 'Early.', 'locked_until': null}},
          {'chapter_key': 'c', 'status': 'error', 'manifest': null, 'error': {'code': 'other', 'message': 'x'}},
        ],
      });
      expect(w.locked['a'], DateTime.utc(2026, 11, 23, 14, 15, 24));
      expect(w.locked.containsKey('b'), isTrue);
      expect(w.locked['b'], isNull);
      expect(w.locked.containsKey('c'), isFalse);
      expect(w.errors['a'], 'Early access.');
    });
  });
}
