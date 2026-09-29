import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/at_risk.dart';
import 'package:manhwamaniacs/features/home/utils/local_feed.dart';
import 'package:manhwamaniacs/features/home/utils/offline_edition.dart';
import 'package:manhwamaniacs/features/library/utils/all_followed.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

enum HomeFeedState { loading, ready, empty, unavailable }

/// Where the feed came from: the server, the on-device composer, or the offline edition.
enum HomeFeedOrigin { server, local, offline }

/// [retryAfter] is the server's `Retry-After` when `GET /home` answered 429.
typedef HomeFeedView = ({HomeFeedState state, HomeFeed? feed, HomeFeedOrigin origin, bool offline, Duration? retryAfter});

/// The skin-neutral Tonight / Home feed (both skins read it). Rebuilds on a profile switch, a gate
/// change or a mode change (the web key `["home", profileId, matureEnabled, contentKind]`), and
/// stays alive for 10 minutes after the last listener to match the server's cache.
final homeFeedProvider = AsyncNotifierProvider.autoDispose<HomeFeedController, HomeFeedView>(HomeFeedController.new, name: 'homeFeed');

class HomeFeedController extends AutoDisposeAsyncNotifier<HomeFeedView> {
  @override
  Future<HomeFeedView> build() {
    final link = ref.keepAlive();
    final timer = Timer(const Duration(minutes: 10), link.close);
    ref.onDispose(timer.cancel);
    ref.watch(activeProfileProvider.select((p) => p?.id));
    ref.watch(matureGateOpenProvider);
    ref.watch(contentModeControllerProvider);
    ref.watch(novelsEnabledProvider);
    return _load(refresh: false);
  }

  /// Refetches (skipping the server's composed cache); the previous feed stays until it settles.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _load(refresh: true));
  }

  bool _sourceMature(String sourceId) {
    final pins = ref.read(sourcePinsProvider).valueOrNull?.pins ?? const [];
    for (final p in pins) {
      if (p.sourceId == sourceId) return p.mature;
    }
    return false;
  }

  Future<HomeFeedView> _load({required bool refresh}) async {
    final now = ref.read(clockProvider)();
    final novelsOn = ref.read(novelsEnabledProvider);
    final mode = ref.read(contentModeControllerProvider);
    final kind = novelsOn ? mode.wire : null;
    final storeKind = mode.wire;
    final result = await ref.read(homeRepositoryProvider).fetch(contentKind: kind, tzOffsetMinutes: now.timeZoneOffset.inMinutes, refresh: refresh);

    if (result.isOk) {
      final feed = applyAtRisk(result.value, now);
      try {
        saveLastFeed(ref, storeKind, feed, sourceMature: _sourceMature, now: now);
      } catch (_) {
        // The offline copy is best effort.
      }
      return _view(feed, HomeFeedOrigin.server);
    }
    final error = result.error;
    if (error is NetworkError || error is TimeoutError) {
      List<DownloadedSeriesGroup> saved = const [];
      try {
        saved = await ref.read(downloadedSeriesProvider.future);
      } catch (_) {}
      final feed = composeOfflineEdition(
        lastFeed: readLastFeed(ref, storeKind),
        saved: saved,
        matureEnabled: ref.read(matureGateOpenProvider),
        now: now,
      );
      return (state: HomeFeedState.ready, feed: feed, origin: HomeFeedOrigin.offline, offline: true, retryAfter: null);
    }
    return _local(now, storeKind, retryAfter: error is ApiError && error.statusCode == 429 ? (error.retryAfter ?? const Duration(seconds: 10)) : null);
  }

  Future<HomeFeedView> _local(DateTime now, String kind, {Duration? retryAfter}) async {
    final lib = ref.read(libraryRepositoryProvider);
    T? ok<T>(Result<T> r) => r.isOk ? r.value : null;
    final fCont = lib.continueReading(limit: 12);
    final fRecent = lib.recentlyUpdated(limit: 12);
    final fWorld = lib.worldRecommendations();
    final fFollowed = listAllFollowed(lib);
    final fStats = lib.statistics();
    final fPins = ref.read(sourcePinsProvider.future).then<List<SourcePin>?>((s) => s.pins, onError: (_) => null);
    final world = ok(await fWorld);
    final scope = ref.read(contentModeScopeProvider);
    final inputs = LocalFeedInputs(
      continueRows: ok(await fCont),
      recentlyUpdated: ok(await fRecent),
      world: world,
      worldReason: world == null ? 'ai_failed' : world.unavailableReason,
      followed: ok(await fFollowed),
      stats: ok(await fStats),
      pins: await fPins,
      contentKind: kind,
      inMode: scope.novelsEnabled ? (id) => scope.modeOf(id) == scope.mode : null,
    );
    if (inputs.allFailed) return (state: HomeFeedState.unavailable, feed: null, origin: HomeFeedOrigin.local, offline: false, retryAfter: retryAfter);
    return _view(applyAtRisk(composeLocalFeed(inputs, now), now), HomeFeedOrigin.local);
  }

  HomeFeedView _view(HomeFeed feed, HomeFeedOrigin origin) {
    final empty = feed.cover == null && !feed.sections.any((s) => s.hasItems);
    return (state: empty ? HomeFeedState.empty : HomeFeedState.ready, feed: feed, origin: origin, offline: false, retryAfter: null);
  }
}
