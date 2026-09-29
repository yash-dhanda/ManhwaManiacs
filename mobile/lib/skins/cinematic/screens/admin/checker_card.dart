import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/admin/utils/status_format.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/status_card.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Update checker credits, the server's error block and `Check now`.
class CheckerCard extends StatelessWidget {
  const CheckerCard({
    super.key,
    required this.health,
    required this.now,
    required this.loading,
    required this.checking,
    required this.onCheckNow,
    this.error,
    this.onRetry,
    this.checkNowFocus,
  });

  final CheckerHealth health;
  final DateTime now;
  final bool loading;
  final bool checking;
  final VoidCallback onCheckNow;
  final String? error;
  final VoidCallback? onRetry;
  final FocusNode? checkNowFocus;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final s = health.schedule;
    final last = s?.lastRunAt;
    final next = s?.estimatedNextRunAt;
    final failed = health.failedRuns.length;
    final serverError = health.lastRun?.error ?? health.failedRuns.firstOrNull?.error;
    return StatusCard(
      kicker: 'UPDATE CHECKER',
      loading: loading,
      greekRows: 5,
      error: error,
      onRetry: onRetry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusCredit(label: 'LAST RUN', value: last == null ? 'NEVER' : '${clockLabel(last)} · ${agoLabel(last, now)}', mono: true),
          StatusCredit(label: 'NEXT', value: next == null ? '–' : '≈ ${clockLabel(next)} · ${inLabel(next, now)}', mono: true),
          StatusCredit(label: 'INTERVAL', value: s == null ? '–' : intervalLabel(s.intervalMinutes), mono: true),
          StatusCredit(label: 'FAILED RUNS (RECENT)', value: '$failed', mono: true, color: failed > 0 ? c.colorProof : null),
          if (serverError != null && serverError.isNotEmpty) ...[SizedBox(height: c.space2), ErrorBlock(serverError)],
          SizedBox(height: c.space4),
          Align(
            alignment: Alignment.centerLeft,
            child: CineButton(
              label: 'Check now',
              variant: CineButtonVariant.secondary,
              loading: checking,
              focusNode: checkNowFocus,
              onPressed: onCheckNow,
            ),
          ),
          SizedBox(height: c.space3),
          CineRoleText('The next run is an estimate from the last run and the interval.', c.typeCaption, color: c.colorInk60),
        ],
      ),
    );
  }
}
