import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart' show Glyph;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_30.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Step 3, Formats: four toggle cards (Web novels only when the server has them), multi-select.
class GlassFormatsStep extends ConsumerWidget {
  const GlassFormatsStep({super.key, required this.selected, required this.onToggle});
  final List<FormatId> selected;
  final ValueChanged<FormatId> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novels = ref.watch(novelsEnabledProvider);
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    final cards = [
      for (final f in FormatId.values)
        if (f != FormatId.novel || novels) _FormatCard(format: f, on: selected.contains(f), onTap: () {
          glassFire(ref, HapticEvent.select);
          onToggle(f);
        },),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LetterReveal('What do you read?', role: gt.typeTitle1, screenId: 'onboarding', revealKey: '3', headingLevel: 1),
        const SizedBox(height: 20),
        if (wide)
          Row(children: [for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: cards[i])]])
        else
          Wrap(spacing: 12, runSpacing: 12, children: [for (final c in cards) SizedBox(width: (MediaQuery.sizeOf(context).width - 2 * GlassFrame.screenMargin(context) - 12) / 2, child: c)]),
      ],
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({required this.format, required this.on, required this.onTap});
  final FormatId format;
  final bool on;
  final VoidCallback onTap;

  String get _label => switch (format) {
        FormatId.manhwa => 'Manhwa',
        FormatId.manga => 'Manga',
        FormatId.manhua => 'Manhua',
        FormatId.novel => 'Web novels',
      };

  Widget _glyph(Color c) {
    // Light 40 px glyphs; Duotone `iris400` when chosen.
    const size = 40.0;
    switch (format) {
      case FormatId.manhwa:
        return Icon(on ? GlassGlyphs.stripScrollDuotone : GlassGlyphs.stripScrollRegular, size: size, color: c);
      case FormatId.manga:
        return _phosphor(GlassGlyph30.bookOpenText, GlassGlyph30.bookOpenTextDuotone, size, c);
      case FormatId.manhua:
        return _phosphor(GlassGlyph30.paintBrushBroad, GlassGlyph30.paintBrushBroadDuotone, size, c);
      case FormatId.novel:
        return _phosphor(GlassGlyph30.article, GlassGlyph30.articleDuotone, size, c);
    }
  }

  Widget _phosphor(Glyph glyph, (IconData, IconData) duo, double size, Color c) {
    if (!on) return Icon(glyph.light, size: size, color: c);
    return Stack(alignment: Alignment.center, children: [Opacity(opacity: 0.2, child: Icon(duo.$2, size: size, color: c)), Icon(duo.$1, size: size, color: c)]);
  }

  @override
  Widget build(BuildContext context) => Semantics(
        checked: on,
        button: true,
        label: _label,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(26), border: on ? Border.all(color: gt.colorIris500, width: 2) : null),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 140),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [_glyph(on ? gt.colorIris400 : gt.colorLabel2), const SizedBox(height: 12), GlassText(_label, role: gt.typeHeadline)]),
            ),
          ),
        ),
      );
}
