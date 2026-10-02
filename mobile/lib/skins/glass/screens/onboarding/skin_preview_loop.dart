import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/skin_preview.dart';

/// The live preview of a skin (glass 8.7 step 2, 8.25.1, 8.25.2): the skin's [SkinPreview] miniature, fitted into the box at the
/// phone's 390:844 ratio and scrolling every vsync while visible. Under reduced motion it holds still on the top with a plain
/// "Play preview" that plays one pass.
class GlassSkinPreviewLoop extends ConsumerStatefulWidget {
  const GlassSkinPreviewLoop({super.key, required this.skin});
  final String skin;

  @override
  ConsumerState<GlassSkinPreviewLoop> createState() => _GlassSkinPreviewLoopState();
}

class _GlassSkinPreviewLoopState extends ConsumerState<GlassSkinPreviewLoop> {
  bool _once = false;

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        SkinPreview(skin: widget.skin, play: !reduced || _once, once: reduced && _once, onDone: () => setState(() => _once = false)),
        if (reduced && !_once)
          Positioned(
            right: 8,
            bottom: 8,
            child: GestureDetector(
              onTap: () => setState(() => _once = true),
              child: Semantics(button: true, label: 'Play preview', child: const Text('Play preview', style: TextStyle(color: Color(0xFFF5F7FA), fontSize: 13, decoration: TextDecoration.none))),
            ),
          ),
      ],
    );
  }
}
