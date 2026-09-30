import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/narrating_indicator.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `NARRATING 3 CHAPTERS` and its determinate rule (Listen's `NarratingIndicator`), opening the
/// book being narrated with the Audiobook sheet open when this device knows which book it is.
class NarrationBlock extends ConsumerWidget {
  const NarrationBlock({super.key, this.jobs});

  /// Test and proof hook.
  final List<NarrationJob>? jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<NarrationJob> list = jobs ?? ref.watch(activeNarrationJobsProvider);
    if (list.isEmpty) return const SizedBox.shrink();
    final c = context.cine;
    final first = list.first;
    return Container(
      key: const Key('narration-block'),
      margin: EdgeInsets.only(bottom: c.space6),
      child: CinePressable(
        onTap: first.hasBook ? () => context.push<void>(Routes.feature(first.sourceId, first.seriesKey, const {'sheet': 'audiobook'})) : null,
        builder: (context, st) => Padding(padding: EdgeInsets.symmetric(vertical: c.space2), child: NarratingIndicator(jobs: list)),
      ),
    );
  }
}
