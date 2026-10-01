import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paper_frame.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/papers.dart';

/// "3.4k words" (820 words under a thousand).
String glassWordsLabel(int words) => words < 1000 ? '$words words' : '${(words / 1000).toStringAsFixed(1)}k words';

/// "3.4k words · 14 min".
String glassLengthLine(int words, int minutes) => '${glassWordsLabel(words)} · $minutes min';

/// The header's pieces' styles (D5), shared by the widget and the height the paginator reserves.
class GlassHeaderStyles {
  GlassHeaderStyles(BuildContext context, {required double bodySize, required PaperColors colors})
      : kicker = roleStyle(context, gt.typeCaption1, maxScale: 1.3).copyWith(color: colors.muted, letterSpacing: 0.22 * GlassTypeStyleSize.of(context, gt.typeCaption1)),
        title = TextStyle(
          fontFamily: 'LiterataMM',
          fontSize: 1.55 * bodySize,
          height: 1.2,
          color: colors.ink,
          fontVariations: const [FontVariation('opsz', 36), FontVariation('wght', 560)],
        ),
        meta = roleStyle(context, gt.typeMono, size: 12, height: 16, maxScale: 1.3).copyWith(color: colors.muted);
  final TextStyle kicker, title, meta;
}

/// Shorthand for a role's rendered size.
abstract final class GlassTypeStyleSize {
  static double of(BuildContext context, GlassTypeRole role) => roleStyle(context, role, maxScale: 1.3).fontSize ?? 12;
}

const double _kTop = 8, _kAfterKicker = 12, _kAfterTitle = 16, _kAfterRule = 12, _kBottom = 40;

/// The chapter header (D5): "CHAPTER 12" in `caption1` +0.22 em muted, the title in Literata `opsz` 36 `wght` 560 at 1.55 x the body
/// as a level-1 heading, a 56 px rule, "3.4k words · 14 min" in muted `mono` 12/16, then the ordered [slots] (`mobile/37` puts the
/// "Listen · 14 min" capsule and the follow-along line there).
class GlassChapterHeader extends StatelessWidget {
  const GlassChapterHeader({super.key, required this.kicker, required this.title, required this.lengthLine, required this.bodySize, this.slots = const []});
  final String kicker, title, lengthLine;
  final double bodySize;
  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    final colors = PaperScope.of(context);
    final s = GlassHeaderStyles(context, bodySize: bodySize, colors: colors);
    return Padding(
      padding: const EdgeInsets.only(top: _kTop, bottom: _kBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kicker, style: s.kicker, textScaler: TextScaler.noScaling),
          const SizedBox(height: _kAfterKicker),
          if (title.isNotEmpty) ...[
            Semantics(header: true, headingLevel: 1, child: Text(title, style: s.title, textScaler: TextScaler.noScaling)),
            const SizedBox(height: _kAfterTitle),
          ],
          ExcludeSemantics(child: SizedBox(width: 56, height: 1, child: ColoredBox(color: colors.muted))),
          const SizedBox(height: _kAfterRule),
          Text(lengthLine, style: s.meta, textScaler: TextScaler.noScaling),
          ...slots,
        ],
      ),
    );
  }
}

/// The header's laid-out height at [width] (the paginator's `openerHeight`, so page one never clips).
double glassHeaderHeight(BuildContext context, {required String kicker, required String title, required String lengthLine, required double bodySize, required double width}) {
  final s = GlassHeaderStyles(context, bodySize: bodySize, colors: PaperScope.of(context));
  double h(String text, TextStyle style) => text.isEmpty ? 0 : measureText(context, text, style, maxWidth: width, maxLines: 1 << 20).height;
  return _kTop + h(kicker, s.kicker) + _kAfterKicker + (title.isEmpty ? 0 : h(title, s.title) + _kAfterTitle) + 1 + _kAfterRule + h(lengthLine, s.meta) + _kBottom;
}
