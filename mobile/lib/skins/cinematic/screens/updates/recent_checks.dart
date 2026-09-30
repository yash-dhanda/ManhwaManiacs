import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_credits_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/hub/hub_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The last update-check runs (admin only).
final recentRunsProvider = FutureProvider.autoDispose<List<UpdateRun>>((ref) async {
  final r = await ref.watch(updatesRepositoryProvider).listRuns(limit: 8);
  if (r.isErr) throw r.error;
  return r.value;
}, name: 'recentRuns',);

/// The "Recent checks" aside (cinematic 8.10, columns 6-8 of a wide tablet): a `Credits` list,
/// `trigger · status` leading dot leaders to `212 series · 3 new · 12 min ago`. Three greeked rows
/// while loading, "No check runs yet." when empty.
class RecentChecks extends ConsumerWidget {
  const RecentChecks({super.key, required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final runs = ref.watch(recentRunsProvider);
    return Padding(
      padding: EdgeInsets.only(left: c.space6, top: c.space6),
      child: Column(key: const Key('recent-checks'), crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: CineRoleText('RECENT CHECKS', c.typeKicker, color: c.colorInk60)),
        SizedBox(height: c.space2),
        DecoratedBox(decoration: BoxDecoration(border: Border(top: c.ruleHair)), child: const SizedBox(width: double.infinity)),
        runs.when(
          loading: () => Column(children: [for (var i = 0; i < 3; i++) Padding(padding: EdgeInsets.symmetric(vertical: c.space2), child: CineGalleyLine(lineHeight: c.typeUi.lines.first, index: i))]),
          error: (_, __) => Padding(padding: EdgeInsets.only(top: c.space3), child: CineRoleText("Recent checks didn't load.", c.typeCaption, color: c.colorProof)),
          data: (list) => list.isEmpty
              ? Padding(padding: EdgeInsets.only(top: c.space3), child: CineRoleText('No check runs yet.', c.typeCaption, color: c.colorInk45))
              : Column(children: [
                  for (final r in list)
                    CineCreditsRow(
                      label: '${r.trigger} · ${r.status}',
                      value: '${r.seriesChecked} series · ${r.newChaptersFound} new${r.startedAt == null ? '' : ' · ${agoWords(r.startedAt!, now)}'}',
                    ),
                ],),
        ),
      ],),
    );
  }
}
