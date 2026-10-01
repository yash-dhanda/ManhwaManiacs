import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/ai_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/flight.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_common.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_flow.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/print_overlay.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Step 5: the seed wall (24 World items, available first). Picking asks for 3 similar ones and
/// inserts them after the pick. A sliver: the counter and the wall.
class SeedsStep extends ConsumerStatefulWidget {
  const SeedsStep({super.key, required this.catalogKey});
  final CatalogKey catalogKey;

  @override
  ConsumerState<SeedsStep> createState() => _SeedsStepState();
}

class _SeedsStepState extends ConsumerState<SeedsStep> {
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'seeds');
  List<WorldItem>? _wall;

  /// Ids inserted by a pick, with their entrance delay (32 ms apart).
  final Map<int, int> _inserted = {};
  bool _sawLoading = false;
  String? _reason;
  bool _noteShown = false;

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  void _tap(WorldItem it) {
    cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
    final first = ref.read(onboardingFlowProvider.notifier).togglePick(it);
    if (first && it.anilistId > 0) unawaited(_similar(it));
  }

  Future<void> _similar(WorldItem it) async {
    final r = await ref.read(similarSeedsProvider(it.anilistId).future);
    if (!mounted) return;
    if (!r.available) {
      if (!_noteShown) {
        setState(() {
          _noteShown = true;
          _reason = r.reason;
        });
      }
      return;
    }
    final wall = _wall!;
    final have = {for (final w in wall) w.anilistId};
    final add = [for (final s in r.items) if (!have.contains(s.anilistId)) s].take(3).toList();
    if (add.isEmpty) return;
    final at = wall.indexWhere((w) => w.anilistId == it.anilistId) + 1;
    setState(() {
      for (var i = 0; i < add.length; i++) {
        _inserted[add[i].anilistId] = 32 * i;
      }
      _wall = [...wall.take(at), ...add, ...wall.skip(at)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(onboardingCatalogProvider(widget.catalogKey));
    final data = catalog.valueOrNull;
    final Widget wall;
    if (data == null && catalog.isLoading) {
      _sawLoading = true;
      wall = const AfterWait(child: _SeedsGalley());
    } else if (data == null) {
      wall = const SeedsUnreachable();
    } else {
      if (_wall == null) {
        _wall = [...data.seeds];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(onboardingFlowProvider.notifier).adoptPicks(_wall!);
        });
      }
      wall = AnimatedSwitcher(
        duration: _sawLoading && !CineMotion.reduced(context) ? CineDur.beat : Duration.zero,
        child: _Wall(key: const ValueKey('wall'), items: _wall!, inserted: _inserted, skipSet: _sawLoading, scope: _scope, onTap: _tap),
      );
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (data != null) const _Counter(),
          if (_reason != null) _Note(reason: _reason!),
          const SizedBox(height: 16),
          wall,
        ],),
      ),
    );
  }
}

class _Counter extends ConsumerWidget {
  const _Counter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final n = ref.watch(onboardingFlowProvider.select((s) => s.picks.length));
    final ok = n >= 3;
    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: ok ? c.colorSet : c.colorInk60),
        duration: CineMotion.reduced(context) ? Duration.zero : c.durBeat,
        builder: (_, color, __) => CineRoleText(ok ? '$n PICKED' : '$n / 3 PICKED', c.typeFolio, color: color),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final copy = aiCopyForCode(reason);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CineRoleText(copy.kicker, c.typeKicker, color: c.colorInk45),
        CineRoleText(copy.text, c.typeCaption, color: c.colorInk60),
      ],),
    );
  }
}

int _cols(BuildContext context) => onboardingWide(context) ? 5 : 3;
double _gap(BuildContext context) => onboardingWide(context) ? 12 : 8;

class _SeedsGalley extends StatelessWidget {
  const _SeedsGalley();

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return ExcludeSemantics(
      child: GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: _cols(context),
        mainAxisSpacing: _gap(context),
        crossAxisSpacing: _gap(context),
        childAspectRatio: 2 / 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 12; i++)
            CineFlicker(
              index: i,
              child: DecoratedBox(decoration: BoxDecoration(color: c.colorPaper1, border: Border.all(color: c.colorRule1)), child: const SizedBox.expand()),
            ),
        ],
      ),
    );
  }
}

