import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Where a "Save to Files" export ends up.
enum ExportDestination {
  /// iOS: `Documents/Exports/{series}`, shown in Files › On My iPhone › ManhwaManiacs.
  iosFiles,

  /// Android 10+: copied into MediaStore `Downloads` (`Download/ManhwaManiacs/Exports/{series}/`).
  mediaStoreDownloads,

  /// Android 7-9: the documents export stays, and the result offers Share.
  shareOnly,
}

/// The destination for [platform] and, on Android, the API level [sdkInt].
ExportDestination exportDestinationFor(TargetPlatform platform, int? sdkInt) {
  if (platform == TargetPlatform.iOS) return ExportDestination.iosFiles;
  return (sdkInt ?? 0) >= 29 ? ExportDestination.mediaStoreDownloads : ExportDestination.shareOnly;
}

String mimeForExportFile(String name) => switch (p.extension(name).toLowerCase()) {
      '.webp' => 'image/webp',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.avif' => 'image/avif',
      '.heic' => 'image/heic',
      '.bmp' => 'image/bmp',
      '.cbz' => 'application/vnd.comicbook+zip',
      _ => 'application/octet-stream',
    };

/// The `mm/media` channel's Dart side (Android). mobile/21 adds its share-card method here.
class MediaStoreChannel {
  MediaStoreChannel({MethodChannel? channel}) : _channel = channel ?? const MethodChannel('mm/media');
  final MethodChannel _channel;

  Future<int?> sdkInt() async {
    try {
      return await _channel.invokeMethod<int>('sdkInt');
    } catch (_) {
      return null;
    }
  }

  Future<ExportDestination> destination({TargetPlatform? platform}) async {
    final target = platform ?? defaultTargetPlatform;
    if (target == TargetPlatform.iOS) return ExportDestination.iosFiles;
    return exportDestinationFor(target, await sdkInt());
  }

  /// Copies one file into `Download/{relativeDir}` (no permission needed on API 29+).
  Future<void> saveDownload({required String relativePath, required String name, required String mime, required String path}) =>
      _channel.invokeMethod<void>('saveDownload', {
        'relativePath': relativePath,
        'name': name,
        'mime': mime,
        'path': path,
      });

  /// Copies every file under [seriesDirectory] (the export's series folder) into
  /// `Download/ManhwaManiacs/Exports/{series}/…`, keeping chapter sub-folders. Returns the file count.
  Future<int> saveExport({required Directory seriesDirectory, required String seriesFolderName}) async {
    var n = 0;
    await for (final e in seriesDirectory.list(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      final rel = p.relative(p.dirname(e.path), from: seriesDirectory.path);
      final sub = rel == '.' ? '' : '${rel.replaceAll(r'\', '/')}/';
      await saveDownload(
        relativePath: 'Download/ManhwaManiacs/Exports/$seriesFolderName/$sub',
        name: p.basename(e.path),
        mime: mimeForExportFile(e.path),
        path: e.path,
      );
      n++;
    }
    return n;
  }
}

final mediaStoreChannelProvider = Provider<MediaStoreChannel>((ref) => MediaStoreChannel(), name: 'mediaStoreChannel');

/// "Files › Downloads › ManhwaManiacs › Exports › {series}" (Android 10+) or the iOS route.
String exportPathLine(ExportDestination d, String series) => switch (d) {
      ExportDestination.iosFiles => 'Files › On My iPhone › ManhwaManiacs › Exports › $series',
      ExportDestination.mediaStoreDownloads => 'Files › Downloads › ManhwaManiacs › Exports › $series',
      ExportDestination.shareOnly => '',
    };
