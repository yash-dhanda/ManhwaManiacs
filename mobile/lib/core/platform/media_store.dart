
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `mm/media` channel (Android): saving into the shared media collections.
/// Every other platform, and the test host, answers `false`.
///
/// mobile/17 adds `saveDownload` beside these two.
class MediaStore {
  const MediaStore();

  static const MethodChannel _channel = MethodChannel('mm/media');

  bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// True on Android 10 (API 29) and later: `Save image` is offered there.
  Future<bool> canSaveImage() async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('canSaveImage') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Saves a PNG into `Pictures/ManhwaManiacs` (no permission needed). True on success.
  Future<bool> saveImage(Uint8List bytes, String name) async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('saveImage', {'bytes': bytes, 'name': name}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final mediaStoreProvider = Provider<MediaStore>((_) => const MediaStore(), name: 'mediaStore');
