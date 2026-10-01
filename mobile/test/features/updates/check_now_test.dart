import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository_impl.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final (int, Object) Function(RequestOptions o) respond;
  final log = <String>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? body, Future<void>? cancel) async {
    log.add('${options.method} ${options.path}');
    final (status, data) = respond(options);
    return ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    },);
  }

  @override
  void close({bool force = false}) {}
}

UpdatesRepositoryImpl _repo(_Adapter a) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'))..httpClientAdapter = a;
  // The app's error interceptor maps an error status to the contract's ApiError.
  dio.interceptors.add(InterceptorsWrapper(onError: (e, h) {
    final d = e.response?.data;
    if (d is Map) {
      h.next(e.copyWith(error: ApiError(statusCode: e.response!.statusCode!, code: '${d['code']}', message: '${d['message']}')));
    } else {
      h.next(e);
    }
  },),);
  return UpdatesRepositoryImpl(dio);
}

const _run = {'id': 4, 'trigger': 'manual', 'status': 'completed', 'series_checked': 3, 'new_chapters_found': 1};

void main() {
  test('a check that runs inline is `ran`', () async {
    final a = _Adapter((o) => (200, _run));
    final r = await _repo(a).checkNow();
    expect(r.value, CheckOutcome.ran);
    expect(a.log, ['POST /updates/check']);
  });

  test('a check behind a running one is `queued`', () async {
    final r = await _repo(_Adapter((o) => (200, {'queued': true}))).checkNow();
    expect(r.value, CheckOutcome.queued);
  });

  test('409 check_already_running is `alreadyRunning`, not an error; other errors stay errors', () async {
    final r = await _repo(_Adapter((o) => (409, {'code': 'check_already_running', 'message': 'busy'}))).checkNow();
    expect(r.isOk, isTrue);
    expect(r.value, CheckOutcome.alreadyRunning);
    final bad = await _repo(_Adapter((o) => (500, {'code': 'boom', 'message': 'x'}))).checkNow();
    expect(bad.isErr, isTrue);
  });

  test('sources, run and per-series check hit their paths', () async {
    final a = _Adapter((o) => switch (o.path) {
          '/updates/sources' => (200, [{'id': 'asura'}, {'id': 'mangadex'}]),
          _ => (200, _run),
        },);
    final repo = _repo(a);
    expect((await repo.listUpdateSources()).value, ['asura', 'mangadex']);
    expect((await repo.getRun(4)).value.id, 4);
    expect((await repo.checkSeries(9)).value.id, 4);
    expect(a.log, ['GET /updates/sources', 'GET /updates/runs/4', 'POST /updates/followed/9/check']);
  });
}
