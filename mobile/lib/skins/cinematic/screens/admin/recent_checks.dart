import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/admin/utils/status_format.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/status_card.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Up to 8 recent checks: a status badge (1 px `set` / `spot` / `proof` / `ink.60`), the trigger,
/// the counts, the start time and the error in Plex Mono.
class RecentChecks extends StatelessWidget {
  const RecentChecks({super.key, required this.runs, required this.now, required this.loading, this.error, this.onRetry});
  final List<UpdateRun> runs;
  final DateTime now;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    Color tone(String status) => switch (status) {
          'completed' || 'finished' => c.colorSet,
          'running' => c.colorSpot,
          'failed' => c.colorProof,
          _ => c.colorInk60,
        };
    String word(String status) => switch (status) {
          'completed' || 'finished' => 'FINISHED',
          'running' => 'RUNNING',
          'failed' => 'FAILED',
          _ => status.toUpperCase(),
        };
    return StatusCard(
      kicker: 'RECENT CHECKS',
      loading: loading,
      greekRows: 3,
      error: error,
      onRetry: onRetry,
      child: runs.isEmpty
          ? CineRoleText('No update checks have run yet.', c.typeCaption, color: c.colorInk60)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in runs.take(8))
                  Container(
                    key: ValueKey('run-${r.id}'),
                    padding: EdgeInsets.symmetric(vertical: c.space3),
                    decoration: BoxDecoration(border: Border(bottom: c.ruleHair)),
                    child: Semantics(
                      container: true,
                      label: '${word(r.status)}, ${r.trigger}, ${runCountsLabel(r.seriesChecked, r.newChaptersFound)}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(border: Border.all(color: tone(r.status))),
                                child: CineRoleText(word(r.status), c.typeMicro, color: tone(r.status)),
                              ),
                              SizedBox(width: c.space2),
                              Flexible(child: CineRoleText(r.trigger, c.typeKicker, color: c.colorInk60)),
                            ],
                          ),
                          SizedBox(height: c.space1),
                          CineRoleText(runCountsLabel(r.seriesChecked, r.newChaptersFound), c.typeFolio, color: c.colorInk80),
                          if (r.startedAt != null) CineRoleText('${clockLabel(r.startedAt!)} · ${agoLabel(r.startedAt!, now)}', c.typeFolio, color: c.colorInk60),
                          if (r.error != null && r.error!.isNotEmpty) ...[SizedBox(height: c.space2), ErrorBlock(r.error!)],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
