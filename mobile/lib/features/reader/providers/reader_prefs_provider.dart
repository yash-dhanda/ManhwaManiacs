import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/models/reader_prefs.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// The per-series map `mm.reader-prefs.u{user}p{profile}`: `{"source:series": {layout, ...}}`.
class ReaderSeriesPrefsNotifier extends ProfileRecordNotifier {
  @override
  String get prefix => kReaderPrefsPrefix;

  /// Merges [patch] into the entry of [seriesRef] (`source:series`) and saves the map.
  Future<void> setFor(String seriesRef, Map<String, dynamic> patch) =>
      put({seriesRef: state.child(seriesRef).merge(patch).data});

  /// Saves (or, with null, removes) this series' Glass soundscape; the rest of its entry is untouched.
  Future<void> setSoundscape(String seriesRef, SeriesSoundscape? s) {
    final own = {...state.child(seriesRef).data};
    s == null ? own.remove('soundscape') : own['soundscape'] = s.toJson();
    return put({seriesRef: own});
  }
}

final readerSeriesPrefsProvider = NotifierProvider<ReaderSeriesPrefsNotifier, JsonRecord>(
  ReaderSeriesPrefsNotifier.new,
  name: 'readerSeriesPrefs',
);

/// The resolved controls for [seriesRef] (`source:series`): the series' own values, then the
/// profile's record (over the device seed the migration left), then the built-ins.
final readerPrefsProvider = Provider.family<ReaderPrefs, String>(
  (ref, seriesRef) {
    final profile = ref.watch(readerSettingsProvider);
    final seed = JsonRecord(readerPrefsSeed(ref.watch(sharedPrefsProvider)));
    final effective = JsonRecord({...seed.data, ...profile.data});
    final own = ref.watch(readerSeriesPrefsProvider).data[seriesRef];
    return ReaderPrefs.resolve(effective, own is Map ? JsonRecord(Map<String, dynamic>.from(own)) : null);
  },
  name: 'readerPrefs',
);

/// Runs the one-time legacy migration on the first open of the Cinematic reader. The profile
/// keys are the signed-in account's profiles plus the active one.
final readerPrefsMigrationProvider = FutureProvider<void>((ref) async {
  final prefs = ref.read(sharedPrefsProvider);
  if (prefs.getBool(kReaderPrefsMigratedKey) ?? false) return;
  final auth = ref.read(authControllerProvider);
  final userId = auth is AuthAuthenticated ? auth.user.id : null;
  final ids = <int>{};
  final active = ref.read(activeProfileProvider)?.id;
  if (active != null) ids.add(active);
  try {
    for (final p in await ref.read(profilesProvider.future)) {
      ids.add(p.id);
    }
  } catch (_) {
    // Offline: the active profile still migrates, the seed covers the rest.
  }
  final keys = userId == null ? const <String>[] : [for (final id in ids) '${kReaderSettingsPrefix}u${userId}p$id'];
  await migrateReaderPrefs(prefs, profileKeys: keys);
  ref.invalidate(readerSettingsProvider);
},
    name: 'readerPrefsMigration',);
