import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

// TODO(mobile/15): swap for mobile/15's exported NarratingIndicator; this is its stand-in with the
// same kicker and the same "book row with a determinate rule" anatomy.

/// `NARRATING 3 CHAPTERS` and a determinate rule per book, each row opening that book with the
/// Audiobook sheet open.
class NarrationBlock extends ConsumerWidget {
  const NarrationBlock({super.key, this.jobs});

  /// Test and proof hook.
  final List<NarrationJob>? jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<NarrationJob> list = jobs ?? ref.watch(activeNarrationJobsProvider);
    if (list.isEmpty) return const SizedBox.shrink();
    final c = context.cine;
    final chapters = list.fold<int>(0, (a, j) => a + (j.total - j.done).clamp(1, 1 << 20));
    return Container(
      key: const Key('narration-block'),
      margin: EdgeInsets.only(bottom: c.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CineRoleText('NARRATING $chapters ${chapters == 1 ? 'CHAPTER' : 'CHAPTERS'}', c.typeKicker, color: c.colorInk60),
          SizedBox(height: c.space2),
          for (final j in list)
            CinePressable(
              onTap: () => context.push<void>(Routes.feature(j.sourceId, j.seriesKey, const {'sheet': 'audiobook'})),
              builder: (context, st) => Padding(
                padding: EdgeInsets.symmetric(vertical: c.space2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CineRoleText(j.title, c.typeTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: c.space1),
                    CineRuleProgress(value: j.progress, semanticLabel: 'Narrating ${j.title}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
