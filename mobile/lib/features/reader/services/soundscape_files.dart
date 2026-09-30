import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The eight house-sound loops, in the order the picker lists them.
const List<String> soundscapeIds = [
  'projector-room',
  'rain-on-glass',
  'night-city',
  'cafe',
  'night-wind',
  'low-drone',
  'afternoon-park',
  'temple-bells',
];

/// The cache folder under the application support directory; bump when a recording changes.
const String soundscapeCacheDir = 'soundscapes-v1';

/// `m4a` on iOS and `ogg` on Android (cinematic 9.4.2 Formats).
String soundscapeExtension() => Platform.isIOS || Platform.isMacOS ? 'm4a' : 'ogg';

/// Downloads and caches the loops. [dio] carries the API base URL; [root] and [ext] are seams for
/// tests, defaulting to the support directory and the platform format.
class SoundscapeFiles {
  SoundscapeFiles(this._dio, {Future<Directory> Function()? root, String? ext})
      : _root = root ?? getApplicationSupportDirectory,
        _ext = ext ?? soundscapeExtension();

  final Dio _dio;
  final Future<Directory> Function() _root;
  final String _ext;

  Future<File> _fileFor(String id) async => File(p.join((await _root()).path, soundscapeCacheDir, '$id.$_ext'));

  Future<bool> isCached(String id) async {
    final f = await _fileFor(id);
    return f.existsSync() && f.lengthSync() > 0;
  }

  /// The cached file, downloaded once. A partial download is written to `<name>.part` and renamed
  /// when complete, so a killed download never leaves a truncated loop behind.
  Future<File> soundscapeFile(String id) async {
    final file = await _fileFor(id);
    if (file.existsSync() && file.lengthSync() > 0) return file;
    await file.parent.create(recursive: true);
    final part = File('${file.path}.part');
    try {
      await _dio.download('/app/soundscapes/$id.$_ext', part.path);
      await part.rename(file.path);
    } catch (_) {
      if (part.existsSync()) part.deleteSync();
      rethrow;
    }
    return file;
  }
}
