
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/glass/primitives/content_mode_switch.dart' show lastModeSwitchOriginProvider;
import 'package:manhwamaniacs/skins/glass/primitives/rail.dart';
import 'package:manhwamaniacs/skins/glass/primitives/wave.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/ai_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/circle_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/continue_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/genre_chips.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rail_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/pinned_sources_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/poster_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/this_week_card.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassWaveOriginProvider;

/// Every rail of Home in one [GlassRailGroup] (one focus stop per rail, arrows within, up and down between). The first data paint and a
/// mode switch run the entrance wave; a re-rank moves a rail only while it is outside the viewport.
class HomeRailsView extends ConsumerStatefulWidget {
  const HomeRailsView({super.key, required this.rails, required this.env, required this.waveKey, this.footer});
  final List<HomeRailSpec> rails;
  final HomeRailEnv env;

  /// A new value runs the wave again (a new feed, a mode switch).
  final Object waveKey;
  final Widget? footer;

  @override
  ConsumerState<HomeRailsView> createState() => _HomeRailsViewState();
}

class _HomeRailsViewState extends ConsumerState<HomeRailsView> {
  final Map<String, GlobalKey> _keys = {};
  List<String> _order = const [];
  ScrollPosition? _position;

  GlobalKey _key(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  bool _inViewport(String id) {
    final ro = _keys[id]?.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return false;
    final r = ro.localToGlobal(Offset.zero) & ro.size;
    return r.overlaps(Offset.zero & MediaQuery.sizeOf(context));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = Scrollable.maybeOf(context)?.position;
    if (p != _position) {
      _position?.isScrollingNotifier.removeListener(_scrolled);
      _position = p?..isScrollingNotifier.addListener(_scrolled);
    }
  }

  void _scrolled() {
    if (mounted && _position?.isScrollingNotifier.value == false) setState(() {});
  }

  @override
  void dispose() {
    _position?.isScrollingNotifier.removeListener(_scrolled);
    super.dispose();
  }

  Widget _rail(HomeRailSpec r) => switch (r.kind) {
        HomeRailKind.continueStack => HomeContinueRail(rail: r),
        HomeRailKind.posters => HomePosterRail(rail: r, env: widget.env),
        HomeRailKind.ai => HomeAiRail(rail: r, env: widget.env),
        HomeRailKind.circle => HomeCircleRail(rail: r, env: widget.env),
        HomeRailKind.chips => HomeGenreChips(rail: r),
        HomeRailKind.sources => HomePinnedSourcesRail(rail: r),
        HomeRailKind.numbers => HomeThisWeekCard(numbers: r.items.whereType<HomeNumbersItem>().first),
      };

  @override
  Widget build(BuildContext context) {
    final byId = {for (final r in widget.rails) r.id: r};
    final wanted = [for (final r in widget.rails) r.id];
    _order = gatedRailOrder(_order, wanted, _inViewport);
    final ordered = [for (final id in _order) if (byId[id] != null) byId[id]!];
    final cause = ref.read(glassWaveOriginProvider) ?? ref.read(lastModeSwitchOriginProvider) ?? Offset.zero;
    final children = [
      for (final r in ordered) KeyedSubtree(key: _key(r.id), child: Padding(padding: const EdgeInsets.only(bottom: 20), child: _rail(r))),
    ];
    return GlassRailGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassWave(key: ValueKey('${widget.waveKey}:${children.length}'), cause: cause, children: children),
          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }
}
