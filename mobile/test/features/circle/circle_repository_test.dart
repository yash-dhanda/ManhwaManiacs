import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/network/interceptors/error_interceptor.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository_impl.dart';

class Call {
  Call(this.method, this.path, this.query, this.body);
  final String method, path;
  final Map<String, dynamic> query;
  final Object? body;
}

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.reply);
  final (int, Object?) Function(RequestOptions) reply;
  final calls = <Call>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    calls.add(Call(o.method, o.path, o.queryParameters, o.data));
    final (status, body) = reply(o);
    return ResponseBody.fromString(body == null ? '' : jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    },);
  }

  @override
  void close({bool force = false}) {}
}

CircleRepositoryImpl _repo(FakeAdapter a) {
  final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))..httpClientAdapter = a;
  dio.interceptors.add(ErrorInterceptor());
  return CircleRepositoryImpl(dio);
}

void main() {
  test('unreact sends the DELETE body', () async {
    final a = FakeAdapter((_) => (204, null));
    final r = await _repo(a).unreact(sourceId: 's', seriesKey: 'k', chapterKey: 'c1');
    expect(r.isOk, isTrue);
    expect(a.calls.single.method, 'DELETE');
    expect(a.calls.single.path, '/circle/reactions');
    expect(a.calls.single.body, {'source_id': 's', 'series_key': 'k', 'chapter_key': 'c1'});
  });

  test('react posts the wire kind and parses ChapterReactions', () async {
    final a = FakeAdapter((_) => (200, {
          'chapter_key': 'c1',
          'chapter_number': 142.0,
          'counts': {'loved': 1, 'chefs_kiss': 2},
          'total': 3,
          'by': [
            {'profile_id': 2, 'name': 'Riya', 'kind': 'chefs_kiss'},
          ],
          'mine': 'loved',
          'sealed': false,
        }));
    final r = await _repo(a).react(sourceId: 's', seriesKey: 'k', chapterKey: 'c1', kind: ReactionKind.chefsKiss);
    expect((a.calls.single.body! as Map)['kind'], 'chefs_kiss');
    expect(r.value.countOf(ReactionKind.chefsKiss), 2);
    expect(r.value.mine, ReactionKind.loved);
    expect(r.value.sealed, isFalse);
  });

  test('409 recipient_unavailable keeps details.profile_ids', () async {
    final a = FakeAdapter((_) => (409, {'code': 'recipient_unavailable', 'message': 'no', 'details': {'profile_ids': [2]}}));
    final r = await _repo(a).sendLetter(toProfileIds: [2], sourceId: 's', seriesKey: 'k', note: ' hi ');
    expect((a.calls.single.body! as Map)['note'], 'hi');
    final e = r.error as ApiError;
    expect(e.code, 'recipient_unavailable');
    expect(((e.details! as Map)['profile_ids'] as List).single, 2);
  });

  test('404 circle_member_not_sharing', () async {
    final a = FakeAdapter((_) => (404, {'code': 'circle_member_not_sharing', 'message': 'x'}));
    final e = (await _repo(a).member(2)).error as ApiError;
    expect(e.code, 'circle_member_not_sharing');
    expect(e.statusCode, 404);
  });

  test('members with a series asks for can_receive', () async {
    final a = FakeAdapter((_) => (200, [
          {'profile_id': 2, 'name': 'Riya', 'shares': {'activity': true}, 'can_receive': true, 'now': null},
        ]));
    final r = await _repo(a).members(sourceId: 's', seriesKey: 'k');
    expect(a.calls.single.query['source_id'], 's');
    expect(r.value.single.canReceive, isTrue);
    expect(r.value.single.shares.activity, isTrue);
  });

  test('collectionsWithShared reads both lists', () async {
    final a = FakeAdapter((_) => (200, {
          'collections': [
            {'id': 1, 'name': 'Mine', 'role': 'owner'},
          ],
          'shared_with_me': [
            {'id': 2, 'name': 'Hers', 'role': 'can_add', 'owner': {'profile_id': 2, 'name': 'Riya'}},
          ],
        }));
    final r = (await _repo(a).collectionsWithShared()).value;
    expect(a.calls.single.query['include_shared'], true);
    expect(r.collections.single.role, 'owner');
    expect(r.sharedWithMe.single.owner!.name, 'Riya');
  });

  test('unshareMember and patchLetter hit their routes', () async {
    final a = FakeAdapter((o) => o.method == 'PATCH' ? (200, {'id': 5, 'state': 'kept', 'from': {'profile_id': 2, 'name': 'R'}}) : (204, null));
    final r = _repo(a);
    await r.unshareMember(3, 'me');
    expect(a.calls.last.path, '/library/collections/3/share/me');
    final l = (await r.patchLetter(5, LetterState.kept)).value;
    expect(l.state, LetterState.kept);
    expect(a.calls.last.body, {'state': 'kept'});
  });

  test('series 404 means not deployed', () async {
    final a = FakeAdapter((_) => (404, {'code': 'not_found', 'message': 'x'}));
    expect((await _repo(a).series(sourceId: 's', seriesKey: 'k')).value, isNull);
  });
}
