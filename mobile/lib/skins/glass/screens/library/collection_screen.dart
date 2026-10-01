import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart' show ProfileRef, SharedShelfDetail, ShelfSeriesRow;
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_order.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart' show activeProfileProvider;
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/collections/adder_orb.dart';
import 'package:manhwamaniacs/skins/glass/parts/collections/shared_shelf_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/add_series_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/density_pinch.dart' show PinchState;
import 'package:manhwamaniacs/skins/glass/screens/library/fanned_stack.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/flip_grid.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_grid.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

class _Member {
  const _Member(this.sourceId, this.seriesKey, this.series);
  final String sourceId, seriesKey;
  final FollowedSeries? series;
  String get key => '$sourceId|$seriesKey';
  String get title => series?.title ?? seriesKey.replaceAll(RegExp(r'[-_]+'), ' ');
}

/// A collection's page (glass 8.18, ScreenId `collection`): the fanned-cover header, Add series, Edit and the menu, the member grid,
/// Auto shelves read-only, reorder by drag, remove with Undo, and every state.
class GlassCollectionScreen extends ConsumerStatefulWidget {
  const GlassCollectionScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<GlassCollectionScreen> createState() => _GlassCollectionScreenState();
}

class _GlassCollectionScreenState extends ConsumerState<GlassCollectionScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fan = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  final GlobalKey _stackKey = GlobalKey();
  final GlassSelectModeController<int> _select = GlassSelectModeController<int>();
  final FlipRegistry _flip = FlipRegistry();
  final ShelfWave _wave = ShelfWave();
  final ValueNotifier<PinchState?> _live = ValueNotifier(null);
  final ValueNotifier<int?> _focused = ValueNotifier(null);
  List<_Member> _members = const [];
  List<_Member> _full = const [];

  @override
  void initState() {
    super.initState();
    unawaited(GlassMotion.play(MotionName.fanOpen, controller: _fan, target: 1));
    WidgetsBinding.instance.addPostFrameCallback(_publishRect);
  }

  void _publishRect(Duration _) {
    if (!mounted) return;
    final ro = _stackKey.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.attached) ref.read(collectionHeaderRectProvider.notifier).state = ro.localToGlobal(Offset.zero) & ro.size;
  }

  @override
  void dispose() {
    _fan.dispose();
    _select.dispose();
    _live.dispose();
    _focused.dispose();
    super.dispose();
  }

  int get _id => widget.id;
  CollectionDetailNotifier get _detail => ref.read(collectionDetailProvider(_id).notifier);

  void _openSheet(String id) {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    GoRouter.of(context).go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': id, 'collection': '$_id'}).toString());
  }

  Future<void> _remove(_Member m, String collectionName) async {
    final err = await _detail.removeSeries(sourceId: m.sourceId, seriesKey: m.seriesKey);
    if (!mounted) return;
    if (err != null) {
      showGlassToast(ref, const GlassToastSpec("Couldn't remove that series", kind: GlassToastKind.error));
      return;
    }
    showGlassToast(ref, GlassToastSpec('Removed from $collectionName', undo: () => unawaited(_detail.addSeries(sourceId: m.sourceId, seriesKey: m.seriesKey))));
  }

  Future<void> _delete(CollectionDetail d, Rect from) async {
    final ok = await showGlassAlert<bool>(
      context,
      title: 'Delete ${d.name}?',
      body: 'The series stay in your library.',
      sourceRect: from,
      actions: const [GlassAlertAction<bool>('Cancel', role: GlassAlertRole.cancel, value: false)],
      extra: Builder(builder: (ctx) => HoldToConfirm(label: 'Hold to delete', mode: HoldMode.inAlert, fallbackLabel: 'Delete collection', onConfirm: () => Navigator.of(ctx).pop(true))),
    );
    if (ok != true || !mounted) return;
    final err = await _detail.deleteCollection();
    if (!mounted) return;
    if (err != null) {
      showGlassToast(ref, const GlassToastSpec("Couldn't delete that collection", kind: GlassToastKind.error));
      return;
    }
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      GoRouter.of(context).go(Routes.collections());
    }
  }

  List<MemberKey> _reordered(int from, int to) {
    final moved = _members[from], anchor = _members[to];
    final order = [..._full]..removeWhere((m) => m.key == moved.key);
    var at = order.indexWhere((m) => m.key == anchor.key);
    if (to > from) at++;
    order.insert(at.clamp(0, order.length), moved);
    return [for (final m in order) (sourceId: m.sourceId, seriesKey: m.seriesKey)];
  }

  Future<void> _move(int from, int to) async {
    if (from == to || from < 0 || to < 0 || to >= _members.length) return;
    final ok = await ref.read(collectionOrderProvider).members(_id, _reordered(from, to));
    if (!ok && mounted) showGlassToast(ref, const GlassToastSpec("Couldn't save the order", kind: GlassToastKind.error));
  }

  Widget _lens(LensSituation s, String title, {String? description, LensAction? primary, LensAction? secondary, GlassLensTone tone = GlassLensTone.empty}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: GlassObjectLens(situation: s, title: title, description: description, tone: tone, primary: primary, secondary: secondary),
      );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(collectionDetailProvider(_id));
    final followedAsync = ref.watch(librarySeriesPickerProvider);
    final scope = ref.watch(contentModeScopeProvider);
    final gate = ref.watch(matureGateOpenProvider);
    final frame = GlassFrame.of(context);
    final width = MediaQuery.sizeOf(context).width - 2 * GlassFrame.screenMargin(context);
    final sd = ref.watch(sharedShelfDetailProvider(_id)).valueOrNull;
    final d = async.valueOrNull;
    final followed = followedAsync.valueOrNull ?? const <FollowedSeries>[];
    final smart = d?.rules != null;
    final readOnlyShared = sd != null && sd.shelf.role != 'owner';

    var full = <_Member>[];
    if (readOnlyShared) {
      full = [for (final r in sd.series) _Member(r.sourceId, r.seriesKey, null)];
    } else if (d != null) {
      final byKey = {for (final s in followed) '${s.sourceId}|${s.seriesKey}': s};
      final byIdentity = {for (final s in followed) '${s.sourceId}|${s.identity}': s};
      if (smart) {
        full = [for (final s in evaluateShelf(d.rules!, followed, contentKindOf: (s) => scope.novelsEnabled ? scope.modeOf(s.sourceId).name : null)) _Member(s.sourceId, s.seriesKey, s)];
      } else {
        full = [for (final m in d.series) _Member(m.sourceId, m.seriesKey, byKey['${m.sourceId}|${m.seriesKey}'] ?? byIdentity['${m.sourceId}|${m.seriesKey}'])];
      }
    }
    final visible = [for (final m in full) if (!scope.novelsEnabled || scope.modeOf(m.sourceId) == scope.mode) m];
    _full = full;
    _members = visible;
    final mismatch = full.isNotEmpty && visible.isEmpty && scope.novelsEnabled;

    final name = d?.name ?? sd?.shelf.name ?? 'Collection';
    final offline = async.hasError && d == null && async.error is NetworkError;
    final ui = ShelfUi(select: _select, flip: _flip, live: _live, wave: _wave, focused: _focused, downloaded: const {}, gateOpen: gate);
    final cols = frame == GlassFrameKind.phone ? 3 : 5;
    const gap = 12.0;
    final cell = (width - gap * (cols - 1)) / cols;
    final canEdit = d != null && !readOnlyShared;
    final canReorder = canEdit && !smart && visible.length > 1;

    Widget plainTile(_Member m, FollowedSeries? s) {
      if (s == null) {
        return SizedBox(
          width: cell,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(aspectRatio: 2 / 3, child: DecoratedBox(decoration: BoxDecoration(color: gt.colorSurface2, borderRadius: BorderRadius.circular(gt.radiusSm)))),
            const SizedBox(height: 6),
            GlassLabel(m.title, role: gt.typeFootnote, maxLines: 2),
            if (!readOnlyShared) GlassLabel('No longer in your library', role: gt.typeCaption1, color: gt.colorLabel3, maxLines: 2),
          ],),
        );
      }
      return GestureDetector(
        onSecondaryTap: canEdit && !smart ? () => unawaited(_remove(m, name)) : null,
        child: ShelfTile(series: s, ui: ui, width: cell, compact: false),
      );
    }

    // Posters someone else added to a shared shelf carry that person's 20 px orb (glass 9.3.3).
    final me = ref.watch(activeProfileProvider)?.id;
    final adders = <String, ProfileRef>{
      for (final r in sd?.series ?? const <ShelfSeriesRow>[])
        if (r.addedBy != null && r.addedBy!.profileId != me) '${r.sourceId}|${r.seriesKey}': r.addedBy!,
    };

    Widget tile(_Member m) {
      final adder = adders[m.key];
      if (adder == null) return plainTile(m, m.series);
      return Stack(clipBehavior: Clip.none, children: [
        plainTile(m, m.series),
        Positioned(left: 6, top: cell * 1.5 - 30, child: AdderOrb(member: adder)),
      ],);
    }

    Widget body;
    if (async.hasError && d == null && !readOnlyShared) {
      final e = async.error;
      body = e is ApiError && e.statusCode == 404
          ? _lens(LensSituation.notFound, "This collection isn't available", primary: LensAction('Back to collections', () => GoRouter.of(context).go(Routes.collections())))
          : offline
              ? _lens(LensSituation.offline, 'This collection needs a connection', tone: GlassLensTone.offline, primary: LensAction('Open downloads', () => GoRouter.of(context).go('/downloads')))
              : _lens(LensSituation.loadError, "Couldn't load this collection", tone: GlassLensTone.error, primary: LensAction('Try again', () => ref.invalidate(collectionDetailProvider(_id))), secondary: LensAction('Back to collections', () => GoRouter.of(context).go(Routes.collections())));
    } else if (d == null && !readOnlyShared) {
      body = GlassSkeletonGroup(child: Wrap(spacing: gap, runSpacing: gap, children: [for (var i = 0; i < 6; i++) GlassSkeleton(width: cell, height: cell * 1.5, index: i)]));
    } else if (mismatch) {
      body = _lens(LensSituation.collection, scope.isNovel ? 'No novels in this collection' : 'No titles in this collection', description: 'It holds titles from the other mode. Switch modes to see them.');
    } else if (visible.isEmpty) {
      body = smart
          ? _lens(LensSituation.collection, 'No series match these rules yet.', primary: canEdit ? LensAction('Edit rules', () => _openSheet('collection-edit')) : null)
          : _lens(LensSituation.collection, 'This collection is empty', primary: canEdit ? LensAction('Add series', () => _openSheet('add-series')) : null);
    } else if (canReorder) {
      body = GlassReorderList<_Member>(
        items: visible,
        layout: GlassReorderLayout.grid,
        columns: cols,
        nameOf: (m) => m.title,
        onReorder: (a, b) => unawaited(_move(a, b)),
        itemBuilder: (context, m, i, info) => tile(m),
      );
    } else {
      body = Wrap(spacing: gap, runSpacing: gap, children: [for (final m in visible) tile(m)]);
    }

    final covers = [for (final m in visible.take(4)) HomeCoverImage(url: m.series?.coverUrl, width: 96)];
    final first = visible.isEmpty ? null : visible.first.series;
    final palette = first == null ? null : paletteOf(null, first.ambient);
    final rules = d?.rules;

    final header = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        key: _stackKey,
        height: 220,
        child: Align(alignment: Alignment.centerLeft, child: covers.isEmpty ? const SizedBox.shrink() : FannedStack(covers: covers, open: _fan, coverWidth: 96)),
      ),
      if ((d?.description ?? sd?.shelf.description) case final desc? when desc.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 4), child: GlassText(desc, role: gt.typeCallout, color: gt.colorLabel2)),
      GlassLabel('${d?.seriesCount ?? sd?.shelf.seriesCount ?? visible.length} series', role: gt.typeSubhead, color: gt.colorLabel2),
      if (rules != null) Padding(padding: const EdgeInsets.only(top: 8), child: GlassLabel(describeRules(rules).split(' · ').join(' · '), role: gt.typeCaption1, color: gt.colorLabel3, maxLines: 3)),
      if (rules != null) const Padding(padding: EdgeInsets.only(top: 6), child: Align(alignment: Alignment.centerLeft, child: GlassChip(label: 'Auto', kind: GlassChipKind.assist))),
      if (canEdit)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            if (!smart) GlassButton(label: 'Add series', onPressed: () => _openSheet('add-series')),
            GlassButton(label: 'Edit', onPressed: () => _openSheet('collection-edit')),
          ],),
        )
      else
        const SizedBox(height: 12),
    ],);

    return LibraryKeys(
      group: 'Collection',
      bindings: [
        if (canEdit && !smart) LibraryKey(description: 'Add series', keys: const ['a'], single: true, match: kChar('a'), action: () => _openSheet('add-series')),
        if (canEdit) LibraryKey(description: 'Edit', keys: const ['e'], single: true, match: kChar('e'), action: () => _openSheet('collection-edit')),
        if (canEdit && !smart) LibraryKey(description: 'Remove the focused series', keys: const ['Delete'], match: kKey(LogicalKeyboardKey.delete), action: () => _removeFocused(name)),
        if (canEdit && !smart) LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.backspace), action: () => _removeFocused(name)),
        LibraryKey(description: 'Move through the series', keys: const ['←', '↑', '→', '↓'], match: kKey(LogicalKeyboardKey.arrowRight), action: () => FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.right)),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowLeft), action: () => FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.left)),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowUp), action: () => FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.up)),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowDown), action: () => FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.down)),
      ],
      child: GlassScaffold(
        title: name,
        leading: GlassLeading.back,
        ambient: palette == null ? null : GlassAmbientSpec.palette(palette, opacity: 0.18),
        trailing: [
          if (canEdit) GlassBarAction(id: 'menu', label: 'More', glyph: roleGlyph(GlassIconRole.overflow), onPress: () => _overflow(d)),
          // A member of someone's shared shelf (mobile/43, glass 9.3.3): Save a copy, Leave shelf (and Add series with Can add).
          if (readOnlyShared) GlassBarAction(id: 'menu', label: 'More', glyph: roleGlyph(GlassIconRole.overflow), onPress: () => _sharedMenu(sd)),
        ],
        slivers: [
          SliverToBoxAdapter(child: header),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 24), child: body)),
        ],
      ),
    );
  }

  void _removeFocused(String name) {
    final id = _focused.value;
    if (id == null) return;
    final m = _members.where((m) => m.series?.id == id).firstOrNull;
    if (m != null) unawaited(_remove(m, name));
  }

  void _overflow(CollectionDetail? d) {
    if (d == null) return;
    final w = MediaQuery.sizeOf(context).width;
    final anchor = Rect.fromLTWH(w - 24, 80, 1, 1);
    unawaited(showGlassMenu(context, anchor: anchor, title: d.name, entries: [
      GlassMenuEntry(label: 'Edit', onSelected: () => _openSheet('collection-edit')),
      if (d.rules == null) GlassMenuEntry(label: 'Add series', onSelected: () => _openSheet('add-series')),
      GlassMenuEntry(label: 'Share', onSelected: () => _openSheet('collection-share')),
      GlassMenuEntry(label: 'Delete collection', destructive: true, separatorBefore: true, onSelected: () => unawaited(_delete(d, anchor))),
    ],),);
  }
}

extension _SharedShelf on _GlassCollectionScreenState {
  void _sharedMenu(SharedShelfDetail sd) {
    final w = MediaQuery.sizeOf(context).width;
    final router = GoRouter.of(context);
    final entries = [
      for (final e in sharedShelfMenu(context, ref, sd, onAddSeries: ShelfRights(sd.shelf.role).canAdd ? () => _openSheet('add-series') : null))
        if (e.label == 'Leave shelf')
          GlassMenuEntry(
            label: e.label,
            destructive: true,
            onSelected: () async {
              if (await leaveShelf(context, ref, sd.shelf)) router.go(Routes.collections());
            },
          )
        else
          e,
    ];
    unawaited(showGlassMenu(context, anchor: Rect.fromLTWH(w - 24, 80, 1, 1), title: sd.shelf.name, entries: entries));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
