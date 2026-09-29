import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_query_provider.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

class _Profile extends ActiveProfileNotifier {
  _Profile(this.id);
  final int id;
  @override
  ActiveProfile? build() => ActiveProfile(id: id, name: 'P$id', avatarKey: null, mood: Mood.neutral);
}

Future<ProviderContainer> _open(Map<String, Object> prefs, {int profile = 1}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(p),
    authenticatedAuthOverride(),
    activeProfileProvider.overrideWith(() => _Profile(profile)),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('migration: K16 list view opens LIST, cover scale 0.8 opens COMPACT, 1.2 opens WALL', () async {
    var c = await _open({'manhwamaniacs:library-query': '{"sort":"recentlyAdded","filter":"reading","favoritesOnly":true,"viewMode":"list"}'});
    var q = c.read(shelfQueryProvider);
    expect(q.density, ShelfDensity.list);
    expect(q.sort, ShelfSort.added);
    expect(q.status, ShelfStatus.reading);
    expect(q.fav, isTrue);
    c = await _open({'settings_library_cover_scale': 0.8});
    expect(c.read(shelfQueryProvider).density, ShelfDensity.compact);
    c = await _open({'manhwamaniacs:library-query': '{"viewMode":"grid"}', 'settings_library_cover_scale': 1.2});
    expect(c.read(shelfQueryProvider).density, ShelfDensity.wall);
    c = await _open({});
    expect(c.read(shelfQueryProvider), const ShelfQuery());
  });

  test('the legacy keys are left in place', () async {
    final c = await _open({'manhwamaniacs:library-query': '{"viewMode":"list"}'});
    c.read(shelfQueryProvider);
    expect(c.read(sharedPrefsProvider).getString('manhwamaniacs:library-query'), isNotNull);
  });

  test('a stored query survives a restart for the same profile and not for another', () async {
    var c = await _open({});
    c.read(shelfQueryProvider.notifier).set(const ShelfQuery(sort: ShelfSort.read, status: ShelfStatus.completed, q: 'temp'));
    final stored = <String, Object>{for (final k in c.read(sharedPrefsProvider).getKeys()) k: c.read(sharedPrefsProvider).get(k)!};
    c = await _open(stored);
    expect(c.read(shelfQueryProvider), const ShelfQuery(sort: ShelfSort.read, status: ShelfStatus.completed));
    c = await _open(stored, profile: 2);
    expect(c.read(shelfQueryProvider), const ShelfQuery());
  });

  test('route parameters override the stored query for the visit and are not stored', () async {
    final c = await _open({});
    final n = c.read(shelfQueryProvider.notifier);
    n.set(const ShelfQuery(sort: ShelfSort.title));
    n.applyRoute({'status': 'reading'});
    expect(c.read(shelfQueryProvider).status, ShelfStatus.reading);
    expect(c.read(shelfQueryProvider).sort, ShelfSort.title);
    expect(ShelfQuery.fromStoredJson(c.read(sharedPrefsProvider).getString('mm.shelf-query.u1p1'))!.status, ShelfStatus.all);
  });
}
