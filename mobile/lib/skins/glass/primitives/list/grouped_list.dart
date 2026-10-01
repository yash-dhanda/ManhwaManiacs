import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The separator inset of a row: 60 px when it has an icon tile, else 16.
double glassSeparatorInset(Widget row) => row is GlassListRow && row.hasIconTile ? 60 : 16;

/// Rows with hairlines between them (0.5 px `separator`, inset from the leading edge). Shared by the grouped and plain lists.
List<Widget> glassSeparated(List<Widget> rows) => [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) Padding(padding: EdgeInsetsDirectional.only(start: glassSeparatorInset(rows[i])), child: const SizedBox(height: 0.5, width: double.infinity, child: ColoredBox(color: GlassColors.separator))),
        rows[i],
      ],
    ];

/// The inset grouped list (glass 7.17): a `surface1` container, radius 20, 16 px from the screen edges (the frame's
/// margin on wider frames), an optional uppercase header and footer. Inside a T4/T5 host it draws no fill (rows sit on
/// the glass body); on the solid surfaces it keeps `surface1`.
class GlassGroupedList extends StatelessWidget {
  const GlassGroupedList({super.key, required this.children, this.header, this.footer, this.inset = true});
  final List<Widget> children;
  final String? header;
  final String? footer;

  /// False when the parent already applies the screen margin.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final host = GlassHost.of(context);
    final margin = inset ? GlassFrame.contentMargin(context) : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Semantics(
                header: true,
                headingLevel: 2,
                child: GlassLabel(header!, role: gt.typeFootnote, wght: 600, upper: true, extraTrackingEm: 0.04, color: host ? gt.colorOnGlass.withValues(alpha: 0.72) : gt.colorLabel2, onGlass: host),
              ),
            ),
          // The rows' focus rings report here and paint outside the card's clip (glass 2.6, 14.4: never masked).
          GlassFocusRingHost(
            child: ClipRSuperellipse(
              borderRadius: BorderRadius.circular(20),
              child: ColoredBox(color: host ? const Color(0x00000000) : gt.colorSurface1, child: Column(mainAxisSize: MainAxisSize.min, children: glassSeparated(children))),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GlassText(footer!, role: gt.typeFootnote, color: host ? gt.colorOnGlass.withValues(alpha: 0.56) : gt.colorLabel3, onGlass: host),
            ),
        ],
      ),
    );
  }
}

/// The sliver form, for `CustomScrollView`s.
class GlassSliverGroupedList extends StatelessWidget {
  const GlassSliverGroupedList({super.key, required this.children, this.header, this.footer});
  final List<Widget> children;
  final String? header;
  final String? footer;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(child: GlassGroupedList(header: header, footer: footer, children: children));
}
