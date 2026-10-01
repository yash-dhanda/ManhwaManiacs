import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart' show ContentMode;
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/relative_read_time.dart';
import 'package:manhwamaniacs/features/updates/mark_all_read.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/features/updates/utils/notification_grouping.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart' show GlassSpinner;
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show roleGlyph;
import 'package:manhwamaniacs/skins/glass/screens/library/library_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/updates/followed_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/updates/notification_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/updates/recent_checks.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart' show useGlassRefresh;
import 'package:manhwamaniacs/skins/skins.dart';

enum UpdatesTab { all, unread, followed }

/// Updates (glass 8.21): a pushed page with Check now, the All, Unread and Followed segments, the source filter, one notification card
/// per series, the recent checks for admins, and every state.
class GlassUpdatesScreen extends ConsumerStatefulWidget {
  const GlassUpdatesScreen({super.key, this.initialTab});
  final String? initialTab;

  @override
  ConsumerState<GlassUpdatesScreen> createState() => _GlassUpdatesScreenState();
}

class _GlassUpdatesScreenState extends ConsumerState<GlassUpdatesScreen> {
  late UpdatesTab _tab = switch (widget.initialTab) { 'unread' => UpdatesTab.unread, 'followed' => UpdatesTab.followed, _ => UpdatesTab.all };
  String? _source;
  bool _checking = false;
  bool _alive = true;
  SeriesUpdate? _focused;
  final GlassPullToRefreshController _pull = GlassPullToRefreshController();
  VoidCallback? _offRefresh;

  @override
  void initState() {
    super.initState();
    _offRefresh = useGlassRefresh(() => unawaited(_checkNow()));
  }

  @override
  void dispose() {
    _alive = false;
    _offRefresh?.call();
    _pull.dispose();
    super.dispose();
  }

  bool get _admin {
    final a = ref.read(authControllerProvider);
    return a is AuthAuthenticated && a.user.isAdmin;
  }

