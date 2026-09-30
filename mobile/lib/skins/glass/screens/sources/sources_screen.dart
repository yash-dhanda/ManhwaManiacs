import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide ShortcutRegistry;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/source_health.dart';
import 'package:manhwamaniacs/features/sources/utils/source_latest.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/pin_fly.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/pinned_shelf.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/source_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/sources_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/sources_states.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/skins.dart';

enum _Chip { all, pinned, mature, trouble }

/// `/sources` (glass 8.10): health line, filter, chips, the Pinned section (drag handles), All sources, pin fly, reorder, swipe.
class GlassSourcesScreen extends ConsumerStatefulWidget {
  const GlassSourcesScreen({super.key});

  @override
  ConsumerState<GlassSourcesScreen> createState() => _GlassSourcesScreenState();
}

class _GlassSourcesScreenState extends ConsumerState<GlassSourcesScreen> with TickerProviderStateMixin {
  final TextEditingController _filter = TextEditingController();
  final FocusNode _filterFocus = FocusNode(debugLabel: 'sources filter');
  final GlassPullToRefreshController _refresh = GlassPullToRefreshController();
  final Object _token = Object();
  late final ShortcutRegistry _shortcuts;
  final Map<String, GlobalKey> _rowKeys = {};
  final GlobalKey _pinnedAnchor = GlobalKey();
  _Chip _chip = _Chip.all;
  List<String> _visiblePins = const [];

  @override
  void initState() {
    super.initState();
    _shortcuts = ref.read(shortcutRegistryProvider.notifier);
    Future.microtask(() => _shortcuts.register(_token, sourcesShortcutEntries()));
  }

  @override
  void dispose() {
    _filter.dispose();
    _filterFocus.dispose();
    _refresh.dispose();
    final s = _shortcuts;
    final t = _token;
    Future.microtask(() => s.unregister(t));
    super.dispose();
  }

  Future<RefreshResult> _onRefresh() async {
    ref.invalidate(sourcesListProvider);
    ref.invalidate(sourcesHealthProvider);
    ref.invalidate(sourceHealthSummaryProvider);
    try {
      await ref.read(sourcePinsProvider.notifier).refresh();
    } catch (_) {}
    return RefreshResult.changed;
  }

