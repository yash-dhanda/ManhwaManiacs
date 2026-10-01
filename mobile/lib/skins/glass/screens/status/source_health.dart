import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/health_bead.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/summary_banner.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Source health (glass 8.26): rows worst first, each a focus stop for the arrow keys. A failing or dead source's bead flickers
/// when a new probe for it lands ([SourceHealthRow.lastCheckedAt] is its flicker key); a demoted source's bead has the ring.
class SourceHealthCard extends StatelessWidget {
  const SourceHealthCard({super.key, required this.rows, required this.now, this.onRetry});
  final List<SourceHealthRow>? rows;
  final DateTime now;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (onRetry != null) {
      body = StatusCardError(onRetry: onRetry!);
    } else if (rows == null) {
      body = const GlassRowSkeletons(4, label: 'Loading source health');
    } else if (rows!.isEmpty) {
      body = GlassText('No sources to check', role: gt.typeCallout, color: gt.colorLabel2);
    } else {
      body = FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final r in rows!) _SourceRow(row: r, now: now)]),
      );
    }
    return StatusCard(title: 'Source health', child: body);
  }
}

class _SourceRow extends StatefulWidget {
  const _SourceRow({required this.row, required this.now});
  final SourceHealthRow row;
  final DateTime now;
  @override
  State<_SourceRow> createState() => _SourceRowState();
}

class _SourceRowState extends State<_SourceRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final failing = r.state == StatusState.warning || r.state == StatusState.down;
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: Semantics(
        container: true,
        label: '${r.name}, ${statusWord(r.state)}${r.demoted ? ', demoted' : ''}',
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: _focused ? gt.colorIris300 : const Color(0x00000000), width: 2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GlassHealthBead(status: beadOf(r.state), demoted: r.demoted, flickerKey: failing ? r.lastCheckedAt : null, label: statusWord(r.state)),
              const SizedBox(width: 8),
              Expanded(child: GlassText(r.name, role: gt.typeHeadline, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (r.demoted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: gt.colorWarning.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: GlassText('demoted', role: gt.typeCaption1, wght: 600, color: gt.colorWarning, maxScale: 1.5),
                ),
            ],),
            GlassText(r.id, role: gt.typeMono, color: gt.colorLabel2),
            if (r.lastCheckedAt != null) GlassText('last probe ${glassAgo(r.lastCheckedAt!, widget.now)}', role: gt.typeFootnote, color: gt.colorLabel2),
            GlassText(r.message, role: gt.typeFootnote, color: gt.colorLabel2),
            if (r.lastError != null && r.lastError!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: MonoBlock(r.lastError!)),
          ],),
        ),
      ),
    );
  }
}
