import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/health_bead.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_monogram.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';

/// A source row (glass 7.7): 64 tall: a 44 px logo (radius 10, or the monogram when [logo] is null or fails),
/// the name in `headline` followed by the 10 px health bead and the language tag, a one-line description,
/// an 18+ tag when mature, and the pin toggle.
class GlassSourceRowCard extends StatelessWidget {
  const GlassSourceRowCard({
    super.key,
    required this.sourceId,
    required this.name,
    required this.description,
    this.language = 'EN',
    this.health = GlassSourceHealth.unknown,
    this.demoted = false,
    this.mature = false,
    this.pinned = false,
    this.logo,
    this.onTap,
    this.onPin,
    this.enabled = true,
    this.disabledReason,
  });

  final String sourceId;
  final String name;
  final String description;
  final String language;
  final GlassSourceHealth health;
  final bool demoted;
  final bool mature;
  final bool pinned;

  /// The logo widget (network image); it draws the monogram itself on failure via [GlassSourceMonogram].
  final Widget? logo;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final bool enabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: GlassSlab(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          onTap: onTap,
          enabled: enabled,
          disabledReason: disabledReason,
          sink: 0.99,
          semanticsLabel: '$name, ${health.spoken}${demoted ? ', skipped by search' : ''}, $language${mature ? ', mature' : ''}',
          child: Row(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(gt.radiusSm), child: SizedBox(width: 44, height: 44, child: logo ?? GlassSourceMonogram(name: name, sourceId: sourceId))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(child: GlassLabel(name, role: gt.typeHeadline)),
                        const SizedBox(width: 6),
                        GlassHealthBead(status: health, demoted: demoted),
                        const SizedBox(width: 6),
                        GlassChip(label: language, kind: GlassChipKind.tag),
                        if (mature) ...[const SizedBox(width: 4), const GlassBadge.mature()],
                      ],
                    ),
                    GlassLabel(description, role: gt.typeFootnote, color: gt.colorLabel2),
                  ],
                ),
              ),
              GlassIconButton(
                icon: GlassButtonIcon.glyph(GlassGlyph.pushPin),
                label: 'Pin source',
                toggle: pinned,
                onColor: gt.colorIris400,
                onPressed: onPin,
              ),
            ],
          ),
        ),
      );
}