class _Wall extends ConsumerWidget {
  const _Wall({super.key, required this.items, required this.inserted, required this.skipSet, required this.scope, required this.onTap});
  final List<WorldItem> items;
  final Map<int, int> inserted;
  final bool skipSet;
  final FocusScopeNode scope;
  final void Function(WorldItem) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cols = _cols(context);
    final ui = ref.watch(printUiProvider);
    final picks = ref.watch(onboardingFlowProvider.select((s) => s.picks));
    final flight = ref.watch(cineFlightProvider);
    final flow = ref.read(onboardingFlowProvider.notifier);
    return FocusScope(
      node: scope,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: _gap(context), crossAxisSpacing: _gap(context), childAspectRatio: 2 / 3),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final it = items[i];
          final picked = picks.any((p) => p.anilistId == it.anilistId);
          final insertDelay = inserted[it.anilistId];
          final delay = insertDelay ?? (skipSet ? 0 : (32 * (i % cols) + 64 * (i ~/ cols)).clamp(0, 480));
          final a = it.available.firstOrNull;
          Widget tile = KeyedSubtree(
            key: flow.posterKey(it.anilistId),
            child: _SeedTile(item: it, picked: picked, index: i, scope: scope, onTap: () => onTap(it)),
          );
          // The flight layer paints this poster's copy: the wall hides it in the same frame.
          tile = Visibility(
            visible: a == null || !flight.hides('${a.sourceId}:${a.seriesKey}'),
            maintainSize: true,
            maintainState: true,
            maintainAnimation: true,
            child: tile,
          );
          if (ui.printing) {
            tile = AnimatedOpacity(
              opacity: ui.fade && !ui.keep.contains(it.anilistId) ? 0 : 1,
              duration: const Duration(milliseconds: 240),
              curve: CineCurves.lift,
              child: tile,
            );
          }
          return SetIn(key: ValueKey('seed-${it.anilistId}'), delay: Duration(milliseconds: skipSet && insertDelay == null ? 0 : delay), skip: skipSet && insertDelay == null, child: tile);
        },
      ),
    );
  }
}

/// **Set**: fade 0 -> 1 and rise 8 px -> 0 over 320 ms `settle`, after [delay]. Reduced: one
/// 160 ms fade. [skip] shows it at once (a skeleton just dissolved into it).
class SetIn extends StatefulWidget {
  const SetIn({super.key, required this.delay, required this.child, this.skip = false});
  final Duration delay;
  final bool skip;
  final Widget child;

  @override
  State<SetIn> createState() => _SetInState();
}

class _SetInState extends State<SetIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _t;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.skip) {
      _c.value = 1;
      return;
    }
    final reduced = CineMotion.reduced(context);
    _c.duration = reduced ? const Duration(milliseconds: 160) : const Duration(milliseconds: 320);
    void go() {
      if (mounted) _c.forward();
    }

    widget.delay == Duration.zero ? go() : _t = Timer(widget.delay, go);
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = CineMotion.reduced(context);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = CineCurves.settle.transform(_c.value);
        return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, reduced ? 0 : 8 * (1 - t)), child: child));
      },
    );
  }
}

class _SeedTile extends StatelessWidget {
  const _SeedTile({required this.item, required this.picked, required this.index, required this.scope, required this.onTap});
  final WorldItem item;
  final bool picked;
  final int index;
  final FocusScopeNode scope;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final info = item.available.isEmpty;
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, e) => rovingKey(FocusManager.instance.primaryFocus ?? node, e, scope: scope, grid: true),
      child: Semantics(
        button: true,
        toggled: picked,
        label: picked ? '${item.title}, picked' : item.title,
        excludeSemantics: true,
        onTap: onTap,
        child: Tooltip(
          message: item.title,
          triggerMode: TooltipTriggerMode.longPress,
          child: SelectFrame(
            selected: picked,
            child: CinePoster(
              title: item.title,
              url: item.coverUrl,
              caption: CinePosterCaption.wall,
              withCredentials: false,
              flickerIndex: index,
              badges: [if (item.isAdult) CineBadge.certificate(onArt: true)],
              duotone: info ? (item.ambient?.duo ?? c.colorAmbientFallbackDuo) : null,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}
