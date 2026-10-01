import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/summary_banner.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Update checker (glass 8.26): "Check now", last and next run, the interval, failed runs and the server error.
class CheckerCard extends StatelessWidget {
  const CheckerCard({super.key, required this.checker, required this.now, required this.onCheck, required this.checking, this.failed = false, this.onRetry});
  final CheckerHealth checker;
  final DateTime now;
  final VoidCallback onCheck;
  final bool checking, failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = checker.schedule;
    Widget line(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Expanded(child: GlassText(k, role: gt.typeCallout, color: gt.colorLabel2)),
            GlassText(v, role: gt.typeCallout, color: color),
          ],),
        );
    final error = checker.lastRun?.error;
    return StatusCard(
      title: 'Update checker',
      trailing: GlassButton(label: 'Check now', size: GlassButtonSize.small, loading: checking, onPressed: checking ? null : onCheck),
      child: failed && onRetry != null
          ? StatusCardError(onRetry: onRetry!)
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              GlassText(checker.message, role: gt.typeFootnote, color: statusColour(checker.state)),
              const SizedBox(height: 8),
              line('Last run', s?.lastRunAt == null ? 'Never' : '${glassClock(s!.lastRunAt!)} · ${glassAgo(s.lastRunAt!, now)}'),
              line('Next run', s?.estimatedNextRunAt == null ? '—' : glassIn(s!.estimatedNextRunAt!, now)),
              if (s != null) line('Interval', 'Every ${glassInterval(s.intervalMinutes)}'),
              line('Failed runs', '${checker.failedRuns.length}', color: checker.failedRuns.isNotEmpty ? gt.colorDanger : null),
              if (error != null && error.isNotEmpty) ...[const SizedBox(height: 8), MonoBlock(error, color: gt.colorDanger)],
            ],),
    );
  }
}
