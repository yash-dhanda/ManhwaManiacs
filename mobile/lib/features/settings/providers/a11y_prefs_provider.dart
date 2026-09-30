import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Per-profile accessibility preferences read before first paint
/// (`mm.boot.a11y.u{user}p{profile}`, cinematic 3.4 and 4.8). Unknown fields
/// survive a write. Glass adds `solid` (Solid glass) and `contrast` (Increase contrast); `sr` is web only.
class A11yPrefs {
  const A11yPrefs({this.legible = false, this.motion = 'system', this.solid = false, this.contrast = false, this.extra = const {}});

  final bool legible;

  /// Glass: Solid glass (the Reduce Transparency look).
  final bool solid;

  /// Glass: Increase contrast (OR-ed with the OS).
  final bool contrast;

  /// `"system"` or `"reduced"`.
  final String motion;
  final Map<String, dynamic> extra;

  factory A11yPrefs.fromJson(Object? json) {
    if (json is! Map) return const A11yPrefs();
    final m = Map<String, dynamic>.from(json);
    final legible = m.remove('legible');
    final motion = m.remove('motion');
    final solid = m.remove('solid');
    final contrast = m.remove('contrast');
    return A11yPrefs(
      legible: legible == true,
      motion: motion == 'reduced' ? 'reduced' : 'system',
      solid: solid == true,
      contrast: contrast == true,
      extra: m,
    );
  }

  Map<String, dynamic> toJson() => {...extra, 'legible': legible, 'motion': motion, if (solid) 'solid': true, if (contrast) 'contrast': true};

  A11yPrefs copyWith({bool? legible, String? motion, bool? solid, bool? contrast}) =>
      A11yPrefs(legible: legible ?? this.legible, motion: motion ?? this.motion, solid: solid ?? this.solid, contrast: contrast ?? this.contrast, extra: extra);
}

final a11yPrefsProvider = NotifierProvider<A11yPrefsNotifier, A11yPrefs>(A11yPrefsNotifier.new, name: 'a11yPrefs');

final legibleTextProvider = Provider<bool>((ref) => ref.watch(a11yPrefsProvider.select((p) => p.legible)));

final appReduceMotionProvider = Provider<bool>((ref) => ref.watch(a11yPrefsProvider.select((p) => p.motion == 'reduced')));

class A11yPrefsNotifier extends Notifier<A11yPrefs> {
  static const String _prefix = 'mm.boot.a11y.';
  static const String _deviceKey = 'mm.boot.a11y.device';

  @override
  A11yPrefs build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final raw = prefs.getString(_key(watch: true));
    if (raw == null) return const A11yPrefs();
    try {
      return A11yPrefs.fromJson(jsonDecode(raw));
    } catch (_) {
      return const A11yPrefs();
    }
  }

  Future<void> setLegible(bool v) => _write(state.copyWith(legible: v));

  Future<void> setSolid(bool v) => _write(state.copyWith(solid: v));

  Future<void> setContrast(bool v) => _write(state.copyWith(contrast: v));

  Future<void> setMotion(String v) => _write(state.copyWith(motion: v == 'reduced' ? 'reduced' : 'system'));

  Future<void> _write(A11yPrefs next) async {
    state = next;
    await ref.read(sharedPrefsProvider).setString(_key(watch: false), jsonEncode(next.toJson()));
  }

  String _key({required bool watch}) {
    int? userOf(AuthState a) => a is AuthAuthenticated ? a.user.id : null;
    final userId = watch ? ref.watch(authControllerProvider.select(userOf)) : userOf(ref.read(authControllerProvider));
    final profileId = watch ? ref.watch(activeProfileProvider.select((p) => p?.id)) : ref.read(activeProfileProvider)?.id;
    if (userId == null || profileId == null) return _deviceKey;
    return '${_prefix}u${userId}p$profileId';
  }
}
