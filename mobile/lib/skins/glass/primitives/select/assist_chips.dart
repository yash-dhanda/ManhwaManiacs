import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_paint.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The assist chips above a selectable grid or list (glass 7.35): "Select all ({n} visible)" and "None", plus the screen's own
/// (`extra`: "Next 10", "All unread", "Whole book"). A capped select all says so: "Selected 200 of 412 shown".
class GlassSelectAssistChips<K> extends StatelessWidget {
  const GlassSelectAssistChips({super.key, required this.controller, required this.visible, this.extra = const []});
  final GlassSelectModeController<K> controller;
  final List<K> visible;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final note = controller.count > 0 ? selectionCapMessage(controller.count, visible.length) : null;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              GlassChip(label: selectAllLabel(visible.length), kind: GlassChipKind.assist, onPressed: () => controller.selectAll(visible)),
              GlassChip(label: 'None', kind: GlassChipKind.assist, onPressed: controller.clear),
              ...extra,
            ],),
            if (note != null && controller.count >= kSelectAllCap)
              Padding(padding: const EdgeInsets.only(top: 6), child: Semantics(liveRegion: true, child: GlassText(note, role: gt.typeFootnote, color: gt.colorLabel2))),
          ],);
        },
      );
}
