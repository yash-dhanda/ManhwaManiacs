import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_shortcuts.dart';

/// `Previously on…` in the actions row of the series and book pages (and `P` on a hardware
/// keyboard): shown only when the recap availability for the continue chapter, read once on load,
/// says `available`. It opens the recap with origin `wipe` (the recap continues by the Column wipe).
class PreviouslyOnButton extends ConsumerWidget {
  const PreviouslyOnButton({super.key, required this.sourceId, required this.seriesKey, required this.chapterKey, required this.commands, this.wide = false});
  final String sourceId, seriesKey;
  final String? chapterKey;
  final FeatureCommands commands;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = chapterKey;
    final ok = chapter != null && (ref.watch(recapAvailabilityProvider(RecapKey(sourceId, seriesKey, chapter))).valueOrNull?.available ?? false);
    commands.previouslyOn = ok ? () => openRecap(context, sourceId, seriesKey, chapter) : null;
    if (!ok) return const SizedBox.shrink();
    return SizedBox(
      width: wide ? null : double.infinity,
      child: OutlinedButton(
        key: const Key('previously-on'),
        style: OutlinedButton.styleFrom(minimumSize: Size(48, wide ? 56 : 48)),
        onPressed: commands.previouslyOn,
        child: const Text('Previously on…'),
      ),
    );
  }
}
