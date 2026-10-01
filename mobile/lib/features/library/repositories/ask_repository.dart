import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';

/// The Ask box and the genre-filtered world picks (glass 9.1.2). Separate from [LibraryRepository] so Cinematic's calls and every
/// fake of that interface stay as they are. Omitted fields are not sent.
class AskRepository {
  const AskRepository(this._dio);
  final Dio _dio;

  static const _slow = Duration(seconds: 210);

  /// `POST /library/suggest`: answered from the reader's own sources.
  Future<Result<WorldSuggestResponse>> librarySuggest({required String prompt, int? limit, bool? useTaste, String? contentKind, CancelToken? cancel}) => _run(
        () => _dio.post<Map<String, dynamic>>(
          '/library/suggest',
          data: {'prompt': prompt, if (limit != null) 'limit': limit, if (useTaste != null) 'use_taste': useTaste, if (contentKind != null) 'content_kind': contentKind},
          cancelToken: cancel,
          options: Options(receiveTimeout: _slow),
        ),
        (d) => WorldSuggestResponse(
          items: [for (final raw in (d['items'] as List? ?? const [])) if (raw is Map<String, dynamic>) WorldItem.fromShelfJson(raw)],
          dropped: (d['dropped'] as num?)?.toInt() ?? 0,
          model: (d['model'] as String?) ?? '',
          remainingToday: (d['remaining_today'] as num?)?.toInt() ?? 0,
        ),
      );

  /// `POST /library/world/suggest`: answered from the whole medium.
  Future<Result<WorldSuggestResponse>> worldSuggest({required String prompt, int? limit, bool? useTaste, CancelToken? cancel}) => _run(
        () => _dio.post<Map<String, dynamic>>(
          '/library/world/suggest',
          data: {'prompt': prompt, if (limit != null) 'limit': limit, if (useTaste != null) 'use_taste': useTaste},
          cancelToken: cancel,
          options: Options(receiveTimeout: _slow),
        ),
        WorldSuggestResponse.fromJson,
      );

  /// `GET /library/world/recommendations?genre=`.
  Future<Result<WorldRecommendations>> worldRecommendations({String? genre, CancelToken? cancel}) => _run(
        () => _dio.get<Map<String, dynamic>>(
          '/library/world/recommendations',
          queryParameters: {if (genre != null && genre.isNotEmpty) 'genre': genre},
          cancelToken: cancel,
          options: Options(receiveTimeout: const Duration(seconds: 90)),
        ),
        WorldRecommendations.fromJson,
      );

  Future<Result<T>> _run<T>(Future<Response<Map<String, dynamic>>> Function() call, T Function(Map<String, dynamic>) parse) async {
    try {
      final r = await call();
      return Ok(parse(r.data ?? const {}));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      return Err(e.error is AppError ? e.error! as AppError : UnknownError(message: e.message ?? 'Dio error', cause: e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }
}
