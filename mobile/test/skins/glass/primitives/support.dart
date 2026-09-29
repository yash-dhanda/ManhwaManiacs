import 'package:flutter/material.dart' show DefaultMaterialLocalizations, Material, MaterialType, Theme, ThemeData;
import 'package:flutter/services.dart' show CachingAssetBundle, ByteData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_feedback/haptic_feedback.dart' show HapticsType;
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// A Glass host for primitive tests: providers, an overlay (tooltips), the frost backdrop group.
class _NullDriver implements HapticsDriver {
  @override
  Future<void> named(HapticsType type) async {}
  @override
  Future<void> ahap(String json) async {}
  @override
  Future<void> impact(String style, double intensity) async {}
  @override
  Future<bool> perform(String pattern) async => true;
  @override
  Future<bool> oneShot(int ms, int amplitude) async => true;
  @override
  Future<bool> systemEnabled() async => true;
}

class _Bundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => key;
}

int _t = 0;

/// Haptics that record into `GlassHaptics.debugLog` and never rate limit (each call is a second later).
final glassHapticsTestOverride = glassHapticsProvider.overrideWith(
  (ref) => GlassHaptics(
    haptics: SkinHaptics(skin: SkinId.glass, map: glassHaptics, enabled: true, driver: _NullDriver(), bundle: _Bundle()),
    clock: () => Duration(seconds: _t++),
  ),
);

Widget primHost(
  Widget child, {
  List<Override> overrides = const [],
  Size size = const Size(390, 844),
  TargetPlatform platform = TargetPlatform.iOS,
  bool reduced = false,
  bool solid = false,
  bool align = true,
  double textScale = 1,
}) =>
    ProviderScope(
      overrides: [
        glassHapticsTestOverride,
        ...overrides,
        if (reduced) glassMotionPrefsProvider.overrideWith((ref) => const GlassMotionPrefs(reduced: true)),
        if (solid) glassA11yProvider.overrideWith((ref) => const GlassA11y(solid: true)),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: 3, textScaler: TextScaler.linear(textScale)),
        child: Theme(
          data: ThemeData(platform: platform),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
              style: const TextStyle(),
              child: Shortcuts(
                shortcuts: WidgetsApp.defaultShortcuts,
                child: Actions(
                  actions: WidgetsApp.defaultActions,
                  child: FocusTraversalGroup(
                    child: FocusScope(
                      autofocus: true,
                      child: SkinGlassRoot(
                      child: Localizations(
                        locale: const Locale('en'),
                        delegates: const [DefaultWidgetsLocalizations.delegate, DefaultMaterialLocalizations.delegate],
                        child: Material(
                          type: MaterialType.transparency,
                          child: Overlay(
                            initialEntries: [
                              OverlayEntry(builder: (_) => align ? Align(alignment: Alignment.topLeft, child: child) : child),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

ProviderContainer primContainer(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(SkinGlassRoot)));

void bindReduced(WidgetTester tester) {
  GlassMotion.isReduced = () => primContainer(tester).read(glassMotionPrefsProvider).reduced;
  addTearDown(() => GlassMotion.isReduced = () => false);
}

/// Pumps [ms] in 16 ms frames, like a real device (a single long pump renders one frame).
Future<void> pumpFor(WidgetTester tester, int ms) async {
  var left = ms;
  while (left > 0) {
    final step = left < 16 ? left : 16;
    await tester.pump(Duration(milliseconds: step));
    left -= step;
  }
}
