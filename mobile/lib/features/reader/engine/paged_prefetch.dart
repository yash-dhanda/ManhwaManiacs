import 'package:manhwamaniacs/core/network/request_limiter.dart';

/// Paged prefetch priority (cinematic 15.6): the visible view and the next are P0, the rest ahead P3.
RequestPriority pagedPrefetchPriority(int viewsAhead) => viewsAhead <= 1 ? RequestPriority.p0 : RequestPriority.p3;

/// Runs [warm] holding a sources-limiter slot at [priority]; the slot is always released.
Future<void> warmThroughLimiter(RequestLimiter limiter, RequestPriority priority, Future<void> Function() warm, {Future<void>? cancel}) async {
  final ticket = await limiter.acquire(priority, cancel: cancel);
  try {
    await warm();
  } finally {
    limiter.release(ticket);
  }
}
