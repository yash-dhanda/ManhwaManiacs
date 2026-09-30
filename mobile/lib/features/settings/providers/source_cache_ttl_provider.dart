import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// `source_cache_ttl_minutes` on `GET/PUT /settings` (instance-wide, admin, at least 5).
final sourceCacheTtlProvider = AsyncNotifierProvider<SourceCacheTtlNotifier, int>(SourceCacheTtlNotifier.new, name: 'sourceCacheTtl');

const kMinSourceCacheTtl = 5;

/// "At least 5 minutes." for [text] under the floor or not a number, else null.
String? sourceCacheTtlError(String text) {
  final n = int.tryParse(text.trim());
  return n == null || n < kMinSourceCacheTtl ? 'At least 5 minutes.' : null;
}

class SourceCacheTtlNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final r = await ref.watch(dioProvider).get<Map<String, dynamic>>('/settings');
    return (r.data?['source_cache_ttl_minutes'] as num?)?.toInt() ?? 360;
  }

  /// Null on success, the error otherwise.
  Future<AppError?> save(int minutes) async {
    if (minutes < kMinSourceCacheTtl) return const ValidationError('At least 5 minutes.');
    try {
      await ref.read(dioProvider).put<Map<String, dynamic>>('/settings', data: {'source_cache_ttl_minutes': minutes});
      state = AsyncData(minutes);
      return null;
    } on DioException catch (e) {
      return e.error is AppError ? e.error! as AppError : UnknownError(message: e.message ?? 'Could not save.', cause: e);
    }
  }
}
