import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/sse.dart';

/// `/ai/recap/*` on the app's authenticated dio client (Bearer, `X-Profile-Id`, `X-App-Version`).
class RecapRepository {
  RecapRepository(this._dio);
  final Dio _dio;

  Map<String, String> _q(RecapKey k) => {'source': k.source, 'series': k.series, 'to': k.to};

  Future<RecapAvailability> availability(RecapKey k, {CancelToken? cancel}) async {
    final r = await _dio.get<Map<String, dynamic>>('/ai/recap/availability', queryParameters: _q(k), cancelToken: cancel);
    return RecapAvailability.tryParse(r.data ?? const {}) ?? const RecapAvailability(available: false);
  }

  /// A JSON answer maps to [RecapNone]; an event stream to [RecapStream].
  Future<RecapOpen> open(RecapKey k, {CancelToken? cancel}) async {
    final Response<ResponseBody> r;
    try {
      r = await _dio.get<ResponseBody>(
        '/ai/recap',
        queryParameters: _q(k),
        cancelToken: cancel,
        options: Options(responseType: ResponseType.stream, headers: {'Accept': 'text/event-stream, application/json'}),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) return const RecapOpen.none('not_found');
      final offline = e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout;
      return RecapOpen.none(offline ? 'offline' : 'error');
    }
    final body = r.data!;
    final type = (r.headers.value('content-type') ?? '').toLowerCase();
    if (type.contains('json')) {
      final text = await utf8.decodeStream(body.stream.map<List<int>>((c) => c));
      Map<String, dynamic> j = const {};
      try {
        final d = jsonDecode(text);
        if (d is Map<String, dynamic>) j = d;
      } catch (_) {}
      final after = int.tryParse(r.headers.value('retry-after') ?? '');
      return RecapOpen.none((j['reason'] ?? j['code'] ?? 'error') as String, retryAfter: after);
    }
    return RecapOpen.stream(_events(body.stream));
  }

  Stream<RecapEvent> _events(Stream<List<int>> bytes) async* {
    await for (final e in parseSse(bytes)) {
      Map<String, dynamic> j = const {};
      try {
        final d = jsonDecode(e.data);
        if (d is Map<String, dynamic>) j = d;
      } catch (_) {}
      switch (e.event) {
        case 'meta':
          yield RecapMeta.fromJson(j);
        case 'delta':
          yield RecapDelta((j['text'] as String?) ?? '');
        case 'done':
          yield RecapDone(generatedAt: DateTime.tryParse((j['generated_at'] as String?) ?? ''));
        case 'error':
          yield RecapError((j['code'] as String?) ?? 'ai_failed', (j['message'] as String?) ?? '', retryAfter: (j['retry_after'] as num?)?.toInt());
      }
    }
  }
}
