import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/stocks.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/type_rows.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';

/// The body type as the reader sets it: the book's values over the profile's over the face
/// defaults scaled by the system text scale. Watched by the screen, the sheet and the tiles.
NovelType watchNovelType(WidgetRef ref, BuildContext context, String prefsKey) {
  final book = ref.watch(novelPreferencesControllerProvider(prefsKey));
  final settings = ref.watch(novelSettingsProvider);
  final legible = ref.watch(legibleTextProvider);
  final size = MediaQuery.sizeOf(context);
  return resolveNovelType(
    book: book,
    settings: settings,
    legible: legible,
    systemScale: MediaQuery.textScalerOf(context).scale(1),
    tablet: size.shortestSide >= 600,
    osBold: MediaQuery.boldTextOf(context),
  );
}

/// Opens `Text and page` (cinematic 8.15.5): a `[0.5, 0.92]` live-preview sheet painted in the
/// current stock, with the kicker `TEXT AND PAGE`. Every change applies live under it; the
/// returned future completes when it closes, and the caller hides the chrome then.
Future<void> showNovelTypeSheet(
  BuildContext context, {
  required String prefsKey,
  required CineStockColors stock,
  AmbientRoles? ambient,
  List<NovelTypeRow>? rows,
}) =>
    showCineSheet<void>(
      context,
      kicker: 'TEXT AND PAGE',
      title: 'Text and page',
      livePreview: true,
      builder: (sheetContext) => CineStock.stock(
        stock,
        Material(
          type: MaterialType.transparency,
          child: NovelTypeBody(prefsKey: prefsKey, ambient: ambient, rows: rows ?? kNovelTypeRows),
        ),
      ),
    );

/// The rows of the sheet and its `Reset text and page` footer.
class NovelTypeBody extends ConsumerWidget {
  const NovelTypeBody({super.key, required this.prefsKey, required this.rows, this.ambient});

  final String prefsKey;
  final AmbientRoles? ambient;
  final List<NovelTypeRow> rows;

  Future<void> _reset(WidgetRef ref) async {
    await ref.read(novelPreferencesControllerProvider(prefsKey).notifier).resetType();
    await ref.read(novelSettingsProvider.notifier).put({for (final k in kNovelProfileTypeKeys) k: null});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(novelSettingsProvider);
    final c = NovelTypeCtx(
      context: context,
      ref: ref,
      prefsKey: prefsKey,
      prefs: ref.watch(novelPreferencesControllerProvider(prefsKey)),
      type: watchNovelType(ref, context, prefsKey),
      settings: settings,
      tablet: MediaQuery.sizeOf(context).shortestSide >= 600,
      stockId: ref.watch(novelStockIdProvider),
      ambient: ambient,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) row(c),
        const SizedBox(height: 16),
        quietAction('Reset text and page', () => unawaited(_reset(ref))),
        const SizedBox(height: 24),
      ],
    );
  }
}
