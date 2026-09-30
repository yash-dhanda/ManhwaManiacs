import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show sheetOnGlass;

/// `?sheet=run&run={id}` (medium, admins only): trigger, status, times, duration, series checked, new chapters and the whole error in a
/// `mono` block with a Copy button.
final GlassSheetSpec glassRunSheetSpec = GlassSheetSpec(
  title: 'Update check',
  builder: (context) => GlassRunBody(runId: int.tryParse(GoRouterState.of(context).uri.queryParameters['run'] ?? '') ?? 0),
  detents: const [GlassDetent.medium, GlassDetent.large],
  opening: GlassDetent.medium,
);

final glassRunProvider = FutureProvider.autoDispose.family<UpdateRun, int>((ref, id) async {
  final r = await ref.watch(updatesRepositoryProvider).getRun(id);
  if (r.isErr) throw r.error;
  return r.value;
}, name: 'glassRun',);

class GlassRunBody extends ConsumerWidget {
  const GlassRunBody({super.key, required this.runId});
  final int runId;

  static String _t(DateTime? d) => d == null ? '—' : '${d.toLocal().year}-${d.toLocal().month.toString().padLeft(2, '0')}-${d.toLocal().day.toString().padLeft(2, '0')} ${d.toLocal().hour.toString().padLeft(2, '0')}:${d.toLocal().minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final admin = auth is AuthAuthenticated && auth.user.isAdmin;
    final on = sheetOnGlass(context);
    if (!admin) return const Padding(padding: EdgeInsets.all(24), child: GlassObjectLens(situation: LensSituation.adminOnly, title: 'Admins only', placement: GlassLensPlacement.inline));
    final run = ref.watch(glassRunProvider(runId));
    return run.when(
      loading: () => GlassSkeletonGroup(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [for (var i = 0; i < 6; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassSkeleton(height: 28, radius: 8, index: i))]))),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: e is NetworkError
            ? const GlassObjectLens(situation: LensSituation.offline, tone: GlassLensTone.offline, title: "You're offline", placement: GlassLensPlacement.inline)
            : GlassObjectLens(situation: LensSituation.loadError, tone: GlassLensTone.error, title: "Couldn't load this check", placement: GlassLensPlacement.inline, primary: LensAction('Try again', () => ref.invalidate(glassRunProvider(runId)))),
      ),
      data: (r) {
        final dur = r.startedAt != null && r.finishedAt != null ? r.finishedAt!.difference(r.startedAt!) : null;
        Widget line(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: GlassLabel(k, role: gt.typeBody, onGlass: on, color: gt.colorLabel2)), GlassLabel(v, role: gt.typeMono, onGlass: on)]));
        return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
          line('Trigger', '${r.trigger[0].toUpperCase()}${r.trigger.substring(1)}'),
          line('Status', r.status),
          line('Started', _t(r.startedAt)),
          line('Finished', _t(r.finishedAt)),
          line('Duration', dur == null ? '—' : '${dur.inSeconds} s'),
          line('Series checked', '${r.seriesChecked}'),
          line('New chapters', '${r.newChaptersFound}'),
          if (r.error != null && r.error!.isNotEmpty) ...[
            const SizedBox(height: 12),
            DecoratedBox(decoration: BoxDecoration(color: gt.colorSurface2, borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(12), child: GlassLabel(r.error!, role: gt.typeMono, onGlass: on, color: gt.colorDanger, maxLines: 40))),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: GlassButton(label: 'Copy', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: r.error!)));
              showGlassToast(ref, const GlassToastSpec('Copied'));
            },),),
          ],
        ],);
      },
    );
  }
}
