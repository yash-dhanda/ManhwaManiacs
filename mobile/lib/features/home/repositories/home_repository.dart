import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';

/// `GET /home`: the one server-composed feed both skins render.
abstract interface class HomeRepository {
  /// [contentKind] is `manga` or `novel`, or null to omit it (novels off). [refresh] skips the
  /// server's composed cache.
  Future<Result<HomeFeed>> fetch({required String? contentKind, required int tzOffsetMinutes, bool refresh = false});
}
