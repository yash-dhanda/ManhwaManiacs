import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The desktop accessory (glass 7.16, 8.16.1): a 56 px capsule docked above the sidebar's profile capsule, `fill2` with `onGlass` text,
/// showing Now narrating (the voice orb, "Ch 12 · Aurora", play/pause and the 2 px progress line) or Downloading, or nothing. A tap
/// on Now narrating opens the 560 px player window. Collapsed it is a 56 px orb, the narration's with a play overlay.
class GlassDesktopAccessory extends ConsumerWidget {
  const GlassDesktopAccessory({super.key, required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(glassAccessoryProvider);
    final n = s.narration, d = s.downloading;
    if (s.hiddenForSession || (n == null && d == null)) return const SizedBox.shrink();
    final title = n != null ? n.title : 'Saving ${d!.chapters} chapter${d.chapters == 1 ? '' : 's'} · ${(d.progress * 100).round()} %';
    final phase = n == null
        ? ListenPhase.paused
        : switch (n.phase) {
            1 => ListenPhase.preparing,
            2 => ListenPhase.failed,
            _ => n.playing ? ListenPhase.playing : ListenPhase.paused,
          };
    final Widget leading = n != null
        ? ListenVoiceOrb(hue: n.voiceHue ?? gt.colorIris500, initial: n.voiceInitial.isEmpty ? '·' : n.voiceInitial)
        : Icon(listenIcon(GlassIconRole.download), size: 20, color: gt.colorOnGlass);
    return Semantics(
      container: true,
      button: true,
      label: title,
      child: GestureDetector(
        onTap: () => n?.openPlayer(globalRectOf(context)),
        child: Container(
          height: 56,
          width: expanded ? double.infinity : 56,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
          decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: expanded
              ? Stack(
                  children: [
                    Row(
                      children: [
                        leading,
                        const SizedBox(width: 10),
                        Expanded(child: GlassText(title, role: gt.typeSubhead, wght: 600, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.5)),
                        if (n != null) ListenPlayButton(phase: phase, onTap: n.onPlayPause),
                      ],
                    ),
                    if (n != null) Positioned(left: 0, right: 0, bottom: 0, child: ListenProgressLine(progress: n.progress)),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    if (n != null) ListenVoiceOrb(hue: n.voiceHue ?? gt.colorIris500, initial: n.voiceInitial.isEmpty ? '·' : n.voiceInitial, size: 56) else leading,
                    if (n != null)
                      Positioned.fill(
                        child: Center(child: Icon(listenIcon(phase == ListenPhase.playing ? GlassIconRole.pause : GlassIconRole.play), size: 22, color: gt.colorOnGlass)),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
