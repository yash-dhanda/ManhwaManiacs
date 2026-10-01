import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/summary_banner.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// A run's tag colour (glass 7.20): completed `success`, running `iris400`, failed `danger`, other `warning`.
Color runColour(String status) => switch (status) {
      'completed' => gt.colorSuccess,
      'running' => gt.colorIris400,
      'failed' => gt.colorDanger,
      _ => gt.colorWarning,
    };

/// Recent checks (glass 8.26): up to 8 runs.
class RecentChecksCard extends StatelessWidget {
  const RecentChecksCard({super.key, required this.runs, required this.now, this.onRetry});

  /// Null while loading.
  final List<UpdateRun>? runs;
  final DateTime now;

  /// Set when the runs failed to load.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (onRetry != null) {
      body = StatusCardError(onRetry: onRetry!);
    } else if (runs == null) {
      body = const GlassRowSkeletons(3, label: 'Loading recent checks');
    } else if (runs!.isEmpty) {
      body = GlassText('No checks have run yet', role: gt.typeCallout, color: gt.colorLabel2);
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final r in runs!.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              container: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: runColour(r.status).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                    child: GlassText(r.status, role: gt.typeCaption1, wght: 600, color: runColour(r.status), maxScale: 1.5),
                  ),
                  GlassText(r.trigger, role: gt.typeCallout),
                  if (r.startedAt != null) GlassText(glassAgo(r.startedAt!, now), role: gt.typeFootnote, color: gt.colorLabel2),
                ],),
                GlassText('${r.seriesChecked} series · ${r.newChaptersFound} new', role: gt.typeFootnote, color: gt.colorLabel2),
                if (r.error != null && r.error!.isNotEmpty) GlassText(r.error!, role: gt.typeFootnote, color: gt.colorDanger),
              ],),
            ),
          ),
      ],);
    }
    return StatusCard(title: 'Recent checks', child: body);
  }
}
