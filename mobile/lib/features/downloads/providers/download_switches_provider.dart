import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// "Save the next chapter while I read": on by default, per profile.
final saveNextProvider = NotifierProvider<_BoolSwitch, bool>(
  () => _BoolSwitch(prefix: 'mm.downloads.save-next.', fallback: true),
  name: 'saveNext',
);

/// "Download new chapters of followed series automatically": off by default, per profile.
final autoNewProvider = NotifierProvider<_BoolSwitch, bool>(
  () => _BoolSwitch(prefix: 'mm.downloads.auto-new.', fallback: false),
  name: 'autoNew',
);

class _BoolSwitch extends Notifier<bool> {
  _BoolSwitch({required this.prefix, required this.fallback});
  final String prefix;
  final bool fallback;

  String _key({required bool watch}) =>
      profileScopedKey(ref, prefix: prefix, deviceKey: '${prefix}device', watch: watch);

  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_key(watch: true)) ?? fallback;

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPrefsProvider).setBool(_key(watch: false), on);
  }
}
