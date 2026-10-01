/// The small parts every listen surface shares (glass 8.16): the voice orb, the 2 px progress line, the play button with its states
/// (preparing, buffering, failed) and the numbers in the player's tiles.
library;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/contract.g.dart' show HapticEvent;
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show project;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// A role's glyph (Fill by default).
IconData listenIcon(GlassIconRole r, [GlassIconWeight w = GlassIconWeight.fill]) => glassIcons[r]![w]!;

/// A 32 px twin disc (`fill2`) with the voice's initial in its [hue] (the row, the accessories, the cast rows).
class ListenVoiceOrb extends StatelessWidget {
  const ListenVoiceOrb({super.key, required this.hue, required this.initial, this.size = 32});
  final Color hue;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gt.colorFill2,
            gradient: RadialGradient(center: const Alignment(-0.4, -0.5), radius: 0.9, colors: [hue.withValues(alpha: 0.30), hue.withValues(alpha: 0.08)]),
          ),
          child: Text(initial, style: roleStyle(context, gt.typeSubhead, wght: 700, size: size * 0.44, maxScale: 1).copyWith(color: hue), textScaler: TextScaler.noScaling),
        ),
      );
}

/// The 2 px progress line along an edge: the played part in `iris500`, the buffered part at 35 %.
class ListenProgressLine extends StatelessWidget {
  const ListenProgressLine({super.key, required this.progress, this.buffered = 0});
  final double progress, buffered;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 2,
        child: Stack(
          children: [
            FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: buffered.clamp(0.0, 1.0), child: ColoredBox(color: gt.colorIris500.withValues(alpha: 0.35), child: const SizedBox.expand())),
            FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress.clamp(0.0, 1.0), child: ColoredBox(color: gt.colorIris500, child: const SizedBox.expand())),
          ],
        ),
      );
}

/// What the play button and the lines around it say about the narration (glass 8.16.8).
enum ListenPhase { idle, preparing, buffering, playing, paused, failed }

ListenPhase listenPhaseOf(NarrationState s) => switch (s.status) {
      NarrationStatus.preparing => ListenPhase.preparing,
      NarrationStatus.loading || NarrationStatus.buffering => ListenPhase.buffering,
      NarrationStatus.playing => ListenPhase.playing,
      NarrationStatus.paused || NarrationStatus.completed => ListenPhase.paused,
      NarrationStatus.failed => ListenPhase.failed,
      NarrationStatus.idle => ListenPhase.idle,
    };

String listenPhaseLabel(ListenPhase p) => switch (p) {
      ListenPhase.preparing => 'Preparing audio',
      ListenPhase.playing => 'Pause',
      ListenPhase.failed => "Audio couldn't load, retry",
      ListenPhase.buffering => 'Loading audio',
      _ => 'Play',
    };

/// The row's and the accessories' play/pause: a 44 px `fill2` twin circle; a liquid ring while preparing, the liquid spinner while
/// buffering, a `warning` ring when failed. [disabledReason] makes it inert ("Needs a connection or saved audio").
class ListenPlayButton extends ConsumerWidget {
  const ListenPlayButton({super.key, required this.phase, required this.onTap, this.size = 44, this.disabledReason, this.tinted = false});
  final ListenPhase phase;
  final VoidCallback onTap;
  final double size;
  final String? disabledReason;
  final bool tinted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glyph = phase == ListenPhase.playing ? listenIcon(GlassIconRole.pause) : (phase == ListenPhase.failed ? PhosphorFill.arrowClockwise : listenIcon(GlassIconRole.play));
    final busy = phase == ListenPhase.preparing || phase == ListenPhase.buffering;
    final disabled = disabledReason != null;
    return SizedBox(
      width: size,
      height: size,
      child: GlassPressable(
        material: GlassMaterial.content,
        sink: 0.92,
        shape: const GlassShape.circle(),
        minHit: false,
        enabled: !disabled,
        onTap: onTap,
        semanticsLabel: listenPhaseLabel(phase),
        semanticsHint: disabledReason,
        disabledReason: disabledReason,
        builder: (context, info) => Container(
          margin: EdgeInsets.all((size - 36) / 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tinted ? gt.colorIris600.withValues(alpha: 0.86) : gt.colorFill2,
            border: phase == ListenPhase.failed ? Border.all(color: gt.colorWarning, width: 2) : null,
          ),
          child: Center(
            child: busy
                ? GlassSpinner(size: 18, color: gt.colorOnGlass, label: phase == ListenPhase.preparing ? 'Preparing audio' : null)
                : Icon(glyph, size: 18, color: disabled ? gt.colorLabel3 : gt.colorOnGlass),
          ),
        ),
      ),
    );
  }
}

