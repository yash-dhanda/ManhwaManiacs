import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/interceptors/error_interceptor.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/repositories/circle_repository_impl.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

import 'circle_repository_test.dart' show FakeAdapter;

Dio _dio(FakeAdapter a) => Dio(BaseOptions(baseUrl: 'https://x.test'))
  ..httpClientAdapter = a
  ..interceptors.add(ErrorInterceptor());

void main() {
  test('Sent letters ask box=sent and read the recipients', () async {
    final a = FakeAdapter((_) => (200, [
          {
            'id': 'g1',
            'to': [
              {'profile_id': 2, 'name': 'Aarav', 'avatar_key': 'rose', 'state': 'new'},
              {'profile_id': 3, 'name': 'Mira', 'state': 'read'},
            ],
            'source_id': 's',
            'series_key': 'k',
            'title': 'Solo Leveling',
            'note': 'the tower',
            'state': 'new',
            'created_at': '2026-09-30T10:00:00Z',
          },
        ]),);
    final c = ProviderContainer(overrides: [dioProvider.overrideWithValue(_dio(a))]);
    addTearDown(c.dispose);
    final sent = await c.read(sentLettersProvider.future);
    expect(a.calls.single.path, '/circle/letters');
    expect(a.calls.single.query, {'box': 'sent'});
    expect(sent.single.to.map((t) => (t.name, t.opened)), [('Aarav', false), ('Mira', true)]);
    expect(sent.single.title, 'Solo Leveling');
  });

  test("a friend's feed sends profile_id and pages on the cursor", () async {
    final a = FakeAdapter((o) => (200, {
          'items': [
            {'id': o.queryParameters['cursor'] == null ? 'a' : 'b', 'kind': 'started', 'actor': {'profile_id': 2, 'name': 'Aarav'}, 'source_id': 's', 'series_key': 'k', 'title': 'T'},
          ],
          'next_cursor': o.queryParameters['cursor'] == null ? 'c2' : null,
        }),);
    final c = ProviderContainer(overrides: [circleRepositoryProvider.overrideWithValue(CircleRepositoryImpl(_dio(a)))]);
    addTearDown(c.dispose);
    final first = await c.read(memberFeedProvider(2).future);
    expect(first.items.single.id, 'a');
    expect(a.calls.first.query['profile_id'], 2);
    await c.read(memberFeedProvider(2).notifier).loadMore();
    expect(c.read(memberFeedProvider(2)).value!.items.map((i) => i.id), ['a', 'b']);
    expect(a.calls.last.query, containsPair('cursor', 'c2'));
    expect(a.calls.last.query, containsPair('profile_id', 2));
  });
}
