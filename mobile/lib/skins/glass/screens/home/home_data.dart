import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/all_followed.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// Every series the active profile follows, for "Recently added to your library" (current mode only is applied by the caller).
final homeFollowedProvider = FutureProvider.autoDispose<List<FollowedSeries>>((ref) async {
  ref.watch(activeProfileProvider.select((p) => p?.id));
  ref.watch(contentModeControllerProvider);
  // Re-read with every new feed (pull to refresh, the 18+ gate, a read): the Home branch stays mounted, so nothing else would.
  ref.watch(homeFeedProvider.select((v) => v.valueOrNull?.feed));
  final r = await listAllFollowed(ref.read(libraryRepositoryProvider));
  if (r.isErr) throw r.error;
  return r.value;
}, name: 'homeFollowed',);

/// True while the AI rails are being computed (their headers show the orbit and half-speed skeletons); the screen also treats a reload with
/// a previous feed as thinking. A seam for the captures.
final homeAiThinkingProvider = StateProvider<bool>((ref) => false, name: 'homeAiThinking');
