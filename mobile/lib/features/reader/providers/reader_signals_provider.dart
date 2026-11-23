import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';

/// When a chapter fetch was refused with a 429 and when the reader may ask again (null: not
/// limited). Set by the two reader entry screens' chapter loaders, read by the engine's footer
/// to draw the live-countdown band.
final readerRateLimitedUntilProvider = StateProvider<DateTime?>((ref) => null, name: 'readerRateLimitedUntil');

/// The wait a 429 asked for (10 s when the server named none), or null for any other error.
Duration? rateLimitWait(Object error) =>
    error is ApiError && error.statusCode == 429 ? (error.retryAfter ?? const Duration(seconds: 10)) : null;

/// The next chapter the strip could not open because it is early access, with when it opens. Set by the two reader entry
/// screens' chapter loaders (a null instant means the source did not say), cleared when a chapter loads; read by a skin's
/// "next chapter did not load" band so it can say "Opens in 3:27:14" instead of offering a retry that cannot work yet.
final readerLockedNextProvider = StateProvider<({String chapterKey, DateTime? lockedUntil, String message, String? sourceId})?>((ref) => null, name: 'readerLockedNext');
