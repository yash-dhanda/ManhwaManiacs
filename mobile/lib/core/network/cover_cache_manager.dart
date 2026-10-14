import 'dart:async';

import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The on-device cover cache: a cover is fetched once, kept on the phone, and
/// every later paint of it reads the file, with no network and no limiter slot.
///
/// This replaces `DefaultCacheManager` for covers because its defaults are made
/// for a handful of avatars, not a catalogue:
///
/// * **200 objects.** One grid page is ~24 covers, so a few pages of browsing
///   pushed the earlier ones out and they were fetched again (18+ sources, whose
///   covers are the slowest upstream, made this the most visible).
/// * **The temp directory.** iOS and Android both purge it under storage
///   pressure, so "saved on the phone" was not true. This cache lives in the
///   application-support directory, beside the offline chapter store.
/// * **30 days stale, then revalidate on every paint.** A cover is immutable for
///   a URL, so the validity is a year (see [CoverFileService]).
class CoverCacheManager extends CacheManager {
  CoverCacheManager._() : super(_config());

  /// The one shared instance; created on first use so tests that never paint a
  /// remote cover never touch the platform channels.
  static final CoverCacheManager instance = CoverCacheManager._();

  /// Folder / database name under the application-support directory.
  static const cacheKey = 'mmCovers';

  /// Covers are 96-720 px WebP/JPEG (see `kCoverSnapWidths`), tens of KB each,
  /// so this is a few hundred MB at the very most and normally far less.
  static const maxCovers = 3000;

  /// How long a stored cover is trusted before it is revalidated (ETag, so an
  /// unchanged one costs a 304) and how long an untouched one is kept.
  static const keepFor = Duration(days: 365);

  static Config _config() => Config(
        cacheKey,
        stalePeriod: keepFor,
        maxNrOfCacheObjects: maxCovers,
        fileSystem: SupportDirFileSystem(cacheKey),
        fileService: CoverFileService(),
      );
}

/// Stores cache files under `getApplicationSupportDirectory()/<key>`.
///
/// The stock `IOFileSystem` hard-codes `getTemporaryDirectory()`, which is the
/// part that makes a cache purgeable; everything else is the same.
class SupportDirFileSystem implements FileSystem {
  SupportDirFileSystem(this._key, {Future<String> Function()? baseDir})
      : _baseDir = baseDir ?? _supportPath;

  final String _key;
  final Future<String> Function() _baseDir;
  Future<Directory>? _dir;

  static Future<String> _supportPath() async =>
      (await getApplicationSupportDirectory()).path;

  Future<Directory> _create() async {
    final directory =
        const LocalFileSystem().directory(p.join(await _baseDir(), _key));
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<File> createFile(String name) async {
    var directory = await (_dir ??= _create());
    // The OS (or the user clearing app data) can remove the folder under us.
    if (!await directory.exists()) {
      directory = await (_dir = _create());
    }
    return directory.childFile(name);
  }
}

/// The cover [FileService]: [HttpFileService] with two changes.
///
/// * A response is trusted for [CoverCacheManager.keepFor] whatever
///   `Cache-Control` says, so a cover already on the phone is never re-asked for
///   just because the server's `max-age` lapsed.
/// * A transient failure (connection error, 429, 5xx) is retried with a short
///   backoff. An 18+ source's first cover fetch often needs a second try, and
///   the stock manager gives up after one.
class CoverFileService extends FileService {
  CoverFileService({
    FileService? inner,
    this.attempts = 3,
    this.backoff = const Duration(seconds: 1),
  }) : _inner = inner ?? HttpFileService();

  final FileService _inner;

  /// Total tries per cover, the first included.
  final int attempts;

  /// Wait before try *n+1* is `backoff * n`.
  final Duration backoff;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    for (var attempt = 1;; attempt++) {
      try {
        final response = await _inner.get(url, headers: headers);
        if (!_transient(response.statusCode) || attempt >= attempts) {
          return _LongLived(response);
        }
        // An unlistened streamed response holds its socket open.
        unawaited(response.content.drain<void>().catchError((Object _) {}));
      } on Exception {
        if (attempt >= attempts) rethrow;
      }
      await Future<void>.delayed(backoff * attempt);
    }
  }

  static bool _transient(int status) => status == 429 || status >= 500;
}

class _LongLived implements FileServiceResponse {
  _LongLived(this._inner) : _receivedAt = DateTime.now();

  final FileServiceResponse _inner;
  final DateTime _receivedAt;

  @override
  Stream<List<int>> get content => _inner.content;

  @override
  int? get contentLength => _inner.contentLength;

  @override
  int get statusCode => _inner.statusCode;

  @override
  DateTime get validTill => _receivedAt.add(CoverCacheManager.keepFor);

  @override
  String? get eTag => _inner.eTag;

  @override
  String get fileExtension => _inner.fileExtension;
}
