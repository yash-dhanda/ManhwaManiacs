import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `NARRATING 3 CHAPTERS` in `type.kicker` with a mini determinate rule (the average job
/// progress), built when active jobs exist (cinematic 8.16.8). Exported for Index and Downloads
/// (mobile/17), which mount it; [jobs] is the test and proof hook.
class NarratingIndicator extends ConsumerWidget {
  const NarratingIndicator({super.key, this.jobs});

  final List<NarrationJob>? jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<NarrationJob> list = jobs ?? ref.watch(activeNarrationJobsProvider);
    if (list.isEmpty) return const SizedBox.shrink();
    final c = context.cine;
    final chapters = list.fold<int>(0, (a, j) => a + (j.total - j.done).clamp(1, 1 << 20));
    final average = list.fold<double>(0, (a, j) => a + j.progress) / list.length;
    final label = 'NARRATING $chapters ${chapters == 1 ? 'CHAPTER' : 'CHAPTERS'}';
    return Semantics(
      container: true,
      label: '$label, ${(average * 100).round()} percent',
      excludeSemantics: true,
      child: Column(
        key: const Key('narrating-indicator'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CineRoleText(label, c.typeKicker, color: c.colorInk60),
          SizedBox(height: c.space1),
          CineRuleProgress(value: average),
        ],
      ),
    );
  }
}
