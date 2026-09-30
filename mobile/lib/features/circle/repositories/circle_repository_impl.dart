import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository.dart';

class CircleRepositoryImpl implements CircleRepository {
  CircleRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<Result<CircleSeriesData?>> series({required String sourceId, required String seriesKey}) async {
    final query = {'source': sourceId, 'series': seriesKey};
    try {
      final r = await _dio.get<Map<String, dynamic>>('/circle/series', queryParameters: query);
      final readers = [
        for (final e in (r.data?['readers'] as List? ?? const []))
          if (e is Map) CircleReader.fromJson(Map<String, dynamic>.from(e)),
      ];
      var chapters = const <CircleChapterReactions>[];
      try {
        final x = await _dio.get<Map<String, dynamic>>('/circle/reactions', queryParameters: query);
        chapters = [
          for (final e in (x.data?['chapters'] as List? ?? const []))
            if (e is Map) CircleChapterReactions.fromJson(Map<String, dynamic>.from(e)),
        ];
      } on DioException {
        // The readers alone still answer who is where.
      }
      return Ok(CircleSeriesData(readers: readers, chapters: chapters));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Ok(null);
      if (e.error is AppError) return Err(e.error! as AppError);
      return Err(UnknownError(message: e.message ?? 'Dio error', cause: e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }
}
