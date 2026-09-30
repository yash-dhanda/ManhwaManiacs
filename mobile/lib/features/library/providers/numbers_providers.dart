import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/repositories/numbers_repository.dart';
import 'package:manhwamaniacs/features/library/store/numbers_snapshot.dart';
import 'package:manhwamaniacs/features/library/utils/numbers_rules.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

final numbersRepositoryProvider = Provider<NumbersRepository>(
  (ref) => NumbersRepositoryImpl(ref.watch(dioProvider)),
  name: 'numbersRepository',
);

/// `u{user}p{profile}`: the suffix of every per-profile key of this feature.
String numbersScopeOf(Ref ref) {
  final auth = ref.read(authControllerProvider);
  final user = auth is AuthAuthenticated ? auth.user.id : 0;
  return 'u${user}p${ref.read(activeProfileProvider)?.id ?? 0}';
}

/// [numbersScopeOf] for widgets: unique per user and profile. Read, not watched, and listed in
/// `profileScopedInvalidators` like every other per-profile cache (a watch on the active profile
/// would make invalidating it from the profile notifier a circular dependency).
final numbersScopeProvider =
    Provider<String>(numbersScopeOf, name: 'numbersScope');

final numbersSnapshotProvider = Provider<NumbersSnapshot>((ref) {
  final auth = ref.read(authControllerProvider);
  return NumbersSnapshot(
    ref.watch(sharedPrefsProvider),
    userId: auth is AuthAuthenticated ? auth.user.id : 0,
    profileId: ref.read(activeProfileProvider)?.id ?? 0,
  );
});

/// A payload plus whether it came from the offline snapshot.
class NumbersLoad<T> {
  const NumbersLoad(this.data, {this.offline = false});
  final T data;
  final bool offline;
}

bool _isOffline(Object e) => e is NetworkError;

final numbersStatisticsProvider = FutureProvider.autoDispose
    .family<NumbersLoad<LibraryStatistics>, int>((ref, days) async {
  final result =
      await ref.watch(numbersRepositoryProvider).statistics(days: days);
  final snap = ref.watch(numbersSnapshotProvider);
  if (result.isOk) {
    final raw = result.value.raw;
    if (raw != null) await snap.writeNumbers(days, raw);
    return NumbersLoad(result.value);
  }
  final saved = _isOffline(result.error) ? snap.readNumbers(days) : null;
  if (saved != null) {
    return NumbersLoad(LibraryStatistics.fromJson(saved), offline: true);
  }
  throw result.error;
});

final annualProvider = FutureProvider.autoDispose
    .family<NumbersLoad<Annual>, int>((ref, year) async {
  final result = await ref.watch(numbersRepositoryProvider).annual(year);
  final snap = ref.watch(numbersSnapshotProvider);
  if (result.isOk) {
    final raw = result.value.raw;
    if (raw != null) await snap.writeAnnual(year, raw);
    return NumbersLoad(result.value);
  }
  final saved = _isOffline(result.error) ? snap.readAnnual(year) : null;
  if (saved != null) return NumbersLoad(Annual.fromJson(saved), offline: true);
  throw result.error;
});

/// The current local year's payload: `availableYears`, `recordedDays`, `partial`.
final annualIndexProvider = FutureProvider.autoDispose<Annual?>((ref) async {
  try {
    return (await ref.watch(annualProvider(DateTime.now().year).future)).data;
  } catch (_) {
    return null;
  }
});

/// 7 | 30 | 90 | 365, remembered per profile (Glass shares the key).
class StatsRangeNotifier extends Notifier<int> {
  String get _key => 'mm.stats.range.${numbersScopeOf(ref)}';

  @override
  int build() {
    final key = _key;
    final v = ref.watch(sharedPrefsProvider).getInt(key);
    return v != null && kNumbersRanges.contains(v) ? v : 30;
  }

  Future<void> set(int days) async {
    if (!kNumbersRanges.contains(days)) return;
    state = days;
    await ref.read(sharedPrefsProvider).setInt(_key, days);
  }
}

final statsRangeProvider = NotifierProvider<StatsRangeNotifier, int>(
    StatsRangeNotifier.new,
    name: 'statsRange',);
