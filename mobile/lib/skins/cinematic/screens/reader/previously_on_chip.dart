import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/recap/utils/should_open_recap.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';

/// The readers' first-page chip (cinematic 9.1.5): `PREVIOUSLY ON · 2 MIN` under the running head
/// on the first page of a chapter, only when [chipVisible] holds (a gap of `seriesDays`, or 14 days
/// when the setting is `always` or `off`) and the recap is available. The availability is read once
/// on the first page. It opens the recap with origin `reader` (`returnTo` is the reader's location)
/// and hides with the chrome like the rest of the running head.
///
/// TODO(mobile/12): mount under the manga reader's running head on page 1.
/// TODO(mobile/14): mount under the novel reader's running head on page 1.
class PreviouslyOnChip extends ConsumerWidget {
  const PreviouslyOnChip({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, required this.lastReadAt});
  final String sourceId, seriesKey, chapterKey;

  /// When this profile last read the series, before this session.
  final DateTime? lastReadAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(recapSettingProvider);
    final now = ref.read(clockProvider)();
    // No request unless the gap alone could show the chip.
    if (!chipVisible(setting: setting, lastReadAt: lastReadAt, now: now, available: true)) return const SizedBox.shrink();
    final a = ref.watch(recapAvailabilityProvider(RecapKey(sourceId, seriesKey, chapterKey))).valueOrNull;
    if (a == null || !a.available) return const SizedBox.shrink();
    final min = (a.estSeconds ?? 0) <= 0 ? 1 : ((a.estSeconds!) / 60).ceil();
    return Semantics(
      button: true,
      label: 'Previously on, $min ${min == 1 ? 'minute' : 'minutes'}',
      excludeSemantics: true,
      onTap: () => openRecap(context, sourceId, seriesKey, chapterKey, origin: RecapEntry.reader),
      child: CineButton(
        key: const Key('previously-on-chip'),
        label: 'PREVIOUSLY ON · $min MIN',
        variant: CineButtonVariant.quiet,
        size: CineButtonSize.sm,
        onPressed: () => openRecap(context, sourceId, seriesKey, chapterKey, origin: RecapEntry.reader),
      ),
    );
  }
}
