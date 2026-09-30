import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// glass 12.2 and `brand/glass/icon-registration.md`: the alternate icons `release/01` registers. iOS names the Glass icon
/// set; `null` restores the primary icon (Cinematic's since `release/00`).
const String kGlassIosIconName = 'AppIcon-Glass';

/// Android: the fully qualified `activity-alias` class names (the plugin compares class names, so short names would fail).
const String kAndroidGlassIconAlias = 'com.manhwamaniacs.reader.GlassIcon';
const String kAndroidCinematicIconAlias = 'com.manhwamaniacs.reader.CinematicIcon';

/// Per device: "App icon follows the skin" (default off).
const String kIconFollowKey = 'mm.icon.follow';

/// Per device: the Android alias waiting for the next `AppLifecycleState.paused`.
const String kIconPendingKey = 'mm.icon.pending';

/// The two plugin calls, injectable so tests run without a platform channel.
abstract interface class AppIconPlugin {
  Future<void> setIos(String? name);
  Future<void> setAndroid(String name);
}

class DynamicIconPlugin implements AppIconPlugin {
  const DynamicIconPlugin();

  @override
  Future<void> setIos(String? name) => FlutterDynamicIconPlus.setAlternateIconName(iconName: name);

  @override
  Future<void> setAndroid(String name) =>
      FlutterDynamicIconPlus.setAlternateIconName(iconName: name);
}

/// The app icon rules of glass 12.2. Only an explicit skin choice on this device moves the icon: never a profile hand-off, never a
/// boot-time mismatch. Nothing runs while `Flags.glassAvailable` is false (the alternate icons are unregistered until `release/01`).
class AppIconSwitcher {
  AppIconSwitcher({
    required SharedPreferences prefs,
    AppIconPlugin plugin = const DynamicIconPlugin(),
    bool glassAvailable = Flags.glassAvailable,
    TargetPlatform? platform,
  })  : _prefs = prefs,
        _plugin = plugin,
        _glassAvailable = glassAvailable,
        _platform = platform;

  final SharedPreferences _prefs;
  final AppIconPlugin _plugin;
  final bool _glassAvailable;
  final TargetPlatform? _platform;

  TargetPlatform get _target => _platform ?? defaultTargetPlatform;

  bool get follow => _prefs.getBool(kIconFollowKey) ?? false;

  Future<void> setFollow(bool on) => _prefs.setBool(kIconFollowKey, on);

  String? get pending => _prefs.getString(kIconPendingKey);

  /// Called once per explicit skin choice, inside the restart moment (after the melt reaches black, before the restart).
  /// iOS changes the icon now, so the system's one-line alert lands over black; Android queues the alias until the app pauses.
  Future<void> onExplicitSkinChoice(SkinId skin) async {
    if (!_glassAvailable) {
      appLogger.d('icon: skipped, glass_available false');
      return;
    }
    if (!follow) return;
    switch (_target) {
      case TargetPlatform.iOS:
        try {
          await _plugin.setIos(skin == SkinId.glass ? kGlassIosIconName : null);
        } catch (e, st) {
          appLogger.w('icon: iOS switch failed', e, st);
        }
      case TargetPlatform.android:
        await _prefs.setString(kIconPendingKey, skin == SkinId.glass ? kAndroidGlassIconAlias : kAndroidCinematicIconAlias);
      default:
        break;
    }
  }

  /// Android: applies the queued alias and clears the key. Never called during the restart: a component toggle can end the task.
  Future<void> applyPending() async {
    final name = pending;
    if (name == null || _target != TargetPlatform.android) return;
    await _prefs.remove(kIconPendingKey);
    try {
      await _plugin.setAndroid(name);
    } catch (e, st) {
      appLogger.w('icon: Android switch failed', e, st);
    }
  }
}

final appIconSwitcherProvider = Provider<AppIconSwitcher>((ref) => AppIconSwitcher(prefs: ref.watch(sharedPrefsProvider)), name: 'appIconSwitcher');

/// Skin-neutral, registered once at app start: applies the queued Android alias when the app goes to the background.
class AppIconPauseListener extends ConsumerStatefulWidget {
  const AppIconPauseListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppIconPauseListener> createState() => _AppIconPauseListenerState();
}

class _AppIconPauseListenerState extends ConsumerState<AppIconPauseListener> {
  late final AppLifecycleListener _listener = AppLifecycleListener(onPause: () => unawaited(ref.read(appIconSwitcherProvider).applyPending()));

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
