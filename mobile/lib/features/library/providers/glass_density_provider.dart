import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefix = 'mm.glass.library-density.';
const _legacyQueryKey = 'manhwamaniacs:library-query'; // K16
const _legacyCoverScaleKey = 'settings_library_cover_scale'; // K15
const _glassPrefsPrefix = 'mm.glass.prefs.';

/// The Glass library density of one profile: the phone ladder value and the wide-frame value.
@immutable
class GlassDensity {
  const GlassDensity({this.phone = GlassPhoneDensity.c3, this.wide = GlassDensityWide.comfortable});
  final GlassPhoneDensity phone;
  final GlassDensityWide wide;

  GlassDensity copyWith({GlassPhoneDensity? phone, GlassDensityWide? wide}) => GlassDensity(phone: phone ?? this.phone, wide: wide ?? this.wide);

  String toJson() => jsonEncode({'phone': phone.wire, 'wide': wide.name});

  static GlassDensity? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      return GlassDensity(
        phone: GlassPhoneDensity.parse(m['phone']),
        wide: GlassDensityWide.values.firstWhere((d) => d.name == m['wide'], orElse: () => GlassDensityWide.comfortable),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) => other is GlassDensity && other.phone == phone && other.wide == wide;

  @override
  int get hashCode => Object.hash(phone, wide);
}

/// glass 8.25.3, row "Library density": K16 `viewMode: list` → List; else K15 cover scale `< 0.85` → 4 columns / Compact,
/// `0.85–1.25` → 3 / Comfortable, `> 1.25` → 2 / Comfortable; nothing stored → 3 / Comfortable. The legacy keys are only read.
/// [libraryColumns] is the 2, 3 or 4 the settings migration seeded in the profile's `mm.glass.prefs` entry; it stands in for K15.
GlassDensity migrateGlassDensity(SharedPreferences prefs, {int? libraryColumns}) {
  final raw = prefs.getString(_legacyQueryKey);
  if (raw != null && raw.isNotEmpty) {
    try {
      final m = jsonDecode(raw);
      if (m is Map && m['viewMode'] == 'list') return const GlassDensity(phone: GlassPhoneDensity.list, wide: GlassDensityWide.list);
    } catch (_) {}
  }
  switch (libraryColumns) {
    case 4:
      return const GlassDensity(phone: GlassPhoneDensity.c4, wide: GlassDensityWide.compact);
    case 3:
      return const GlassDensity();
    case 2:
      return const GlassDensity(phone: GlassPhoneDensity.c2);
  }
  final scale = prefs.getDouble(_legacyCoverScaleKey);
  if (scale == null) return const GlassDensity();
  if (scale < 0.85) return const GlassDensity(phone: GlassPhoneDensity.c4, wide: GlassDensityWide.compact);
  if (scale > 1.25) return const GlassDensity(phone: GlassPhoneDensity.c2);
  return const GlassDensity();
}

final glassDensityProvider = NotifierProvider<GlassDensityNotifier, GlassDensity>(GlassDensityNotifier.new, name: 'glassDensity');

class GlassDensityNotifier extends Notifier<GlassDensity> {
  String _key({required bool watch}) => profileScopedKey(ref, prefix: _prefix, deviceKey: '${_prefix}device', watch: watch);

  @override
  GlassDensity build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final key = _key(watch: true);
    final stored = GlassDensity.fromJson(prefs.getString(key));
    if (stored != null) return stored;
    final derived = migrateGlassDensity(prefs, libraryColumns: _seededColumns(prefs, key));
    prefs.setString(key, derived.toJson());
    return derived;
  }

  /// The `libraryColumns` field of the same persona's `mm.glass.prefs` entry, if any.
  int? _seededColumns(SharedPreferences prefs, String densityKey) {
    if (!densityKey.startsWith(_prefix) || densityKey.endsWith('device')) return null;
    try {
      final m = jsonDecode(prefs.getString(_glassPrefsPrefix + densityKey.substring(_prefix.length)) ?? '');
      final v = m is Map ? m['libraryColumns'] : null;
      return v is int ? v : null;
    } catch (_) {
      return null;
    }
  }

  void _set(GlassDensity next) {
    if (next == state) return;
    state = next;
    ref.read(sharedPrefsProvider).setString(_key(watch: false), next.toJson());
  }

  void setPhone(GlassPhoneDensity d) => _set(state.copyWith(phone: d));
  void setWide(GlassDensityWide d) => _set(state.copyWith(wide: d));
  void stepPhoneBy({required bool larger}) => setPhone(stepPhone(state.phone, larger: larger));
  void stepWideBy({required bool larger}) => setWide(stepWide(state.wide, larger: larger));
}
