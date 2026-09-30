import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/features/collections/utils/collection_sorting.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefix = 'mm.collections.sort.';

/// The Collections sort, kept per profile.
final collectionSortProvider = StateProvider<CollectionSort>(
  (ref) {
    // A host without the preferences (a bare test scope) just keeps the choice in memory.
    SharedPreferences? prefs;
    try {
      prefs = ref.watch(sharedPrefsProvider);
    } on Object {
      return CollectionSort.name;
    }
    String key({required bool watch}) => profileScopedKey(ref, prefix: _prefix, deviceKey: '${_prefix}device', watch: watch);
    // ignore: deprecated_member_use
    ref.listenSelf((prev, next) {
      if (prev != null && prev != next) prefs?.setString(key(watch: false), next.name);
    });
    final stored = prefs?.getString(key(watch: true));
    return CollectionSort.values.where((s) => s.name == stored).firstOrNull ?? CollectionSort.name;
  },
  name: 'collectionSort',
);
