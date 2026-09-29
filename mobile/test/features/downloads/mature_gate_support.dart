// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_stamper.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/followed_series_cache.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/downloads_test_support.dart';

/// The gate as a switch the test flips.
final testGate = StateProvider<bool>((ref) => true);

class FixedQueue extends DownloadQueueController {
  @override
  DownloadQueueState build() => const DownloadQueueState();
}

FollowedSeries follow(int id, String key, {required String rating, bool? override, String content = 'safe'}) => FollowedSeries(
      id: id,
      sourceId: 'src',
      seriesKey: key,
      title: key,
      coverUrl: '',
      isFavorite: false,
      readingStatus: 'reading',
      notify: false,
      sortOrder: id,
      contentRating: content,
      rating: rating,
      matureOverride: override,
      chapterCount: 3,
    );

class GateRig {
  GateRig(this.container, this.harness, this.prefs);
  final ProviderContainer container;
  final TestDownloadsHarness harness;
  final SharedPreferences prefs;
  static const scope = 'u1p1';

  Future<void> writeFollows(List<FollowedSeries> rows) => writeCachedFollowedSeries(prefs, followedSeriesCacheKeyFor(scope), rows);
  void gate(bool open) => container.read(testGate.notifier).state = open;
}

Future<GateRig> gateRig({List<FollowedSeries> follows = const [], List<Override> extra = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final harness = await TestDownloadsHarness.create();
  late ProviderContainer container;
  container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    activeDownloadsScopeIdProvider.overrideWithValue(GateRig.scope),
    sourcesListProvider.overrideWith((ref) async => const []),
    ...extra,
    matureGateOpenProvider.overrideWith((ref) => ref.watch(testGate)),
    downloadQueueControllerProvider.overrideWith(FixedQueue.new),
    downloadsStoreProvider.overrideWith(
      (ref) => harness.storeFor(GateRig.scope, matureResolver: (s, k) => ref.read(matureStamperProvider).resolve(s, k)),
    ),
  ],);
  final rig = GateRig(container, harness, prefs);
  await rig.writeFollows(follows);
  return rig;
}
