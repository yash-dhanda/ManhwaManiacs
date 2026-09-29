import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_masthead.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/backend_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/checker_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/recent_checks.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/source_health_list.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/status_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/summary_banner.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

String _message(Object e) => e is AppError ? (e is ApiError ? e.message : e.userMessage) : 'Something went wrong.';

/// System status (`/admin/status`, cinematic 8.31): backend health, the update checker, recent
/// checks and per-source failures, all read from endpoints the server already exposes.
class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({super.key});

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> {
  Timer? _tick;
  Timer? _sources;
  final Map<String, FocusNode> _nodes = {};
  List<String> _order = const [];
  final FocusNode _checkNow = FocusNode(debugLabel: 'check-now');

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _sources = Timer.periodic(kSourcesPollEvery, (_) => ref.invalidate(sourcesHealthProvider));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _sources?.cancel();
    _checkNow.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _node(String id) => _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'source-$id'));

  void _walk(int delta) {
    if (_order.isEmpty) return;
    final at = _order.indexWhere((k) => _nodes[k]?.hasFocus ?? false);
    final next = at < 0 ? (delta > 0 ? 0 : _order.length - 1) : (at + delta).clamp(0, _order.length - 1);
    _nodes[_order[next]]?.requestFocus();
  }

  Future<void> _refreshAll() async {
    ref
      ..invalidate(backendHealthProvider)
      ..invalidate(updateSettingsProvider)
      ..invalidate(updateRunsProvider)
      ..invalidate(sourcesHealthProvider);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _checkNowRun() async {
    final r = await ref.read(manualCheckProvider.notifier).run();
    if (!mounted) return;
    cineFeedback(context, r.ok ? HapticEvent.success : HapticEvent.error);
    final toasts = ref.read(cineToastsProvider.notifier);
    r.ok ? toasts.success(r.message) : toasts.error(r.message);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final auth = ref.watch(authControllerProvider);
    final admin = auth is AuthAuthenticated && auth.user.isAdmin;
    final resolving = auth is AuthUnknown;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final side = wide ? c.space8 : c.space4;

    Widget masthead(double top, {Widget? actions}) => Padding(
          padding: EdgeInsets.fromLTRB(side, top + c.space6, side, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CineMasthead(
                kicker: 'ADMINISTRATION',
                title: 'System status',
                deck: 'Backend health, the update checker, per-source failures and update runs.',
                id: 'status',
              ),
              if (actions != null) actions,
            ],
          ),
        );

    Widget frame(Widget Function(double top) body, {Widget Function(Widget scaffold)? keys}) {
      final scaffold = CineScaffold(
        tabletLayout: true,
        firstRunNote: false,
        body: Builder(builder: (context) => body(CineScaffoldScope.topExtentOf(context))),
      );
      return keys == null ? scaffold : keys(scaffold);
    }

    if (resolving) return frame((top) => SingleChildScrollView(child: masthead(top)));

    if (!admin) {
      return frame(
        (top) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              masthead(top),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: CineNotice(
                  tone: CineNoticeTone.caution,
                  kicker: 'ADMINISTRATORS ONLY',
                  headline: 'System status is instance-wide.',
                  deck: 'Ask the owner to check it.',
                  primary: CineNoticeAction('Back to Tonight', () => context.go(Routes.tonight())),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final poll = ref.watch(backendHealthProvider);
    final settings = ref.watch(updateSettingsProvider);
    final runs = ref.watch(updateRunsProvider);
    final sources = ref.watch(sourcesHealthProvider);
    final checking = ref.watch(manualCheckProvider);

    final backend = poll.valueOrNull?.health ?? deriveBackendHealth(loading: true);
    final summary = summarise(
      backend: backend,
      checkerSettings: settings.valueOrNull,
      checkerLoading: settings.isLoading && !settings.hasValue,
      runs: runs.valueOrNull,
      sourceHealth: sources.valueOrNull,
      now: now,
    );
    _order = [for (final r in summary.sources) r.id];
    final refetching = poll.isLoading || settings.isLoading || runs.isLoading || sources.isLoading;
    final nextPoll = poll.valueOrNull?.nextPollAt;
    final left = nextPoll == null
        ? kBackendPollEvery.inSeconds
        : ((nextPoll.difference(now).inMilliseconds + 999) ~/ 1000).clamp(0, kBackendPollEvery.inSeconds);

    final actions = Padding(
      padding: EdgeInsets.only(top: c.space2),
      child: Row(
        children: [
          CineButton(
            label: 'Refresh all',
            variant: CineButtonVariant.quiet,
            size: CineButtonSize.sm,
            onPressed: () => unawaited(_refreshAll()),
            leadingGlyph: refetching ? null : 0xE036,
          ),
          if (refetching) Padding(padding: EdgeInsets.only(left: c.space1), child: const CineLeaderDial(size: 16, showAfter: Duration.zero, semanticLabel: 'Refreshing')),
          const Spacer(),
          Semantics(
            label: 'Live, refreshes in $left seconds',
            excludeSemantics: true,
            child: CineRoleText('LIVE · $left S', c.typeFolio, color: c.colorInk60),
          ),
        ],
      ),
    );

    // The keys wrap the whole scaffold: route focus lands on the running head's title.
    return frame(
      keys: (scaffold) => StatusKeys(
        onRefresh: () => unawaited(_refreshAll()),
        onCheck: () => unawaited(_checkNowRun()),
        onNext: () => _walk(1),
        onPrevious: () => _walk(-1),
        child: scaffold,
      ),
      (top) => CinePullToReprint(
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                masthead(top, actions: actions),
                Padding(
                  padding: EdgeInsets.fromLTRB(side, 0, side, c.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SummaryBanner(summary: summary),
                      BackendCard(health: backend, loading: poll.isLoading && !poll.hasValue),
                      CheckerCard(
                        health: summary.checker,
                        now: now,
                        loading: settings.isLoading && !settings.hasValue,
                        checking: checking,
                        checkNowFocus: _checkNow,
                        onCheckNow: () => unawaited(_checkNowRun()),
                        error: settings.hasError && !settings.hasValue ? _message(settings.error!) : null,
                        onRetry: () => ref.invalidate(updateSettingsProvider),
                      ),
                      RecentChecks(
                        runs: runs.valueOrNull ?? const [],
                        now: now,
                        loading: runs.isLoading && !runs.hasValue,
                        error: runs.hasError && !runs.hasValue ? _message(runs.error!) : null,
                        onRetry: () => ref.invalidate(updateRunsProvider),
                      ),
                      SourceHealthList(
                        rows: summary.sources,
                        now: now,
                        loading: sources.isLoading && !sources.hasValue,
                        nodeFor: _node,
                        error: sources.hasError && !sources.hasValue ? _message(sources.error!) : null,
                        onRetry: () => ref.invalidate(sourcesHealthProvider),
                      ),
                      SizedBox(height: c.space8),
                      CineRoleText(
                        'Everything on this page is read from endpoints the server already exposes; nothing here changes a setting except Check now.',
                        c.typeCaption,
                        color: c.colorInk60,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
