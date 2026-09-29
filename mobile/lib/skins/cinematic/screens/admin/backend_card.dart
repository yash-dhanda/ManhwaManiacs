import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/status_card.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Backend credits: state (tinted), name, version (Plex Mono) and the probe.
class BackendCard extends StatelessWidget {
  const BackendCard({super.key, required this.health, required this.loading});
  final BackendHealth health;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return StatusCard(
      kicker: 'BACKEND',
      loading: loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusCredit(label: 'STATE', value: stateWord(health.state), color: stateColor(c, health.state)),
          StatusCredit(label: 'NAME', value: health.name ?? '–'),
          StatusCredit(label: 'VERSION', value: health.version ?? '–', mono: true),
          const StatusCredit(label: 'PROBE', value: 'GET /health', mono: true),
        ],
      ),
    );
  }
}
