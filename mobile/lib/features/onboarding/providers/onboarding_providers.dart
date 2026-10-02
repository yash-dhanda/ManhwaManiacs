import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository_impl.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) => OnboardingRepositoryImpl(ref.watch(dioProvider)), name: 'onboardingRepository');

/// What a catalog is keyed by: the server caches it 24 h per gate, formats and genres.
class CatalogKey {
  const CatalogKey({required this.profileId, required this.matureEnabled, this.formats = const [], this.genres = const [], this.styles = const []});
  final int? profileId;
  final bool matureEnabled;
  final List<String> formats, genres, styles;

  @override
  bool operator ==(Object other) =>
      other is CatalogKey &&
      other.profileId == profileId &&
      other.matureEnabled == matureEnabled &&
      other.formats.join(',') == formats.join(',') &&
      other.genres.join(',') == genres.join(',') &&
      other.styles.join(',') == styles.join(',');
  @override
  int get hashCode => Object.hash(profileId, matureEnabled, formats.join(','), genres.join(','), styles.join(','));
}

/// The catalog for the answers so far. A failure throws the `AppError`, so a screen can tell
/// "unreachable" from "offline" (`NetworkError`).
final onboardingCatalogProvider = FutureProvider.autoDispose.family<OnboardingCatalog, CatalogKey>((ref, k) async {
  ref.keepAlive();
  final r = await ref.read(onboardingRepositoryProvider).catalog(formats: k.formats, genres: k.genres, styles: k.styles);
  if (r case Err(:final error)) throw error;
  return r.value;
},
    name: 'onboardingCatalog',
);

/// The key for the active profile and its gate.
CatalogKey catalogKeyFor(Ref ref, {List<String> formats = const [], List<String> genres = const [], List<String> styles = const []}) => CatalogKey(
      profileId: ref.read(activeProfileProvider)?.id,
      matureEnabled: ref.read(matureGateOpenProvider),
      formats: formats,
      genres: genres,
      styles: styles,
    );

/// Three similar World items for a pick (`GET /ai/similar?anilist_id=`), for the session.
/// A failure reads as an unavailable desk.
final similarSeedsProvider = FutureProvider.autoDispose.family<SimilarResult, int>((ref, anilistId) async {
  ref.keepAlive();
  try {
    return await ref.watch(aiRepositoryProvider).similar(SimilarQuery.anilist(anilistId));
  } catch (_) {
    return const SimilarResult(available: false, reason: 'failed');
  }
},
    name: 'similarSeeds',
);

/// The profile whose unfinished onboarding was put off for this app session ('Skip for now' while
/// offline): Tonight's resume redirect leaves it alone until the next launch.
final onboardingDeferredProvider = StateProvider<int?>((ref) => null, name: 'onboardingDeferred');
