import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/health_bead.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/summary_banner.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Backend (glass 8.26): the state capsule with its health bead (pulsing once per successful poll, [pulseKey]), the name, the
/// version in `mono` and "Probe GET /health".
class BackendCard extends StatelessWidget {
  const BackendCard({super.key, required this.health, required this.pulseKey, this.error, this.onRetry});
  final BackendHealth health;
  final int pulseKey;
  final bool? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => StatusCard(
        title: 'Backend',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: gt.colorFill3, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GlassHealthBead(key: const ValueKey('backend-bead'), status: beadOf(health.state), pulseKey: health.state == StatusState.healthy ? pulseKey : null, label: statusWord(health.state)),
              const SizedBox(width: 8),
              GlassText(statusWord(health.state), role: gt.typeCaption1, wght: 600, maxScale: 1.5),
            ],),
          ),
          const SizedBox(height: 8),
          GlassText(health.name?.isNotEmpty ?? false ? health.name! : 'ManhwaManiacs API', role: gt.typeBody),
          if (health.version != null && health.version!.isNotEmpty) GlassText(health.version!, role: gt.typeMono, color: gt.colorLabel2),
          GlassText(health.message, role: gt.typeFootnote, color: gt.colorLabel2),
          const SizedBox(height: 4),
          GlassText('Probe GET /health', role: gt.typeFootnote, color: gt.colorLabel3),
        ],),
      );
}
