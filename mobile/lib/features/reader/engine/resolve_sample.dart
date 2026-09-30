import 'dart:ui' show Color;
import 'package:manhwamaniacs/features/reader/engine/page_sample.dart';

/// The sample to publish after [next] arrives. A greyscale [next] (tint null) keeps the previous
/// tint; after [greyLimit] greyscale pages in a row the tint becomes the first colour of
/// [coverPalette]. [greyRun] counts the greyscale pages in a row including [next].
PageSample resolveSample(PageSample? previous, PageSample next, int greyRun, List<Color>? coverPalette,
    {int greyLimit = 6,}) {
  if (next.tint != null) return next;
  if (greyRun >= greyLimit && coverPalette != null && coverPalette.isNotEmpty) {
    return next.withTint(coverPalette.first);
  }
  return next.withTint(previous?.tint);
}

/// The next grey run: 0 after a chromatic page, +1 after a greyscale one.
int nextGreyRun(int run, PageSample decoded) => decoded.tint == null ? run + 1 : 0;

/// Luminance stand-in for the chrome while only a manifest tint is known (dim 0.64).
const double kUnknownLuminanceDim = 0.64;
