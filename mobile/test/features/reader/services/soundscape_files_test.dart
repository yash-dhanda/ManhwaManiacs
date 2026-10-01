import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/services/soundscape_files.dart';

class _Adapter implements HttpClientAdapter {
  final paths = <String>[];
  bool fail = false;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    paths.add(o.path);
    if (fail) return ResponseBody.fromBytes(const [], 500);
    return ResponseBody.fromBytes(List<int>.filled(64, 7), 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tmp;
  late _Adapter adapter;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('sc');
    adapter = _Adapter();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  SoundscapeFiles make(String ext) => SoundscapeFiles(
        Dio(BaseOptions(baseUrl: 'https://x.test'))..httpClientAdapter = adapter,
        root: () async => tmp,
        ext: ext,
      );

  test('downloads once into soundscapes-v1 then serves the cache', () async {
    final s = make('m4a');
    expect(await s.isCached('rain-on-glass'), isFalse);
    final f = await s.soundscapeFile('rain-on-glass');
    expect(f.path, endsWith('soundscapes-v1/rain-on-glass.m4a'));
    expect(f.lengthSync(), 64);
    await s.soundscapeFile('rain-on-glass');
    expect(adapter.paths, ['/app/soundscapes/rain-on-glass.m4a']);
    expect(await s.isCached('rain-on-glass'), isTrue);
  });

  test('android format is ogg and a failed download leaves no partial file', () async {
    final s = make('ogg');
    adapter.fail = true;
    await expectLater(s.soundscapeFile('cafe'), throwsA(isA<DioException>()));
    final dir = Directory('${tmp.path}/soundscapes-v1');
    expect(dir.listSync(), isEmpty);
    expect(await s.isCached('cafe'), isFalse);
    adapter.fail = false;
    expect((await s.soundscapeFile('cafe')).path, endsWith('cafe.ogg'));
  });

  test('eight ids', () => expect(soundscapeIds, hasLength(8)));

  group('GlassSoundscapeFiles', () {
    GlassSoundscapeFiles glass({Future<bool> Function()? online}) => GlassSoundscapeFiles(
          Dio(BaseOptions(baseUrl: 'https://x.test'))..httpClientAdapter = adapter,
          root: () async => tmp,
          online: online,
        );

    test('200 writes the file once and a second call makes no request', () async {
      final g = glass();
      final f = await g.ensure('rain', 'bed');
      expect(f!.path, endsWith('soundscapes/glass/rain-bed.ogg'));
      expect(f.lengthSync(), 64);
      await g.ensure('rain', 'bed');
      expect(adapter.paths, ['/app/soundscapes/glass-rain-bed.ogg']);
    });

    test('a failure returns null, leaves no .part and is not retried this session', () async {
      adapter.fail = true;
      final g = glass();
      expect(await g.ensure('wind', 'tone'), isNull);
      expect(await g.ensure('wind', 'tone'), isNull);
      expect(adapter.paths.length, 1);
      expect(tmp.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.part')), isEmpty);
    });

    test('a leftover .part file never counts as cached', () async {
      final dir = Directory('${tmp.path}/soundscapes/glass')..createSync(recursive: true);
      File('${dir.path}/deep-bed.ogg.part').writeAsBytesSync([1, 2, 3]);
      final f = await glass().ensure('deep', 'bed');
      expect(adapter.paths.length, 1);
      expect(f!.lengthSync(), 64);
    });

    test('offline asks for nothing and tries again later', () async {
      var on = false;
      final g = glass(online: () async => on);
      expect(await g.ensure('ocean', 'bed'), isNull);
      expect(adapter.paths, isEmpty);
      on = true;
      expect(await g.ensure('ocean', 'bed'), isNotNull);
    });
  });
}
