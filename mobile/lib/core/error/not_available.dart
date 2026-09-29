import 'package:manhwamaniacs/core/error/app_error.dart';

/// Why a series or source page has nothing to show (cinematic 8.0.10). Gated 18+ content answers
/// the same codes as removed content, so the wording never reveals it.
enum NotAvailableKind { series, source, notBrowsable }

NotAvailableKind? notAvailableKind(AppError e) {
  if (e is! ApiError) return null;
  return switch (e.code) {
    'series_not_found' => NotAvailableKind.series,
    'source_not_found' => NotAvailableKind.source,
    'source_not_browsable' => NotAvailableKind.notBrowsable,
    _ => null,
  };
}
