import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/presence.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_orb.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const double kArcBandHeight = 120;

/// The accessible name of a member's orb (glass 9.3.1): "Aarav, reading Omniscient Reader now", "Mira, active today", "Kai,
/// away, 12-day streak".
String presenceLabel(CircleMember m, PresenceState s) {
  final streak = m.streak == null ? '' : ', ${m.streak!.currentDays}-day streak';
  return switch (s) {
    PresenceState.reading => '${m.name}, reading ${m.now?.title ?? ''} now$streak',
    PresenceState.today => '${m.name}, active today$streak',
    PresenceState.away => '${m.name}, away$streak',
  };
}

/// The presence arc (glass 9.3.1): each member's orb placed by [arcLayout]; positions and sizes drift on `springDrift` when
/// states change. Reading now wears the breathing `bloom` ring and "Reading *title*" (the chapter withheld); active today a
/// static ring at 40 %; away no ring at 0.7. A shared streak adds the 16 px flame and count on a 24 px backing disc. Read front
/// to back as a list; arrows move along the arc.
class PresenceArc extends ConsumerStatefulWidget {
  const PresenceArc({super.key, required this.members, required this.now, this.ringPhase});
  final List<CircleMember> members;
  final DateTime now;

  /// Captures: freeze the breathing ring at this phase.
  final double? ringPhase;

  @override
  ConsumerState<PresenceArc> createState() => _PresenceArcState();
}

class _PresenceArcState extends ConsumerState<PresenceArc> {
  final Map<int, FocusNode> _nodes = {};

  FocusNode _node(int id) => _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'arc orb $id'));

  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _move(List<CircleMember> order, int delta) {
    final i = order.indexWhere((m) => _nodes[m.profileId]?.hasFocus ?? false);
    if (i < 0) return;
    final j = (i + delta).clamp(0, order.length - 1);
    _node(order[j].profileId).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final order = arcOrder(widget.members, widget.now);
    final states = [for (final m in order) presenceState(m, widget.now)];
    return LayoutBuilder(
      builder: (context, c) {
        final slots = arcLayout(order.length, c.maxWidth, states: states);
        // Spatial order on the arc (left to right) for the arrows; the list order (front to back) for screen readers.
        final byX = [for (var i = 0; i < order.length; i++) i]..sort((a, b) => slots[a].centre.dx.compareTo(slots[b].centre.dx));
        final spatial = [for (final i in byX) order[i]];
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowRight): () => _move(spatial, 1),
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _move(spatial, -1),
            const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(spatial, 1),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(spatial, -1),
          },
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: 'Your Circle',
              child: SizedBox(
                height: kArcBandHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < order.length; i++)
                      _ArcOrb(
                        key: ValueKey(order[i].profileId),
                        member: order[i],
                        state: states[i],
                        slot: slots[i],
                        index: i,
                        focusNode: _node(order[i].profileId),
                        ringPhase: widget.ringPhase,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArcOrb extends StatelessWidget {
  const _ArcOrb({super.key, required this.member, required this.state, required this.slot, required this.index, required this.focusNode, this.ringPhase});
  final CircleMember member;
  final PresenceState state;
  final ArcSlot slot;
  final int index;
  final FocusNode focusNode;
  final double? ringPhase;

  @override
  Widget build(BuildContext context) {
    final reading = state == PresenceState.reading;
    return SpringValue(
      value: slot.centre.dx,
      spring: gt.springDrift,
      name: MotionName.presenceDrift,
      builder: (context, x, _) => SpringValue(
        value: slot.centre.dy,
        spring: gt.springDrift,
        builder: (context, y, _) => SpringValue(
          value: slot.size,
          spring: gt.springDrift,
          builder: (context, size, _) {
            const w = 96.0;
            return Positioned(
              left: x - w / 2,
              top: y - size / 2 - 5,
              width: w,
              child: Semantics(
                sortKey: OrdinalSortKey(index.toDouble()),
                child: FocusTraversalOrder(
                  order: NumericFocusOrder(index.toDouble()),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PresenceRing(
                            state: state,
                            size: size,
                            phase: ringPhase,
                            child: CircleOrbButton(member: member, size: size, brightness: slot.brightness, semanticsLabel: presenceLabel(member, state), focusNode: focusNode),
                          ),
                          if (member.streak != null) Positioned(right: -6, bottom: -2, child: _StreakBadge(days: member.streak!.currentDays, alive: member.streak!.aliveToday)),
                        ],
                      ),
                      ExcludeSemantics(child: GlassText(member.name, role: gt.typeCaption2, color: gt.colorLabel2, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.4)),
                      if (reading && member.now != null)
                        ExcludeSemantics(
                          child: Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'Reading '),
                              TextSpan(text: member.now!.title, style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: roleStyle(context, gt.typeFootnote, maxScale: 1.4).copyWith(color: gt.colorBloom), textScaler: TextScaler.noScaling,),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The 16 px flame and the count on a 24 px backing disc (decoration inside the orb's hit area).
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days, required this.alive});
  final int days;
  final bool alive;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: gt.colorBackingDisc, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            StreakFlame(size: 16, state: alive ? FlameState.litToday : FlameState.notYetToday, days: days, semanticLabel: false),
            const SizedBox(width: 2),
            GlassText('$days', role: gt.typeCaption1, wght: 700, maxScale: 1.2),
          ],),
        ),
      );
}

/// Orb skeletons on the arc while the members load.
class PresenceArcSkeleton extends StatelessWidget {
  const PresenceArcSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final slots = arcLayout(5, c.maxWidth);
          return SizedBox(
            height: kArcBandHeight,
            child: Stack(children: [
              for (var i = 0; i < slots.length; i++)
                Positioned(left: slots[i].centre.dx - 28, top: slots[i].centre.dy - 28, child: GlassSkeleton(width: 56, height: 56, circle: true, index: i)),
            ],),
          );
        },
      );
}
