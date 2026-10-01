import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/utils/you_cards.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/app_update_provider.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/circle_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/orb_lift.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/profile_block.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/reading_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/wrapped_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_lists.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart' show useGlassRefresh;
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:motor/motor.dart';

/// The You hub's clock (the Wrapped card's window); tests and captures pin it.
final youClockProvider = Provider<DateTime Function()>((ref) => DateTime.now, name: 'youClock');

/// You (`/more`, ScreenId `index`, glass 8.24): the profile block, the Reading, Wrapped and Circle cards, the grouped lists, and
/// the Orb lift on the first arrival per app session per profile (phone frame only).
class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({super.key, this.platform, this.clock});
  final TargetPlatform? platform;

  /// Tests and captures: a fixed "now" for the Wrapped card.
  final DateTime Function()? clock;

  @override
  ConsumerState<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends ConsumerState<YouScreen> with TickerProviderStateMixin {
  final GlassPullToRefreshController _refresh = GlassPullToRefreshController();
  final GlobalKey _orbKey = GlobalKey(debugLabel: 'you orb');
  late final VoidCallback _offRefresh;
  late final SingleMotionController _fade = SingleMotionController(motion: const Motion.linear(Duration(milliseconds: 200)), vsync: this, initialValue: 1);
  bool _lifting = false;
  OrbLift? _lift;

  @override
  void initState() {
    super.initState();
    _offRefresh = useGlassRefresh(() => unawaited(_refresh.refresh()));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_maybeLift()));
  }

  @override
  void dispose() {
    _offRefresh();
    _lift?.cancel();
    _refresh.dispose();
    _fade.dispose();
    super.dispose();
  }

  /// The orb slot's global rect; null when it is not laid out (or its element is not active this frame, a route rebuild).
  Rect? _rectOf(GlobalKey k) {
    try {
      final box = k.currentContext?.findRenderObject() as RenderBox?;
      return box == null || !box.hasSize || !box.attached ? null : box.localToGlobal(Offset.zero) & box.size;
    } on FlutterError {
      return null;
    }
  }

  /// The first arrival per app session per profile on the phone frame lifts the orb out of the dock; later ones (and other frames)
  /// keep the shell's tab cross-fade.
  Future<void> _maybeLift() async {
    if (!mounted || GlassFrame.of(context) != GlassFrameKind.phone) return;
    final pid = ref.read(activeProfileProvider)?.id;
    final shown = ref.read(youOrbLiftShownProvider);
    if (pid == null || shown.contains(pid)) return;
    ref.read(youOrbLiftShownProvider.notifier).state = {...shown, pid};
    final to = _rectOf(_orbKey);
    if (to == null) return;
    setState(() => _lifting = true);
    if (ref.read(glassMotionPrefsProvider).reduced) {
      // Reduced motion: a 200 ms cross-fade of the orb in place (GlassMotion swaps the reduced form in).
      _fade.value = 0;
      setState(() => _lifting = false);
      await GlassMotion.playMotor(MotionName.orbLift, _fade, 1);
      return;
    }
    _lift = startOrbLift(context: context, vsync: this, from: dockTabRect(context, GlassTab.you), to: to, orb: (s) => YouOrb(size: s));
    await _lift?.done;
    _lift = null;
    if (mounted) setState(() => _lifting = false);
  }

  Future<RefreshResult> _onRefresh() async {
    ref
      ..invalidate(numbersStatisticsProvider(7))
      ..invalidate(numbersStatisticsProvider(1))
      ..invalidate(circleMembersProvider)
      ..invalidate(circleFeedProvider(null))
      ..invalidate(appUpdateProvider);
    try {
      await ref.read(numbersStatisticsProvider(7).future);
    } catch (_) {}
    return RefreshResult.changed;
  }

  @override
  Widget build(BuildContext context) {
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    final offline = ref.watch(glassOfflineProvider);
    ref.watch(dailyGoalProvider);
    final DateTime Function() clock = widget.clock ?? ref.watch(youClockProvider);
    final now = clock();
    final year = wrappedCardYear(now);
    final profileLoading = ref.watch(activeProfileProvider) == null && ref.watch(profilesProvider).isLoading;
    final block = profileLoading
        ? const ProfileBlockSkeleton()
        : AnimatedBuilder(animation: _fade, builder: (_, __) => ProfileBlock(orbKey: _orbKey, orbOpacity: _lifting ? 0 : _fade.value));
    final cards = <Widget>[
      ReadingCard(offline: offline),
      if (year != null) WrappedCard(year: year),
      CircleCard(offline: offline),
    ];
    Widget gap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w);
    final Widget content;
    if (phone) {
      content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        gap(block),
        for (final c in cards) gap(c),
        YouLists(platform: widget.platform),
      ],);
    } else {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [gap(block), gap(cards.first)])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final c in cards.skip(1)) gap(c)])),
            ],),
            YouLists(platform: widget.platform),
          ],),
        ),
      );
    }
    return GlassScaffold(
      title: 'You',
      leading: GlassLeading.none,
      overflow: [GlassMenuEntry(label: 'Refresh', onSelected: () => unawaited(_refresh.refresh()))],
      refreshSliver: GlassPullToRefresh(controller: _refresh, onRefresh: _onRefresh),
      slivers: [SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: 24), child: content))],
    );
  }
}
