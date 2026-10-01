import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/library/utils/bulk_runner.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/mark_all_read.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/features/updates/utils/notification_grouping.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/recap/continue_to.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/hub/hub_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/library_hub.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/updates/recent_checks.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/updates/schedule_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/updates/updates_following.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/updates/updates_new.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Updates, "Stop press" (cinematic 8.10, ScreenId `updates`): the check with live progress, the
/// new chapters by day and series, the followed list, mark all read, the schedule deck and, for an
/// admin on a wide tablet, the recent runs. The nested tabs switch by tap only; the hub owns every
/// horizontal drag.
class UpdatesScreen extends ConsumerStatefulWidget {
  const UpdatesScreen({super.key});

  @override
  ConsumerState<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends ConsumerState<UpdatesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  final _mastheadFocus = FocusNode(debugLabel: 'updates-masthead');
  final _scroll = ScrollController();
  final List<FocusNode> _nodes = [];
  String? _source;
  bool _checking = false, _conflict = false, _alive = true;
  String? _liveDeck;
  UpdatesState? _last;

  @override
  void dispose() {
    _alive = false;
    _tabs.dispose();
    _mastheadFocus.dispose();
    _scroll.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  bool get _admin {
    final a = ref.read(authControllerProvider);
    return a is AuthAuthenticated && a.user.isAdmin;
  }

  UpdatesNotifier get _notifier => ref.read(updatesProvider.notifier);
  CineToastsNotifier get _toasts => ref.read(cineToastsProvider.notifier);

  // ---- the check -----------------------------------------------------------------------------

  Future<void> _check() async {
    if (_checking) return;
    cineFeedback(context, HapticEvent.tapPrimary);
    setState(() {
      _checking = true;
      _conflict = false;
      _liveDeck = null;
    });
    final before = _last?.unreadCount ?? 0;
    AppError? err;
    if (_admin) {
      err = await _adminCheck();
    } else {
      err = await _notifier.triggerCheck();
    }
    if (!_alive) return;
    if (err is ApiError && err.code == 'check_already_running') {
      setState(() {
        _checking = false;
        _conflict = true;
      });
      return;
    }
    if (err != null) {
      setState(() => _checking = false);
      _toasts.error("Couldn't start a check.");
      return;
    }
    final after = ref.read(updatesProvider).valueOrNull?.unreadCount ?? before;
    setState(() {
      _checking = false;
      _liveDeck = null;
    });
    if (after > before && mounted) cineFeedback(context, HapticEvent.success);
  }

  /// An admin's check: start it, then read the run every 2 s so the deck counts live.
  Future<AppError?> _adminCheck() async {
    final repo = ref.read(updatesRepositoryProvider);
    final started = await repo.triggerCheck();
    if (started.isErr) return started.error;
    if (started.value.queued) {
      final runs = await repo.listRuns(limit: 1);
      final id = runs.isOk && runs.value.isNotEmpty ? runs.value.first.id : null;
      final total = _last?.followed.length ?? 0;
      if (id != null) {
        final every = ref.read(updateRunPollIntervalProvider);
        for (var i = 0; i < 300; i++) {
          final r = await repo.getRun(id);
          if (!_alive) return null;
          if (r.isErr) break;
          final run = r.value;
          setState(() => _liveDeck = 'Checked ${run.seriesChecked} of ${total < run.seriesChecked ? run.seriesChecked : total} · ${run.newChaptersFound} new');
          if (run.status != 'running') break;
          await Future<void>.delayed(every);
          if (!_alive) return null;
        }
      }
    }
    await _notifier.refresh();
    ref.invalidate(recentRunsProvider);
    return null;
  }

  Future<void> _markAllRead() async {
    final scope = ref.read(contentModeScopeProvider);
    final err = await _notifier.markAllRead(mode: markAllReadMode(novelsEnabled: scope.novelsEnabled, mode: scope.mode));
    if (!mounted) return;
    if (err != null) {
      _toasts.error("Couldn't mark them read.");
    } else {
      _toasts.success('Marked every new chapter as seen.');
    }
  }

  // ---- one group / one series -------------------------------------------------------------------

  Future<void> _markGroupRead(SeriesUpdate g) async {
    final repo = ref.read(updatesRepositoryProvider);
    final ids = [for (final c in g.chapters) if (!c.read) c.notificationId];
    if (ids.isEmpty) return;
    cineFeedback(context, HapticEvent.select);
    final out = await runBulk<int>(ids, repo.markRead);
    if (!mounted) return;
    await _notifier.refresh();
    if (out.failed > 0 && mounted) _toasts.error("Couldn't mark them all read.");
  }

  void _read(String sourceId, String seriesKey, String chapterKey) =>
      unawaited(continueTo(context, ref, sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey, origin: RecapEntry.dip));

  Future<void> _toggleNotify(FollowedSeries s) async {
    final r = await ref.read(libraryRepositoryProvider).patchSeries(s.id, notify: !s.notify);
    if (!mounted) return;
    if (r.isErr) {
      _toasts.error("Couldn't update notifications.");
      return;
    }
    await _notifier.refreshFollowed();
  }

  Future<void> _checkSeries(FollowedSeries s) async {
    _toasts.info('Checking ${s.title}.');
    final r = await ref.read(updatesRepositoryProvider).checkFollowed(s.id);
    if (!mounted) return;
    if (r.isErr) {
      _toasts.error("Couldn't check ${s.title}.");
      return;
    }
    await _notifier.refresh();
  }

  Future<void> _unfollow(FollowedSeries s) async {
    final actions = ref.read(librarySeriesActionsProvider);
    final removed = await actions.remove(s);
    if (removed.error != null) {
      _toasts.error("Couldn't remove ${s.title}.");
      return;
    }
    if (mounted) cineFeedback(context, HapticEvent.followRemove);
    _toasts.action('Removed ${s.title}.', label: 'Undo', onAction: () async {
      final err = await actions.restore(s, slots: removed.slots);
      if (err != null) _toasts.error("Couldn't undo that.");
    },);
  }

  Future<void> _turnOnNotices() async {
    final id = ref.read(activeProfileProvider)?.id;
    if (id == null) return;
    final err = await ref.read(profilesProvider.notifier).edit(id, notifyEnabled: true);
    if (mounted && err != null) _toasts.error("Couldn't turn notices on.");
  }

  // ---- the source filter --------------------------------------------------------------------------

  Future<void> _pickSource(List<({String? id, String name})> options) async {
    final picked = await showCineSheet<String>(
      context,
      kicker: 'SOURCE',
      title: 'Source',
      builder: (ctx) => Column(children: [
        for (final o in options)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: CineRadio<String?>(value: o.id, groupValue: _source, label: o.name, onChanged: (v) => Navigator.of(ctx).pop(v ?? '')),
          ),
      ],),
    );
    if (picked == null || !mounted) return;
    setState(() => _source = picked.isEmpty ? null : picked);
  }

