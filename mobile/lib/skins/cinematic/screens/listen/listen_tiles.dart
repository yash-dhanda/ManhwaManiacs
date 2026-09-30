import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// One square outlined tile of the reading room (cinematic 8.16.3): 1 px `rule.2`, 88 px tall at
/// least, a kicker, a value and a caption; the whole tile is the button.
class ListenTile extends StatelessWidget {
  const ListenTile({super.key, required this.kicker, required this.value, required this.onTap, this.caption, this.valueColor, this.semanticLabel});

  final String kicker, value;
  final String? caption;
  final Color? valueColor;
  final String? semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      button: true,
      label: semanticLabel ?? folioLabel('$kicker $value${caption == null ? '' : ' $caption'}'),
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        onTap: onTap,
        expand: true,
        builder: (context, st) => Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: EdgeInsets.all(c.space3),
          decoration: BoxDecoration(border: Border.all(color: st.focused || st.hovered ? c.colorInk60 : c.colorRule2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CineRoleText(kicker, c.typeKicker, color: c.colorInk60),
              CineRoleText(value, c.typeFolioLg, color: valueColor ?? c.colorInk100, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (caption != null) CineRoleText(caption!, c.typeMicro, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis) else const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three tiles in a row: `SPEED 1.00x` with `≈ 182 WPM`, `VOICES IRIS + 4`, and `SLEEP END OF
/// CH.` (or the live countdown folio).
class ListenTiles extends StatelessWidget {
  const ListenTiles({super.key, required this.speed, required this.voices, required this.sleep});
  final ListenTile speed, voices, sleep;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: speed),
          SizedBox(width: c.space2),
          Expanded(child: voices),
          SizedBox(width: c.space2),
          Expanded(child: sleep),
        ],
      ),
    );
  }
}
