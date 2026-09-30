import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/color/cover_palette.dart';
import 'package:manhwamaniacs/core/color/oklch.dart' show relativeLuminance;
import 'package:manhwamaniacs/core/network/api_image.dart' show resolveApiResourceUrl;
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';

/// The screen id of Home's letter reveals (`{profileId}:tonight:{railId}`).
const String kHomeScreenId = 'tonight';

/// A cover of a home item: the source's absolute URL or the backend's relative proxy path, or a flat surface when there is none.
class HomeCoverImage extends ConsumerWidget {
  const HomeCoverImage({super.key, required this.url, this.width});
  final String? url;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = url;
    if (u == null || u.isEmpty) return ColoredBox(color: gt.colorSurface2);
    return GlassCoverImage(url: resolveApiResourceUrl(ref.watch(apiBaseUrlProvider), u), width: width);
  }
}

/// A palette for an item: the server's, else one built from the `ambient` colours the payload carries, else null.
CoverPalette? paletteOf(CoverPalette? palette, Ambient? ambient) {
  if (palette != null) return palette;
  if (ambient == null) return null;
  // The payload names no luminances: the issue colours stand in (the mean from the duo tone, the brightest from the ink).
  return CoverPalette(a: [ambient.duo, ambient.tint, ambient.ink], l: relativeLuminance(ambient.duo) * 0.6, lMax: relativeLuminance(ambient.ink));
}

/// "Ch 143" for a chapter number.
String chLabel(num? n) => n == null ? '' : 'Ch ${n == n.roundToDouble() ? n.round() : n}';
