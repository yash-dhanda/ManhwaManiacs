import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
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
    this.ai = false,
    this.friendName,
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
    this.ai = false,
    this.friendName,
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

  /// An AI card (glass 2.1.9, 7.38): a 0.5 px `machineRim` rim instead of the slab border and the machine badge before the `why`.
  final bool ai;

  /// An AI card that shows a friend's pick also carries the friend's `bloom` chip: the people light next to the machine light.
  final String? friendName;

  Future<void> _external() async {
    try {
      await launchUrl(Uri.parse(siteUrl!), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // The source badge shares the title's row, so a long title wraps before it instead of running under it.
    final badge = infoOnly
        ? null
        : Row(mainAxisSize: MainAxisSize.min, children: [GlassBadge.source(sourceName!, icon: sourceIcon), if (extraSources > 0) ...[const SizedBox(width: 4), GlassBadge.role('+$extraSources')]]);
    final text = Expanded(
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge == null)
            GlassLabel(title, role: gt.typeHeadline, maxLines: 2)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: GlassLabel(title, role: gt.typeHeadline, maxLines: 2)), const SizedBox(width: 4), badge],
            ),
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
              if (ai) ...[const MachineBadge(), const SizedBox(width: 4)],
              Expanded(child: GlassLabel(why, role: gt.typeFootnote, italic: true, color: gt.colorLabel2)),
              if (ai && friendName != null) Padding(padding: const EdgeInsets.only(left: 4), child: _FriendChip(friendName!)),
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
          borderColor: ai ? gt.colorMachineRim : const Color(0x0FFFFFFF),
          borderWidth: ai ? 0.5 : 1,
          onTap: onOpen,
          semanticsLabel: '$title, $kind, $why, on $sourceName${extraSources > 0 ? ' and $extraSources more' : ''}',
          child: head,
        ),
      );
    }
    return SizedBox(
      width: 300,
      height: 200,
      child: GlassSlab(
        padding: const EdgeInsets.all(6),
        borderColor: ai ? gt.colorMachineRim : const Color(0x0FFFFFFF),
        borderWidth: ai ? 0.5 : 1,
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

/// The friend's pick on an AI card: the people light (`bloom`) beside the machine light (glass 2.1.9).
class _FriendChip extends StatelessWidget {
  const _FriendChip(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: gt.colorBloomWash, borderRadius: BorderRadius.circular(gt.radiusCapsule), border: Border.all(color: gt.colorBloomRim, width: 0.5)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), child: GlassLabel(name, role: gt.typeCaption2, color: gt.colorBloom)),
      );
}
