import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart';
import 'package:manhwamaniacs/skins/glass/glass_scroll_behavior.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/orientation.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/recede.dart';
import 'package:manhwamaniacs/skins/glass/router.dart';
import 'package:manhwamaniacs/skins/glass/shell/focus_policy.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart';
import 'package:manhwamaniacs/skins/glass/shell/handoff_layer.dart';
import 'package:manhwamaniacs/skins/glass/shell/session_loss.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/splash/glass_splash.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/transitions/glass_page_transitions.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

class GlassSkin implements Skin {
  const GlassSkin();

  static final ThemeData baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    canvasColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.dark(surface: Color(0xFF000000)),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: GlassPageTransitionsBuilder(),
        TargetPlatform.iOS: GlassPageTransitionsBuilder(),
      },
    ),
    textSelectionTheme: TextSelectionThemeData(selectionColor: const Color(0x667563F2), cursorColor: glassTokens.colorIris400),
    extensions: const [glassTokens],
  );

  @override
  SkinId get id => SkinId.glass;

  @override
  ThemeData theme(WidgetRef ref) => baseTheme;

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
  Widget wrap(BuildContext context, Widget child) => GlassRoot(child: child);

  // The splash is built later.
  @override
  Widget splash(BuildContext context) => const GlassSplash();

  @override
  Map<HapticEvent, List<HapticStep>> get haptics => glassHaptics;

  @override
  Map<SoundEvent, List<String>> get soundEvents => glassSoundEvents;

  @override
  Map<String, String> get soundCues => glassSoundCues;

  @override
  Future<void> prepare() {
    GlassSplash.pending = true;
    return ensureLiquidGlassReady();
  }
}

/// The Glass root under `MaterialApp.builder`: true black, the ambient field (z 0.5) behind the routes,
/// the preference bridge, the phone orientation lock, the library scope with one `BackdropGroup`, and the
/// motion-timings overlay above everything.
class GlassRoot extends ConsumerStatefulWidget {
  const GlassRoot({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassRoot> createState() => _GlassRootState();
}

class _GlassRootState extends ConsumerState<GlassRoot> {
  late final GlassFocusTraversalPolicy _focusPolicy = GlassFocusTraversalPolicy(
    bands: (context) => glassFocusBands(context, accessory: ref.read(glassAccessoryVisibleProvider)),
  );

  bool _reducedProbe() => ref.read(glassMotionPrefsProvider).reduced;

  @override
  void initState() {
    super.initState();
    GlassMotion.isReduced = _reducedProbe;
    GlassMotion.recorder.attach();
    GlassMotionRecorder.instance.mark('SKIN RESTART');
  }

  @override
  void dispose() {
    // The static probe must not outlive the ref it reads (a later move would throw "Cannot use ref after the widget was disposed"). After a
    // skin restart the new root has already installed its own probe, which this check leaves alone.
    if (GlassMotion.isReduced == _reducedProbe) GlassMotion.isReduced = () => false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showTimings = ref.watch(glassShowMotionTimingsProvider);
    return GlassPrefsBridge(
      child: GlassOrientationScope(
        child: SkinGlassRoot(
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Color(0xFF000000))),
              const Positioned.fill(child: GlassAmbientField()),
              Positioned.fill(
                child: ScrollConfiguration(
                  behavior: const GlassScrollBehavior(),
                  child: FocusTraversalGroup(
                    policy: _focusPolicy,
                    child: GlassRecedeScope(
                      child: GlassLastSeenWriter(
                        child: GlassEffectsLayer(
                          child: GlassSessionLoss(child: GlassListenLayer(child: GlassGlobalKeys(child: widget.child))),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned.fill(child: GlassSplash()),
              if (showTimings) const GlassMotionTimingsOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}
