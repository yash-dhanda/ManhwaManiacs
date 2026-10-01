import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

enum SkinId {
  cinematic,
  glass;

  /// The display face's family name as `pubspec.yaml` `fonts:` declares it (Cinematic: Bodoni
  /// Moda; Glass: Google Sans Flex).
  String get displayFamily => switch (this) {
        SkinId.cinematic => 'BodoniModa',
        SkinId.glass => 'GoogleSansFlexMM',
      };
}

/// Exact enum name, else null. The retired `legacy` (and anything unknown) is null, so every
/// caller falls back to [kDefaultSkin].
SkinId? skinIdFromName(String? name) {
  for (final s in SkinId.values) {
    if (s.name == name) return s;
  }
  return null;
}

/// Cinematic is the default; a stored `legacy` from before 4.0.1 boots it too.
const SkinId kDefaultSkin = SkinId.cinematic;

abstract interface class Skin {
  SkinId get id;

  ThemeData theme(WidgetRef ref);
  SystemUiOverlayStyle overlayStyle(WidgetRef ref);

  /// Called once per ProviderScope.
  GoRouter buildRouter(Ref ref);

  /// Skin-specific wrappers under MaterialApp.builder.
  Widget wrap(BuildContext context, Widget child);

  /// The skin's first frame after the black native frame.
  Widget splash(BuildContext context);
  Map<HapticEvent, List<HapticStep>> get haptics;
  Map<SoundEvent, List<String>> get soundEvents;

  /// cue -> asset path.
  Map<String, String> get soundCues;

  /// Awaited before the router is built (Glass loads its shaders in mobile/03).
  Future<void> prepare();
}
