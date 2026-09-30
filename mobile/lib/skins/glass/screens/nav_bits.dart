import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The height of a bar row: 44, or the Android touch minimum of 48.
double glassBarHeight(BuildContext context) => math.max(44.0, GlassFrame.hitMin(context));

/// A plain text action inside a bar group's glass ("Edit", "Skip"): one shape of the group, 44 px tall, no glass of its own.
SkinGlassShape glassTextShape(BuildContext context, String label, VoidCallback? onTap) {
  final style = roleStyle(context, gt.typeSubhead, onGlass: true, wght: 600);
  final w = measureText(context, label, style).width + 32;
  return SkinGlassShape(
    size: Size(math.max(w, 64), glassBarHeight(context)),
    child: GlassPressable(
      material: GlassMaterial.content,
      sink: 0.96,
      onTap: onTap,
      enabled: onTap != null,
      semanticsLabel: label,
      minHit: false,
      builder: (context, info) => Center(child: GlassText(label, role: gt.typeSubhead, onGlass: true, wght: 600, maxLines: 1)),
    ),
  );
}
