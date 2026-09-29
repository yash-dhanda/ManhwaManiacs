import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_lightbox.dart';

/// The cover Lightbox of the series page: mobile/05's `openCineLightbox` (the cover `Hero` flies
/// 480 ms, pinch 1x to 4x, double tap 1x / 2.5x, drag down to dismiss, `x`, `Esc` and back close).
Future<void> showCoverLightbox(
  BuildContext context, {
  required String imageUrl,
  required String title,
  Object? heroTag,
  Map<String, String>? headers,
}) =>
    openCineLightbox(
      context,
      heroTag: heroTag ?? 'cover-$imageUrl',
      image: CachedNetworkImageProvider(imageUrl, headers: headers),
      title: title,
      folio: 'COVER · 720 × 1080',
    );
