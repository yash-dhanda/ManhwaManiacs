import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart' show sourcesHealthProvider;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/backend_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/checker_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/recent_checks.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/source_health.dart';
import 'package:manhwamaniacs/skins/glass/screens/status/summary_banner.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart' show useGlassRefresh;
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The content width from which System status lays its cards in two columns (glass 8.26).
const double kStatusGridMin = 1280;

/// System status (`/admin/status`, ScreenId `status`, glass 8.26): the summary banner, Backend, Update checker, Recent checks and
/// Source health, with the painted health beads.
class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({super.key, this.clock});
  final DateTime Function()? clock;
  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> {
  late final VoidCallback _offRefresh;
  final FocusNode _pageFocus = FocusNode(debugLabel: 'status page', skipTraversal: true);
  Timer? _sources;
  int _pulses = 0;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _offRefresh = useGlassRefresh(_refreshAll);
    _sources = Timer.periodic(kSourcesPollEvery, (_) {
      if (mounted) ref.invalidate(sourcesHealthProvider);
    });
  }

  @override
  void dispose() {
    _offRefresh();
    _pageFocus.dispose();
    _sources?.cancel();
    super.dispose();
  }

  void _refreshAll() {
    ref
      ..invalidate(backendHealthProvider)
      ..invalidate(sourcesHealthProvider)
      ..invalidate(updateSettingsProvider)
      ..invalidate(updateRunsProvider);
  }

  Future<void> _check() async {
    final r = await ref.read(manualCheckProvider.notifier).run();
    if (!mounted) return;
    if (r.message == kCheckAlreadyRunning) {
      showGlassToast(ref, const GlassToastSpec('A check is already running'));
    } else {
      showGlassToast(ref, GlassToastSpec(r.message, kind: r.ok ? GlassToastKind.success : GlassToastKind.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Each successful poll pulses the healthy backend bead once.
    ref.listen(backendHealthProvider, (_, next) {
      if (next.valueOrNull?.health.state == StatusState.healthy && !next.isLoading) setState(() => _pulses++);
    });
    final auth = ref.watch(authControllerProvider);
    final backend = ref.watch(backendHealthProvider);
    final settings = ref.watch(updateSettingsProvider);
    final runs = ref.watch(updateRunsProvider);
    final sources = ref.watch(sourcesHealthProvider);
    final checking = ref.watch(manualCheckProvider);
    final refreshing = backend.isLoading || settings.isLoading || runs.isLoading || sources.isLoading;

    Widget page(List<Widget> body) => RegisteredShortcuts(
          group: 'System status',
          entries: [
            ShortcutEntry(group: 'System status', activator: const SingleActivator(LogicalKeyboardKey.keyR), description: 'Refresh all', onInvoke: _refreshAll, singleKey: true, keys: const ['R']),
            ShortcutEntry(group: 'System status', activator: const SingleActivator(LogicalKeyboardKey.keyC), description: 'Check now', onInvoke: () => unawaited(_check()), singleKey: true, keys: const ['C']),
          ],
          // Holds focus when nothing inside has it, so `r` and `c` work as soon as the page opens.
          child: Focus(
            focusNode: _pageFocus,
            autofocus: true,
            child: GlassScaffold(
            title: 'System status',
            leading: GlassLeading.back,
            trailing: [
              GlassBarAction(
                id: 'refresh',
                label: 'Refresh',
                glyph: YouGlyphs.arrowsClockwise,
                onPress: _refreshAll,
                iconBuilder: refreshing ? (_) => const GlassSpinner(size: 20, label: 'Refreshing') : null,
              ),
            ],
            slivers: [SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body))],
          ),
          ),
        );

    if (auth is AuthUnknown) {
      return page([const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: SizedBox(height: 4, child: GlassLinearProgress(label: 'Checking your account')))]);
    }
    if (!(auth is AuthAuthenticated && auth.user.isAdmin)) {
      return page([
        GlassObjectLens(
          situation: LensSituation.adminOnly,
          title: 'Administrators only',
          description: 'System status is instance-wide. Ask the account owner to check it.',
          placement: GlassLensPlacement.inline,
          primary: LensAction('Back home', () => GoRouter.of(context).go(Routes.tonight())),
        ),
      ]);
    }
    if (ref.watch(glassOfflineProvider) && !backend.hasValue && !sources.hasValue) {
      return page([
        GlassObjectLens(
          situation: LensSituation.offline,
          tone: GlassLensTone.offline,
          title: "You're offline",
          description: 'System status needs a connection.',
          placement: GlassLensPlacement.inline,
          primary: LensAction('Try again', _refreshAll),
        ),
      ]);
    }

    final now = _now;
    final health = backend.valueOrNull?.health ?? deriveBackendHealth(loading: true);
    final summary = summarise(
      backend: health,
      checkerSettings: settings.valueOrNull,
      checkerLoading: settings.isLoading && !settings.hasValue,
      runs: runs.valueOrNull,
      sourceHealth: sources.valueOrNull,
      now: now,
    );
    final backendCard = BackendCard(health: health, pulseKey: _pulses);
    final checkerCard = CheckerCard(
      checker: summary.checker,
      now: now,
      checking: checking,
      onCheck: () => unawaited(_check()),
      failed: settings.hasError && !settings.hasValue,
      onRetry: () => ref.invalidate(updateSettingsProvider),
    );
    final recent = RecentChecksCard(runs: runs.valueOrNull, now: now, onRetry: runs.hasError && !runs.hasValue ? () => ref.invalidate(updateRunsProvider) : null);
    final sourceCard = SourceHealthCard(rows: sources.hasValue ? summary.sources : null, now: now, onRetry: sources.hasError && !sources.hasValue ? () => ref.invalidate(sourcesHealthProvider) : null);
    final note = GlassText('Everything here reads endpoints that already exist; nothing on this page changes the server except Check now.', role: gt.typeFootnote, color: gt.colorLabel3);

    return page([
      GlassText('ADMINISTRATION', role: gt.typeCaption1, color: gt.colorLabel2),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, c) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: StatusGrid(
              twoColumns: c.maxWidth >= kStatusGridMin,
              banner: SummaryBanner(summary: summary),
              backend: backendCard,
              checker: checkerCard,
              recent: recent,
              sources: sourceCard,
              sourcesSpan: summary.sources.length > 8,
              note: note,
            ),
          ),
        ),
      ),
    ]);
  }
}

/// The cards: one column, or at 1,280 and wider two (Backend and Update checker first, Recent checks and Source health below;
/// Source health spans both columns above 8 rows), 20 px gaps.
class StatusGrid extends StatelessWidget {
  const StatusGrid({super.key, required this.twoColumns, required this.banner, required this.backend, required this.checker, required this.recent, required this.sources, required this.sourcesSpan, required this.note});
  final bool twoColumns, sourcesSpan;
  final Widget banner, backend, checker, recent, sources, note;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 20, width: 20);
    Widget pair(Widget a, Widget b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), gap, Expanded(child: b)]);
    final children = twoColumns
        ? [
            banner,
            gap,
            pair(backend, checker),
            gap,
            if (sourcesSpan) ...[recent, gap, sources] else pair(recent, sources),
          ]
        : [banner, gap, backend, gap, checker, gap, recent, gap, sources];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...children, gap, note, const SizedBox(height: 24)]);
  }
}
