import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';

/// The AI desk's suggested-tags line. Any failure (a 404 before backend/05
/// exists, offline, the desk closed) reads as "nothing suggested": the UI
/// omits the line rather than showing an error (DESIGN §9.1.8).
typedef SuggestedTags = ({List<String> tags, bool available, String? reason});

const SuggestedTags kNoSuggestedTags = (tags: <String>[], available: false, reason: null);

class AiRepository {
  AiRepository(this._dio);
  final Dio _dio;

  Future<SuggestedTags> suggestedTags(String sourceId, String seriesKey) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/ai/tags',
        queryParameters: {'source': sourceId, 'series': seriesKey},
      );
      final d = r.data ?? const {};
      final tags = [
        for (final t in (d['tags'] as List<dynamic>? ?? const []))
          if (t is String && t.trim().isNotEmpty) t.trim(),
      ];
      return (
        tags: tags,
        available: d['available'] as bool? ?? tags.isNotEmpty,
        reason: d['reason'] as String?,
      );
    } catch (_) {
      return kNoSuggestedTags;
    }
  }

  /// `GET /ai/similar`. Failures throw (the caller shows the §9.1.8 unavailable state).
  Future<SimilarResult> similar(SimilarQuery q) async {
    final r = await _dio.get<Map<String, dynamic>>('/ai/similar', queryParameters: q.params);
    return SimilarResult.fromJson(r.data ?? const {});
  }

  /// `POST /ai/feedback` with `signal: tag_rejected`; best effort.
  Future<void> rejectSuggestedTag(String sourceId, String seriesKey, String tag) async {
    try {
      await _dio.post<void>('/ai/feedback', data: {
        'signal': 'tag_rejected',
        'source_id': sourceId,
        'series_key': seriesKey,
        'tag': tag,
      },);
    } catch (_) {}
  }

  /// `POST /ai/feedback` (204): `not_interested`, `undo`, `liked_pick`, `tag_rejected`, `clear`.
  Future<Result<void>> sendFeedback({
    required String signal,
    int? anilistId,
    String? sourceId,
    String? seriesKey,
    String? tag,
  }) async {
    try {
      await _dio.post<void>('/ai/feedback', data: {
        'signal': signal,
        if (anilistId != null) 'anilist_id': anilistId,
        if (sourceId != null) 'source_id': sourceId,
        if (seriesKey != null) 'series_key': seriesKey,
        if (tag != null) 'tag': tag,
      },);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(e.error is AppError ? e.error! as AppError : UnknownError(message: e.message ?? 'Dio error', cause: e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }
}
