import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/router.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

class GlassSkin implements Skin {
  const GlassSkin();

  static final ThemeData _theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    canvasColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.dark(surface: Color(0xFF000000)),
    extensions: const [glassTokens],
  );

  @override
  SkinId get id => SkinId.glass;

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
  GoRouter buildRouter(Ref ref) => buildGlassRouter(ref);

  @override
  Widget wrap(BuildContext context, Widget child) => child;

  // mobile/03 loads shaders here; the splash is built later.
  @override
  Widget splash(BuildContext context) => const ColoredBox(color: Color(0xFF000000));

  @override
  Map<HapticEvent, List<HapticStep>> get haptics => glassHaptics;

  @override
  Map<SoundEvent, List<String>> get soundEvents => glassSoundEvents;

  @override
  Map<String, String> get soundCues => glassSoundCues;

  @override
  Future<void> prepare() async {}
}
