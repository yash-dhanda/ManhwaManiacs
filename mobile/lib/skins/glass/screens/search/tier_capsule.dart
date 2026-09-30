import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';

/// The tier progress capsule (glass 8.9): "18 results · searching 8 more sources" with a liquid fill of sources answered over queried
/// that ends in a check when everyone has answered. Its text is a polite live region; it is a `glassThin` capsule in the spec and
/// draws as a flat `fill2` capsule here (no glass layer: the page's budget is 3 layers).
class TierCapsule extends ConsumerWidget {
  const TierCapsule({super.key, required this.results, required this.pending, required this.answered, required this.queried});
  final int results;
  final int pending;
  final int answered;
  final int queried;

  static String textFor(int results, int pending) => pending > 0 ? '$results results · searching $pending more sources' : '$results results';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = pending <= 0;
    final text = textFor(results, pending);
    final value = queried <= 0 ? 1.0 : (answered / queried).clamp(0.0, 1.0);
    return Semantics(
      liveRegion: true,
      label: text,
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: ShapeDecoration(color: gt.colorFill2, shape: const StadiumBorder()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 56, child: LiquidProgress(value: done ? 1 : value, height: 8)),
                const SizedBox(width: 10),
                Flexible(child: GlassLabel(text, role: gt.typeFootnote, color: gt.colorLabel1)),
                if (done) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(GlassGlyph28.check.regular, size: 14, color: gt.colorSuccess)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Announces a late group's arrival ("MangaSource: 6 results").
void announceGroup(BuildContext context, String text) {
  try {
    SemanticsService.sendAnnouncement(View.of(context), text, Directionality.of(context));
  } catch (_) {}
}
