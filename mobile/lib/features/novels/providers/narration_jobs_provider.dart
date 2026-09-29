import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One book whose narration is being generated or saved right now.
class NarrationJob {
  const NarrationJob({
    required this.sourceId,
    required this.seriesKey,
    required this.title,
    required this.done,
    required this.total,
  });
  final String sourceId;
  final String seriesKey;
  final String title;
  final int done;
  final int total;

  double get progress => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

// TODO(mobile/15): mobile/15 owns this provider (the audiobook engine's running jobs); until it
// lands nothing narrates, so the Downloads and Index blocks that read it render nothing.
final activeNarrationJobsProvider = Provider<List<NarrationJob>>((ref) => const [], name: 'activeNarrationJobs');
