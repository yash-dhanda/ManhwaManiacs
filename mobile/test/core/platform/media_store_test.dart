import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('destination by platform and API level', () {
    expect(exportDestinationFor(TargetPlatform.iOS, null), ExportDestination.iosFiles);
    expect(exportDestinationFor(TargetPlatform.android, 34), ExportDestination.mediaStoreDownloads);
    expect(exportDestinationFor(TargetPlatform.android, 29), ExportDestination.mediaStoreDownloads);
    expect(exportDestinationFor(TargetPlatform.android, 28), ExportDestination.shareOnly);
    expect(exportDestinationFor(TargetPlatform.android, 24), ExportDestination.shareOnly);
    expect(exportDestinationFor(TargetPlatform.android, null), ExportDestination.shareOnly);
  });

  test('mime by page type and CBZ', () {
    expect(mimeForExportFile('001.webp'), 'image/webp');
    expect(mimeForExportFile('001.jpg'), 'image/jpeg');
    expect(mimeForExportFile('001.png'), 'image/png');
    expect(mimeForExportFile('Chapter 1.cbz'), 'application/vnd.comicbook+zip');
  });

  test('saveDownload sends the four arguments through mm/media; sdkInt asks the channel', () async {
    const channel = MethodChannel('mm/media');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) async {
      calls.add(c);
      return c.method == 'sdkInt' ? 33 : null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final m = MediaStoreChannel();
    expect(await m.destination(platform: TargetPlatform.android), ExportDestination.mediaStoreDownloads);
    await m.saveDownload(relativePath: 'Download/ManhwaManiacs/Exports/Solo/', name: 'a.cbz', mime: 'application/vnd.comicbook+zip', path: '/x/a.cbz');
    final save = calls.last;
    expect(save.method, 'saveDownload');
    expect(save.arguments, {
      'relativePath': 'Download/ManhwaManiacs/Exports/Solo/',
      'name': 'a.cbz',
      'mime': 'application/vnd.comicbook+zip',
      'path': '/x/a.cbz',
    });
  });

  test('the path line per destination', () {
    expect(exportPathLine(ExportDestination.mediaStoreDownloads, 'Solo'), 'Files › Downloads › ManhwaManiacs › Exports › Solo');
    expect(exportPathLine(ExportDestination.iosFiles, 'Solo'), 'Files › On My iPhone › ManhwaManiacs › Exports › Solo');
    expect(exportPathLine(ExportDestination.shareOnly, 'Solo'), '');
  });
}
