import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/services/backup_download.dart';

class _Dio implements Dio {
  String? path, savePath;
  Map<String, dynamic>? query;

  @override
  Future<Response<dynamic>> download(String urlPath, dynamic savePath,
      {ProgressCallback? onReceiveProgress, Map<String, dynamic>? queryParameters, CancelToken? cancelToken, bool deleteOnError = true,
      String lengthHeader = Headers.contentLengthHeader, Object? data, Options? options, FileAccessMode fileAccessMode = FileAccessMode.write,}) async {
    path = urlPath;
    this.savePath = savePath as String;
    query = queryParameters;
    onReceiveProgress?.call(124, 412);
    return Response(requestOptions: RequestOptions(path: urlPath));
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  test('file name carries the local date and minute', () {
    expect(backupFileName(DateTime(2026, 9, 28, 3, 5)), 'manhwamaniacs-backup-20260928-0305.db');
  });

  test('restore validation lines', () {
    expect(validateRestoreFile(name: 'notes.txt', size: 10), "That isn't a .db file.");
    expect(validateRestoreFile(name: 'a.db', size: 0), 'That file is empty.');
    expect(validateRestoreFile(name: 'A.DB', size: 3), isNull);
  });

  test('export streams to the temp dir with include_cache and reports progress', () async {
    final dio = _Dio();
    final dir = Directory.systemTemp.createTempSync('bk');
    addTearDown(() => dir.deleteSync(recursive: true));
    final got = <(int, int)>[];
    final path = await BackupDownloader(dio, tempDir: () async => dir, clock: () => DateTime(2026, 9, 28, 3))
        .download(includeCaches: true, onProgress: (r, t) => got.add((r, t)));
    expect(dio.path, '/backup/export');
    expect(dio.query, {'include_cache': true});
    expect(path, '${dir.path}/manhwamaniacs-backup-20260928-0300.db');
    expect(got, [(124, 412)]);
    expect(backupProgressLabel(124 * 1024 * 1024, 412 * 1024 * 1024), '124 MB OF 412 MB');
  });

  test('include_cache is sent only when the switch is on', () async {
    final dir = Directory.systemTemp.createTempSync('bk');
    addTearDown(() => dir.deleteSync(recursive: true));
    final off = _Dio();
    await BackupDownloader(off, tempDir: () async => dir).download(includeCaches: false);
    expect(off.query, isNull);
    final on = _Dio();
    await BackupDownloader(on, tempDir: () async => dir).download(includeCaches: true);
    expect(on.query, {'include_cache': true});
  });
}
