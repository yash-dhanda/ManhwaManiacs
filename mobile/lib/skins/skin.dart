import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

enum SkinId {
  cinematic,
  glass,
  legacy;

  /// The display face's family name as `pubspec.yaml` `fonts:` declares it (Cinematic: Bodoni
  /// Moda; Glass: Google Sans Flex; the legacy skin has no display face of its own).
  String get displayFamily => switch (this) {
        SkinId.cinematic => 'BodoniModa',
        SkinId.glass => 'GoogleSansFlexMM',
        SkinId.legacy => 'Syne',
      };
}

/// Exact enum name, else null.
SkinId? skinIdFromName(String? name) {
  for (final s in SkinId.values) {
    if (s.name == name) return s;
  }
  return null;
}

/// v1 (3.5.0) ships Cinematic as the default; release/00 later deletes legacy.
const SkinId kDefaultSkin = SkinId.cinematic;

/// release/00 replaces legacy with [SkinId.glass] at the flip; mobile/25 only checks it.
const List<SkinId> kDebugSkins = [SkinId.legacy, SkinId.cinematic];

abstract interface class Skin {
  SkinId get id;

  /// Legacy watches its palette and preset providers.
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
