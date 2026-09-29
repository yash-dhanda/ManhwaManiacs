import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A Letter (a recommendation from a person): a duotone cover strip at left; kicker `FROM RIYA`,
/// the title, the note in italic quotes and action slots at right (cinematic 7.6).
class CineLetterCard extends StatelessWidget {
  const CineLetterCard({
    super.key,
    required this.from,
    required this.title,
    required this.note,
    this.imageUrl,
    this.duo,
    this.isNew = false,
    this.onOpen,
    this.onRead,
    this.onAdd,
    this.onKeep,
    this.onDismiss,
  });

  final String from, title, note;
  final String? imageUrl;
  final Color? duo;
  final bool isNew;
  final VoidCallback? onOpen, onRead, onAdd, onKeep, onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final actions = <(String, VoidCallback?)>[('Read', onRead), ('Add', onAdd), ('Keep', onKeep), ('Dismiss', onDismiss)].where((a) => a.$2 != null).toList();
    return CinePressable(
      hit: false,
      onTap: onOpen,
      builder: (context, st) {
        final lit = st.hovered || st.focused;
        return AnimatedContainer(
          duration: reduced ? Duration.zero : (st.pressed ? c.durTick : c.durBeat),
          transform: Matrix4.translationValues(0, st.pressed ? 1 : 0, 0),
          child: CineStock.raised(Builder(
            builder: (context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 132,
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: ClipRect(
                    child: AnimatedScale(
                      scale: lit && !reduced ? 1.04 : 1,
                      duration: reduced ? Duration.zero : c.durClip,
                      curve: c.easeSettle,
                      child: CineDuotone(duo: duo ?? c.colorAmbientFallbackDuo, child: CineImage(url: imageUrl, title: title)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: c.space3),
              Expanded(
                child: Semantics(
                  container: true,
                  label: 'From $from, $title. $note',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      if (isNew) ...[Container(width: 6, height: 6, color: c.colorSpot), SizedBox(width: c.space2)],
                      Flexible(child: CineRoleText('FROM ${from.toUpperCase()}', c.typeKicker, color: context.cine.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],),
                    SizedBox(height: c.space1),
                    CineRoleText(title, c.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis, decoration: lit ? TextDecoration.underline : null),
                    SizedBox(height: c.space1),
                    CineRoleText('“$note”', c.typeBodyItalic, color: context.cine.colorInk60, maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (actions.isNotEmpty)
                      Wrap(spacing: c.space1, children: [
                        for (final a in actions)
                          CineButton(
                            label: a.$1,
                            variant: a.$1 == 'Read' ? CineButtonVariant.secondary : CineButtonVariant.quiet,
                            size: CineButtonSize.sm,
                            onPressed: a.$2,
                          ),
                      ],),
                  ],),
                ),
              ),
            ],),
          ),),
        );
      },
    );
  }
}