/// "5:12" and "-18:40" in `mono`.
String listenClock(int ms, {bool remaining = false}) {
  final s = (ms.abs() / 1000).floor();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  final t = h > 0 ? '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}' : '$m:${sec.toString().padLeft(2, '0')}';
  return remaining && ms > 0 ? '−$t' : t;
}

/// "5 minutes 12 of 23 minutes 52" for the scrubber's semantics value.
String listenSpokenClock(int ms, int total) {
  String one(int v) {
    final s = (v / 1000).floor();
    return '${s ~/ 60} minutes ${s % 60}';
  }

  return '${one(ms)} of ${one(total)}';
}

/// Announces [message] politely (a speaker change, a chapter change).
void listenAnnounce(BuildContext context, String message) {
  try {
    SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context));
  } catch (_) {}
}

/// The row's and the accessory's shared gestures (glass 8.16.1, 7.15, D2): a tap opens the player; a sideways projection past 30 % of
/// the width changes chapter (`chapter.next`); a downward projection past 40 px stops with Undo; a 450 ms press opens Pin / Hide;
/// `Semantics(onDismiss:)` and a "Dismiss" custom action hide it for the session.
class ListenGestures extends ConsumerWidget {
  const ListenGestures({
    super.key,
    required this.child,
    required this.onOpen,
    required this.onNext,
    required this.onPrevious,
    required this.onStop,
    required this.onHide,
    required this.pinned,
    required this.onTogglePin,
    this.label = 'Now narrating',
  });

  final Widget child;
  final void Function(Rect from) onOpen;
  final VoidCallback onNext, onPrevious, onStop, onHide, onTogglePin;
  final bool pinned;
  final String label;

  Rect _rect(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
        container: true,
        onDismiss: onHide,
        customSemanticsActions: {const CustomSemanticsAction(label: 'Dismiss'): onHide},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onOpen(_rect(context)),
          onHorizontalDragEnd: (e) {
            final w = context.size?.width ?? 300;
            final p = project(0, e.velocity.pixelsPerSecond.dx);
            if (p.abs() >= 0.3 * w) {
              glassFire(ref, HapticEvent.chapterNext);
              (p < 0 ? onNext : onPrevious)();
            }
          },
          onVerticalDragEnd: (e) {
            if (project(0, e.velocity.pixelsPerSecond.dy) >= 40) onStop();
          },
          onLongPress: () {
            glassFire(ref, HapticEvent.longpressOpen);
            showGlassMenu(
              context,
              anchor: _rect(context),
              title: label,
              entries: [
                GlassMenuEntry(label: pinned ? 'Unpin' : 'Pin', checked: pinned, onSelected: onTogglePin),
                GlassMenuEntry(label: 'Hide for this session', onSelected: onHide),
              ],
            );
          },
          child: child,
        ),
      );
}

/// The live sleep countdown ("12:40", `mono`) while a minutes timer runs; nothing otherwise.
class ListenSleepCountdown extends StatelessWidget {
  const ListenSleepCountdown({super.key, required this.narration, this.padRight = 6});
  final NarrationController narration;
  final double padRight;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<SleepState>(
        valueListenable: narration.sleepState,
        builder: (context, s, _) {
          final c = s.countdown;
          if (c == null) return const SizedBox.shrink();
          return Padding(padding: EdgeInsets.only(right: padRight), child: Semantics(label: 'Sleep timer $c', excludeSemantics: true, child: GlassText(c, role: gt.typeMono, size: 12, onGlass: true, maxScale: 1.3)));
        },
      );
}
