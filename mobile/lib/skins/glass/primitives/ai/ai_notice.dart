import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/copy/ai.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// A missing AI answer (glass 7.38, 9.1.5): a `surface1` slab, radius 20, padding 12 16, the `sparkle-slash` glyph 20 in `label2`
/// (never `danger`: a missing AI answer is not an error), the reason's short line (rails, badges) or long line (For you, recaps,
/// More like this), and a slot for the non-AI path beside it (the local rail, world picks, Continue). Administrators also see
/// "Add an AI API key on the server to turn it on." under `not_configured`.
class AiNotice extends StatelessWidget {
  const AiNotice({super.key, required this.reason, this.long = false, this.retrySeconds, this.admin = false, this.alternative});
  final String? reason;
  final bool long;
  final int? retrySeconds;
  final bool admin;
  final Widget? alternative;

  @override
  Widget build(BuildContext context) {
    final lines = glassAiLines(reason, retrySeconds: retrySeconds);
    final text = long ? lines.long : lines.short;
    final host = GlassHost.of(context);
    final color = host ? gt.colorOnGlass : gt.colorLabel2;
    return DecoratedBox(
      decoration: BoxDecoration(color: host ? const Color(0x00000000) : gt.colorSurface1, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(GlassGlyphs.sparkleSlashRegular, size: 20, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassText(text, role: long ? gt.typeCallout : gt.typeFootnote, color: color, onGlass: host),
                    if (admin && reason == 'not_configured')
                      Padding(padding: const EdgeInsets.only(top: 4), child: GlassText(glassAiAdminHint, role: gt.typeFootnote, color: host ? color : gt.colorLabel3, onGlass: host)),
                    if (alternative != null) Padding(padding: const EdgeInsets.only(top: 8), child: alternative),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
