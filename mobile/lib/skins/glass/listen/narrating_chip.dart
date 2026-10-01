/// The "Narrating 3" chip (glass 8.13, C7): a `fill2` chip (no machine light) at the top of Downloads and on the desktop frame's sidebar
/// Library -> Downloads item while renders are in flight; it opens the Audiobook sheet of the first active job's book.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_jobs_provider.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart' show GlassSpinner;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Narrating 3": the chapters in flight.
String narratingLabel(int chapters) => 'Narrating $chapters';

class GlassNarratingChip extends ConsumerWidget {
  const GlassNarratingChip({super.key, this.onGlass = false});
  final bool onGlass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(activeNarrationJobsProvider);
    if (jobs.isEmpty) return const SizedBox.shrink();
    final j = jobs.first;
    final label = narratingLabel(j.total);
    return GlassPressable(
      material: GlassMaterial.content,
      sink: 0.96,
      onTap: j.hasBook ? () => ref.read(glassNarrationActionsProvider).openSheet('audiobook', extra: {'series': '${j.sourceId}:${j.seriesKey}'}) : null,
      enabled: j.hasBook,
      semanticsLabel: '$label chapters. Open the audiobook',
      builder: (context, info) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          widthFactor: 1,
          child: DecoratedBox(
            decoration: ShapeDecoration(color: gt.colorFill2, shape: const GlassShape.capsule().border(const Size(110, 32))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const GlassSpinner(size: 14), const SizedBox(width: 8), GlassText(label, role: gt.typeSubhead, wght: 600, onGlass: onGlass, maxLines: 1)]),
            ),
          ),
        ),
      ),
    );
  }
}
