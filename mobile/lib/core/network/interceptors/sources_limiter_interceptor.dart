import 'package:dio/dio.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';

/// Gates `/sources…` requests through the shared [RequestLimiter]. Every
/// existing call is P1 (never waits) unless it sets `extra['mm.priority']`.
class SourcesLimiterInterceptor extends Interceptor {
  SourcesLimiterInterceptor(this.limiter);

  final RequestLimiter limiter;
  static const _ticketKey = 'mm.limiter.ticket';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.path.startsWith('/sources')) {
      final p = options.extra['mm.priority'] as RequestPriority? ?? RequestPriority.p1;
      options.extra[_ticketKey] = await limiter.acquire(p);
    }
    handler.next(options);
  }

  void _end(RequestOptions o, Response<dynamic>? r) {
    final t = o.extra.remove(_ticketKey);
    if (t is LimiterTicket) limiter.release(t);
    if (r?.statusCode == 429) {
      limiter.pause(parseRetryAfter(r!.headers.value('retry-after')) ?? const Duration(seconds: 12));
    }
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _end(response.requestOptions, response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _end(err.requestOptions, err.response);
    handler.next(err);
  }
}
