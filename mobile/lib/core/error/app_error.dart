import 'package:manhwamaniacs/core/time/locked_until.dart';

/// Unified error type for the ManhwaManiacs mobile client.
///
/// Maps 1-to-1 with the backend's `{ code, message, details? }` contract,
/// and covers network/parsing failures too.
sealed class AppError implements Exception {
  const AppError();

  String get userMessage;
}

/// 4xx / 5xx response from the ManhwaManiacs API.
final class ApiError extends AppError {
  const ApiError({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
    this.retryAfter,
  });

  final int statusCode;
  final String code;
  final String message;
  final Object? details;

  /// The `Retry-After` header as a duration, when the server sent one.
  final Duration? retryAfter;

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isServerError => statusCode >= 500;

  /// An early-access chapter (HTTP 423): real, listed, but not open to this
  /// reader yet. Not a missing chapter and not a session problem.
  bool get isChapterLocked => code == 'chapter_locked';

  /// When a locked chapter opens to everyone (`details.locked_until`), or null
  /// when the source did not say. Always null for any other error.
  DateTime? get lockedUntil {
    if (!isChapterLocked) return null;
    final d = details;
    return d is Map ? lockedUntilOf(d['locked_until']) : null;
  }

  @override
  String get userMessage => message;

  @override
  String toString() => 'ApiError($statusCode, $code): $message';
}

/// No network connection or DNS failure.
final class NetworkError extends AppError {
  const NetworkError({required this.message, this.cause, this.host});

  final String message;
  final Object? cause;

  /// Host the request was aimed at, when known. Surfaced to the user so a
  /// connectivity failure names the server it couldn't reach (aids support).
  final String? host;

  @override
  String get userMessage => host == null || host!.isEmpty
      ? 'Network error — check your connection.'
      : "Can't reach the server at $host — check your connection.";

  @override
  String toString() => 'NetworkError: $message';
}

/// Request timed out.
final class TimeoutError extends AppError {
  const TimeoutError();

  @override
  String get userMessage => 'Request timed out — try again.';

  @override
  String toString() => 'TimeoutError';
}

/// Client-side validation failure (e.g. a malformed or disallowed input).
///
/// Unlike [UnknownError], its [userMessage] is the specific [message] so the UI
/// can tell the user exactly what to fix.
final class ValidationError extends AppError {
  const ValidationError(this.message);

  final String message;

  @override
  String get userMessage => message;

  @override
  String toString() => 'ValidationError: $message';
}

/// JSON decoding or model mapping failure.
final class ParseError extends AppError {
  const ParseError({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String get userMessage => 'Unexpected response format.';

  @override
  String toString() => 'ParseError: $message';
}

/// Catch-all for unexpected errors.
final class UnknownError extends AppError {
  const UnknownError({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String get userMessage => 'Something went wrong — please try again.';

  @override
  String toString() => 'UnknownError: $message';
}
