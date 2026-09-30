import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository.dart';

class CircleRepositoryImpl implements CircleRepository {
  CircleRepositoryImpl(this._dio);
  final Dio _dio;

  AppError _err(DioException e) => e.error is AppError ? e.error! as AppError : UnknownError(message: e.message ?? 'Dio error', cause: e);

  Future<Result<T>> _run<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  static List<Map<String, dynamic>> _maps(Object? o) => [for (final e in (o as List? ?? const [])) if (e is Map) Map<String, dynamic>.from(e)];

  @override
  Future<Result<CircleSeriesData?>> series({required String sourceId, required String seriesKey}) async {
    final query = {'source': sourceId, 'series': seriesKey};
    try {
      final r = await _dio.get<Map<String, dynamic>>('/circle/series', queryParameters: query);
      final readers = [for (final e in _maps(r.data?['readers'])) CircleReader.fromJson(e)];
      final followers = [for (final e in _maps(r.data?['followers'])) ProfileRef.fromJson(e)];
      var chapters = const <ChapterReactions>[];
      try {
        final x = await _dio.get<Map<String, dynamic>>('/circle/reactions', queryParameters: query);
        chapters = [for (final e in _maps(x.data?['chapters'])) ChapterReactions.fromJson(e)];
      } on DioException {
        // The readers alone still answer who is where.
      }
      return Ok(CircleSeriesData(readers: readers, chapters: chapters, followers: followers));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Ok(null);
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<List<CircleMember>>> members({String? sourceId, String? seriesKey}) => _run(() async {
        final r = await _dio.get<List<dynamic>>('/circle/members', queryParameters: {
          'tz_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
          if (sourceId != null && seriesKey != null) ...{'source_id': sourceId, 'series_key': seriesKey},
        },);
        return [for (final e in _maps(r.data)) CircleMember.fromJson(e)];
      });

  @override
  Future<Result<MemberPage>> member(int profileId) => _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/circle/members/$profileId');
        return MemberPage.fromJson(r.data ?? const {});
      });

  @override
  Future<Result<FeedPage>> feed({String? cursor, int limit = 50, String? kind, int? profileId}) => _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/circle/feed', queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
          if (kind != null) 'kind': kind,
          if (profileId != null) 'profile_id': profileId,
        },);
        return FeedPage(items: [for (final e in _maps(r.data?['items'])) FeedItem.fromJson(e)], nextCursor: r.data?['next_cursor'] as String?);
      });

  @override
  Future<Result<List<ChapterReactions>>> reactions({required String sourceId, required String seriesKey}) => _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/circle/reactions', queryParameters: {'source': sourceId, 'series': seriesKey});
        return [for (final e in _maps(r.data?['chapters'])) ChapterReactions.fromJson(e)];
      });

  @override
  Future<Result<ChapterReactions>> react({required String sourceId, required String seriesKey, required String chapterKey, required ReactionKind kind}) => _run(() async {
        final r = await _dio.post<Map<String, dynamic>>('/circle/reactions', data: {'source_id': sourceId, 'series_key': seriesKey, 'chapter_key': chapterKey, 'kind': kind.wire});
        return ChapterReactions.fromJson(r.data ?? const {});
      });

  @override
  Future<Result<void>> unreact({required String sourceId, required String seriesKey, required String chapterKey}) => _run(() async {
        await _dio.delete<void>('/circle/reactions', data: {'source_id': sourceId, 'series_key': seriesKey, 'chapter_key': chapterKey});
      });

  @override
  Future<Result<List<Letter>>> letters() => _run(() async {
        final r = await _dio.get<List<dynamic>>('/circle/letters', queryParameters: {'box': 'inbox'});
        return [for (final e in _maps(r.data)) Letter.fromJson(e)];
      });

  @override
  Future<Result<void>> sendLetter({required List<int> toProfileIds, required String sourceId, required String seriesKey, String? note}) => _run(() async {
        final n = note?.trim();
        await _dio.post<void>('/circle/letters', data: {'to_profile_ids': toProfileIds, 'source_id': sourceId, 'series_key': seriesKey, if (n != null && n.isNotEmpty) 'note': n});
      });

  @override
  Future<Result<Letter>> patchLetter(int id, LetterState state) => _run(() async {
        final r = await _dio.patch<Map<String, dynamic>>('/circle/letters/$id', data: {'state': state.wire});
        return Letter.fromJson(r.data ?? const {});
      });

  @override
  Future<Result<Sharing>> sharing(int profileId) => _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/profiles/$profileId/sharing');
        return Sharing.fromJson(r.data ?? const {});
      });

  @override
  Future<Result<Sharing>> patchSharing(int profileId, Map<String, Object?> partial) => _run(() async {
        final r = await _dio.patch<Map<String, dynamic>>('/profiles/$profileId/sharing', data: partial);
        return Sharing.fromJson(r.data ?? const {});
      });

  @override
  Future<Result<void>> clearActivity() => _run(() async {
        await _dio.delete<void>('/circle/activity');
      });

  @override
  Future<Result<({List<SharedShelf> collections, List<SharedShelf> sharedWithMe})>> collectionsWithShared() => _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/library/collections', queryParameters: {'include_shared': true});
        return (
          collections: [for (final e in _maps(r.data?['collections'])) SharedShelf.fromJson(e)],
          sharedWithMe: [for (final e in _maps(r.data?['shared_with_me'])) SharedShelf.fromJson(e)],
        );
      });

  @override
  Future<Result<SharedShelfDetail>> shelfDetail(int id) => _run(() async {
        final r = await _dio.get<Map<String, dynamic>>('/library/collections/$id');
        return SharedShelfDetail.fromJson(r.data ?? const {});
      });

  @override
  Future<Result<void>> shareCollection(int id, {required List<int> profileIds, required String mode}) => _run(() async {
        await _dio.post<void>('/library/collections/$id/share', data: {'profile_ids': profileIds, 'mode': mode});
      });

  @override
  Future<Result<void>> unshareMember(int id, String profileRef) => _run(() async {
        await _dio.delete<void>('/library/collections/$id/share/$profileRef');
      });
}
