import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/presence.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/activity_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_orb.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/letters_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/presence_arc.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/read_together_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/shelves_list.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart' show useGlassRefresh;
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

enum CircleTab { activity, letters, shelves }

CircleTab circleTabOf(String? s) => CircleTab.values.where((t) => t.name == s).firstOrNull ?? CircleTab.activity;

/// The Circle's clock (presence and day headers); captures pin it.
final circleClockProvider = Provider<DateTime Function()>((ref) => DateTime.now, name: 'glassCircleClock');

/// Whether this profile is alone on the server. The server exposes no such signal (members are only the profiles that share),
/// so this is false unless a later endpoint says so; "Your Circle is quiet" covers the empty Circle meanwhile.
final circleServerAloneProvider = Provider<bool>((ref) => false, name: 'glassCircleAlone');

/// The bloom field: the `aurora3` `#FF9ED8` blob at the screen's field opacity (the people light).
final GlassAmbientSpec kBloomField = GlassAmbientSpec.palette(CoverPalette(a: [gt.colorAurora3], l: 0.62, lMax: 0.62), opacity: 0.20);

/// Circle (`/circle`, ScreenId `circle`, glass 9.3.1): the presence arc, Activity · Letters · Shelves on `?tab=`, every state, the
/// wide right column at 1,280 px and the "Circle" keys. The whole screen polls through `GlassCirclePollScope`.
class CircleScreen extends ConsumerStatefulWidget {
  const CircleScreen({super.key, this.tab, this.ringPhase});
  final String? tab;

  /// Captures: freeze the breathing ring.
  final double? ringPhase;

