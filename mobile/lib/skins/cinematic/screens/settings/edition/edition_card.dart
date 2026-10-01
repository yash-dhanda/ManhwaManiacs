import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/skin_preview.dart';

/// One edition card: a 3:4 plate (`paper.1`) holding a centred phone frame (390:844, 1 px `rule.2`) with
/// the skin's live miniature ([SkinPreview], still under reduced motion), then the name, a one-line
/// description and the badge or button.
class EditionCard extends StatelessWidget {
  const EditionCard({
    super.key,
    required this.skinFolder,
    required this.name,
    required this.family,
    required this.description,
    this.italic = false,
    this.current = false,
    this.onSwitch,
    this.switchLabel = '',
  });

  final String skinFolder, name, family, description;
  final String switchLabel;
  final bool italic, current;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      label: '$name. $description${current ? ' This edition.' : ''}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ExcludeSemantics(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              color: c.colorPaper1,
              padding: EdgeInsets.symmetric(vertical: c.space3),
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: kSkinPreviewAspect,
                child: Container(
                  foregroundDecoration: BoxDecoration(border: Border.all(color: c.colorRule2)),
                  child: SkinPreview(key: Key('edition-preview-$skinFolder'), skin: skinFolder, play: !CineMotion.reduced(context)),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: c.space3),
        Text(name, style: CineText.style(context, c.typeSubhead).copyWith(fontFamily: family, fontStyle: italic ? FontStyle.italic : FontStyle.normal, color: c.colorInk100)),
        SizedBox(height: c.space1),
        CineRoleText(description, c.typeCaption, color: c.colorInk60),
        SizedBox(height: c.space3),
        if (current)
          const Align(alignment: Alignment.centerLeft, child: CineBadge('THIS EDITION', variant: CineBadgeVariant.text))
        else if (onSwitch != null)
          Align(alignment: Alignment.centerLeft, child: CineButton(label: switchLabel, variant: CineButtonVariant.secondary, onPressed: onSwitch)),
      ],),
    );
  }
}
