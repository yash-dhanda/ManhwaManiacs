import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:url_launcher/url_launcher.dart';

/// The AI and "For you" card (glass 7.7): 300 x 132: cover 80 x 120, the title in two lines, "Manhwa - Ongoing",
/// "120 ch - star 8.4" in `mono` 13, up to three tags, and the `why` line in `footnote` italic `label2`
/// after the machine `sparkle` glyph in `machine`. The **available** variant carries a source badge (and
/// "+2") and the whole card opens the series. The **info-only** variant has a dashed 1 px border, "Not on
/// your sources", and two plain buttons: "Search my sources" and "Read on {site}" (external).
class GlassWorldCard extends StatelessWidget {
  const GlassWorldCard.available({
    super.key,
    required this.cover,
    required this.title,
    required this.kind,
    required this.stats,
    required this.why,
    required String source,
    this.extraSources = 0,
    this.tags = const [],
    this.onOpen,
    this.sourceIcon,
  })  : sourceName = source,
        infoOnly = false,
        site = null,
        siteUrl = null,
        onSearchMySources = null;

  const GlassWorldCard.infoOnly({
    super.key,
    required this.cover,
    required this.title,
    required this.kind,
    required this.stats,
    required this.why,
    required String this.site,
    required String this.siteUrl,
    this.tags = const [],
    this.onSearchMySources,
  })  : sourceName = null,
        extraSources = 0,
        infoOnly = true,
        onOpen = null,
        sourceIcon = null;

  final Widget cover;
  final String title;

  /// "Manhwa - Ongoing".
  final String kind;

  /// "120 ch - 8.4".
  final String stats;
  final String why;
  final String? sourceName;
  final int extraSources;
  final Widget? sourceIcon;
  final List<String> tags;
  final bool infoOnly;
  final String? site;
  final String? siteUrl;
  final VoidCallback? onOpen;
  final VoidCallback? onSearchMySources;

  Future<void> _external() async {
    try {
      await launchUrl(Uri.parse(siteUrl!), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final text = Expanded(
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassLabel(title, role: gt.typeHeadline, maxLines: 2),
          GlassLabel(kind, role: gt.typeCaption1, color: gt.colorLabel3),
          GlassLabel(stats, role: gt.typeMono, size: 13, height: 16, color: gt.colorLabel2),
          if (tags.isNotEmpty)
            Padding(
              padding: EdgeInsets.zero,
              child: Wrap(spacing: 4, children: [for (final t in tags.take(3)) GlassChip(label: t, kind: GlassChipKind.tag)]),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              GlyphIcon(GlassGlyph.sparkle, size: 14, color: gt.colorMachine),
              const SizedBox(width: 4),
              Expanded(child: GlassLabel(why, role: gt.typeFootnote, italic: true, color: gt.colorLabel2)),
            ],
          ),
        ],
      ),
        ),
      ),
    );
    final head = SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, height: 120, child: ClipRRect(borderRadius: BorderRadius.circular(gt.radiusMd), child: cover)),
          const SizedBox(width: 10),
          text,
        ],
      ),
    );
    if (!infoOnly) {
      return SizedBox(
        width: 300,
        height: 132,
        child: GlassSlab(
          padding: const EdgeInsets.all(6),
          onTap: onOpen,
          semanticsLabel: '$title, $kind, $why, on $sourceName${extraSources > 0 ? ' and $extraSources more' : ''}',
          child: Stack(
            children: [
              head,
              Positioned(right: 0, top: 0, child: Row(children: [GlassBadge.source(sourceName!, icon: sourceIcon), if (extraSources > 0) ...[const SizedBox(width: 4), GlassBadge.role('+$extraSources')]])),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: 300,
      height: 200,
      child: GlassSlab(
        padding: const EdgeInsets.all(6),
        dashed: true,
        semanticsLabel: '$title, not on your sources',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: head),
            Padding(padding: const EdgeInsets.only(left: 8), child: GlassLabel('Not on your sources', role: gt.typeCaption1, color: gt.colorLabel3)),
            Wrap(
              children: [
                GlassButton(label: 'Search my sources', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: onSearchMySources),
                GlassButton(label: 'Read on $site', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, icon: GlassButtonIcon.glyph(GlassGlyph.arrowSquareOut), onPressed: _external),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
