import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_dot_leader.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The credits row (cinematic 7.16): label, dot leaders, value on one baseline. Minimum 40; the
/// hit target grows to 44 / 48 only when [onTap] is set.
class CineCreditsRow extends StatelessWidget {
  const CineCreditsRow({super.key, required this.label, required this.value, this.onTap, this.valueColor});

  final String label, value;
  final VoidCallback? onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final row = CineLeaderRow(
      label: CineRoleText(label, c.typeUi, color: c.colorInk60),
      value: CineRoleText(value, c.typeUi, color: valueColor, textAlign: TextAlign.right),
    );
    Widget box(CinePressState? st) => ConstrainedBox(
          constraints: BoxConstraints(minHeight: onTap != null ? cineHitMin(context) : 40),
          child: Align(child: row),
        );
    return Semantics(
      container: true,
      label: '$label, $value',
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: onTap == null ? box(null) : CinePressable(onTap: onTap, hit: false, builder: (_, st) => box(st)),
    );
  }
}
