/// The Audiobook sheet's job rows (glass 8.16.5, B7): wording, tone and the actions a viewer has.
library;

import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';

enum JobTone { waiting, working, success, danger, muted }

class JobRow {
  const JobRow({required this.title, required this.tone, this.progress, this.spinner = false, this.canCancel = false, this.canRerender = false, this.removable = false});
  final String title;
  final JobTone tone;

  /// 0..1 for the liquid bar, null for none.
  final double? progress;

  /// The liquid ring (planning).
  final bool spinner;
  final bool canCancel, canRerender, removable;
}

/// Queued, planning, rendering, done, failed, cancelled; cancel and "Render again" are the owner's.
JobRow jobRowFor(NovelAudioJob job, {required bool owner}) {
  if (job.isCancelled) return const JobRow(title: 'Cancelled', tone: JobTone.muted, removable: true);
  if (job.isDone) return const JobRow(title: 'Narrated', tone: JobTone.success);
  if (job.isFailed) {
    final code = job.errorCode;
    final title = switch (code) {
      'lease_expired' => 'The narration PC stopped responding',
      'audio_convert_failed' => "Rendering failed: the audio couldn't be converted",
      null || '' => 'Rendering failed',
      _ => 'Rendering failed ($code)',
    };
    return JobRow(title: title, tone: JobTone.danger, canRerender: owner);
  }
  if (job.status == 'planning') return JobRow(title: 'Working out who speaks', tone: JobTone.working, spinner: true, canCancel: owner);
  if (job.status == 'rendering') {
    final pct = (job.progress * 100).round().clamp(0, 100);
    return JobRow(title: 'Rendering · $pct %', tone: JobTone.working, progress: job.progress.clamp(0.0, 1.0), canCancel: owner);
  }
  return JobRow(title: 'Waiting for the narration PC', tone: JobTone.waiting, canCancel: owner);
}
