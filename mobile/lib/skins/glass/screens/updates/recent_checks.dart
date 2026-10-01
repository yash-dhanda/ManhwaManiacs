import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/library/utils/relative_read_time.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';

/// The last update-check runs (admin only).
final glassRecentRunsProvider = FutureProvider.autoDispose<List<UpdateRun>>((ref) async {
  final r = await ref.watch(updatesRepositoryProvider).listRuns(limit: 8);
  if (r.isErr) throw r.error;
  return r.value;
}, name: 'glassRecentRuns',);

String runSummaryLine(UpdateRun r) => '${r.trigger[0].toUpperCase()}${r.trigger.substring(1)} · ${r.status} · ${r.seriesChecked} series · ${r.newChaptersFound} new';

/// "Recent checks" (glass 8.21, admin): one row per run; a failed run shows its error in a `mono` block. Tapping a run opens `?sheet=run&run={id}`.
class GlassRecentChecks extends ConsumerWidget {
  const GlassRecentChecks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runs = ref.watch(glassRecentRunsProvider);
    final now = ref.watch(clockProvider)();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Semantics(header: true, headingLevel: 2, child: GlassLabel('Recent checks', role: gt.typeFootnote, wght: 600, upper: true, color: gt.colorLabel2))),
      runs.when(
        loading: () => GlassSkeletonGroup(child: Column(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassSkeleton(height: 52, radius: 12, index: i))])),
        error: (_, __) => GlassLabel("Recent checks didn't load", role: gt.typeFootnote, color: gt.colorDanger),
        data: (list) => list.isEmpty
            ? GlassLabel('No check runs yet', role: gt.typeFootnote, color: gt.colorLabel3)
            : Column(children: [
                for (final r in list)
                  GlassRowShell(
                    semanticsLabel: '${runSummaryLine(r)}${r.startedAt == null ? '' : ', ${relativeReadTime(r.startedAt!, now: now)}'}',
                    minHeight: 56,
                    onTap: () {
                      final uri = Uri.parse(GoRouterState.of(context).uri.toString());
                      GoRouter.of(context).go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': 'run', 'run': '${r.id}'}).toString());
                    },
                    builder: (context, stacked, info) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        GlassLabel(runSummaryLine(r), role: gt.typeSubhead),
                        if (r.startedAt != null) GlassLabel(relativeReadTime(r.startedAt!, now: now), role: gt.typeCaption1, color: gt.colorLabel3),
                        if (r.error != null && r.error!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: GlassLabel(r.error!, role: gt.typeMono, color: gt.colorDanger, maxLines: 3)),
                      ],),
                    ),
                  ),
              ],),
      ),
    ],);
  }
}
