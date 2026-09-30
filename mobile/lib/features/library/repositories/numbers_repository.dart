import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';

/// The Numbers, the streak milestones and The Annual (cinematic 9.2.7).
///
/// A repository of its own so `LibraryRepository` keeps its shape: ten test
/// fakes implement that interface in full and stay valid.
abstract interface class NumbersRepository {
  /// `GET /library/statistics?days=&tz_offset_minutes=`.
  Future<Result<LibraryStatistics>> statistics({required int days});

  /// `GET /library/annual?year=&tz_offset_minutes=`.
  Future<Result<Annual>> annual(int year);

  /// `POST /library/statistics/milestones/{days}/seen` (204).
  Future<Result<void>> markMilestoneSeen(int days);
}

/// The device's UTC offset, clamped to the API's accepted range
/// (UTC-12:00..UTC+14:00) so a mis-zoned device degrades to UTC-ish bucketing
/// rather than a 422. Always sent: the server refuses to guess where a day starts.
int clampedTzOffsetMinutes([Duration? offset]) =>
    (offset ?? DateTime.now().timeZoneOffset).inMinutes.clamp(-720, 840);

class NumbersRepositoryImpl implements NumbersRepository {
  const NumbersRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<LibraryStatistics>> statistics({required int days}) => _get(
        '/library/statistics',
        {'days': days, 'tz_offset_minutes': clampedTzOffsetMinutes()},
        LibraryStatistics.fromJson,
      );

  @override
  Future<Result<Annual>> annual(int year) => _get(
        '/library/annual',
        {'year': year, 'tz_offset_minutes': clampedTzOffsetMinutes()},
        Annual.fromJson,
      );

  @override
  Future<Result<void>> markMilestoneSeen(int days) async {
    try {
      await _dio.post<void>('/library/statistics/milestones/$days/seen');
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_error(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  Future<Result<T>> _get<T>(
    String path,
    Map<String, Object?> query,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return Ok(fromJson(response.data ?? const {}));
    } on DioException catch (e) {
      return Err(_error(e));
    } catch (e) {
      return Err(UnknownError(message: e.toString(), cause: e));
    }
  }

  AppError _error(DioException e) {
    final inner = e.error;
    if (inner is AppError) return inner;
    final offline = e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
    return offline
        ? NetworkError(message: e.message ?? 'Network error', cause: e)
        : UnknownError(message: e.message ?? 'Dio error', cause: e);
  }
}
