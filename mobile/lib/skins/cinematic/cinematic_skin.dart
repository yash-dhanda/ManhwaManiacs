import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/app_frame.dart';
import 'package:manhwamaniacs/skins/cinematic/flight_layer.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/router.dart';
import 'package:manhwamaniacs/skins/cinematic/scroll_behavior.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/system_bars.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
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
    // The Material fallbacks (a stray FilledButton, a Material text field) read the skin: `spot`
    // is the accent, black is its ink, and the UI face is Archivo. Nothing here is purple.
    fontFamily: 'Archivo',
    colorScheme: ColorScheme.dark(
      surface: const Color(0xFF000000),
      primary: cinematicTokens.colorSpot,
      secondary: cinematicTokens.colorSpot,
      outline: cinematicTokens.colorInk60,
      outlineVariant: cinematicTokens.colorRule2,
    ),
    extensions: const [cinematicTokens],
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x00000000),
    hoverColor: const Color(0x00000000),
    focusColor: const Color(0x00000000),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: cinematicTokens.colorSpot,
      selectionColor: cinematicTokens.colorSpotWash,
      selectionHandleColor: cinematicTokens.colorSpot,
    ),
    // iOS routes are SwipeablePages; the entry keeps MaterialPageRoutes that a package pushes
    // consistent. Zoom and PredictiveBackFullscreen never ship.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CinePageTransitionsBuilder(),
      TargetPlatform.iOS: CinePageTransitionsBuilder(),
    },),
  );

  /// The skin's theme, for the primitives gallery harnesses.
  static ThemeData get baseTheme => _theme;

  @override
  SkinId get id => SkinId.cinematic;

  @override
  ThemeData theme(WidgetRef ref) => _theme;

  @override
  SystemUiOverlayStyle overlayStyle(WidgetRef ref) => cineRestingOverlayStyle;

  ScrollBehavior get scrollBehavior => const CineScrollBehavior();

  @override
  GoRouter buildRouter(Ref ref) => buildCinematicRouter(ref);

  @override
  Widget wrap(BuildContext context, Widget child) => CineContrastScope(
        child: CineMotionScope(
          child: CineTextSettings(
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: cineRestingOverlayStyle,
              child: CineAppFrame(child: FlightLayer(child: child)),
            ),
          ),
        ),
      );

  /// "Press start" (cinematic 12.4): the same widget the frame mounts.
  @override
  Widget splash(BuildContext context) => const CineSplash();

  @override
  Map<HapticEvent, List<HapticStep>> get haptics => cinematicHaptics;

  @override
  Map<SoundEvent, List<String>> get soundEvents => cinematicSoundEvents;

  @override
  Map<String, String> get soundCues => cinematicSoundCues;

  @override
  Future<void> prepare() async {}
}
