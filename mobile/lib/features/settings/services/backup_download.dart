import 'dart:io';
import 'dart:ui' show Rect;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// `manhwamaniacs-backup-yyyyMMdd-HHmm.db`.
String backupFileName(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'manhwamaniacs-backup-${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}.db';
}

/// The reason a picked restore file is refused, or null when it is fine.
String? validateRestoreFile({required String name, required int size}) {
  if (!name.toLowerCase().endsWith('.db')) return "That isn't a .db file.";
  if (size <= 0) return 'That file is empty.';
  return null;
}

/// `124 MB OF 412 MB` (or `124 MB` while the total is unknown).
String backupProgressLabel(int received, int total) {
  String mb(int b) => '${(b / (1024 * 1024)).round()} MB';
  return total > 0 ? '${mb(received)} OF ${mb(total)}' : mb(received);
}

/// Cinematic 8.30.6: streams `/backup/export` with the app's own authenticated client into the
/// temporary directory, then hands the file to the share sheet.
class BackupDownloader {
  BackupDownloader(this._dio, {Future<Directory> Function()? tempDir, DateTime Function()? clock, Future<void> Function(String path)? share})
      : _tempDir = tempDir ?? getTemporaryDirectory,
        _clock = clock ?? DateTime.now,
        _share = share;

  final Dio _dio;
  final Future<Directory> Function() _tempDir;
  final DateTime Function() _clock;
  final Future<void> Function(String path)? _share;

  /// Downloads and returns the file path; [onProgress] gets received and total bytes (total is -1
  /// when the server sends no length).
  Future<String> download({required bool includeCaches, void Function(int received, int total)? onProgress}) async {
    final dir = await _tempDir();
    final path = '${dir.path}/${backupFileName(_clock())}';
    await _dio.download(
      '/backup/export',
      path,
      // `include_cache=true` only when asked; the backend's default is false (glass 8.25.10).
      queryParameters: includeCaches ? const {'include_cache': true} : null,
      onReceiveProgress: onProgress,
    );
    return path;
  }

  /// Opens the share sheet; [origin] is the global rect of the button that asked (the iPad popover anchor).
  Future<void> share(String path, {Rect? origin}) => _share?.call(path) ?? _sharePath(path, origin);

  static Future<void> _sharePath(String path, Rect? origin) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: 'application/octet-stream')], sharePositionOrigin: origin));
  }
}

final backupDownloaderProvider = Provider<BackupDownloader>((ref) => BackupDownloader(ref.watch(dioProvider)), name: 'backupDownloader');
