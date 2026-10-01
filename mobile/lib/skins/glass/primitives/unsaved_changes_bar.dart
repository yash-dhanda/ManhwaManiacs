import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/floating_bar.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The floating "Unsaved changes" bar of a draft-then-save section (glass 8.25.6): the bulk toolbar's capsule (glass 7.35), on
/// phones in the bottom accessory slot above the dock, on tablet and desktop frames 52 px tall, 24 px above the bottom, centred on
/// the content column, at most 720 wide, `glassRegular` (T3). "Discard" is plain, "Save" tinted; a failed save shakes "Save"
/// ([errorTrigger]). The bar is lifted into the nearest [Overlay] so it floats over the page whatever the caller's layout.
class GlassUnsavedChangesBar extends StatefulWidget {
  const GlassUnsavedChangesBar({super.key, required this.visible, required this.onDiscard, required this.onSave, this.saving = false, this.errorTrigger = 0});
  final bool visible;
  final VoidCallback onDiscard, onSave;
  final bool saving;
  final int errorTrigger;

  @override
  State<GlassUnsavedChangesBar> createState() => _GlassUnsavedChangesBarState();
}

class _GlassUnsavedChangesBarState extends State<GlassUnsavedChangesBar> {
  final OverlayPortalController _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _portal.show();
  }

  Widget _row(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Expanded(child: Semantics(liveRegion: true, child: GlassText('Unsaved changes', role: gt.typeHeadline, color: gt.colorOnGlass, maxLines: 1, overflow: TextOverflow.ellipsis))),
          GlassButton(label: 'Discard', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: widget.saving ? null : widget.onDiscard),
          const SizedBox(width: 8),
          GlassButton(label: 'Save', variant: GlassButtonVariant.primary, size: GlassButtonSize.small, loading: widget.saving, errorTrigger: widget.errorTrigger, onPressed: widget.saving ? null : widget.onSave),
        ],),
      );

  @override
  Widget build(BuildContext context) {
    final bar = GlassFloatingBar(kind: GlassBottomBar.unsaved, visible: widget.visible, debugLabel: 'unsaved changes', child: Builder(builder: _row));
    return OverlayPortal(controller: _portal, overlayChildBuilder: (_) => bar, child: const SizedBox.shrink());
  }
}