  // ---- keys ------------------------------------------------------------------------------------------

  int _focused() {
    for (var i = 0; i < _nodes.length; i++) {
      if (_nodes[i].hasFocus) return i;
    }
    return -1;
  }

  void _step(int d, int n) {
    if (n == 0) return;
    final cur = _focused();
    final to = (cur < 0 ? (d > 0 ? 0 : n - 1) : cur + d).clamp(0, n - 1);
    _nodes[to].requestFocus();
    final ctx = _nodes[to].context;
    if (ctx != null) unawaited(Scrollable.ensureVisible(ctx, duration: hubScroll(context), alignment: 0.3));
  }

  List<FocusNode> _nodesFor(int n) {
    while (_nodes.length < n) {
      _nodes.add(FocusNode(debugLabel: 'updates-${_nodes.length}'));
    }
    return _nodes;
  }

  // ---- build --------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final async = ref.watch(updatesProvider);
    final scope = ref.watch(contentModeScopeProvider);
    final settings = ref.watch(updateSettingsProvider).valueOrNull;
    final sourcesList = ref.watch(sourcesListProvider).valueOrNull ?? const [];
    final updateSources = ref.watch(updateSourcesProvider).valueOrNull ?? const <String>[];
    final now = ref.watch(clockProvider)();
    final seen = ref.watch(seenUpdateIdsProvider);
    final apiBase = ref.watch(apiBaseUrlProvider);
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final activeId = ref.watch(activeProfileProvider)?.id;
    final noticesOff = profiles.any((p) => p.id == activeId && !p.notifyEnabled);
    final grid = CineGrid.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final desk = MediaQuery.sizeOf(context).width >= 900;
    final admin = _admin;

