import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/router/app_router.dart';
import 'package:manhwamaniacs/app/theme/app_theme.dart';
import 'package:manhwamaniacs/app/theme/app_theme_provider.dart';
import 'package:manhwamaniacs/app/theme/theme_controller.dart';
import 'package:manhwamaniacs/features/auth/screens/splash_screen.dart';
import 'package:manhwamaniacs/features/settings/widgets/whats_new_auto_show.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

/// Today's app, unchanged: the only skin allowed to import `app/theme/`,
/// `app/router/` and `features/*/{screens,widgets}`.
class LegacySkin implements Skin {
  const LegacySkin();

  @override
  SkinId get id => SkinId.legacy;

  @override
  ThemeData theme(WidgetRef ref) => ref.watch(appThemeProvider);

  @override
  SystemUiOverlayStyle overlayStyle(WidgetRef ref) =>
      AppTheme.overlayStyleFor(ref.watch(themeControllerProvider));

  @override
  GoRouter buildRouter(Ref ref) => ref.watch(appRouterProvider);

  @override
  ScrollBehavior get scrollBehavior => const MaterialScrollBehavior();

  @override
  Widget wrap(BuildContext context, Widget child) => WhatsNewAutoShow(child: child);

  @override
  Widget splash(BuildContext context) => const SplashScreen();

  @override
  Map<HapticEvent, List<HapticStep>> get haptics => const {};

  @override
  Map<SoundEvent, List<String>> get soundEvents => const {};

  @override
  Map<String, String> get soundCues => const {};

  @override
  Future<void> prepare() async {}
}
