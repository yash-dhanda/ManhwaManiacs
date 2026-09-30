import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/providers/streak_events_provider.dart';
import 'package:manhwamaniacs/features/library/utils/milestones.dart';
import 'package:manhwamaniacs/features/library/utils/progress_streak.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart' show registerPurgeHolder;
import 'package:manhwamaniacs/skins/skins.dart';

/// What the streak events changed on screen: the flare and spark counters every `StreakFlame` watches, the "+1" for Home's chip and the
/// record caption. Session state only (in memory), so each plays once.
class StreakUiState {
  const StreakUiState({this.flare = 0, this.sparks = 0, this.plusOne = 0, this.recordDays});
  final int flare;
  final int sparks;

  /// Increments with each flare; Home's chip shows "+1" when this is above what it already played.
  final int plusOne;

  /// "New longest streak: N days" while set.
  final int? recordDays;

  StreakUiState copyWith({int? flare, int? sparks, int? plusOne, int? recordDays}) =>
      StreakUiState(flare: flare ?? this.flare, sparks: sparks ?? this.sparks, plusOne: plusOne ?? this.plusOne, recordDays: recordDays ?? this.recordDays);
}

class StreakUiNotifier extends Notifier<StreakUiState> {
  @override
  StreakUiState build() => const StreakUiState();

  void flare() => state = state.copyWith(flare: state.flare + 1, plusOne: state.plusOne + 1);
  void record(int days) => state = state.copyWith(sparks: state.sparks + 1, recordDays: days);
}

final streakUiProvider = NotifierProvider<StreakUiNotifier, StreakUiState>(StreakUiNotifier.new, name: 'streakUi');

/// Deletes the active profile's `mm.numbers.last.*` and `mm.annual.last.*` snapshots and invalidates every statistics and Wrapped payload
/// outright, so the screens show their offline states offline.
void purgeNumbers(Ref ref) {
  unawaited(ref.read(numbersSnapshotProvider).purge());
  ref
    ..invalidate(numbersStatisticsProvider)
    ..invalidate(annualProvider)
    ..invalidate(annualIndexProvider);
}

/// Set to `streak` just before pushing Statistics from the milestone toast: the hero then lifts and flips to the Streak share side.
/// (`share=streak` is not a query key of `numbers` in `contract.g.dart`, so the intent travels here.)
final statsShareIntentProvider = StateProvider<String?>((ref) => null);

/// Mounted once in the Glass shell: turns the server's progress answers into the flare, its haptic, the toasts, the record check and the
/// milestone (glass 9.2.2). The app never infers any of it: a flare needs the server's `extended_today` going false to true.
class GlassStreakEventsListener extends ConsumerStatefulWidget {
  const GlassStreakEventsListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassStreakEventsListener> createState() => _GlassStreakEventsListenerState();
}

class _GlassStreakEventsListenerState extends ConsumerState<GlassStreakEventsListener> {
  StreamSubscription<StreakEvent>? _sub;
  VoidCallback? _offPurge;

  @override
  void initState() {
    super.initState();
    // The 18+ purge deletes this profile's statistics and Wrapped snapshots and drops the payloads (glass 8.0.8 step 5).
    _offPurge = registerPurgeHolder('mobile-42.numbers', purgeNumbers);
    _sub = ref.read(streakEventsProvider).stream.listen((e) {
      switch (e) {
        case StreakFlare(:final currentDays):
          unawaited(_flare(currentDays));
        case GoalMet():
          // The ring closes itself (GlassGoalRing) and fires goal.met.
          break;
        case StreakToday():
          break;
      }
    });
  }

  @override
  void dispose() {
    _offPurge?.call();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _flare(int days) async {
    if (!mounted) return;
    final ui = ref.read(streakUiProvider.notifier)..flare();
    glassFire(ref, HapticEvent.streakExtend);
    glassSound(ref, SoundEvent.streakExtend);
    showGlassToast(ref, GlassToastSpec('$days-day streak', kind: GlassToastKind.success));
    final before = ref.read(numbersStatisticsProvider(1)).valueOrNull?.data.streak.longestDays;
    try {
      final fresh = (await ref.refresh(numbersStatisticsProvider(1).future)).data.streak;
      if (!mounted) return;
      if (before != null && fresh.currentDays > before) ui.record(fresh.currentDays);
      final m = pendingMilestone(fresh);
      if (m == null) return;
      glassFire(ref, HapticEvent.streakMilestone);
      glassSound(ref, SoundEvent.streakMilestone);
      showGlassToast(
        ref,
        GlassToastSpec(
          '$m days in a row',
          kind: GlassToastKind.success,
          actionLabel: 'Share',
          onAction: () {
            ref.read(statsShareIntentProvider.notifier).state = 'streak';
            unawaited(ref.read(skinRouterProvider).push<void>(Routes.numbers()));
          },
        ),
      );
      final repo = ref.read(numbersRepositoryProvider);
      for (final d in milestonesToMark(fresh, m)) {
        unawaited(repo.markMilestoneSeen(d));
      }
    } catch (_) {
      // A failed refetch only skips the record and milestone extras.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