    if (async.hasValue) _last = async.value;
    final data = async.valueOrNull ?? _last;
    final failed = async.hasError && !async.isLoading;
    final offline = failed && async.error is NetworkError;
    final names = {for (final s in sourcesList) s.id: s.name};

    // What the lists show: the content mode, then the source filter.
    List<UpdateNotification> notes = const [];
    List<FollowedSeries> followed = const [];
    if (data != null) {
      notes = scope.filter(data.notifications, (n) => n.sourceId).where((n) => _source == null || n.sourceId == _source).toList();
      followed = scope.filter(data.followed, (s) => s.sourceId).where((s) => _source == null || s.sourceId == _source).toList();
    }
    final unread = notes.where((n) => !n.isRead).toList();
    final days = groupNotifications(notes, now, followed: data?.followed ?? const []);
    final groups = [for (final d in days) ...d.groups];
    final followedSources = {for (final s in (data?.followed ?? const <FollowedSeries>[])) s.sourceId};
    final sourceOptions = <({String? id, String name})>[
      (id: null, name: 'All sources'),
      for (final id in updateSources.where(followedSources.contains)) (id: id, name: names[id] ?? id),
    ];
    final showSource = followedSources.length > 1 && sourceOptions.length > 2;

    // The deck: what is new, when it was last checked, and how often.
    final deckParts = <String>[
      if (_liveDeck != null)
        _liveDeck!
      else if (unread.isNotEmpty)
        '${unread.length} new ${unread.length == 1 ? 'chapter' : 'chapters'} across ${{for (final n in unread) '${n.sourceId}/${n.seriesKey}'}.length} series',
      if (_liveDeck == null && settings?.lastRunAt != null) 'last checked ${agoWords(settings!.lastRunAt!, now)}',
      if (_liveDeck == null && settings != null) scheduleShort(settings),
    ];
    final label = markAllReadLabel(markAllReadMode(novelsEnabled: scope.novelsEnabled, mode: scope.mode));
    final live = data != null && !offline;
    final nodes = _nodesFor(groups.length);

