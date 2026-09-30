import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// The Circle endpoints the reader uses. `mobile/22` extends this with the rest.
abstract interface class CircleRepository {
  /// `GET /circle/series` and `GET /circle/reactions` for one series; null when the Circle is not
  /// deployed (404). A failed reactions call leaves the readers.
  Future<Result<CircleSeriesData?>> series({required String sourceId, required String seriesKey});
}
