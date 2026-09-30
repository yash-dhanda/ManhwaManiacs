import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/utils/browse_freshness.dart' show FreshnessLabel;
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_monogram.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';

/// The catalogue header (glass 8.11): the 48 px logo, the name in `largeTitle` with the letter reveal, the count line, the freshness
/// capsule (tap a stale one for "The source didn't answer, so this is the last copy the server saved.") and the health notice.
class CatalogueHeader extends ConsumerStatefulWidget {
  const CatalogueHeader({super.key, required this.sourceId, required this.name, this.iconUrl, required this.countLine, this.freshness, this.health});
  final String sourceId;
  final String name;
  final String? iconUrl;
  final String countLine;
  final FreshnessLabel? freshness;
  final SourceHealth? health;

  @override
  ConsumerState<CatalogueHeader> createState() => _CatalogueHeaderState();
}

class _CatalogueHeaderState extends ConsumerState<CatalogueHeader> {
  bool _why = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.freshness;
    final st = widget.health?.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 48, height: 48, child: widget.iconUrl == null || widget.iconUrl!.isEmpty ? GlassSourceMonogram(name: widget.name, sourceId: widget.sourceId, size: 48) : HomeCoverImage(url: widget.iconUrl, width: 48))),
          const SizedBox(width: 12),
          Expanded(child: LetterReveal(widget.name, role: gt.typeLargeTitle, revealKey: 'catalogue-${widget.sourceId}', screenId: 'source', headingLevel: 1, maxLines: 2)),
        ]),
        const SizedBox(height: 6),
        GlassLabel(widget.countLine, role: gt.typeFootnote, color: gt.colorLabel2),
        if (f != null) ...[
          const SizedBox(height: 8),
          Semantics(
            button: f.stale,
            label: f.text,
            excludeSemantics: true,
            onTap: f.stale ? () => setState(() => _why = !_why) : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: f.stale ? () => setState(() => _why = !_why) : null,
              child: DecoratedBox(
                decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(16)),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: GlassLabel(f.text, role: gt.typeFootnote, wght: 600, color: f.stale ? gt.colorWarning : gt.colorLabel1)),
              ),
            ),
          ),
          if (_why && f.stale) Padding(padding: const EdgeInsets.only(top: 6), child: GlassLabel("The source didn't answer, so this is the last copy the server saved.", role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 3)),
        ],
        if (st == SourceHealthStatus.failing) const Padding(padding: EdgeInsets.only(top: 10), child: GlassInlineNotice(message: 'This source is having trouble; pages may not load.', variant: GlassNoticeVariant.warning)),
        if (st == SourceHealthStatus.dead) const Padding(padding: EdgeInsets.only(top: 10), child: GlassInlineNotice(message: "This source isn't working right now.", variant: GlassNoticeVariant.danger)),
      ],
    );
  }
}