  @override
  ConsumerState<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends ConsumerState<CircleScreen> {
  final GlassPullToRefreshController _refresh = GlassPullToRefreshController();
  final RowHandles _rows = RowHandles();
  final Map<CircleTab, GlobalKey> _sections = {for (final t in CircleTab.values) t: GlobalKey()};
  final FocusNode _screenFocus = FocusNode(debugLabel: 'circle screen');
  late final VoidCallback _offRefresh;
  late CircleTab _tab = circleTabOf(widget.tab);

  @override
  void initState() {
    super.initState();
    _offRefresh = useGlassRefresh(() => unawaited(_refresh.refresh()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusSection(_tab));
  }

  @override
  void didUpdateWidget(CircleScreen old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) {
      _tab = circleTabOf(widget.tab);
      _focusSection(_tab);
    }
  }

  @override
  void dispose() {
    _offRefresh();
    _screenFocus.dispose();
    _refresh.dispose();
    _rows.dispose();
    super.dispose();
  }

  bool get _wide => MediaQuery.sizeOf(context).width >= 1280 && GlassFrame.of(context) != GlassFrameKind.phone;

  /// On the wide layout `?tab=letters|shelves` scrolls to and focuses that section.
  void _focusSection(CircleTab t) {
    if (!mounted || !_wide || t == CircleTab.activity) return;
    final c = _sections[t]!.currentContext;
    if (c != null) unawaited(Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 250)));
  }

  void _setTab(CircleTab t) {
    if (t == _tab) return;
    glassFire(ref, HapticEvent.select);
    setState(() => _tab = t);
    unawaited(ref.read(skinRouterProvider).replace<void>(Routes.circle({'tab': t.name})));
    // The focused row may leave with its tab: keep the keys alive on the screen itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final f = FocusManager.instance.primaryFocus;
      if (mounted && (f == null || f.context == null || !f.context!.mounted)) _screenFocus.requestFocus();
    });
  }

  void _step(int d) => _setTab(CircleTab.values[(_tab.index + d).clamp(0, CircleTab.values.length - 1)]);

  Future<RefreshResult> _onRefresh() async {
    ref
      ..invalidate(circleMembersProvider)
      ..invalidate(circleFeedProvider(null))
      ..invalidate(lettersProvider)
      ..invalidate(sentLettersProvider)
      ..invalidate(sharedCollectionsProvider);
    try {
      await ref.read(circleMembersProvider.future);
    } catch (_) {}
    return RefreshResult.changed;
  }

  void _friendOfFocused() {
    final id = _rows.focusedId;
    final item = id == null ? null : (ref.read(circleFeedProvider(null)).valueOrNull?.items ?? const <FeedItem>[]).where((i) => i.id == id).firstOrNull;
    if (item != null) unawaited(openFriend(ref, item.actor, returnFocus: _rows.focusOf(id!)));
  }

  void _openFocused() {
    final id = _rows.focusedId;
    final item = id == null ? null : (ref.read(circleFeedProvider(null)).valueOrNull?.items ?? const <FeedItem>[]).where((i) => i.id == id).firstOrNull;
    if (item != null) unawaited(ref.read(skinRouterProvider).push<void>(Routes.feature(item.sourceId, item.seriesKey)));
  }

  List<ShortcutEntry> _keys() => [
        ShortcutEntry(group: 'Circle', activator: const SingleActivator(LogicalKeyboardKey.bracketLeft), description: 'Previous tab', onInvoke: () => _step(-1), singleKey: true, keys: const ['[']),
        ShortcutEntry(group: 'Circle', activator: const SingleActivator(LogicalKeyboardKey.bracketRight), description: 'Next tab', onInvoke: () => _step(1), singleKey: true, keys: const [']']),
        ShortcutEntry(group: 'Circle', activator: const SingleActivator(LogicalKeyboardKey.keyJ), description: 'Next row', onInvoke: () => _rows.move(1), singleKey: true, keys: const ['j']),
        ShortcutEntry(group: 'Circle', activator: const SingleActivator(LogicalKeyboardKey.keyK), description: 'Previous row', onInvoke: () => _rows.move(-1), singleKey: true, keys: const ['k']),
        ShortcutEntry(group: 'Circle', activator: const SingleActivator(LogicalKeyboardKey.enter), description: 'Open the focused row', onInvoke: _openFocused, keys: const ['Enter']),
        ShortcutEntry(group: 'Circle', activator: const SingleActivator(LogicalKeyboardKey.keyR), description: 'Refresh', onInvoke: () => unawaited(_refresh.refresh()), singleKey: true, keys: const ['r']),
        ShortcutEntry(group: 'Circle', activator: const SingleActivator(LogicalKeyboardKey.keyE), description: "React to the focused row's chapter", onInvoke: _rows.react, singleKey: true, keys: const ['e']),
        ShortcutEntry(group: 'Circle', activator: const SingleActivator(LogicalKeyboardKey.keyF), description: "Open the focused person's Circle page", onInvoke: _friendOfFocused, singleKey: true, keys: const ['f']),
      ];

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(glassOfflineProvider);
    final now = ref.watch(circleClockProvider)();
    final pid = ref.watch(activeProfileProvider)?.id;
    final sharing = pid == null ? null : ref.watch(sharingProvider(pid)).valueOrNull;
    final members = ref.watch(circleMembersProvider);
    final feed = ref.watch(circleFeedProvider(null));
    final newLetters = ref.watch(newLetterCountProvider);
    final margin = GlassFrame.screenMargin(context);
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    final width = MediaQuery.sizeOf(context).width;
    final wide = _wide;
    final oneColumn = !phone && width < 900;
    final notSharing = sharing != null && !sharing.activity;

    final slivers = <Widget>[];
    Widget box(Widget w) => SliverToBoxAdapter(child: w);

    if (notSharing) slivers.add(box(Padding(padding: EdgeInsets.fromLTRB(margin, 0, margin, 16), child: const ReadTogetherCard())));

    // Presence arc.
    if (members.hasValue) {
      final list = members.value!;
      if (list.isNotEmpty) {
        slivers.add(box(Padding(padding: EdgeInsets.symmetric(horizontal: phone ? 0 : margin, vertical: 8), child: PresenceArc(members: list, now: now, ringPhase: widget.ringPhase))));
      }
    } else if (members.isLoading && !offline) {
      slivers.add(box(const GlassSkeletonGroup(label: 'Loading your Circle', child: PresenceArcSkeleton())));
    }

    final membersEmpty = members.hasValue && members.value!.isEmpty;
    if (offline && !members.hasValue) {
      slivers.add(box(CircleOffline(onRetry: () async {
        ref.invalidate(circleMembersProvider);
        try {
          await ref.read(circleMembersProvider.future);
          return true;
        } catch (_) {
          return false;
        }
      },),),);
    } else if (members.hasError && !members.hasValue) {
      slivers.add(box(CircleError(onRetry: () => ref
        ..invalidate(circleMembersProvider)
        ..invalidate(circleFeedProvider(null)),),),);
    } else if (membersEmpty && !notSharing) {
      slivers.add(box(ref.watch(circleServerAloneProvider) ? const CircleOnlyYou() : const CircleQuiet()));
    } else {
      final activity = _activitySlivers(feed);
      if (wide) {
        slivers.add(SliverCrossAxisGroup(slivers: [
          SliverMainAxisGroup(slivers: activity),
          SliverConstrainedCrossAxis(
            maxExtent: 360 + margin,
            sliver: SliverPadding(
              padding: EdgeInsets.only(right: margin),
              sliver: SliverList.list(children: [
                _sectionTitle(CircleTab.letters, 'Letters', newLetters),
                const CircleLetters(),
                const SizedBox(height: 24),
                _sectionTitle(CircleTab.shelves, 'Shelves', 0),
                const _Shelves(column: true),
              ],),
            ),
          ),
        ],),);
      } else {
        slivers.add(box(Padding(
          padding: EdgeInsets.fromLTRB(margin, 8, margin, 12),
          child: Align(
            alignment: oneColumn || phone ? Alignment.center : Alignment.centerLeft,
            child: GlassSegmented<CircleTab>(
              asTabs: true,
              selected: _tab,
              onSelected: _setTab,
              segments: [
                const GlassSegment(value: CircleTab.activity, label: 'Activity'),
                GlassSegment(value: CircleTab.letters, label: newLetters > 0 ? 'Letters $newLetters' : 'Letters'),
                const GlassSegment(value: CircleTab.shelves, label: 'Shelves'),
              ],
            ),
          ),
        ),),);
        switch (_tab) {
          case CircleTab.activity:
            slivers.addAll(activity);
          case CircleTab.letters:
            slivers.add(box(const CircleLetters()));
          case CircleTab.shelves:
            slivers.add(box(const _Shelves()));
        }
      }
    }
    slivers.add(box(const SizedBox(height: 96)));

    return GlassCirclePollScope(
      child: RegisteredShortcuts(
        group: 'Circle',
        entries: _keys(),
        child: Focus(
          focusNode: _screenFocus,
          autofocus: true,
          child: GestureDetector(
          // The tabs sit over a swipeable pager: a horizontal fling moves one tab.
          onHorizontalDragEnd: wide
              ? null
              : (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() > 600) _step(v < 0 ? 1 : -1);
                },
          child: GlassScaffold(
            title: 'Circle',
            leading: GlassLeading.back,
            ambient: kBloomField,
            overflow: [GlassMenuEntry(label: 'Refresh', onSelected: () => unawaited(_refresh.refresh()))],
            refreshSliver: GlassPullToRefresh(controller: _refresh, onRefresh: _onRefresh),
            slivers: slivers,
          ),
        ),
        ),
      ),
    );
  }

  Widget _sectionTitle(CircleTab t, String title, int badge) => Padding(
        key: _sections[t],
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Focus(
          autofocus: _tab == t,
          child: Semantics(
            header: true,
            headingLevel: 2,
            child: Row(children: [
              GlassText(title, role: gt.typeTitle3),
              if (badge > 0) Padding(padding: const EdgeInsets.only(left: 8), child: GlassBadge.count(badge)),
            ],),
          ),
        ),
      );

  List<Widget> _activitySlivers(AsyncValue<CircleFeedState> feed) {
    if (feed.hasError && !feed.hasValue) {
      return [SliverToBoxAdapter(child: CircleError(onRetry: () => ref.invalidate(circleFeedProvider(null))))];
    }
    if (!feed.hasValue) return const [SliverToBoxAdapter(child: ActivitySkeleton())];
    final s = feed.value!;
    if (s.items.isEmpty) return const [SliverToBoxAdapter(child: CircleEmpty(CircleEmpty.activity))];
    final days = activityDays(s.items, ref.read(circleClockProvider)());
    _rows.order
      ..clear()
      ..addAll([for (final d in days) for (final e in d.entries) e.item.id]);
    return activitySlivers(
      days: days,
      feed: s,
      onLoadMore: () => unawaited(ref.read(circleFeedProvider(null).notifier).loadMore()),
      focusOf: _rows.focusOf,
      reactOf: _rows.reactOf,
    );
  }
}

class _Shelves extends ConsumerWidget {
  const _Shelves({this.column = false});
  final bool column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(sharedCollectionsProvider);
    final m = column ? 0.0 : GlassFrame.screenMargin(context);
    return a.when(
      data: (all) {
        final list = shelvesForCircle(all);
        if (list.isEmpty) return const CircleEmpty(CircleEmpty.shelves);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: m),
          child: Wrap(spacing: 16, runSpacing: 16, children: [for (final s in list) SharedShelfCard(key: ValueKey(s.id), shelf: s, width: column ? 340 : 320)]),
        );
      },
      loading: () => GlassSkeletonGroup(label: 'Loading shelves', child: Padding(padding: EdgeInsets.symmetric(horizontal: m), child: const GlassSkeleton(height: 180, radius: 26))),
      error: (_, __) => CircleError(title: "Couldn't load shared shelves", onRetry: () => ref.invalidate(sharedCollectionsProvider)),
    );
  }
}

/// `presenceState` of every member, for tests and the gallery.
List<PresenceState> presenceStates(List<CircleMember> ms, DateTime now) => [for (final m in arcOrder(ms, now)) presenceState(m, now)];
