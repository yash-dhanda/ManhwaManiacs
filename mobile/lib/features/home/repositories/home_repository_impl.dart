import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<Result<HomeFeed>> fetch({required String? contentKind, required int tzOffsetMinutes, bool refresh = false}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/home', queryParameters: {
        if (contentKind != null) 'content_kind': contentKind,
        'tz_offset_minutes': tzOffsetMinutes,
        if (refresh) 'refresh': 1,
      },);
      return Ok(HomeFeed.fromJson(r.data!));
    } on DioException catch (e) {
      return Err(e.error is AppError ? e.error! as AppError : UnknownError(message: e.message ?? 'Dio error', cause: e));
    } catch (e) {
      return Err(ParseError(message: e.toString(), cause: e));
    }
  }
}
