import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show project;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The content of the accessory capsule (glass 7.15), a shape of the dock's group: Now narrating, then Downloading, then Continue.
/// A downward swipe projected past 40 px hides it for the session (narration pauses first, with an Undo toast).
class GlassAccessoryBody extends ConsumerWidget {
  const GlassAccessoryBody({super.key, required this.state, required this.minimised});
  final GlassAccessoryState state;
  final bool minimised;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = state.narration, d = state.downloading, c = state.continueItem;
    final Widget content;
    if (n != null) {
      content = _Narrating(n: n, minimised: minimised);
    } else if (d != null) {
      content = _Downloading(d: d, minimised: minimised);
    } else if (c != null) {
      content = _Continue(c: c, minimised: minimised);
    } else {
      return const SizedBox.shrink();
    }
    void hide() {
      if (n != null && n.playing) {
        n.onPlayPause();
        showGlassToast(ref, GlassToastSpec('Paused', undo: n.onPlayPause));
      }
      ref.read(glassAccessoryProvider.notifier).hideForSession();
    }

    return Semantics(
      container: true,
      onDismiss: hide,
      customSemanticsActions: {const CustomSemanticsAction(label: 'Dismiss'): hide},
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (e) {
          if (project(0, e.velocity.pixelsPerSecond.dy) >= 40) {
            if (n?.onStop != null) {
              n!.onStop!();
            } else {
              hide();
            }
          }
        },
        onLongPress: () => unawaited(
          showGlassMenu(
            context,
            anchor: globalRectOf(context),
            title: 'Accessory',
            entries: [
              GlassMenuEntry(label: 'Hide for this session', onSelected: hide),
              GlassMenuEntry(
                label: state.pinned ? 'Unpin' : 'Pin',
                checked: state.pinned,
                onSelected: () => ref.read(glassAccessoryProvider.notifier).setPinned(!state.pinned),
              ),
            ],
          ),
        ),
        child: content,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.title, this.trailing, required this.minimised, this.progress}) : subtitle = null;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool minimised;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              leading,
              if (!minimised) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassText(title, role: gt.typeSubhead, wght: 600, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitle != null) GlassText(subtitle!, role: gt.typeCaption1, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ] else
                const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        if (progress != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            height: 2,
            child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress!.clamp(0.0, 1.0), child: ColoredBox(color: gt.colorIris400)),
          ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onTap, required this.label});
  final bool playing;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 44,
        height: 44,
        child: GlassPressable(
          material: GlassMaterial.content,
          sink: 0.92,
          shape: const GlassShape.circle(),
          minHit: false,
          onTap: onTap,
          semanticsLabel: label,
          builder: (context, info) => Center(child: Icon(playing ? roleIcon(GlassIconRole.pause).fill : roleIcon(GlassIconRole.play).fill, size: 22, color: gt.colorOnGlass)),
        ),
      );
}

class _Narrating extends StatelessWidget {
  const _Narrating({required this.n, required this.minimised});
  final GlassNarrationAccessory n;
  final bool minimised;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => n.openPlayer(globalRectOf(context)),
        onHorizontalDragEnd: (e) {
          final w = context.size?.width ?? 300;
          final p = e.velocity.pixelsPerSecond.dx * 0.0555;
          if (p.abs() >= 0.3 * w) (p < 0 ? n.onNextChapter : n.onPreviousChapter)?.call();
        },
        child: _Row(
          minimised: minimised,
          progress: n.progress,
          leading: ListenVoiceOrb(hue: n.voiceHue ?? gt.colorIris500, initial: n.voiceInitial.isEmpty ? '·' : n.voiceInitial),
          title: n.title,
          trailing: ListenPlayButton(phase: _phaseOf(n), onTap: n.onPlayPause),
        ),
      );
}

ListenPhase _phaseOf(GlassNarrationAccessory n) => switch (n.phase) {
      1 => ListenPhase.preparing,
      2 => ListenPhase.failed,
      _ => n.playing ? ListenPhase.playing : ListenPhase.paused,
    };

class _Downloading extends StatelessWidget {
  const _Downloading({required this.d, required this.minimised});
  final GlassDownloadingAccessory d;
  final bool minimised;

  @override
  Widget build(BuildContext context) => _Row(
        minimised: minimised,
        leading: SizedBox(width: 24, height: 24, child: CustomPaint(painter: _RingPainter(d.progress, gt.colorIris400))),
        title: 'Saving ${d.chapters} chapter${d.chapters == 1 ? '' : 's'} · ${(d.progress * 100).round()} %',
        trailing: _PlayButton(playing: !d.paused, onTap: d.onToggle, label: d.paused ? 'Resume downloads' : 'Pause downloads'),
      );
}

class _Continue extends StatelessWidget {
  const _Continue({required this.c, required this.minimised});
  final GlassContinueAccessory c;
  final bool minimised;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => c.onOpen(globalRectOf(context)),
        child: _Row(
          minimised: minimised,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(width: 24, height: 32, child: c.coverUrl == null ? ColoredBox(color: gt.colorFill3) : Image.network(c.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ColoredBox(color: gt.colorFill3))),
          ),
          title: '${c.title} · ${c.subtitle}',
          trailing: SizedBox(width: 44, height: 44, child: Center(child: Icon(roleIcon(GlassIconRole.play).fill, size: 22, color: gt.colorOnGlass))),
        ),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0x33FFFFFF));
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progress.clamp(0.0, 1.0), false, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}
