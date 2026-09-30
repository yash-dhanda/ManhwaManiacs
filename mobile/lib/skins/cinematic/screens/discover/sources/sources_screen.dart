import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/index_field_header.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/health_details_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/source_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/sources/source_table.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// `/sources`: the directory with health marks, pins (drag / Move items) and
/// the 18+ mark.
class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen> {
  final _filter = TextEditingController();
  final _filterFocus = FocusNode();
  final _nodes = <String, FocusNode>{};

  @override
  void dispose() {
    _filter.dispose();
    _filterFocus.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _node(String id) => _nodes.putIfAbsent(id, FocusNode.new);

  void _toast(String text, {bool error = false}) => error
      ? ref.read(cineToastsProvider.notifier).error(text)
      : ref.read(cineToastsProvider.notifier).info(text);

  Future<void> _toggle(SourceSummary s) async {
    final pins = ref.read(sourcePinsProvider).valueOrNull;
    final wasPinned = pins?.contains(s.id) ?? false;
    unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.select));
    try {
      await ref
          .read(sourcePinsProvider.notifier)
          .toggle(s.id, name: s.name, iconUrl: s.iconUrl, mature: s.mature);
      if (mounted) {
        _toast(wasPinned ? '${s.name} unpinned' : '${s.name} pinned');
      }
    } on AppError {
      if (mounted) _toast("Couldn't update your pinned sources.", error: true);
    }
  }

  /// The pin ids the screen shows (available, past the 18+ gate), in order;
  /// set by build. Hidden pins keep their slots in the full order.
  List<String> _visible = const [];

  /// Move within the [_visible] pins and write the full order: every pin the
  /// screen hides (unavailable, gated) stays exactly where it was.
  Future<void> _move(
    String id,
    int Function(int index, int last) target,
  ) async {
    final pins = ref.read(sourcePinsProvider).valueOrNull?.pins ?? const [];
    final vis = [..._visible];
    final from = vis.indexOf(id);
    if (from < 0) return;
    final to = target(from, vis.length - 1).clamp(0, vis.length - 1);
    if (to == from) return;
    vis
      ..removeAt(from)
      ..insert(to, id);
    final shown = _visible.toSet();
    final next = <String>[];
    var k = 0;
    for (final p in pins) {
      next.add(shown.contains(p.sourceId) ? vis[k++] : p.sourceId);
    }
    await _write(next);
    if (!mounted) return;
    final name = pins.firstWhere((p) => p.sourceId == id).name;
    announce(context, '$name moved to position ${to + 1} of ${vis.length}');
  }

  Future<void> _write(List<String> order) async {
    try {
      await ref.read(sourcePinsProvider.notifier).reorder(order);
    } on AppError {
      if (mounted) _toast("Couldn't update your pinned sources.", error: true);
    }
  }

  Future<void> _menu(
    SourceSummary s, {
    required bool pinned,
    required int index,
    required int last,
  }) async {
    unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.longpressOpen));
    final action = await showCineSheet<String>(
      context,
      title: s.name,
      body: (context) {
        final t = context.cine;
        Widget item(String id, String label, {bool enabled = true}) => InkWell(
              onTap: enabled ? () => Navigator.of(context).pop(id) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: cineText(
                        context,
                        t.typeTitle,
                        color: enabled ? t.colorInk100 : t.colorInk30,
                      ),
                    ),
                  ),
                ),
              ),
            );
        return ListView(
          shrinkWrap: true,
          children: [
            item('open', 'Open'),
            item('pin', pinned ? 'Unpin' : 'Pin'),
            item('health', 'Health details'),
            if (pinned) ...[
              item('up', 'Move up', enabled: index > 0),
              item('down', 'Move down', enabled: index < last),
              item('top', 'Move to top', enabled: index > 0),
              item('bottom', 'Move to bottom', enabled: index < last),
            ],
          ],
        );
      },
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'open':
        unawaited(context.push(Routes.source(s.id)));
      case 'pin':
        await _toggle(s);
      case 'health':
        await showHealthDetails(context, s);
      case 'up':
        await _move(s.id, (i, _) => i - 1);
      case 'down':
        await _move(s.id, (i, _) => i + 1);
      case 'top':
        await _move(s.id, (_, __) => 0);
      case 'bottom':
        await _move(s.id, (_, l) => l);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final sourcesAsync = ref.watch(sourcesListProvider);
    final pinsAsync = ref.watch(sourcePinsProvider);
    final summary = ref.watch(sourceHealthSummaryProvider).valueOrNull;
    final query = ref.watch(sourcesFilterQueryProvider).trim().toLowerCase();
    final filter = ref.watch(sourcesFilterProvider);
    final gateOpen = ref.watch(matureContentProvider).valueOrNull ?? false;
    final scope = ref.watch(contentModeScopeProvider);
    final pinsState = pinsAsync.valueOrNull;
    final pinsOk = pinsState?.synced ?? false;
    final tablet = isTablet(context);

    Widget scaffold(Widget body) => CineKeys(
          group: 'Sources',
          keys: [
            CineKey(
              key(LogicalKeyboardKey.slash),
              _filterFocus.requestFocus,
              whenTextFieldFree: true,
            ),
            CineKey(
              key(LogicalKeyboardKey.keyJ),
              () => focusStep(context, forward: true),
              whenTextFieldFree: true,
            ),
            CineKey(
              key(LogicalKeyboardKey.keyK),
              () => focusStep(context, forward: false),
              whenTextFieldFree: true,
            ),
            CineKey(
              key(LogicalKeyboardKey.keyP),
              () {
                final id = _nodes.entries
                    .where((e) => e.value.hasFocus)
                    .firstOrNull
                    ?.key;
                final s = sourcesAsync.valueOrNull
                    ?.where((x) => x.id == id)
                    .firstOrNull;
                if (s != null && pinsOk) unawaited(_toggle(s));
              },
              whenTextFieldFree: true,
            ),
            CineKey(key(LogicalKeyboardKey.arrowUp, alt: true), () {
              final id = _nodes.entries
                  .where((e) => e.value.hasFocus)
                  .firstOrNull
                  ?.key;
              if (id != null) unawaited(_move(id, (i, _) => i - 1));
            }),
            CineKey(key(LogicalKeyboardKey.arrowDown, alt: true), () {
              final id = _nodes.entries
                  .where((e) => e.value.hasFocus)
                  .firstOrNull
                  ?.key;
              if (id != null) unawaited(_move(id, (i, _) => i + 1));
            }),
          ],
          child: Scaffold(
            backgroundColor: t.colorPaper0,
            body: SafeArea(child: body),
          ),
        );

    if (sourcesAsync.isLoading && !sourcesAsync.hasValue) {
      return scaffold(
        ListView(
          children: [
            for (var i = 0; i < 10; i++)
              const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: CineSpace.s4, vertical: 8),
                child: FlickerPlate(height: 48),
              ),
          ],
        ),
      );
    }
    if (sourcesAsync.hasError && !sourcesAsync.hasValue) {
      final offline = sourcesAsync.error is NetworkError ||
          sourcesAsync.error is TimeoutError;
      final cached = pinsState?.pins ?? const [];
      return scaffold(
        ListView(
          children: [
            CineNotice(
              kicker: offline ? 'OFFLINE EDITION' : 'CORRECTION',
              kickerColor: offline ? null : t.colorProof,
              headline: offline
                  ? 'The source list needs a connection.'
                  : "Couldn't load the sources.",
              actions: [
                QuietButton(
                  'Try again',
                  onPressed: () => ref.invalidate(sourcesListProvider),
                ),
              ],
            ),
            if (offline)
              for (final p in cached)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CineSpace.s4,
                    vertical: CineSpace.s2,
                  ),
                  child: Text(
                    p.name,
                    style: cineText(context, t.typeTitle, color: t.colorInk60),
                  ),
                ),
          ],
        ),
      );
    }

    var all = scope.filter(
      sourcesAsync.valueOrNull ?? const <SourceSummary>[],
      (s) => s.id,
    );
    if (!gateOpen) {
      all = [
        for (final s in all)
          if (!s.mature) s,
      ];
    }
    final byId = {for (final s in all) s.id: s};
    final pinnedRows = [
      for (final p in pinsState?.pins ?? const <SourcePin>[])
        if (p.available && byId[p.sourceId] != null) byId[p.sourceId]!,
    ];
    bool matches(SourceSummary s) =>
        query.isEmpty ||
        s.name.toLowerCase().contains(query) ||
        s.id.toLowerCase().contains(query);
    final shownPinned = pinnedRows.where(matches).toList();
    _visible = [for (final r in pinnedRows) r.id];
    final shownAll = [
      for (final s in all)
        if (matches(s) && (filter != SourcesFilter.mature || s.mature)) s,
    ];
    // After the 18+ gate the server-wide summary would over-count.
    final rowsHealthy = all.where((s) => s.health?.status.name == 'ok').length;
    final healthy = gateOpen ? (summary?.ok ?? rowsHealthy) : rowsHealthy;
    final deck =
        '${all.length} sources · $healthy healthy · ${pinnedRows.length} pinned';
    const pinReason =
        "Pinned sources couldn't be loaded, so pinning is off until they are.";

    SourceRow row(SourceSummary s, {Widget? handle, int index = 0}) {
      final pinned = pinsState?.contains(s.id) ?? false;
      return SourceRow(
        key: ValueKey('row-${s.id}-${handle != null}'),
        source: s,
        pinned: pinned,
        pinEnabled: pinsOk,
        pinReason: pinReason,
        focusNode: _node(s.id),
        onOpen: () => context.push(Routes.source(s.id)),
        onTogglePin: () => _toggle(s),
        onMenu: () =>
            _menu(s, pinned: pinned, index: index, last: pinnedRows.length - 1),
        trailingHandle: handle,
      );
    }

    final none = all.isEmpty;
    final noMatch = !none && shownAll.isEmpty && query.isNotEmpty;

    return scaffold(
      CinePullToReprint(
        onRefresh: () async {
          ref.invalidate(sourcesListProvider);
          await ref.read(sourcePinsProvider.notifier).refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                tablet ? CineSpace.s8 : CineSpace.s4,
                CineSpace.s6,
                CineSpace.s4,
                CineSpace.s2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Kicker('No. 04 — Discover / Sources'),
                  const SizedBox(height: CineSpace.s2),
                  HeadingFocus(
                    child: SetHeading(
                        'Sources',
                        id: 'sources',
                        style: cineText(context, t.typeMasthead),
                        cap: t.typeMasthead.cap,
                        level: 1,
                        trigger: SetTrigger.mount,
                      ),
                  ),
                  Text(
                    deck,
                    style: cineText(context, t.typeDeck, color: t.colorInk60),
                  ),
                  const SizedBox(height: CineSpace.s2),
                  const DrawnRule(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
              child: IndexField(
                controller: _filter,
                focusNode: _filterFocus,
                hint: 'Filter sources',
                compact: true,
                onChanged: (v) =>
                    ref.read(sourcesFilterQueryProvider.notifier).state = v,
                onSubmitted: (v) =>
                    ref.read(sourcesFilterQueryProvider.notifier).state = v,
              ),
            ),
            SlugTabs(
              folios: false,
              labels: [
                'ALL',
                'PINNED${raisedCount(pinnedRows.length)}',
                if (gateOpen) '18+',
              ],
              selected: switch (filter) {
                SourcesFilter.all => 0,
                SourcesFilter.pinned => 1,
                SourcesFilter.mature => 2,
              },
              onSelected: (i) {
                unawaited(
                  ref.read(skinHapticsProvider).fire(HapticEvent.select),
                );
                ref.read(sourcesFilterProvider.notifier).state = switch (i) {
                  1 => SourcesFilter.pinned,
                  2 => SourcesFilter.mature,
                  _ => SourcesFilter.all,
                };
              },
            ),
            if (pinsAsync.hasValue && !pinsOk && !pinsAsync.isLoading)
              CineNotice(
                kicker: 'NOTE',
                kickerColor: t.colorSpot,
                headline: pinReason,
                actions: [
                  QuietButton(
                    'Try again',
                    onPressed: () =>
                        ref.read(sourcePinsProvider.notifier).refresh(),
                  ),
                ],
              ),
            if (!none) const SourceTableHead(),
            if (none)
              const CineNotice(
                kicker: 'NOTE',
                headline: 'No sources installed on this server.',
              )
            else if (noMatch)
              CineNotice(
                kicker: 'NOTE',
                headline: 'No sources match "${_filter.text.trim()}".',
              )
            else ...[
              if (filter != SourcesFilter.mature) ...[
                const SectionHead(null, 'Pinned'),
                if (pinnedRows.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: CineSpace.s4),
                    child: Text(
                      'No pinned sources. Tap the pin on any source to keep it at the top.',
                      style:
                          cineText(context, t.typeCaption, color: t.colorInk60),
                    ),
                  )
                else
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    // The drag proxy lives in the Overlay, above the Scaffold's
                    // Material: the row's InkWell needs its own.
                    proxyDecorator: (child, _, __) => Material(
                      type: MaterialType.transparency,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.colorPaper0,
                          border: Border.all(color: t.colorInk100),
                        ),
                        child: child,
                      ),
                    ),
                    onReorderItem: (from, to) {
                      unawaited(
                        ref.read(skinHapticsProvider).fire(HapticEvent.select),
                      );
                      final id = shownPinned[from].id;
                      // Drop position in the filtered list -> slot in the full visible order.
                      final dest = _visible.indexOf(
                        shownPinned[to.clamp(0, shownPinned.length - 1)].id,
                      );
                      unawaited(_move(id, (_, __) => dest));
                    },
                    children: [
                      for (var i = 0; i < shownPinned.length; i++)
                        KeyedSubtree(
                          key: ValueKey('pinned-${shownPinned[i].id}'),
                          child: row(
                            shownPinned[i],
                            index: i,
                            handle: ReorderableDragStartListener(
                              index: i,
                              child: SizedBox(
                                width: 32,
                                height: 48,
                                child: Icon(
                                  kDotsSixVertical,
                                  size: 20,
                                  color: t.colorInk60,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
              if (filter != SourcesFilter.pinned) ...[
                const SectionHead(null, 'All sources'),
                for (final s in shownAll) row(s),
              ],
            ],
            const SizedBox(height: CineSpace.s16),
          ],
        ),
      ),
    );
  }
}
