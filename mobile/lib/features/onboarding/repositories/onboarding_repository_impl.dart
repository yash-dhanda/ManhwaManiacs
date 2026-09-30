import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._dio);
  final Dio _dio;

  Err<T> _err<T>(Object e) {
    if (e is DioException) return Err(e.error is AppError ? e.error! as AppError : UnknownError(message: e.message ?? 'Dio error', cause: e));
    return Err(ParseError(message: e.toString(), cause: e));
  }

  @override
  Future<Result<OnboardingCatalog>> catalog({List<String> formats = const [], List<String> genres = const [], List<String> styles = const []}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/onboarding/catalog', queryParameters: {
        if (formats.isNotEmpty) 'formats': formats.join(','),
        if (genres.isNotEmpty) 'genres': genres.join(','),
        if (styles.isNotEmpty) 'styles': styles.join(','),
      },);
      return Ok(OnboardingCatalog.fromJson(r.data ?? const {}));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Result<void>> saveTaste(int profileId, TasteUpdate body) async {
    try {
      await _dio.put<Object>('/profiles/$profileId/taste', data: body.toJson());
      return const Ok(null);
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Result<Taste?>> getTaste(int profileId) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/profiles/$profileId/taste');
      return Ok(Taste.fromJson(r.data ?? const {}));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) return const Ok(null);
      return _err(e);
    } catch (e) {
      return _err(e);
    }
  }
}
