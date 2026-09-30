import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The seven page stocks by stored id (the same ids `kNovelStocks` / Settings use), with their
/// labels for the Type sheet.
const kNovelStockLabels = <String, String>{
  'nitrate': 'Nitrate',
  'ink': 'Ink',
  'sepiaNight': 'Sepia Night',
  'dusk': 'Dusk',
  'moss': 'Moss',
  'rosewood': 'Rosewood',
  'issue': 'Issue',
};

/// The stock a K26 palette id (`mm.novel-palette.u{user}p{profile}`) migrates to (cinematic
/// 2.1.6): `black`, `app` or no value read Nitrate.
String stockFromPalette(String? palette) => switch (palette) {
      'paper' || 'soft-grey' => 'ink',
      'sepia' || 'cream' || 'dusk' => 'sepiaNight',
      'midnight' || 'solarized-dark' || 'solarized-light' => 'dusk',
      'forest' => 'moss',
      'rose-pine' || 'dawn' => 'rosewood',
      _ => 'nitrate',
    };

/// The stored stock, else the K26 migration. Never writes.
String resolveStockId(JsonRecord settings, String? k26Palette) =>
    settings.hasNovelStock ? settings.novelStock : stockFromPalette(k26Palette);

/// The profile's stock id (Issue resolves per book at paint time).
final novelStockIdProvider = Provider<String>(
  (ref) => resolveStockId(ref.watch(novelSettingsProvider), ref.watch(novelPaletteControllerProvider)),
  name: 'novelStockId',
);

/// The colours of stock [id]. Issue draws from [ambient] and falls back to Nitrate when the series
/// has none.
CineStockColors stockColorsFor(String id, {AmbientRoles? ambient}) => switch (id) {
      'ink' => const CineStockColors(CineColors.stockInkPage, CineColors.stockInkInk, CineColors.stockInkMuted),
      'sepiaNight' => const CineStockColors(CineColors.stockSepiaNightPage, CineColors.stockSepiaNightInk, CineColors.stockSepiaNightMuted),
      'dusk' => const CineStockColors(CineColors.stockDuskPage, CineColors.stockDuskInk, CineColors.stockDuskMuted),
      'moss' => const CineStockColors(CineColors.stockMossPage, CineColors.stockMossInk, CineColors.stockMossMuted),
      'rosewood' => const CineStockColors(CineColors.stockRosewoodPage, CineColors.stockRosewoodInk, CineColors.stockRosewoodMuted),
      'issue' => _issue(ambient),
      _ => const CineStockColors(CineColors.stockNitratePage, CineColors.stockNitrateInk, CineColors.stockNitrateMuted),
    };

CineStockColors _issue(AmbientRoles? ambient) {
  final s = issueStock(ambient);
  return CineStockColors(s.page, s.ink, s.muted);
}

/// The black layer's alpha for a brightness of -75..0.
double brightnessAlpha(int brightness) => math.min(75, brightness.abs()) / 100;
