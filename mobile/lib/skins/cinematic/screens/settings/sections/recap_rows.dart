import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';

/// `Previously on` and `Continue automatically after a recap`: one setting (`mm.recap`), shown in
/// both reading sections. [prefix] keeps the two copies' row ids apart for the search.
class RecapRows extends ConsumerWidget {
  const RecapRows({super.key, this.prefix = ''});
  final String prefix;

  static const String caption = "Plays a short recap before you continue a series you haven't opened for a while.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(recapSettingProvider);
    final auto = ref.watch(recapAutoContinueProvider);
    final n = ref.read(recapSettingProvider.notifier);
    final mode = s.cinematicMode;
    String id(String x) => prefix.isEmpty ? x : '$prefix-$x';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SettingsKicker('PREVIOUSLY ON'),
      slugRow(
        id('recap'),
        'Previously on',
        [
          const CineSlug('always', 'ALWAYS'),
          CineSlug('afterDays', 'AFTER ${s.seriesDays} DAYS AWAY'),
          const CineSlug('never', 'NEVER'),
        ],
        mode.name,
        (v) => n.setCinematicMode(CinematicRecapMode.values.byName(v), days: s.seriesDays),
        description: caption,
      ),
      if (mode == CinematicRecapMode.afterDays)
        stepperRow(id('recap-days'), 'Days away', s.seriesDays, (d) => n.setCinematicMode(CinematicRecapMode.afterDays, days: d), min: 3, max: 60, unit: 'DAYS'),
      switchRow(id('recap-auto'), 'Continue automatically after a recap', auto, (v) => ref.read(recapAutoContinueProvider.notifier).set(v)),
    ],);
  }
}
