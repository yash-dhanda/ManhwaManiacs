import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// `legible` (the Hyperlegible option, cinematic 3.4) for [CineText.style]; fed from
/// `legibleTextProvider`. Mounted by mobile/06 at the skin root and by the gallery.
class CineTextSettings extends ConsumerWidget {
  const CineTextSettings({super.key, required this.child});
  final Widget child;

  static const _off = _CineTextSettingsScope(legible: false, child: SizedBox());

  static ({bool legible}) of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<_CineTextSettingsScope>() ?? _off;
    return (legible: s.legible);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _CineTextSettingsScope(legible: ref.watch(legibleTextProvider), child: child);
}

class _CineTextSettingsScope extends InheritedWidget {
  const _CineTextSettingsScope({required this.legible, required super.child});
  final bool legible;

  @override
  bool updateShouldNotify(_CineTextSettingsScope o) => o.legible != legible;
}

/// The user's text scale as a factor (1.0 = default).
double cineScale(BuildContext context) => MediaQuery.textScalerOf(context).scale(16) / 16;

/// Layout switches at the text-scale steps of cinematic 3.3.
class CineReflow {
  const CineReflow._(this.scale);
  final double scale;

  static CineReflow of(BuildContext context) => CineReflow._(cineScale(context));

  /// >= 1.3: rails show 2.3 posters on phones, captions 2 lines, credits single column, rows grow.
  bool get railCompact => scale >= 1.3;

  /// >= 1.5: split buttons stack.
  bool get stackSplit => scale >= 1.5;

  /// >= 2.0: sheets open at the full detent, two-column rows become one.
  bool get fullDetent => scale >= 2.0;
}

enum CineFace { bodoni, archivo, newsreader, plexMono }

abstract final class CineText {
  static TextStyle _withVariations(TextStyle s, {double? wdth, double? extraTrackingEm}) {
    final v = [
      for (final e in s.fontVariations ?? const <FontVariation>[])
        if (!(wdth != null && e.axis == 'wdth')) e,
      if (wdth != null) FontVariation('wdth', wdth),
    ];
    return s.copyWith(
      fontVariations: v,
      letterSpacing: extraTrackingEm == null ? s.letterSpacing : (s.letterSpacing ?? 0) + extraTrackingEm * (s.fontSize ?? 16),
    );
  }

  /// Archivo and Bodoni carry no box-drawing set: `Continue │ CH 213` drew a missing-glyph box (or
  /// a system font's bar). Plex Mono, already bundled, carries it.
  static const _fallback = ['IBMPlexMono'];

  static bool _capsRole(CineTokens t, CineTextRole r) =>
      identical(r, t.typeKicker) || identical(r, t.typeCredit) || identical(r, t.typeCreditLabel) || identical(r, t.typeNav) || identical(r, t.typeMicro);

  /// The role's style; at scale >= 1.3 the caps roles widen to `wdth` 100, except fixed cells.
  static TextStyle style(BuildContext context, CineTextRole role, {bool fixedCell = false}) {
    final base = CineType.style(context, role, legible: CineTextSettings.of(context).legible).copyWith(fontFamilyFallback: _fallback);
    final scale = cineScale(context);
    if (scale < 1.3 || !_capsRole(context.cine, role)) return base;
    return fixedCell ? _withVariations(base, extraTrackingEm: 0.06) : _withVariations(base, wdth: 100);
  }

  /// The role's clamped scaler (fixed cells cap at 1.3).
  static TextScaler scaler(BuildContext context, CineTextRole role, {bool fixedCell = false}) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: fixedCell ? math.min(1.3, role.cap) : role.cap);

  static double _cap(CineFace face, bool upper) => switch (face) {
        CineFace.bodoni => 1.3,
        CineFace.newsreader => 2.0,
        CineFace.plexMono => 2.0,
        CineFace.archivo => upper ? 1.5 : 2.0,
      };

  static const _wghtMax = {CineFace.bodoni: 900.0, CineFace.archivo: 900.0, CineFace.newsreader: 800.0, CineFace.plexMono: 600.0};

  /// A literal-size style ("Literal sizes", 3.3): unscaled here, render with [literalScaler] (or [CineLit]).
  static TextStyle literal(
    BuildContext context,
    CineFace face,
    double size,
    double line, {
    bool upper = false,
    bool italic = false,
    double wght = 400,
    double? wdth,
  }) {
    final c = context.cine;
    var w = wght;
    if (MediaQuery.boldTextOf(context)) w = math.min(w + 120, _wghtMax[face]!);
    final family = switch (face) {
      CineFace.bodoni => c.fontDisplay,
      CineFace.archivo => c.fontGrotesk,
      CineFace.newsreader => c.fontText,
      CineFace.plexMono => c.fontFolio,
    };
    final slug = face == CineFace.archivo && upper && cineScale(context) >= 1.3;
    final weight = FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: _fallback,
      fontSize: size,
      height: line / size,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      fontWeight: weight,
      color: c.colorInk100,
      fontVariations: [
        if (face != CineFace.plexMono) FontVariation('wght', w),
        if (face == CineFace.bodoni || face == CineFace.newsreader) FontVariation('opsz', math.min(size, 96)),
        if (face == CineFace.archivo) FontVariation('wdth', slug ? 100 : (wdth ?? 100)),
      ],
    );
  }

  static TextScaler literalScaler(BuildContext context, CineFace face, {bool upper = false}) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: _cap(face, upper));
}

/// A literal-size `Text` with its face's cap applied.
class CineLit extends StatelessWidget {
  const CineLit(
    this.text,
    this.face,
    this.size,
    this.line, {
    super.key,
    this.upper = false,
    this.italic = false,
    this.wght = 400,
    this.wdth,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.tracking,
    this.decoration,
  });

  final String text;
  final CineFace face;
  final double size, line, wght;
  final bool upper, italic;
  final double? wdth, tracking;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    var s = CineText.literal(context, face, size, line, upper: upper, italic: italic, wght: wght, wdth: wdth);
    s = s.copyWith(color: color, letterSpacing: tracking == null ? null : tracking! * size, decoration: decoration);
    return Text(
      upper ? text.toUpperCase() : text,
      style: s,
      textScaler: CineText.literalScaler(context, face, upper: upper),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// A role's `Text` with its clamped scaler.
class CineRoleText extends StatelessWidget {
  const CineRoleText(
    this.text,
    this.role, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.fixedCell = false,
    this.decoration,
    this.upper = false,
  });

  final String text;
  final CineTextRole role;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool fixedCell, upper;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) => Text(
        upper || role.upper ? text.toUpperCase() : text,
        style: CineText.style(context, role, fixedCell: fixedCell).copyWith(color: color ?? context.cine.colorInk100, decoration: decoration),
        textScaler: CineText.scaler(context, role, fixedCell: fixedCell),
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
}
