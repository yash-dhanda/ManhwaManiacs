import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/features/profiles/repositories/profiles_repository.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements ProfilesRepository {
  Result<Profile> Function() reply = () => Ok(_p);
  Completer<void>? gate;
  final calls = <(int, String?)>[];

  @override
  Future<Result<Profile>> update(int id,
      {String? name,
      String? avatarKey,
      Mood? mood,
      int? sortOrder,
      bool? matureContentEnabled,
      String? skin,}) async {
    calls.add((id, skin));
    await gate?.future;
    return reply();
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

final _p = Profile(
  id: 1,
  name: 'a',
  avatarKey: null,
  mood: Mood.neutral,
  sortOrder: 0,
  matureContentEnabled: false,
  createdAt: DateTime.utc(2024),
);

void main() {
  late SharedPreferences prefs;
  late _Repo repo;
  late SkinOutbox outbox;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _Repo();
    outbox = SkinOutbox(prefs, repo);
  });

  test('enqueue persists and the latest wins', () async {
    await outbox.enqueue(1, SkinId.glass);
    expect(prefs.getString(kSkinOutboxKey), '{"profileId":1,"skin":"glass"}');
    await outbox.enqueue(1, SkinId.cinematic);
    expect(outbox.pendingFor(1), 'cinematic');
    expect(outbox.pendingFor(2), isNull);
  });

  test('success removes the entry', () async {
    await outbox.enqueue(1, SkinId.glass);
    await outbox.flush();
    expect(repo.calls, [(1, 'glass')]);
    expect(outbox.pendingFor(1), isNull);
  });

  test('a network error keeps it', () async {
    repo.reply = () => const Err(NetworkError(message: 'down'));
    await outbox.enqueue(1, SkinId.glass);
    await outbox.flush();
    expect(outbox.pendingFor(1), 'glass');
  });

  test('a 5xx keeps it; 404 and 422 drop it', () async {
    await outbox.enqueue(1, SkinId.glass);
    repo.reply =
        () => const Err(ApiError(statusCode: 503, code: 'x', message: 'x'));
    await outbox.flush();
    expect(outbox.pendingFor(1), 'glass');
    for (final code in [404, 422]) {
      await outbox.enqueue(1, SkinId.glass);
      repo.reply =
          () => Err(ApiError(statusCode: code, code: 'x', message: 'x'));
      await outbox.flush();
      expect(outbox.pendingFor(1), isNull, reason: '$code');
    }
  });

  test('an entry replaced mid-flight survives the earlier success', () async {
    repo.gate = Completer<void>();
    await outbox.enqueue(1, SkinId.glass);
    final f = outbox.flush();
    await outbox.enqueue(1, SkinId.cinematic);
    repo.gate!.complete();
    await f;
    expect(outbox.pendingFor(1), 'cinematic');
  });

  test('overlapping flushes send one request', () async {
    repo.gate = Completer<void>();
    await outbox.enqueue(1, SkinId.glass);
    final a = outbox.flush();
    final b = outbox.flush();
    repo.gate!.complete();
    await Future.wait([a, b]);
    expect(repo.calls.length, 1);
  });
}