    Widget actions() {
      final checkBtn = CineButton(
        label: 'Check now',
        loadingLabel: 'Checking ${data?.followed.length ?? 0} series…',
        loading: _checking,
        fullWidth: !wide,
        onPressed: live ? _check : null,
        disabledReason: 'Needs a connection.',
      );
      final markBtn = CineButton(
        label: label,
        fullWidth: !wide,
        variant: CineButtonVariant.secondary,
        onPressed: live && unread.isNotEmpty ? _markAllRead : null,
        disabledReason: live ? null : 'Needs a connection.',
      );
      return Padding(
        padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (wide)
            Wrap(spacing: c.space3, runSpacing: c.space2, children: [checkBtn, markBtn])
          else ...[checkBtn, SizedBox(height: c.space2), markBtn],
          if (_conflict)
            Padding(
              padding: EdgeInsets.only(top: c.space2),
              child: Semantics(liveRegion: true, child: CineRoleText('A check is already running.', c.typeCaption, color: c.colorProof)),
            ),
        ],),
      );
    }

    final slivers = <Widget>[
      SliverToBoxAdapter(child: actions()),
      if (noticesOff && !offline)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(grid.left, 0, grid.right, c.space2),
            child: Row(key: const Key('updates-notices-off'), children: [
              CineRoleText('NOTE', c.typeKicker, color: c.colorSpot),
              SizedBox(width: c.space3),
              Expanded(child: CineRoleText('New-chapter notices are off for this profile.', c.typeCaption, color: c.colorSpot)),
              CineButton(label: 'Turn on', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: _turnOnNotices),
            ],),
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(left: grid.left, right: grid.right),
          child: CineGutter(child: Row(children: [
            Expanded(
              child: CineContentsTabs(controller: _tabs, tabs: [
                CineTab(folio: '01', label: 'NEW', count: data == null ? null : unread.length, loading: data == null && !failed),
                CineTab(folio: '02', label: 'FOLLOWING', count: data == null ? null : followed.length, loading: data == null && !failed),
              ],),
            ),
            if (showSource)
              CineButton(
                key: const Key('updates-source'),
                label: 'SOURCE ▾',
                variant: CineButtonVariant.quiet,
                size: CineButtonSize.sm,
                onPressed: () => unawaited(_pickSource(sourceOptions)),
              ),
          ],),),
        ),
      ),
      if (failed)
        SliverToBoxAdapter(
          child: HubErrorNotice(
            error: async.error!,
            offlineHeadline: 'Updates need a connection to check.',
            errorHeadline: "Updates didn't load.",
            onRetry: () => ref.invalidate(updatesProvider),
          ),
        ),
      if (data == null && !failed) const SliverToBoxAdapter(child: HubGalley(count: 3)),
    ];

    if (data != null) {
      final enabled = !offline;
      final newList = _tabs.index == 0;
      Widget? emptyNotice;
      if (newList && groups.isEmpty && !offline) {
        emptyNotice = HubNoticeBox(
          notice: CineNotice(
            key: const Key('updates-new-empty'),
            tone: CineNoticeTone.empty,
            kicker: 'NOTHING NEW',
            headline: 'No new chapters yet.',
            deck: 'Follow a series and this fills in the moment a chapter lands.',
            primary: CineNoticeAction('Find something', () => goSection(context, 2)),
          ),
        );
      } else if (!newList && followed.isEmpty && !offline) {
        emptyNotice = HubNoticeBox(
          notice: CineNotice(
            key: const Key('updates-following-empty'),
            tone: CineNoticeTone.empty,
            kicker: 'NOTHING FOLLOWED YET',
            headline: 'Nothing followed yet.',
            primary: CineNoticeAction('Find something', () => goSection(context, 2)),
          ),
        );
      }
      final Widget list;
      if (emptyNotice != null) {
        list = SliverToBoxAdapter(child: emptyNotice);
      } else if (newList) {
        // Days flatten to rules and rows; the row index runs over the groups only.
        final items = <Object>[for (final d in days) ...[d.label, ...d.groups]];
        var gi = 0;
        final idx = <SeriesUpdate, int>{for (final g in groups) g: gi++};
        list = SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final it = items[i];
            if (it is String) return UpdateDayRule(it);
            final g = it as SeriesUpdate;
            return UpdateGroupRow(
              key: ValueKey('group-${g.sourceId}-${g.seriesKey}-${g.newestAt?.millisecondsSinceEpoch}'),
              group: g,
              coverUrl: g.coverUrl == null || g.coverUrl!.isEmpty ? null : historyCoverUrl(apiBase, g.coverUrl),
              sourceName: names[g.sourceId] ?? g.sourceId,
              now: now,
              fresh: {for (final id in [for (final ch in g.chapters) ch.notificationId]) if (!seen.contains(id)) id},
              enabled: enabled,
              focusNode: nodes[idx[g]!],
              onFolio: (ch) => _read(g.sourceId, g.seriesKey, ch.chapterKey),
              onReadFrom: () {
                final f = g.firstUnread;
                if (f != null) _read(g.sourceId, g.seriesKey, f.chapterKey);
              },
              onMarkRead: () => unawaited(_markGroupRead(g)),
              onOpenSeries: () => openSeries(context, g.sourceId, g.seriesKey),
              onTyped: (ids) => Future.microtask(() {
                if (mounted) ref.read(seenUpdateIdsProvider.notifier).state = {...ref.read(seenUpdateIdsProvider), ...ids};
              }),
            );
          },
        );
      } else {
        list = SliverList.builder(
          itemCount: followed.length,
          itemBuilder: (context, i) {
            final s = followed[i];
            return FollowingRow(
              key: ValueKey('follow-${s.id}'),
              series: s,
              coverUrl: followedSeriesCoverUrl(apiBase, s),
              sourceName: names[s.sourceId] ?? s.sourceId,
              now: now,
              enabled: enabled,
              onOpen: () => unawaited(context.push(Routes.featureByFollow(s.id))),
              onNotify: () => unawaited(_toggleNotify(s)),
              onCheck: () => unawaited(_checkSeries(s)),
              onUnfollow: () => unawaited(_unfollow(s)),
            );
          },
        );
      }
      if (desk) {
        // Columns 1-5 for the lists whatever the role; 6-8 hold the aside for an admin.
        slivers.add(SliverPadding(
          padding: EdgeInsets.only(left: grid.left, right: grid.right),
          sliver: SliverCrossAxisGroup(slivers: [
            SliverCrossAxisExpanded(flex: 5, sliver: list),
            SliverCrossAxisExpanded(
              flex: 3,
              sliver: SliverToBoxAdapter(child: admin ? RecentChecks(key: const Key('updates-aside'), now: now) : const SizedBox.shrink()),
            ),
          ],),
        ),);
      } else {
        slivers.add(SliverPadding(padding: EdgeInsets.only(left: grid.left, right: grid.right), sliver: list));
      }
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 48)));

    final deck = deckParts.join(' · ');
    return CineScaffold(
      runningTitle: 'Updates',
      contentModeChip: true,
      firstRunNote: false,
      mastheadFocusNode: _mastheadFocus,
      body: RegisteredShortcuts(
        group: 'Updates',
        entries: [
          hubKey('Updates', LogicalKeyboardKey.keyR, 'Reload the list', () => unawaited(_reload())),
          hubKey('Updates', LogicalKeyboardKey.keyC, 'Check now', () {
            if (live) unawaited(_check());
          }),
          hubKey('Updates', LogicalKeyboardKey.keyJ, 'Next series', () => _step(1, groups.length)),
          hubKey('Updates', LogicalKeyboardKey.keyK, 'Previous series', () => _step(-1, groups.length)),
          hubKey('Updates', LogicalKeyboardKey.enter, 'Read the focused series', () {
            final i = _focused();
            final f = i < 0 ? null : groups[i].firstUnread;
            if (f != null) _read(groups[i].sourceId, groups[i].seriesKey, f.chapterKey);
          }, single: false,),
          hubKey('Updates', LogicalKeyboardKey.keyM, 'Mark the focused series read', () {
            final i = _focused();
            if (i >= 0) unawaited(_markGroupRead(groups[i]));
          }),
          hubKey('Updates', LogicalKeyboardKey.keyM, 'Mark everything read', () {
            if (live && unread.isNotEmpty) unawaited(_markAllRead());
          }, shift: true, keys: const ['Shift', 'M'],),
        ],
        child: LibraryHub(
          tab: HubTab.updates,
          masthead: (kicker: 'No. 03 — STOP PRESS', title: 'Updates', deck: deck),
          slivers: slivers,
          scrollController: _scroll,
          mastheadFocus: _mastheadFocus,
          onRefresh: _reload,
          onDeckTap: deck.isEmpty
              ? null
              : () {
                  if (admin) {
                    context.go('/settings/notifications');
                  } else {
                    unawaited(showScheduleSheet(context, settings: settings, notifyOff: noticesOff));
                  }
                },
        ),
      ),
    );
  }

  /// Pull to reprint: reloads the list and never starts a server check.
  Future<void> _reload() async {
    ref.invalidate(updateSettingsProvider);
    await _notifier.refresh();
  }
}
