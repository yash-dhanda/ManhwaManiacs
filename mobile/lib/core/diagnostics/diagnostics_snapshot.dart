import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Device facts shown on the Diagnostics screens (both skins).
class DeviceFacts {
  const DeviceFacts({required this.platform, required this.osVersion, required this.cores, required this.buildMode});

  final String platform, osVersion, buildMode;
  final int cores;

  factory DeviceFacts.read() => DeviceFacts(
        platform: kIsWeb
            ? 'Web'
            : Platform.isAndroid
                ? 'Android'
                : Platform.isIOS
                    ? 'iOS'
                    : Platform.operatingSystem,
        osVersion: kIsWeb ? 'browser' : _short(Platform.operatingSystemVersion),
        cores: kIsWeb ? 0 : Platform.numberOfProcessors,
        buildMode: kDebugMode ? 'debug' : (kProfileMode ? 'profile' : 'release'),
      );

  static String _short(String raw) => raw.length > 40 ? '${raw.substring(0, 40)}…' : raw;
}

/// A live look at Flutter's image cache.
class ImageCacheFigures {
  const ImageCacheFigures({required this.live, required this.cached, required this.maxCached, required this.bytes, required this.maxBytes});

  final int live, cached, maxCached, bytes, maxBytes;

  factory ImageCacheFigures.read() {
    final c = PaintingBinding.instance.imageCache;
    return ImageCacheFigures(
      live: c.liveImageCount,
      cached: c.currentSize,
      maxCached: c.maximumSize,
      bytes: c.currentSizeBytes,
      maxBytes: c.maximumSizeBytes,
    );
  }

  String get memoryLabel => '${_mb(bytes)} / ${_mb(maxBytes)}';

  static String _mb(int b) => '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// "1920 × 1080 @ 2.0x" for [view].
String screenLabel(Size logical, double dpr) =>
    '${logical.width.toStringAsFixed(0)} × ${logical.height.toStringAsFixed(0)} @ ${dpr.toStringAsFixed(1)}x';

/// The jank tone: `set` below 5 %, `spot` below 15 %, `proof` above.
enum JankTone { good, warn, bad }

JankTone jankTone(double percent) => percent < 5 ? JankTone.good : (percent < 15 ? JankTone.warn : JankTone.bad);
