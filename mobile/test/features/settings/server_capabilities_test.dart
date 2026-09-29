import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/providers/server_capabilities_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body, {this.fail = false});
  final Map<String, Object?> body;
  final bool fail;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    if (fail) throw DioException.connectionError(requestOptions: o, reason: 'down');
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    },);
  }

  @override
  void close({bool force = false}) {}
}

ProviderContainer _c(_Adapter a) {
  final dio = Dio()..httpClientAdapter = a;
  final c = ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('reads the flags', () async {
    final c = _c(_Adapter({
      'capabilities': {'ocr': false, 'collections': true, 'client_downloads': false},
    }),);
    final caps = await c.read(serverCapabilitiesProvider.future);
    expect(caps.ocr, isFalse);
    expect(caps.clientDownloads, isFalse);
    expect(caps.collections, isTrue);
    expect(caps.onlineSources, isTrue);
  });

  test('all true while offline', () async {
    final caps = await _c(_Adapter({}, fail: true)).read(serverCapabilitiesProvider.future);
    expect(caps.ocr && caps.bookmarks && caps.onlineSources, isTrue);
  });
}
