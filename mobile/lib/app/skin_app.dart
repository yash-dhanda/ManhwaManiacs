import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/display/high_refresh_rate.dart';
import 'package:manhwamaniacs/app/skin_boot_check.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/core/platform/app_icon_switcher.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_lifecycle_gate.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The app root for every skin: the skin owns theme, router, overlay style and wrapper.
class SkinApp extends ConsumerStatefulWidget {
  const SkinApp({super.key});

  @override
  ConsumerState<SkinApp> createState() => _SkinAppState();
}

class _SkinAppState extends ConsumerState<SkinApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SkinRestartTiming.logFirstFrame(ref.read(sharedPrefsProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinProvider);
    final router = ref.watch(skinRouterProvider);
    // Keeps the window's display-mode preference in step with the user's setting.
    ref.watch(highRefreshRateSyncProvider);
    // Binds SkinAudio to the running skin and the active (user, profile) from the first frame, and rebinds on a
    // switch: every cue site plays through SkinAudio.instance, which stays silent until bound.
    ref.watch(skinAudioProvider);
    final themed = skin.theme(ref);

    return MaterialApp.router(
      title: 'ManhwaManiacs',
      debugShowCheckedModeBanner: false,
      theme: themed,
      darkTheme: themed,
      routerConfig: router,
      scrollBehavior: skin is CinematicSkin ? skin.scrollBehavior : null,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: skin.overlayStyle(ref),
        child: AppIconPauseListener(
          child: DownloadsLifecycleGate(
            child: SkinBootCheck(child: skin.wrap(context, child ?? const SizedBox.shrink())),
          ),
        ),
      ),
    );
  }
}
