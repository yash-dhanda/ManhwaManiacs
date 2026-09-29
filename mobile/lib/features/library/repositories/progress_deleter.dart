import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// `DELETE /reader/progress`: Mark unread. The server takes 200 chapter keys
/// at a time, so [deleteProgress] chunks. TODO(mobile/08): mobile/08 owns
/// `deleteProgress` on the reader repository; this stands in until it lands.
class ProgressDeleter {
  const ProgressDeleter(this._dio);
  final Dio _dio;

  Future<Result<void>> deleteProgress({
    required String sourceId,
    required String seriesKey,
    required List<String> chapterKeys,
  }) async {
    try {
      for (final chunk in chunked(chapterKeys)) {
        await _dio.delete<void>('/reader/progress', data: {
          'source_id': sourceId,
          'series_key': seriesKey,
          'chapter_keys': chunk,
        },);
      }
      return const Ok(null);
    } on DioException catch (e) {
      return Err(e.error is AppError
          ? e.error! as AppError
          : UnknownError(message: e.message ?? 'Dio error', cause: e),);
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }
}

final progressDeleterProvider =
    Provider<ProgressDeleter>((ref) => ProgressDeleter(ref.watch(dioProvider)));
