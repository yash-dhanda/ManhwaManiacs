import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/series_detail_provider.dart';
import 'package:manhwamaniacs/features/library/utils/series_identity.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_view.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `/sources/:sourceId/series/:seriesKey`. Finds the follow row by series
/// identity and renders the shared [FeatureView].
class FeatureScreen extends ConsumerWidget {
  const FeatureScreen({super.key, required this.sourceId, required this.seriesKey, this.chapter, this.tab, this.sheet});

  final String sourceId;
  final String seriesKey;
  final String? chapter;
  final String? tab;

  /// `?sheet=audiobook`: opens the owner's Audiobook sheet on the Book page.
  final String? sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(updatesProvider.select((s) => s.valueOrNull?.followed));
    final row = followFor(followed ?? const <FollowedSeries>[], sourceId, seriesKey);
    return FeatureView(
        sourceId: sourceId, seriesKey: seriesKey, followed: row, focusChapter: chapter, tab: tab, sheet: sheet,);
  }
}

/// `/library/:followedId`: the same [FeatureView], located by follow id (cinematic 8.0.10). The
/// follow cache answers at once when it holds the row; otherwise [seriesDetailProvider] resolves
/// it (server first, then the device), with the feature galley while it loads. A series that is
/// gone, unknown or hidden by the 18+ gate is `NOT IN THIS ISSUE`; any other failure is a
/// `CORRECTION` with `Try again`.
class FeatureByFollowScreen extends ConsumerStatefulWidget {
  const FeatureByFollowScreen({super.key, required this.followedId});
  final int followedId;

  @override
  ConsumerState<FeatureByFollowScreen> createState() => _FeatureByFollowScreenState();
}

class _FeatureByFollowScreenState extends ConsumerState<FeatureByFollowScreen> {
  /// The row this route resolved to. Once known the page stays on that series: an unfollow takes the
  /// row out of the cache (and the server answers 404 for its id), an undo follows under a new id,
  /// so from here on the follow is found by series identity like on [FeatureScreen].
  FollowedSeries? _pinned;

  @override
  Widget build(BuildContext context) {
    final followedId = widget.followedId;
    final cached = ref.watch(updatesProvider.select((s) => s.valueOrNull?.followed));
    if (_pinned == null) {
      for (final f in cached ?? const <FollowedSeries>[]) {
        if (f.id == followedId) _pinned = f;
      }
    }
    final pin = _pinned;
    if (pin != null) return FeatureView(sourceId: pin.sourceId, seriesKey: pin.seriesKey, followed: pinnedFollow(pin, cached));
    return ref.watch(seriesDetailProvider(followedId)).when(
          loading: () => const FeatureGalley(),
          data: (v) {
            _pinned = v.series;
            return FeatureView(sourceId: v.series.sourceId, seriesKey: v.series.seriesKey, followed: pinnedFollow(v.series, cached));
          },
          error: (e, _) {
            if (e is ApiError && (e.statusCode == 404 || e.code == 'series_not_found')) return const FeatureNotAvailable();
            return FeatureNotice(
              kicker: 'CORRECTION',
              correction: true,
              headline: "Couldn't load this series.",
              primaryLabel: 'Try again',
              onPrimary: () => ref.invalidate(seriesDetailProvider(followedId)),
              quietLabel: 'Back to library',
              onQuiet: () => context.go(Routes.library()),
            );
          },
        );
  }
}
