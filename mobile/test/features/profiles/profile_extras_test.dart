import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/models/profile_extras.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/features/profiles/utils/daily_goal_options.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_overrides.dart';

Profile _p(int id, int order) => Profile(id: id, name: 'P$id', avatarKey: 'violet', mood: Mood.neutral, sortOrder: order, matureContentEnabled: false, createdAt: DateTime.utc(2024));

class _Repo implements ProfilesRepository {
  _Repo(this.items);
  List<Profile> items;
  Map<String, Object?>? createdWith;
  @override
  Future<Result<List<Profile>>> list() async => Ok(List.of(items));
  @override
  Future<Result<Profile>> create({required String name, required String avatarKey, required Mood mood, int? sortOrder, bool? matureContentEnabled, String? skin}) async {
    createdWith = {'skin': skin, 'name': name};
    final p = _p(50, items.length);
    items = [...items, p];
    return Ok(p);
  }

  @override
  Future<Result<Profile>> update(int id, {String? name, String? avatarKey, Mood? mood, int? sortOrder, bool? matureContentEnabled, String? skin, bool? notifyEnabled}) async => Ok(_p(id, 0));
  @override
  Future<Result<void>> remove(int id) async => const Ok(null);
}

class _Adapter implements HttpClientAdapter {
  _Adapter({this.fail = false});
  final bool fail;
  final List<({String method, String path, Object? body})> calls = [];
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    calls.add((method: o.method, path: o.path, body: o.data));
    if (fail) return ResponseBody.fromString('{"error":{"code":"boom","message":"no"}}', 500, headers: {Headers.contentTypeHeader: ['application/json']});
    final id = int.parse(o.path.split('/').last);
    return ResponseBody.fromString('{"id":$id,"name":"P$id","avatar_key":"violet","mood":"default","sort_order":0,"mature_content_enabled":false,"created_at":"2024-01-01T00:00:00Z","skin":"${(o.data as Map)['skin'] ?? ''}"}', 200, headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

Future<(ProviderContainer, _Repo, _Adapter)> _rig({bool fail = false, List<Profile>? items}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = _Repo(items ?? [_p(1, 0), _p(2, 1), _p(3, 2)]);
  final adapter = _Adapter(fail: fail);
  final dio = Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = adapter;
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    profilesRepositoryProvider.overrideWithValue(repo),
    dioProvider.overrideWithValue(dio),
    authenticatedAuthOverride(),
  ],);
  addTearDown(c.dispose);
  await c.read(profilesProvider.future);
  return (c, repo, adapter);
}

void main() {
  test('kDailyGoalOptions', () => expect(kDailyGoalOptions, [null, 5, 10, 15, 20, 30, 45, 60]));

  test('the POST never carries the skin; one PATCH carries only the extras', () async {
    final (c, repo, a) = await _rig();
    final out = await c.read(profilesProvider.notifier).createWithExtras(name: 'N', avatarKey: 'violet', mood: Mood.neutral, extras: const ProfileExtras(skin: 'glass'));
    expect(repo.createdWith!['skin'], isNull);
    expect(a.calls, hasLength(1));
    expect(a.calls.single.method, 'PATCH');
    expect(a.calls.single.body, {'skin': 'glass'});
    expect(out.created, isNotNull);
    expect(out.extrasFailed, isFalse);
  });

  test('Off sends an explicit null', () async {
    final (c, _, a) = await _rig();
    await c.read(profilesProvider.notifier).createWithExtras(name: 'N', avatarKey: 'violet', mood: Mood.neutral, extras: const ProfileExtras(dailyGoal: (minutes: null)));
    expect(a.calls.single.body, {'daily_goal_minutes': null});
  });

  test('a PATCH failure after a successful POST keeps the profile and flags it', () async {
    final (c, _, _) = await _rig(fail: true);
    final out = await c.read(profilesProvider.notifier).createWithExtras(name: 'N', avatarKey: 'violet', mood: Mood.neutral, extras: const ProfileExtras(skin: 'glass'));
    expect(out.created, isNotNull);
    expect(out.extrasFailed, isTrue);
  });

  test('no extras, no PATCH', () async {
    final (c, _, a) = await _rig();
    await c.read(profilesProvider.notifier).createWithExtras(name: 'N', avatarKey: 'violet', mood: Mood.neutral);
    expect(a.calls, isEmpty);
  });

  test('reorder sends only the moved profiles, in order', () async {
    final (c, _, a) = await _rig();
    await c.read(profilesProvider.notifier).reorder([1, 3, 2]);
    expect(a.calls.map((x) => '${x.path} ${x.body}').toList(), ['/profiles/3 {sort_order: 1}', '/profiles/2 {sort_order: 2}']);
  });

  test('edit with extras is one PATCH with the fields and the extras', () async {
    final (c, _, a) = await _rig();
    await c.read(profilesProvider.notifier).edit(1, name: 'X', extras: const ProfileExtras(dailyGoal: (minutes: 15)));
    expect(a.calls.single.body, {'name': 'X', 'daily_goal_minutes': 15});
  });
}
