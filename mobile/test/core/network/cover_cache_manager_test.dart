import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/cover_cache_manager.dart';

class _Response implements FileServiceResponse {
  _Response(this.statusCode);

  @override
  final int statusCode;
  bool drained = false;

  @override
  Stream<List<int>> get content async* {
    drained = true;
    yield [1, 2, 3];
  }

  @override
  int? get contentLength => 3;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(hours: 1));

  @override
  String? get eTag => 'abc';

  @override
  String get fileExtension => '.webp';
}

/// Plays back [script]: a status code, or an exception for a dropped connection.
class _ScriptedService extends FileService {
  _ScriptedService(this.script);
  final List<Object> script;
  final responses = <_Response>[];
  int calls = 0;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final step = script[calls++];
    if (step is Exception) throw step;
    final r = _Response(step as int);
    responses.add(r);
    return r;
  }
}

CoverFileService _service(_ScriptedService inner, {int attempts = 3}) =>
    CoverFileService(
      inner: inner,
      attempts: attempts,
      backoff: Duration.zero,
    );

void main() {
  group('CoverFileService', () {
    test('a first-try 200 is returned as is', () async {
      final inner = _ScriptedService([200]);
      final r = await _service(inner).get('u');
      expect(r.statusCode, 200);
      expect(inner.calls, 1);
    });

    test('retries a 503 and a dropped connection, then succeeds', () async {
      final inner =
          _ScriptedService([503, const SocketException('reset'), 200]);
      final r = await _service(inner).get('u');
      expect(r.statusCode, 200);
      expect(inner.calls, 3);
      // The abandoned 503 body is drained so its socket is released.
      expect(inner.responses.first.drained, isTrue);
    });

    test('retries a 429', () async {
      final inner = _ScriptedService([429, 200]);
      expect((await _service(inner).get('u')).statusCode, 200);
      expect(inner.calls, 2);
    });

    test('gives up after `attempts` and hands back the last bad status',
        () async {
      final inner = _ScriptedService([502, 502, 502]);
      final r = await _service(inner).get('u');
      expect(r.statusCode, 502);
      expect(inner.calls, 3);
    });

    test('rethrows a connection error once the attempts are spent', () async {
      final inner = _ScriptedService([
        const SocketException('a'),
        const SocketException('b'),
      ]);
      await expectLater(
        _service(inner, attempts: 2).get('u'),
        throwsA(isA<SocketException>()),
      );
      expect(inner.calls, 2);
    });

    test('does not retry a 404 (the cover is genuinely gone)', () async {
      final inner = _ScriptedService([404]);
      expect((await _service(inner).get('u')).statusCode, 404);
      expect(inner.calls, 1);
    });

    test('a stored cover stays valid for a year whatever max-age said',
        () async {
      final inner = _ScriptedService([200]);
      final r = await _service(inner).get('u');
      final left = r.validTill.difference(DateTime.now());
      expect(left, greaterThan(const Duration(days: 364)));
      expect(r.eTag, 'abc');
      expect(r.fileExtension, '.webp');
    });
  });

  group('SupportDirFileSystem', () {
    late Directory base;
    setUp(() => base = Directory.systemTemp.createTempSync('mm_cover_fs'));
    tearDown(() => base.deleteSync(recursive: true));

    test('files live under <base>/<key>, not in a purgeable temp dir',
        () async {
      final fs =
          SupportDirFileSystem('mmCovers', baseDir: () async => base.path);
      final f = await fs.createFile('a.webp');
      expect(f.path, '${base.path}/mmCovers/a.webp');
      await f.writeAsBytes([1]);
      expect(File(f.path).existsSync(), isTrue);
    });

    test('recreates the folder if the OS removed it', () async {
      final fs =
          SupportDirFileSystem('mmCovers', baseDir: () async => base.path);
      await fs.createFile('a.webp');
      Directory('${base.path}/mmCovers').deleteSync(recursive: true);
      final f = await fs.createFile('b.webp');
      await f.writeAsBytes([2]);
      expect(File('${base.path}/mmCovers/b.webp').existsSync(), isTrue);
    });
  });

  test('the shared manager keeps far more than the stock 200 covers', () {
    expect(CoverCacheManager.maxCovers, greaterThan(200));
    expect(CoverCacheManager.keepFor, greaterThan(const Duration(days: 30)));
  });
}