  Future<void> _toggle(SourceSummary s) async {
    final wasPinned = ref.read(sourcePinsProvider).valueOrNull?.contains(s.id) ?? false;
    final from = _rowKeys[s.id]?.currentContext?.findRenderObject();
    final fromRect = from is RenderBox && from.hasSize ? from.localToGlobal(Offset.zero) & from.size : null;
    glassFire(ref, HapticEvent.select);
    try {
      final fly = (!wasPinned && fromRect != null && mounted)
          ? () {
              final a = _pinnedAnchor.currentContext?.findRenderObject();
              final to = a is RenderBox && a.hasSize ? a.localToGlobal(Offset.zero) & fromRect.size : fromRect.shift(const Offset(0, -80));
              return runPinFly(context, ref, from: fromRect, to: to, vsync: this, copy: () => DecoratedBox(decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(20)), child: Center(child: GlassLabel(s.name, role: gt.typeHeadline))));
            }()
          : Future<void>.value();
      await ref.read(sourcePinsProvider.notifier).toggle(s.id, name: s.name, iconUrl: s.iconUrl, mature: s.mature);
      await fly;
      if (mounted) glassFire(ref, HapticEvent.select);
    } on AppError {
      if (mounted) showGlassToast(ref, const GlassToastSpec("Couldn't update your pins", kind: GlassToastKind.error));
    }
  }

  Future<void> _reorder(int from, int to) async {
    final pins = ref.read(sourcePinsProvider).valueOrNull?.pins ?? const <SourcePin>[];
    final vis = [..._visiblePins];
    if (from < 0 || from >= vis.length) return;
    final id = vis.removeAt(from);
    vis.insert(to.clamp(0, vis.length), id);
    final shown = _visiblePins.toSet();
    var k = 0;
    final next = [for (final p in pins) shown.contains(p.sourceId) ? vis[k++] : p.sourceId];
    try {
      await ref.read(sourcePinsProvider.notifier).reorder(next);
    } on AppError {
      if (mounted) showGlassToast(ref, const GlassToastSpec("Couldn't update your pins", kind: GlassToastKind.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(sourcesListProvider);
    final pinsState = ref.watch(sourcePinsProvider).valueOrNull;
    final pinsOk = pinsState?.synced ?? false;
    final summary = ref.watch(sourceHealthSummaryProvider).valueOrNull;
    final query = _filter.text.trim().toLowerCase();
    final gateOpen = ref.watch(matureContentProvider).valueOrNull ?? false;
    final scope = ref.watch(contentModeScopeProvider);
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final margin = GlassFrame.screenMargin(context);
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    final novels = ref.watch(contentModeControllerProvider) == ContentMode.novel;

    Widget body;
    final all0 = sourcesAsync.valueOrNull;
    if (all0 == null && sourcesAsync.isLoading) {
      body = const SourcesSkeleton();
    } else if (all0 == null) {
      final cached = pinsState?.pins ?? const <SourcePin>[];
      final down = sourcesAsync.error is NetworkError || sourcesAsync.error is TimeoutError || !online;
      if (down && cached.isNotEmpty) {
        body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const GlassStatusCapsule(kind: GlassStatusKind.offline),
          const SizedBox(height: 12),
          for (final p in cached)
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: GlassLabel(p.name, role: gt.typeHeadline)), GlassLabel('Needs a connection', role: gt.typeCaption1, color: gt.colorWarning)])),
        ],);
      } else if (down) {
        body = const SourcesOfflineLens();
      } else {
        body = SourcesErrorLens(onRetry: () => ref.invalidate(sourcesListProvider));
      }
    } else {
      var all = scope.filter(all0, (s) => s.id);
      if (!gateOpen) all = [for (final s in all) if (!s.mature) s];
      final byId = {for (final s in all) s.id: s};
      final pinnedRows = [for (final p in pinsState?.pins ?? const <SourcePin>[]) if (p.available && byId[p.sourceId] != null) byId[p.sourceId]!];
      final gone = [for (final p in pinsState?.pins ?? const <SourcePin>[]) if (!p.available || byId[p.sourceId] == null) p];
      bool matches(SourceSummary s) => query.isEmpty || s.name.toLowerCase().contains(query) || s.id.toLowerCase().contains(query);
      final trouble = sortWorstFirst([for (final s in all) if (s.health != null && (s.health!.status == SourceHealthStatus.failing || s.health!.status == SourceHealthStatus.dead)) s], (SourceSummary s) => s.health, (s) => s.name);
      _visiblePins = [for (final r in pinnedRows) r.id];
      final pinnedShown = [for (final r in pinnedRows) if (matches(r)) r];
      final allShown = switch (_chip) {
        _Chip.mature => [for (final s in all) if (s.mature && matches(s)) s],
        _Chip.trouble => [for (final s in trouble) if (matches(s)) s],
        _ => [for (final s in all) if (matches(s)) s],
      };
      final okCount = all.where((s) => s.health?.status == SourceHealthStatus.ok).length;
      final working = gateOpen ? (summary?.ok ?? okCount) : okCount;
      final offline = !online;
      final now = ref.read(clockProvider)();
      final updates = latestUpdateBySource(ref.watch(updatesProvider).valueOrNull?.notifications ?? const []);
      final showPinned = _chip == _Chip.all || _chip == _Chip.pinned;
      final showAll = _chip != _Chip.pinned;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offline) const Padding(padding: EdgeInsets.only(bottom: 8), child: Align(alignment: Alignment.centerLeft, child: GlassStatusCapsule(kind: GlassStatusKind.offline))),
          GlassLabel('$working of ${all.length} sources working', role: gt.typeFootnote, color: gt.colorLabel2),
          const SizedBox(height: 10),
          GlassSearchField(variant: GlassSearchVariant.filter, controller: _filter, focusNode: _filterFocus, placeholder: 'Filter sources', onQuery: (_) => setState(() {}), onSubmitted: (_) => setState(() {})),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              GlassChip(label: 'All', kind: GlassChipKind.choice, selected: _chip == _Chip.all, onPressed: () => setState(() => _chip = _Chip.all)),
              const SizedBox(width: 8),
              GlassChip(label: 'Pinned (${pinnedRows.length})', kind: GlassChipKind.choice, selected: _chip == _Chip.pinned, onPressed: () => setState(() => _chip = _Chip.pinned)),
              if (gateOpen) ...[const SizedBox(width: 8), GlassChip(label: '18+', kind: GlassChipKind.choice, selected: _chip == _Chip.mature, onPressed: () => setState(() => _chip = _Chip.mature))],
              if (trouble.isNotEmpty) ...[const SizedBox(width: 8), GlassChip(label: 'Having trouble (${trouble.length})', kind: GlassChipKind.choice, selected: _chip == _Chip.trouble, onPressed: () => setState(() => _chip = _Chip.trouble))],
            ],),
          ),
          if (!pinsOk && !offline) Padding(padding: const EdgeInsets.only(top: 10), child: GlassInlineNotice(message: 'Pinning is unavailable until your pins load', variant: GlassNoticeVariant.warning, actionLabel: 'Retry', onAction: () => unawaited(_onRefresh()))),
          const SizedBox(height: 12),
          if (all.isEmpty)
            SourcesNoneLens(novels: novels)
          else if (_chip == _Chip.pinned && pinnedShown.isEmpty && gone.isEmpty)
            const SourcesNoMatchLens(pinned: true)
          else if (showAll && allShown.isEmpty && query.isNotEmpty || (_chip == _Chip.pinned && pinnedShown.isEmpty && query.isNotEmpty))
            const SourcesNoMatchLens()
          else ...[
            if (showPinned && (pinnedShown.isNotEmpty || gone.isNotEmpty)) ...[
              KeyedSubtree(key: _pinnedAnchor, child: GlassLabel('Pinned', role: gt.typeHeadline)),
              const SizedBox(height: 8),
              if (wide) PinnedShelf(sources: pinnedShown, updates: updates, now: now) else ...[
                GlassReorderList<SourceSummary>(
                  items: pinnedShown,
                  nameOf: (s) => s.name,
                  onReorder: (f, t) => unawaited(_reorder(f, t)),
                  menuEntries: (s, i) => [
                    GlassMenuEntry(label: 'Open', onSelected: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.source(s.id)))),
                    GlassMenuEntry(label: 'Unpin', enabled: pinsOk && !offline, onSelected: () => unawaited(_toggle(s))),
                    GlassMenuEntry(label: 'Copy source id', onSelected: () {
                      unawaited(Clipboard.setData(ClipboardData(text: s.id)));
                      showGlassToast(ref, const GlassToastSpec('Copied'));
                    },),
                  ],
                  itemBuilder: (context, s, i, info) => KeyedSubtree(
                    key: _rowKeys.putIfAbsent(s.id, GlobalKey.new),
                    child: GlassSourceListRow(source: s, pinned: true, pinEnabled: pinsOk, offline: offline, onPin: () => unawaited(_toggle(s)), trailingHandle: pinsOk && !offline ? info.handle() : null),
                  ),
                ),
              ],
              for (final p in gone)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [GlassLabel(p.name, role: gt.typeHeadline, color: gt.colorLabel2), GlassLabel('No longer installed', role: gt.typeFootnote, color: gt.colorLabel2)])),
                    GlassChip(label: 'Unpin', kind: GlassChipKind.assist, onPressed: () => unawaited(ref.read(sourcePinsProvider.notifier).toggle(p.sourceId).catchError((_) {}))),
                  ],),
                ),
              const SizedBox(height: 16),
            ],
            if (showAll) ...[
              GlassLabel('All sources', role: gt.typeHeadline),
              const SizedBox(height: 8),
              if (wide)
                Wrap(spacing: 12, runSpacing: 8, children: [for (final s in allShown) SizedBox(width: 380, child: _row(s, pinsState, pinsOk, offline))])
              else
                for (final s in allShown) Padding(padding: const EdgeInsets.only(bottom: 8), child: _row(s, pinsState, pinsOk, offline)),
            ],
          ],
        ],
      );
    }

    return SourcesKeys(
      onFilter: _filterFocus.requestFocus,
      onRefresh: () => unawaited(_refresh.refresh()),
      child: GlassScaffold(
        title: 'Sources',
        contentModeSwitch: true,
        refreshSliver: GlassPullToRefresh(controller: _refresh, onRefresh: _onRefresh),
        slivers: [
          SliverPadding(padding: EdgeInsets.fromLTRB(margin, 8, margin, 140), sliver: SliverToBoxAdapter(child: body)),
        ],
      ),
    );
  }

  Widget _row(SourceSummary s, SourcePinsState? pins, bool pinsOk, bool offline) => KeyedSubtree(
        key: _rowKeys.putIfAbsent('all-${s.id}', GlobalKey.new),
        child: GlassSourceListRow(source: s, pinned: pins?.contains(s.id) ?? false, pinEnabled: pinsOk, offline: offline, onPin: () => unawaited(_toggle(s))),
      );
}
