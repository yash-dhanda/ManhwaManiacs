import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The desktop accessory (glass 7.16): a 56 px capsule docked above the sidebar's profile capsule, `fill2` with `onGlass` text, showing
/// Now narrating or Downloading, or nothing. Collapsed it is a 56 px orb.
class GlassDesktopAccessory extends ConsumerWidget {
  const GlassDesktopAccessory({super.key, required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(glassAccessoryProvider);
    final n = s.narration, d = s.downloading;
    if (s.hiddenForSession || (n == null && d == null)) return const SizedBox.shrink();
    final title = n != null ? n.title : 'Saving ${d!.chapters} chapter${d.chapters == 1 ? '' : 's'} · ${(d.progress * 100).round()} %';
    final glyph = n != null ? roleIcon(GlassIconRole.listen).fill : roleIcon(GlassIconRole.download).fill;
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: () => n?.openPlayer(globalRectOf(context)),
        child: Container(
          height: 56,
          width: expanded ? double.infinity : 56,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
          decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(28)),
          child: expanded
              ? Row(children: [Icon(glyph, size: 20, color: gt.colorOnGlass), const SizedBox(width: 10), Expanded(child: GlassText(title, role: gt.typeSubhead, wght: 600, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis))])
              : Center(child: Icon(glyph, size: 22, color: gt.colorOnGlass)),
        ),
      ),
    );
  }
}
