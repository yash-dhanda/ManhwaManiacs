import 'package:manhwamaniacs/core/error/app_error.dart';

/// What a data screen shows (glass 7.24): the skeleton, the offline lens, the error lens, the empty lens, or its content.
enum GlassViewState { loading, offline, error, empty, content }

/// Data wins over everything (stale rows stay on screen); then loading; offline when the error is a `NetworkError` or
/// `TimeoutError`, or the device is offline with nothing to show; then any other error; else empty.
GlassViewState resolveViewState({required bool isLoading, required bool hasData, AppError? error, required bool online}) {
  if (hasData) return GlassViewState.content;
  if (isLoading) return GlassViewState.loading;
  if (error is NetworkError || error is TimeoutError || !online) return GlassViewState.offline;
  if (error != null) return GlassViewState.error;
  return GlassViewState.empty;
}