  /// Check now (glass 8.21): ran, queued (poll the list every 5 s for up to 120 s) or already running (toast).
  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() => _checking = true);
    final r = await ref.read(updatesRepositoryProvider).checkNow();
    if (!_alive) return;
    if (r.isErr) {
      setState(() => _checking = false);
      showGlassToast(ref, const GlassToastSpec("Couldn't start a check", kind: GlassToastKind.error));
      return;
    }
    switch (r.value) {
      case CheckOutcome.alreadyRunning:
        showGlassToast(ref, const GlassToastSpec('A check is already running'));
      case CheckOutcome.queued:
        final before = ref.read(updatesProvider).valueOrNull?.unreadCount;
        for (var t = 0; t < 120 && _alive; t += 5) {
          await Future<void>.delayed(const Duration(seconds: 5));
          if (!_alive) return;
          final c = await ref.read(updatesRepositoryProvider).getUnreadCount();
          if (c.isOk && c.value != before) break;
        }
      case CheckOutcome.ran:
        break;
    }
    if (!_alive) return;
    await ref.read(updatesProvider.notifier).refresh();
    if (!_alive) return;
    ref.invalidate(glassRecentRunsProvider);
    setState(() => _checking = false);
  }

  Future<void> _markAll(ContentMode? mode) async {
    final err = await ref.read(updatesProvider.notifier).markAllRead(mode: mode);
    if (mounted && err != null) showGlassToast(ref, const GlassToastSpec("Couldn't mark them read", kind: GlassToastKind.error));
  }

  Future<void> _checkSeries(FollowedSeries s) async {
    final r = await ref.read(updatesRepositoryProvider).checkSeries(s.id);
    if (!mounted) return;
    if (r.isErr) {
      showGlassToast(ref, const GlassToastSpec("Couldn't check that series", kind: GlassToastKind.error));
    } else {
      showGlassToast(ref, GlassToastSpec('${s.title}: ${r.value.newChaptersFound} new'));
      await ref.read(updatesProvider.notifier).refresh();
    }
  }

  Widget _lens(LensSituation s, String title, {String? description, LensAction? primary, GlassLensTone tone = GlassLensTone.empty}) =>
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: GlassObjectLens(situation: s, title: title, description: description, tone: tone, primary: primary)));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(updatesProvider);
    final scope = ref.watch(contentModeScopeProvider);
    final now = ref.watch(clockProvider)();
    final settings = ref.watch(updateSettingsProvider).valueOrNull;
    final sources = ref.watch(updateSourcesProvider).valueOrNull ?? const <String>[];
    final admin = _admin;
    final data = async.valueOrNull;
    final followed = data == null ? const <FollowedSeries>[] : scope.filter(data.followed, (s) => s.sourceId);
    final notes = data == null ? const <UpdateNotification>[] : scope.filter(data.notifications, (n) => n.sourceId);
    final unreadOnly = _tab == UpdatesTab.unread;
    final days = groupNotifications([for (final n in notes) if (!unreadOnly || !n.isRead) n], now, sourceId: _source, followed: followed);
    final unread = [for (final n in notes) if (!n.isRead) n].length;
    final line = _checking ? 'Checking ${followed.length} series…' : '$unread unread · ${followed.length} followed';
    final mode = markAllReadMode(novelsEnabled: scope.novelsEnabled, mode: scope.mode);

    final slivers = <Widget>[
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Semantics(liveRegion: true, child: GlassLabel(line, role: gt.typeSubhead, color: gt.colorLabel2)))),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(
              child: GlassSegmented<UpdatesTab>(
                asTabs: true,
                segments: const [GlassSegment(value: UpdatesTab.all, label: 'All'), GlassSegment(value: UpdatesTab.unread, label: 'Unread'), GlassSegment(value: UpdatesTab.followed, label: 'Followed')],
                selected: _tab,
                onSelected: (v) => setState(() => _tab = v),
              ),
            ),
          ],),
        ),
      ),
      if (_tab != UpdatesTab.followed && sources.length > 1)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Builder(builder: (context) => GlassChip(
                label: _source ?? 'All sources',
                onPressed: () {
                  final ro = context.findRenderObject();
                  final r = ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
                  unawaited(showGlassMenu(context, anchor: r, title: 'Source', entries: [
                    GlassMenuEntry(label: 'All sources', checked: _source == null, onSelected: () => setState(() => _source = null)),
                    for (final s in sources) GlassMenuEntry(label: s, checked: _source == s, onSelected: () => setState(() => _source = s)),
                  ],),);
                },
              ),),
            ),
          ),
        ),
      if (settings != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: admin ? () => GoRouter.of(context).push('/settings/notifications') : null,
              child: GlassLabel(
                'Checking every ${settings.checkIntervalMinutes} min · ${settings.lastRunAt == null ? 'not checked yet' : 'last check ${relativeReadTime(settings.lastRunAt!, now: now)}'} · notifications ${settings.notifyEnabled ? 'on' : 'off'}',
                role: gt.typeCaption1,
                color: gt.colorLabel3,
                maxLines: 2,
              ),
            ),
          ),
        ),
    ];

    if (async.isLoading && data == null) {
      slivers.add(SliverToBoxAdapter(child: GlassSkeletonGroup(child: Column(children: [for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassSkeleton(height: 120, radius: 26, index: i))]))));
    } else if (async.hasError && data == null) {
      final offline = async.error is NetworkError || async.error is TimeoutError;
      slivers.add(offline
          ? _lens(LensSituation.offline, 'Updates need a connection to check', tone: GlassLensTone.offline)
          : _lens(LensSituation.loadError, "Couldn't load notifications", tone: GlassLensTone.error, primary: LensAction('Try again', () => ref.invalidate(updatesProvider))),);
    } else if (_tab == UpdatesTab.followed) {
      slivers.add(followed.isEmpty
          ? _lens(LensSituation.library, "You don't follow anything yet", primary: LensAction('Browse sources', () => ref.read(skinRouterProvider).go(Routes.sources())))
          : SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 880), child: GlassFollowedList(rows: followed, onCheck: _checkSeries)))),);
    } else if (days.isEmpty) {
      slivers.add(unreadOnly && notes.isNotEmpty
          ? _lens(LensSituation.caughtUp, "You're caught up")
          : _lens(LensSituation.noUpdates, 'No new chapters yet', description: 'Follow a series and this fills in the moment a new chapter is found.', primary: LensAction('Browse sources', () => ref.read(skinRouterProvider).go(Routes.sources()))),);
    } else {
      slivers.add(SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 880), child: GlassNotificationList(days: days, focusedKey: (g) => _focused = g)))));
    }
    if (admin) slivers.add(const SliverToBoxAdapter(child: GlassRecentChecks()));
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));

    return LibraryKeys(
      group: 'Updates',
      bindings: [
        LibraryKey(description: 'Check now', keys: const ['r'], single: true, match: (e, hk) => false, action: () {}),
        LibraryKey(description: 'Mark the focused card read', keys: const ['m'], single: true, match: kChar('m'), action: () {
          final g = _focused;
          if (g != null) unawaited(markGroupRead(ref, g));
        },),
        LibraryKey(description: 'Mark all read', keys: const ['⇧', 'm'], single: true, match: kShiftLetter(LogicalKeyboardKey.keyM), action: () => unawaited(_markAll(mode))),
        LibraryKey(description: 'Move through the cards', keys: const ['↑', '↓'], match: kKey(LogicalKeyboardKey.arrowDown), action: () => FocusManager.instance.primaryFocus?.nextFocus()),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowUp), action: () => FocusManager.instance.primaryFocus?.previousFocus()),
      ],
      child: GlassScaffold(
        title: 'Updates',
        leading: GlassLeading.back,
        refreshSliver: GlassPullToRefresh(controller: _pull, onRefresh: () async {
          await _checkNow();
          return RefreshResult.changed;
        },),
        trailing: [
          GlassBarAction(
            id: 'check-now',
            label: _checking ? 'Checking for new chapters' : 'Check now',
            glyph: roleGlyph(GlassIconRole.refresh),
            onPress: () => unawaited(_checkNow()),
            iconBuilder: _checking ? (context) => const GlassSpinner(size: 24, label: 'Checking') : null,
          ),
        ],
        overflow: [
          GlassMenuEntry(label: markAllReadLabel(null), onSelected: () => unawaited(_markAll(null))),
          if (scope.novelsEnabled) GlassMenuEntry(label: 'Mark all manga read', onSelected: () => unawaited(_markAllKind('manga'))),
          if (scope.novelsEnabled) GlassMenuEntry(label: 'Mark all novels read', onSelected: () => unawaited(_markAllKind('novel'))),
          if (admin) GlassMenuEntry(label: 'Update settings', onSelected: () => GoRouter.of(context).push('/settings/notifications')),
        ],
        slivers: slivers,
      ),
    );
  }

  Future<void> _markAllKind(String kind) async {
    final r = await ref.read(updatesRepositoryProvider).markAllRead(contentKind: kind);
    if (!mounted) return;
    if (r.isErr) {
      showGlassToast(ref, const GlassToastSpec("Couldn't mark them read", kind: GlassToastKind.error));
    } else {
      await ref.read(updatesProvider.notifier).refresh();
    }
  }
}
