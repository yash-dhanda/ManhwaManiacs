import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/mm_platform.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Motion preference, one answer for every Glass primitive (glass 4.11).
@immutable
class GlassMotionPrefs {
  const GlassMotionPrefs({this.reduced = false});
  final bool reduced;

  @override
  bool operator ==(Object other) => other is GlassMotionPrefs && other.reduced == reduced;
  @override
  int get hashCode => reduced.hashCode;
}

/// Transparency, contrast, weight and typeface preferences (glass 4.11, 3.6).
@immutable
class GlassA11y {
  const GlassA11y({this.solid = false, this.increaseContrast = false, this.boldText = false, this.legible = false});

  final bool solid;
  final bool increaseContrast;
  final bool boldText;
  final bool legible;

  @override
  bool operator ==(Object other) =>
      other is GlassA11y &&
      other.solid == solid &&
      other.increaseContrast == increaseContrast &&
      other.boldText == boldText &&
      other.legible == legible;
  @override
  int get hashCode => Object.hash(solid, increaseContrast, boldText, legible);
}

/// `reduced = MediaQuery.disableAnimations || the in-app switch`.
final glassMotionPrefsProvider = StateProvider<GlassMotionPrefs>((ref) => const GlassMotionPrefs());

/// True while a screen reader is on (`MediaQuery.accessibleNavigation`).
final glassAssistiveProvider = StateProvider<bool>((ref) => false);

final glassA11yProvider = StateProvider<GlassA11y>((ref) => const GlassA11y());

/// The in-app switches. Per profile and shared by both skins, so an accessibility choice survives a
/// skin switch: `mm.a11y.p<profile>.<key>` in shared preferences. `lightFollowsDevice` is per device.
@immutable
class GlassInAppPrefs {
  const GlassInAppPrefs({
    this.reduceMotion = false,
    this.hyperlegible = false,
    this.solidGlass = false,
    this.increaseContrast = false,
    this.lightFollowsDevice = true,
  });

  final bool reduceMotion;
  final bool hyperlegible;
  final bool solidGlass;
  final bool increaseContrast;
  final bool lightFollowsDevice;

  GlassInAppPrefs copyWith({bool? reduceMotion, bool? hyperlegible, bool? solidGlass, bool? increaseContrast, bool? lightFollowsDevice}) =>
      GlassInAppPrefs(
        reduceMotion: reduceMotion ?? this.reduceMotion,
        hyperlegible: hyperlegible ?? this.hyperlegible,
        solidGlass: solidGlass ?? this.solidGlass,
        increaseContrast: increaseContrast ?? this.increaseContrast,
        lightFollowsDevice: lightFollowsDevice ?? this.lightFollowsDevice,
      );
}

const kGlassKeyReduceMotion = 'reduceMotion';
const kGlassKeyHyperlegible = 'hyperlegible';
const kGlassKeySolidGlass = 'solidGlass';
const kGlassKeyIncreaseContrast = 'increaseContrast';
const kGlassKeyLightFollowsDevice = 'mm.glass.lightFollowsDevice';

class GlassInAppPrefsController extends Notifier<GlassInAppPrefs> {
  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPrefsProvider);
    } catch (_) {
      return null;
    }
  }

  String _key(String k) => 'mm.a11y.p${ref.read(activeProfileProvider)?.id ?? 0}.$k';

  @override
  GlassInAppPrefs build() {
    ref.watch(activeProfileProvider.select((p) => p?.id));
    final p = _prefs;
    if (p == null) return const GlassInAppPrefs();
    return GlassInAppPrefs(
      reduceMotion: p.getBool(_key(kGlassKeyReduceMotion)) ?? false,
      hyperlegible: p.getBool(_key(kGlassKeyHyperlegible)) ?? false,
      solidGlass: p.getBool(_key(kGlassKeySolidGlass)) ?? false,
      increaseContrast: p.getBool(_key(kGlassKeyIncreaseContrast)) ?? false,
      lightFollowsDevice: p.getBool(kGlassKeyLightFollowsDevice) ?? true,
    );
  }

  void _set(String key, bool v, GlassInAppPrefs next, {bool perDevice = false}) {
    state = next;
    unawaited(_prefs?.setBool(perDevice ? key : _key(key), v));
  }

  void setReduceMotion(bool v) => _set(kGlassKeyReduceMotion, v, state.copyWith(reduceMotion: v));
  void setHyperlegible(bool v) => _set(kGlassKeyHyperlegible, v, state.copyWith(hyperlegible: v));
  void setSolidGlass(bool v) => _set(kGlassKeySolidGlass, v, state.copyWith(solidGlass: v));
  void setIncreaseContrast(bool v) => _set(kGlassKeyIncreaseContrast, v, state.copyWith(increaseContrast: v));
  void setLightFollowsDevice(bool v) =>
      _set(kGlassKeyLightFollowsDevice, v, state.copyWith(lightFollowsDevice: v), perDevice: true);
}

final glassInAppPrefsProvider =
    NotifierProvider<GlassInAppPrefsController, GlassInAppPrefs>(GlassInAppPrefsController.new);

/// Installed once at the Glass root: reads `MediaQuery` and the `mm/platform` streams and writes the
/// providers whenever they change (post frame, only on change), so `ref.read(glassMotionPrefsProvider)`
/// works outside `build`.
class GlassPrefsBridge extends ConsumerStatefulWidget {
  const GlassPrefsBridge({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassPrefsBridge> createState() => _GlassPrefsBridgeState();
}

class _GlassPrefsBridgeState extends ConsumerState<GlassPrefsBridge> {
  bool _osReduceTransparency = false;
  double _contrastLevel = 0;
  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    final mm = ref.read(mmPlatformProvider);
    _subs.add(mm.reduceTransparencyChanges.listen((v) => setState(() => _osReduceTransparency = v)));
    _subs.add(mm.contrastLevelChanges.listen((v) => setState(() => _contrastLevel = v)));
    unawaited(mm.reduceTransparency().then((v) {
      if (mounted && v != _osReduceTransparency) setState(() => _osReduceTransparency = v);
    }),);
    unawaited(mm.contrastLevel().then((v) {
      if (mounted && v != _contrastLevel) setState(() => _contrastLevel = v);
    }),);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inApp = ref.watch(glassInAppPrefsProvider);
    final motion = GlassMotionPrefs(reduced: MediaQuery.disableAnimationsOf(context) || inApp.reduceMotion);
    final assistive = MediaQuery.accessibleNavigationOf(context);
    final a11y = GlassA11y(
      solid: _osReduceTransparency || inApp.solidGlass,
      increaseContrast: MediaQuery.highContrastOf(context) || _contrastLevel >= 0.5 || inApp.increaseContrast,
      boldText: MediaQuery.boldTextOf(context),
      legible: inApp.hyperlegible,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(glassMotionPrefsProvider) != motion) ref.read(glassMotionPrefsProvider.notifier).state = motion;
      if (ref.read(glassAssistiveProvider) != assistive) ref.read(glassAssistiveProvider.notifier).state = assistive;
      if (ref.read(glassA11yProvider) != a11y) ref.read(glassA11yProvider.notifier).state = a11y;
    });
    return widget.child;
  }
}
