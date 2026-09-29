import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/router.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

class CinematicSkin implements Skin {
  const CinematicSkin();

  static final ThemeData _theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    canvasColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.dark(surface: Color(0xFF000000)),
    extensions: const [cinematicTokens],
  );

  @override
  SkinId get id => SkinId.cinematic;

  @override
  ThemeData theme(WidgetRef ref) => _theme;

  @override
  SystemUiOverlayStyle overlayStyle(WidgetRef ref) => const SystemUiOverlayStyle(
        statusBarColor: Color(0x00000000),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0x00000000),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      );

  @override
  GoRouter buildRouter(Ref ref) => buildCinematicRouter(ref);

  @override
  Widget wrap(BuildContext context, Widget child) => child;

  // mobile/06 builds "Press start".
  @override
  Widget splash(BuildContext context) => const ColoredBox(color: Color(0xFF000000));

  @override
  Map<HapticEvent, List<HapticStep>> get haptics => cinematicHaptics;

  @override
  Map<SoundEvent, List<String>> get soundEvents => cinematicSoundEvents;

  @override
  Map<String, String> get soundCues => cinematicSoundCues;

  @override
  Future<void> prepare() async {}
}
