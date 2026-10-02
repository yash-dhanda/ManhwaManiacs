import 'dart:ui' show Rect;

import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest.dart';
import 'package:manhwamaniacs/features/reader/models/chapter_manifest_window.dart';
import 'package:manhwamaniacs/features/reader/models/reading_progress.dart';
import 'package:manhwamaniacs/features/reader/repositories/reader_repository.dart';

class ReaderRepositoryImpl implements ReaderRepository, ReaderAnalysisReports {
  const ReaderRepositoryImpl(this._dio, {this.onAnswer});

  final Dio _dio;

  /// Called after a successful `POST /reader/progress` or `/batch` with the server's streak answer (mobile/42: the streak events).
  final void Function(ProgressAnswer answer)? onAnswer;

  /// The device's UTC offset, so `extended_today` and `today_seconds` fall on the local day (clamped to the API's range).
  static Map<String, Object?> get _tz => {'tz_offset_minutes': DateTime.now().timeZoneOffset.inMinutes.clamp(-720, 840)};

  @override
  Future<Result<ChapterManifest>> manifest({
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
  }) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/reader/chapter/manifest',
        queryParameters: {
          'source': sourceId,
          'series': seriesKey,
          'chapter': chapterKey,
        },
      );
      return Ok(ChapterManifest.fromJson(r.data!));
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<ChapterManifestWindow>> manifestWindow({
    required String sourceId,
    required String seriesKey,
    required List<String> chapterKeys,
  }) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/reader/chapters/manifest',
        data: {
          'source_id': sourceId,
          'series_key': seriesKey,
          'chapter_keys': chapterKeys,
        },
      );
      return Ok(ChapterManifestWindow.fromJson(r.data ?? const {}));
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  void _answered(Map<String, dynamic> data) {
    final hook = onAnswer;
    if (hook == null) return;
    try {
      hook(ProgressAnswer.fromJson(data));
    } catch (_) {
      // A listener must never fail a save.
    }
  }

  @override
  Future<Result<ReadingProgress>> saveProgress(ProgressPush push) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/reader/progress',
        data: push.toJson(),
        queryParameters: _tz,
      );
      _answered(r.data!);
      return Ok(ReadingProgress.fromJson(r.data!));
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<({int saved, int advanced})>> saveProgressBatch(
    List<ProgressPush> pushes,
  ) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/reader/progress/batch',
        data: [for (final push in pushes) push.toJson()],
        queryParameters: _tz,
      );
      final data = r.data!;
      _answered(data);
      return Ok(
        (
          saved: data['saved'] as int,
          advanced: data['advanced'] as int,
        ),
      );
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<void>> deleteProgress({
    required String sourceId,
    required String seriesKey,
    required List<String> chapterKeys,
  }) async {
    try {
      await _dio.delete<void>('/reader/progress', data: {
        'source_id': sourceId,
        'series_key': seriesKey,
        'chapter_keys': chapterKeys,
      },);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<void>> postPageTints({
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
    required List<({int page, String hex})> tints,
  }) async {
    try {
      await _dio.post<void>('/reader/page-tints', data: {
        'source_id': sourceId,
        'series_key': seriesKey,
        'chapter_key': chapterKey,
        'tints': [for (final t in tints) {'page': t.page, 'hex': t.hex}],
      },);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<void>> postPanels({
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
    required List<({int page, List<Rect> panels})> pages,
  }) async {
    try {
      await _dio.post<void>('/reader/panels', data: {
        'source_id': sourceId,
        'series_key': seriesKey,
        'chapter_key': chapterKey,
        'pages': [
          for (final p in pages)
            {
              'page': p.page,
              'panels': [for (final r in p.panels) {'x': r.left, 'y': r.top, 'w': r.width, 'h': r.height}],
            },
        ],
      },);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<List<ReadingProgress>>> seriesProgress({
    required String sourceId,
    required String seriesKey,
  }) async {
    try {
      final r = await _dio.get<List<dynamic>>(
        '/reader/progress/series',
        queryParameters: {'source': sourceId, 'series': seriesKey},
      );
      final items = (r.data ?? [])
          .map((e) => ReadingProgress.fromJson(e as Map<String, dynamic>))
          .toList();
      return Ok(items);
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<BookmarkSyncResult>> syncBookmarks(List<BookmarkOp> ops) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/reader/bookmarks/batch',
        data: [for (final op in ops) op.toJson()],
      );
      return Ok(BookmarkSyncResult.fromJson(r.data!));
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<List<Bookmark>>> listBookmarks({
    String? sourceId,
    String? seriesKey,
    DateTime? since,
    bool includeDeleted = false,
    int? limit,
    int offset = 0,
  }) async {
    try {
      final r = await _dio.get<List<dynamic>>(
        '/reader/bookmarks',
        queryParameters: {
          if (sourceId != null) 'source': sourceId,
          if (seriesKey != null) 'series': seriesKey,
          if (since != null) 'since': since.toUtc().toIso8601String(),
          if (includeDeleted) 'include_deleted': true,
          if (limit != null) 'limit': limit,
          if (offset > 0) 'offset': offset,
        },
      );
      final items = (r.data ?? [])
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList();
      return Ok(items);
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<void>> deleteBookmark(int bookmarkId) async {
    try {
      await _dio.delete<void>('/reader/bookmarks/$bookmarkId');
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_err(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  AppError _err(DioException e) {
    if (e.error is AppError) return e.error! as AppError;
    return UnknownError(message: e.message ?? 'Dio error', cause: e);
  }
}
